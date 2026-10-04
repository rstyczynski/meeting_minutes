import Foundation
import Testing
@testable import MeetingCore

struct MeetingIntegrationTests {
    @Test func testLongSilenceSavedRecord() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let record = try JSONDecoder().decode(MeetingRecord.self, from: Data(contentsOf:
            URL(fileURLWithPath: "tests/fixtures/long_silence_saved_record.json")))
        let store = MeetingStore(directory: root)
        try store.save(record)
        let reading = try record.readableTranscript()
        #expect(reading.utterances.count == 2)
        #expect(reading.utterances.map(\.speakerID) == ["S1", "S1"])
        #expect(reading.utterances[0].text.hasSuffix("sygnał - od razu zaczynamy."))
        #expect(reading.utterances[0].range.endSeconds == 148.4)
        #expect(reading.utterances[1].range.startSeconds == 181.68)
        #expect(reading.utterances[1].sourceSegmentIDs.first == "segment_105")
        let inspection = try cli(["inspect-cleanup", record.id.uuidString, "--store", root.path])
        #expect(inspection.0 == 0)
        #expect(try JSONDecoder().decode(TranscriptCleanupResult.self,
            from: Data(inspection.1.utf8)) == reading)
        let settings = root.appendingPathComponent("settings.json")
        try Data("{\"transcriber\":\"fluid\",\"transcriptCleanup\":{\"longSilenceBoundarySeconds\":60}}".utf8).write(to: settings)
        let command = ["configure-cleanup", record.id.uuidString, "--settings", settings.path, "--store", root.path]
        #expect(try cli(command).0 == 0)
        let joined = try store.load(record.id)
        #expect(joined.transcriptCleanupPolicy?.longSilenceBoundarySeconds == 60)
        #expect(try joined.readableTranscript().utterances.count == 1)
        #expect(joined.segments == record.segments)
        #expect(joined.transcriptRangeCorrections == record.transcriptRangeCorrections)
        let path = root.appendingPathComponent("\(record.id.uuidString).json")
        let before = try Data(contentsOf: path)
        try Data("{\"transcriber\":\"fluid\",\"transcriptCleanup\":{\"longSilenceBoundarySeconds\":0}}".utf8).write(to: settings)
        #expect(try cli(command).0 == 2)
        #expect(try Data(contentsOf: path) == before)
    }

    @Test func testRangeStoreCorrection() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let raw = try ["To", "jest", "kwota", "milionów."] .enumerated().map { index, text in
            TranscriptSegment(id: "p\(index)",
                range: try SourceRange(startSeconds: Double(index), endSeconds: Double(index + 1)),
                speakerID: "S1", text: text)
        }
        var record = MeetingRecord(sourcePath: "/tmp/fixture.wav", segments: raw,
            backend: "fixture", modelRevision: "test")
        record.reviewItems = [ReviewItem(kind: .summary, text: "Old draft", sourceSegmentIDs: ["p0"], sourceRange: raw[0].range)]
        let store = MeetingStore(directory: root)
        try store.save(record)
        let target = try record.transcriptSelection(utteranceID: "utt_1", range: NSRange(location: 0, length: 13))
        let path = root.appendingPathComponent("\(record.id.uuidString).json")
        let before = try Data(contentsOf: path)
        #expect(throws: Error.self) {
            _ = try store.correctTranscript(record.id, selection: target, to: "To oznacza budżet", audioReviewed: false)
        }
        #expect(try Data(contentsOf: path) == before)
        let updated = try store.correctTranscript(record.id, selection: target, to: "To oznacza budżet", audioReviewed: true)
        #expect(updated.segments == raw && updated.reviewItems.isEmpty)
        var reload = try store.load(record.id)
        #expect(try reload.readableTranscript().utterances[0].text == "To oznacza budżet milionów.")
        let overlappingPhrase = try reload.transcriptSelection(utteranceID: "utt_1",
            range: (try reload.readableTranscript().utterances[0].text as NSString).range(of: "budżet milionów."))
        #expect(overlappingPhrase.text == "budżet milionów.")
        reload = try store.correctTranscript(record.id, selection: overlappingPhrase,
            to: "budżet państwa.", audioReviewed: true)
        #expect(try reload.readableTranscript().utterances[0].text == "To oznacza budżet państwa.")
        #expect(reload.segments == raw)
        #expect(reload.transcriptRangeCorrections?.last?.supersededCorrectionIDs?.count == 1)
        let saved = try Data(contentsOf: path)
        #expect(throws: Error.self) {
            _ = try store.correctTranscript(record.id, selection: target, to: "Stale", audioReviewed: true)
        }
        #expect(try Data(contentsOf: path) == saved)
        let inspection = try cli(["inspect-cleanup", record.id.uuidString, "--store", root.path])
        #expect(inspection.0 == 0)
        #expect(inspection.1.contains("To oznacza budżet państwa."))
        let model = root.appendingPathComponent("model")
        try FileManager.default.createDirectory(at: model, withIntermediateDirectories: true)
        let captured = root.appendingPathComponent("captured.json")
        let response = root.appendingPathComponent("response.json")
        let helper = root.appendingPathComponent("capture.sh")
        try "#!/bin/sh\ncp \"$2\" '\(captured.path)'\ncp '\(response.path)' \"$3\"\n".write(to: helper, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: helper.path)
        let quote = "To oznacza budżet państwa."
        let valid: [String: Any] = [
            "topics": [["id": "t", "title": "Budżet", "sourceUtteranceIDs": ["utt_1"]]],
            "assignments": [["utteranceID": "utt_1", "topicIDs": ["t"]]],
            "summaries": [["topic_id": "t", "text": quote, "source_utterance_ids": ["utt_1"], "evidence_quote": quote]],
            "candidates": []]
        try JSONSerialization.data(withJSONObject: valid).write(to: response)
        let settings = root.appendingPathComponent("settings.json")
        try JSONSerialization.data(withJSONObject: ["transcriber": "fluid", "mlxModelDirectory": model.path,
                                                    "mlxExecutable": helper.path]).write(to: settings)
        let minutes = try cli(["summarize", record.id.uuidString, "--settings", settings.path, "--store", root.path])
        #expect(minutes.0 == 0)
        let input = try JSONSerialization.jsonObject(with: Data(contentsOf: captured)) as! [String: Any]
        #expect((input["utterances"] as! [[String: Any]])[0]["text"] as? String == quote)
        #expect(try store.load(record.id).reviewItems.first?.sourceSegmentIDs == raw.map(\.id))
        let selection = try reload.transcriptSelection(utteranceID: "utt_1", range: NSRange(location: 0, length: 2))
        let restored = try store.correctTranscript(record.id, selection: selection,
            to: selection.originalText, audioReviewed: true, restore: true)
        #expect(try restored.readableTranscript().utterances[0].text == "To jest kwota milionów.")
        #expect(try store.load(record.id).transcriptRangeCorrections?.count == 3)
        let legacy = try store.correctTranscript(record.id, segmentID: "p3", to: "miliardów.", audioReviewed: true)
        #expect(try legacy.readableTranscript().utterances[0].text == "To jest kwota miliardów.")
        #expect(legacy.segments == raw)
        // Backward decoding and the exact source anchors from the reported Sejm failure.
        let prior = try JSONDecoder().decode(MeetingRecord.self, from: Data(contentsOf:
            URL(fileURLWithPath: "tests/fixtures/selection_overlap_saved_record.json")))
        try store.save(prior)
        let previousText = try prior.readableTranscript().utterances[0].text
        let fragment = try prior.transcriptSelection(utteranceID: "utt_1",
            range: (previousText as NSString).range(of: "sygnał. Teraz zaczynamy."))
        #expect(fragment.text == "sygnał. Teraz zaczynamy.")
        let merged = try store.correctTranscript(prior.id, selection: fragment,
            to: "sygnał - od razu zaczynamy.", audioReviewed: true)
        #expect(try merged.readableTranscript().utterances[0].text ==
            previousText.replacingOccurrences(of: "sygnał. Teraz zaczynamy.", with: "sygnał - od razu zaczynamy."))
        #expect(merged.segments == prior.segments)
        #expect(merged.transcriptRangeCorrections?.count == 2)
        #expect(merged.transcriptRangeCorrections?.last?.supersededCorrectionIDs == prior.transcriptRangeCorrections?.map(\.id))
        #expect(try store.load(prior.id).readableTranscript() == merged.readableTranscript())

    }

    @Test func testReviewStoreCorrection() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let range = try SourceRange(startSeconds: 1, endSeconds: 3)
        let segment = TranscriptSegment(id: "word", range: range, speakerID: "S1",
                                        text: "The budget is thirty five million.")
        var original = MeetingRecord(sourcePath: "/tmp/synthetic.wav", segments: [segment],
            reviewItems: [ReviewItem(kind: .summary, text: "Old draft", sourceSegmentIDs: ["word"], sourceRange: range)],
            backend: "fixture", modelRevision: "controlled-test")
        original.cleanedTranscript = try TranscriptCleaner.prepare(original.segments)
        original.processingParameters["topicCoverage"] = "1/1"
        let store = MeetingStore(directory: root)
        try store.save(original)
        let file = root.appendingPathComponent("\(original.id.uuidString).json")
        let bytes = try Data(contentsOf: file)
        for (id, text, confirmed) in [("word", "New words", false), ("word", "  ", true), ("missing", "New words", true)] {
            #expect(throws: (any Error).self) {
                _ = try store.correctTranscript(original.id, segmentID: id, to: text, audioReviewed: confirmed)
            }
            #expect(try Data(contentsOf: file) == bytes)
        }
        var externallyEdited = try store.load(original.id)
        try externallyEdited.assignSpeakerName("S1", to: "Chair")
        try store.save(externallyEdited)
        let corrected = try store.correctTranscript(original.id, segmentID: "word",
            to: "The budget is thirty five billion.", audioReviewed: true)
        #expect(corrected.speakerNames["S1"] == "Chair")
        #expect(corrected.segments == original.segments)
        #expect(corrected.reviewItems.isEmpty && corrected.cleanedTranscript == nil)
        #expect(corrected.processingParameters["topicCoverage"] == nil)
        let reloaded = try store.load(original.id)
        let reading = try TranscriptCleaner.prepare(reloaded.segments, corrections: reloaded.transcriptCorrections ?? [])
        #expect(reading.utterances.first?.text == "The budget is thirty five billion.")
        let restored = try store.correctTranscript(original.id, segmentID: "word", to: segment.text, audioReviewed: true)
        #expect(restored.transcriptCorrections?.count == 2)
        #expect(try store.load(original.id).transcriptCorrections == restored.transcriptCorrections)
        let restoredReading = try TranscriptCleaner.prepare(restored.segments, corrections: restored.transcriptCorrections ?? [])
        #expect(restoredReading.utterances.first?.text == segment.text)
    }

    @Test func testMultiStageCLI() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = try TranscriptSegment(id: "d1", range: SourceRange(startSeconds: 3, endSeconds: 5),
                                           speakerID: nil, text: "We approved the budget.")
        let record = MeetingRecord(sourcePath: "/tmp/meeting.wav", segments: [source],
                                   backend: "fluid", modelRevision: "test")
        let store = MeetingStore(directory: root)
        try store.save(record)
        let model = root.appendingPathComponent("model")
        try FileManager.default.createDirectory(at: model, withIntermediateDirectories: true)
        let responseFile = root.appendingPathComponent("response.json")
        let helper = root.appendingPathComponent("model-helper.sh")
        try "#!/bin/sh\ncp \"$2\" '\(root.appendingPathComponent("captured-input.json").path)'\ncp '\(responseFile.path)' \"$3\"\n".write(to: helper,
            atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: helper.path)
        let settings = root.appendingPathComponent("settings.json")
        try JSONSerialization.data(withJSONObject: ["transcriber": "fluid",
                                                     "mlxModelDirectory": model.path,
                                                     "mlxExecutable": helper.path]).write(to: settings)
        let valid: [String: Any] = [
            "topics": [["id": "t1", "title": "Budget", "sourceUtteranceIDs": ["utt_1"]]],
            "assignments": [["utteranceID": "utt_1", "topicIDs": ["t1"]]],
            "summaries": [["topic_id": "t1", "text": "The budget received approval.",
                            "source_utterance_ids": ["utt_1"],
                            "evidence_quote": "We approved the budget."]],
            "candidates": [["topic_id": "t1", "kind": "decision", "text": "The budget was approved.",
                            "source_utterance_ids": ["utt_1"],
                            "evidence_quote": "We approved the budget."]]
        ]
        try JSONSerialization.data(withJSONObject: valid).write(to: responseFile)
        let arguments = ["summarize", record.id.uuidString, "--summarizer", "mlx",
                         "--pipeline", "multi-stage", "--settings", settings.path,
                         "--store", root.path]
        let success = try cli(arguments)
        if success.0 != 0 { Issue.record("Multi-stage CLI failed: \(success.1)") }
        #expect(success.0 == 0)
        let completed = try store.load(record.id)
        #expect(completed.reviewItems.map(\.kind) == [.summary, .decision])
        #expect(completed.reviewItems.allSatisfy { $0.sourceSegmentIDs == ["d1"] })
        #expect(completed.processingParameters["topicCoverage"] == "1/1")
        #expect(completed.speakerNames.isEmpty)
        let saved = root.appendingPathComponent("\(record.id.uuidString).json")
        let beforeFailure = try Data(contentsOf: saved)
        var invalid = valid
        invalid["assignments"] = []
        try JSONSerialization.data(withJSONObject: invalid).write(to: responseFile)
        let failure = try cli(arguments)
        #expect(failure.0 != 0)
        #expect(try Data(contentsOf: saved) == beforeFailure)
        let corrected = try cli(["transcribe", "correct", record.id.uuidString,
                                 "d1", "We approved the revised budget.",
                                 "--audio-reviewed", "yes", "--store", root.path])
        #expect(corrected.0 == 0)
        let afterCorrection = try store.load(record.id)
        #expect(afterCorrection.segments[0].text == source.text)
        #expect(afterCorrection.reviewItems.isEmpty)
        #expect(afterCorrection.transcriptCorrections?.last?.correctedText ==
                "We approved the revised budget.")

        let second = try TranscriptSegment(id: "d2", range: SourceRange(startSeconds: 7, endSeconds: 8),
                                           speakerID: "S1", text: "Discussion ended.")
        var configurable = MeetingRecord(sourcePath: record.sourcePath,
            segments: [TranscriptSegment(id: source.id, range: source.range,
                                         speakerID: "S1", text: source.text), second],
            speakerNames: ["S1": "Chair"], reviewItems: completed.reviewItems,
            backend: "fluid", modelRevision: "test")
        configurable.cleanedTranscript = try TranscriptCleaner.prepare(configurable.segments)
        configurable.topics = completed.topics
        configurable.topicAssignments = completed.topicAssignments
        configurable.processingParameters["topicCoverage"] = "1/1"
        try store.save(configurable)
        let profile = root.appendingPathComponent("profile.json")
        try Data("{\"transcriber\":\"fluid\",\"transcriptCleanup\":{\"grouping\":\"sourceParts\"}}".utf8).write(to: profile)
        let configure = ["configure-cleanup", configurable.id.uuidString,
                         "--settings", profile.path, "--store", root.path]
        #expect(try cli(configure).0 == 0)
        let configured = try store.load(configurable.id)
        #expect(configured.transcriptCleanupPolicy?.grouping == .sourceParts)
        #expect(configured.segments == configurable.segments)
        #expect(configured.speakerNames == configurable.speakerNames)
        #expect(configured.reviewItems.isEmpty && configured.cleanedTranscript == nil)
        #expect(configured.topics == nil && configured.topicAssignments == nil)
        #expect(configured.processingParameters["topicCoverage"] == nil)
        let inspection = try cli(["inspect-cleanup", configured.id.uuidString, "--store", root.path])
        #expect(inspection.0 == 0)
        let inspected = try JSONDecoder().decode(TranscriptCleanupResult.self, from: Data(inspection.1.utf8))
        #expect(inspected.utterances.count == 2)
        var twoParts = valid
        twoParts["topics"] = [["id": "t1", "title": "Budget", "sourceUtteranceIDs": ["utt_1", "utt_2"]]]
        twoParts["assignments"] = [["utteranceID": "utt_1", "topicIDs": ["t1"]],
                                   ["utteranceID": "utt_2", "topicIDs": ["t1"]]]
        try JSONSerialization.data(withJSONObject: twoParts).write(to: responseFile)
        var configuredArguments = arguments
        configuredArguments[1] = configured.id.uuidString
        #expect(try cli(configuredArguments).0 == 0)
        let input = try JSONSerialization.jsonObject(with: Data(contentsOf:
            root.appendingPathComponent("captured-input.json"))) as! [String: Any]
        let utterances = input["utterances"] as! [[String: Any]]
        #expect(utterances.map { $0["text"] as! String } == inspected.utterances.map(\.text))
        #expect(utterances.map { $0["id"] as! String } == inspected.utterances.map(\.id))
        #expect(utterances.allSatisfy { $0["speakerName"] as? String == "Chair" })
        #expect(try store.load(configured.id).cleanedTranscript == inspected)
        let configuredFile = root.appendingPathComponent("\(configured.id.uuidString).json")
        let savedConfigured = try Data(contentsOf: configuredFile)
        // Reapplying the same profile retains current derived minutes.
        #expect(try cli(configure).0 == 0)
        #expect(try Data(contentsOf: configuredFile) == savedConfigured)
        try Data("{\"transcriber\":\"fluid\",\"transcriptCleanup\":{\"maximumOverlapSeconds\":-1}}".utf8).write(to: profile)
        #expect(try cli(configure).0 != 0)
        #expect(try Data(contentsOf: configuredFile) == savedConfigured)
    }

    @Test func testEvidenceFirstCLI() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = MeetingStore(directory: root)
        let source = try TranscriptSegment(id: "d1", range: SourceRange(startSeconds: 3, endSeconds: 5),
                                           speakerID: "S1", text: "We approved the budget.")
        let record = MeetingRecord(sourcePath: "/tmp/meeting.wav", segments: [source],
                                   backend: "fluid", modelRevision: "test")
        try store.save(record)
        let model = root.appendingPathComponent("model")
        try FileManager.default.createDirectory(at: model, withIntermediateDirectories: true)
        let responseFile = root.appendingPathComponent("response.json")
        let helper = root.appendingPathComponent("model-helper.sh")
        try "#!/bin/sh\ncp '\(responseFile.path)' \"$3\"\n".write(to: helper,
            atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755],
                                              ofItemAtPath: helper.path)
        let response = """
        {"summary":{"text":"We approved the budget.","source_ids":["d1"]},
        "decisions":[{"text":"We approved the budget.","source_ids":["d1"]}],
        "actions":[],"open_questions":[]}
        """
        let wrapper = ["modelRevision": "test", "promptRevision": "test", "response": response]
        try JSONSerialization.data(withJSONObject: wrapper).write(to: responseFile)
        let settings = root.appendingPathComponent("settings.json")
        let config = ["transcriber": "fluid", "mlxModelDirectory": model.path,
                      "mlxExecutable": helper.path]
        try JSONSerialization.data(withJSONObject: config).write(to: settings)
        let result = try cli(["summarize", record.id.uuidString, "--summarizer", "mlx",
                              "--pipeline", "legacy",
                              "--settings", settings.path, "--store", root.path])
        guard result.0 == 0 else {
            Issue.record("CLI summarize failed: \(result.1)")
            return
        }
        let completed = try store.load(record.id)
        XCTAssertEqual(completed.reviewItems.map(\.kind), [.summary, .decision])
        XCTAssertTrue(completed.reviewItems.allSatisfy { $0.sourceSegmentIDs == ["d1"] })
        XCTAssertEqual(completed.reviewItems[1].sourceRange, source.range)
        XCTAssertTrue(completed.speakerNames.isEmpty)
    }

    @Test func testModelValidationFailurePreservesRecord() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = try TranscriptSegment(id: "d1", range: SourceRange(startSeconds: 3, endSeconds: 5),
                                           speakerID: "S1", text: "We approved the budget.")
        var record = MeetingRecord(sourcePath: "/tmp/meeting.wav", segments: [source],
                                   backend: "fluid", modelRevision: "test")
        record.renameSpeaker("S1", to: "Chair")
        let store = MeetingStore(directory: root)
        try store.save(record)
        let saved = root.appendingPathComponent("\(record.id.uuidString).json")
        let original = try Data(contentsOf: saved)
        let model = root.appendingPathComponent("model")
        try FileManager.default.createDirectory(at: model, withIntermediateDirectories: true)
        let responseFile = root.appendingPathComponent("response.json")
        let helper = root.appendingPathComponent("model-helper.sh")
        try "#!/bin/sh\ncp '\(responseFile.path)' \"$3\"\n".write(to: helper,
            atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755],
                                              ofItemAtPath: helper.path)
        let wrapper = ["modelRevision": "test", "promptRevision": "test", "response": "not json"]
        try JSONSerialization.data(withJSONObject: wrapper).write(to: responseFile)
        let settings = root.appendingPathComponent("settings.json")
        let config = ["transcriber": "fluid", "mlxModelDirectory": model.path,
                      "mlxExecutable": helper.path]
        try JSONSerialization.data(withJSONObject: config).write(to: settings)
        let result = try cli(["summarize", record.id.uuidString, "--summarizer", "mlx",
                              "--pipeline", "legacy",
                              "--settings", settings.path, "--store", root.path])
        XCTAssertTrue(result.0 != 0)
        XCTAssertTrue(result.1.contains("Model minutes response is not valid evidence JSON"))
        XCTAssertEqual(try Data(contentsOf: saved), original)
    }
    private var executable: URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/debug/meeting-summarizer")
    }

    private func cli(_ arguments: [String]) throws -> (Int32, String) {
        let process = Process()
        let output = Pipe()
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = output
        try process.run()
        process.waitUntilExit()
        let text = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (process.terminationStatus, text)
    }

    private var fixtureDirectory: URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("tests/fixtures")
    }

    private func reference() throws -> FixtureReference {
        try JSONDecoder().decode(FixtureReference.self,
            from: Data(contentsOf: fixtureDirectory.appendingPathComponent("synthetic_meeting_reference.json")))
    }

    private func createRecord(_ backend: TranscriptionBackend = .fluid,
                              directory: URL) throws -> MeetingRecord {
        let fixture = try reference()
        return try MeetingImporter(store: MeetingStore(directory: directory)).importMedia(
            fixtureDirectory.appendingPathComponent("synthetic_meeting.wav"),
            backend: backend, transcriber: FixtureTranscriber(reference: fixture),
            minutes: FixtureMinutesGenerator(reference: fixture))
    }

    @Test func testCLIRecordOpen() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let executable = repository.appendingPathComponent(".build/debug/meeting-summarizer")
        let media = fixtureDirectory.appendingPathComponent("synthetic_meeting.wav")
        let reference = fixtureDirectory.appendingPathComponent("synthetic_meeting_reference.json")
        let output = Pipe()
        let process = Process()
        process.executableURL = executable
        process.arguments = ["import", media.path, "--fixture-reference", reference.path,
                             "--store", root.path]
        process.standardOutput = output
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        let text = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let id = try #require(UUID(uuidString: text))
        let record = try MeetingStore(directory: root).load(id)
        XCTAssertEqual(record.segments.count, 5)
        XCTAssertEqual(record.sourcePath, media.path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: record.sourcePath))
    }

    @Test func testSourceLinks() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let record = try createRecord(directory: root)
        XCTAssertEqual(record.reviewItems.count, 3)
        let ids = Set(record.segments.map(\.id))
        XCTAssertTrue(record.reviewItems.allSatisfy { Set($0.sourceSegmentIDs).isSubset(of: ids) })
        XCTAssertTrue(record.reviewItems.allSatisfy { $0.sourceRange != nil })
    }

    @Test func testCorrectionAndReview() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = MeetingStore(directory: root)
        var record = try createRecord(directory: root)
        record.renameSpeaker("speaker_1", to: "Chair")
        try record.reassignSegment("turn_1", to: "speaker_2")
        try store.save(record)
        let loaded = try store.load(record.id)
        XCTAssertEqual(loaded.speakerNames["speaker_1"], "Chair")
        XCTAssertEqual(loaded.segments[0].speakerID, "speaker_2")
        XCTAssertNotNil(loaded.reviewItems[0].sourceRange)
    }

    @Test func testChunkMerge() throws {
        let fixture = try reference()
        let segments = try FixtureTranscriber(reference: fixture)
            .transcribe(fixtureDirectory.appendingPathComponent("synthetic_meeting.wav")).segments
        let chunks = stride(from: 0, to: segments.count, by: 2).map {
            Array(segments[$0..<min($0 + 2, segments.count)])
        }
        let merged = chunks.flatMap { $0 }
        XCTAssertEqual(merged.map(\.id), segments.map(\.id))
    }

    @Test func testBackendSelection() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let fluid = try createRecord(.fluid, directory: root)
        let whisper = try createRecord(.whisper, directory: root)
        XCTAssertEqual(fluid.segments, whisper.segments)
        XCTAssertEqual(fluid.backend, "fluid")
        XCTAssertEqual(whisper.backend, "whisper")
        XCTAssertEqual(fluid.modelRevision, "synthetic-reference-v1")
    }

    @Test func testFixtureGeneration() throws {
        let fixture = try reference()
        let wav = try Data(contentsOf: fixtureDirectory.appendingPathComponent("synthetic_meeting.wav"))
        XCTAssertGreaterThan(wav.count, 44)
        XCTAssertEqual(String(decoding: wav.prefix(4), as: UTF8.self), "RIFF")
        XCTAssertEqual(fixture.turns.count, 5)
        let ids = Set(fixture.turns.map(\.id))
        XCTAssertTrue(fixture.turns.allSatisfy { $0.startSeconds < $0.endSeconds })
        XCTAssertTrue(Set(fixture.minutes.decision.sourceTurns).isSubset(of: ids))
        XCTAssertTrue(Set(fixture.minutes.action.sourceTurns).isSubset(of: ids))
        XCTAssertTrue(Set(fixture.minutes.openQuestion.sourceTurns).isSubset(of: ids))
    }

    @Test func testThreeCommands() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let media = fixtureDirectory.appendingPathComponent("synthetic_meeting.wav")
        let reference = fixtureDirectory.appendingPathComponent("synthetic_meeting_reference.json")
        let created = try cli(["transcribe", media.path, "--transcriber", "fluid",
                               "--fixture-reference", reference.path, "--store", root.path])
        XCTAssertEqual(created.0, 0)
        let id = try #require(UUID(uuidString: created.1))
        let store = MeetingStore(directory: root)
        let transcript = try store.load(id)
        XCTAssertEqual(transcript.segments.count, 5)
        XCTAssertTrue(transcript.reviewItems.isEmpty)

        let recognized = try cli(["recognize", created.1, "--diarizer", "fluid",
                                  "--fixture-reference", reference.path, "--store", root.path])
        XCTAssertEqual(recognized.0, 0)
        XCTAssertEqual(try store.load(id).segments[0].speakerID, "speaker_1")
        let named = try cli(["recognize", "name", created.1, "speaker_2", "Ada",
                             "--store", root.path])
        XCTAssertEqual(named.0, 0)
        let moved = try cli(["recognize", "move", created.1, "turn_1", "speaker_2",
                             "--store", root.path])
        XCTAssertEqual(moved.0, 0)
        let afterEdits = try store.load(id)
        XCTAssertEqual(afterEdits.speakerNames["speaker_2"], "Ada")
        XCTAssertEqual(afterEdits.segments[0].speakerID, "speaker_2")
        XCTAssertEqual(afterEdits.segments[0].range, transcript.segments[0].range)

        let summarized = try cli(["summarize", created.1, "--summarizer", "mlx",
                                  "--fixture-reference", reference.path, "--store", root.path])
        XCTAssertEqual(summarized.0, 0)
        let completed = try store.load(id)
        XCTAssertEqual(completed.reviewItems.count, 4)
        XCTAssertEqual(completed.speakerNames["speaker_2"], "Ada")
        XCTAssertEqual(completed.processingParameters["minutesSource"], "fixture")
        XCTAssertEqual(completed.reviewItems.first?.kind, .summary)
    }

    @Test func testNeutralSummary() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let media = fixtureDirectory.appendingPathComponent("synthetic_meeting.wav")
        let reference = fixtureDirectory.appendingPathComponent("synthetic_meeting_reference.json")
        let created = try cli(["transcribe", media.path, "--fixture-reference", reference.path,
                               "--store", root.path])
        XCTAssertEqual(created.0, 0)
        let id = try #require(UUID(uuidString: created.1))
        let summarized = try cli(["summarize", created.1, "--fixture-reference",
                                  reference.path, "--store", root.path])
        XCTAssertEqual(summarized.0, 0)
        let record = try MeetingStore(directory: root).load(id)
        XCTAssertTrue(record.speakerNames.isEmpty)
        XCTAssertEqual(record.segments[3].speakerID, "speaker_2")
        XCTAssertEqual(record.reviewItems.first(where: { $0.kind == .action })?.ownerSpeakerID,
                       "speaker_2")
    }

    @Test func testFailurePreservesRecord() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let media = fixtureDirectory.appendingPathComponent("synthetic_meeting.wav")
        let reference = fixtureDirectory.appendingPathComponent("synthetic_meeting_reference.json")
        let created = try cli(["transcribe", media.path, "--fixture-reference", reference.path,
                               "--store", root.path])
        XCTAssertEqual(created.0, 0)
        let id = try #require(UUID(uuidString: created.1))
        let storedFile = root.appendingPathComponent("\(id.uuidString).json")
        let original = try Data(contentsOf: storedFile)
        let unknown = try cli(["recognize", UUID().uuidString,
                               "--fixture-reference", reference.path, "--store", root.path])
        XCTAssertTrue(unknown.0 != 0)
        XCTAssertTrue(unknown.1.contains("does not exist"))
        let missing = try cli(["summarize", created.1, "--summarizer", "mlx",
                               "--store", root.path])
        XCTAssertTrue(missing.0 != 0)
        XCTAssertTrue(missing.1.contains("Missing local model"))
        let badSpeaker = try cli(["recognize", "name", created.1, "speaker_99", "Ghost",
                                  "--store", root.path])
        XCTAssertTrue(badSpeaker.0 != 0)
        XCTAssertEqual(try Data(contentsOf: storedFile), original)
    }

    @Test func testLanguageRecord() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let media = fixtureDirectory.appendingPathComponent("synthetic_meeting.wav")
        let reference = fixtureDirectory.appendingPathComponent("synthetic_meeting_reference.json")
        let created = try cli(["transcribe", media.path, "--language", "pl",
                               "--fixture-reference", reference.path, "--store", root.path])
        XCTAssertEqual(created.0, 0)
        let id = try #require(UUID(uuidString: created.1))
        let record = try MeetingStore(directory: root).load(id)
        XCTAssertEqual(record.processingParameters["requestedLanguage"], "pl")
        XCTAssertEqual(record.segments.count, 5)
        let before = try FileManager.default.contentsOfDirectory(atPath: root.path).count
        let invalid = try cli(["transcribe", media.path, "--language", "de",
                               "--fixture-reference", reference.path, "--store", root.path])
        XCTAssertTrue(invalid.0 != 0)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path).count, before)
        let fluidSettings = root.appendingPathComponent("fluid-settings.json")
        try Data(#"{"transcriber":"fluid","fluidModelDirectory":"/tmp/parakeet-v2","fluidExecutable":"/tmp/fluid","fluidModelVersion":"v2"}"#.utf8)
            .write(to: fluidSettings)
        let wrongFluid = try cli(["transcribe", media.path, "--language", "pl",
                                  "--settings", fluidSettings.path, "--store", root.path])
        XCTAssertTrue(wrongFluid.0 != 0)
        XCTAssertTrue(wrongFluid.1.contains("English only"))
        let whisperSettings = root.appendingPathComponent("whisper-settings.json")
        try Data(#"{"transcriber":"whisper","whisperModelPath":"/tmp/ggml-base.en.bin","whisperExecutable":"/tmp/whisper"}"#.utf8)
            .write(to: whisperSettings)
        let wrongWhisper = try cli(["transcribe", media.path, "--transcriber", "whisper",
                                    "--language", "pl", "--settings", whisperSettings.path,
                                    "--store", root.path])
        XCTAssertTrue(wrongWhisper.0 != 0)
        XCTAssertTrue(wrongWhisper.1.contains("English only"))
        XCTAssertEqual(try MeetingStore(directory: root).load(id).processingParameters["requestedLanguage"], "pl")
    }
}
