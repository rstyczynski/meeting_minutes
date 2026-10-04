import Foundation
import Testing
@testable import MeetingCore

struct MeetingIntegrationTests {
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
        try "#!/bin/sh\ncp '\(responseFile.path)' \"$3\"\n".write(to: helper,
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
