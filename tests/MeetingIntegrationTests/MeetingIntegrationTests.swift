import Foundation
import Testing
@testable import MeetingCore

struct MeetingIntegrationTests {
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
}
