import Foundation
import Testing
@testable import MeetingCore

struct MeetingIntegrationTests {
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
}
