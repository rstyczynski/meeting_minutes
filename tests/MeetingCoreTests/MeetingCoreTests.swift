import Foundation
import Testing
@testable import MeetingCore

struct MeetingCoreTests {
    private func segment(_ id: String = "s1", speaker: String? = "speaker_1") throws -> TranscriptSegment {
        TranscriptSegment(id: id, range: try SourceRange(startSeconds: 1, endSeconds: 2),
                          speakerID: speaker, text: "We decide to test both engines.")
    }

    @Test func testRecordRanges() throws {
        XCTAssertThrowsError(try SourceRange(startSeconds: -1, endSeconds: 2))
        XCTAssertThrowsError(try SourceRange(startSeconds: 2, endSeconds: 1))
        XCTAssertThrowsError(try SourceRange(startSeconds: .nan, endSeconds: 2))
        let item = try MinutesValidator.item(kind: .decision, text: "Test both engines",
                                              sourceIDs: ["s1"], segments: [segment()])
        XCTAssertEqual(item.sourceRange, try SourceRange(startSeconds: 1, endSeconds: 2))
        let noSource = try MinutesValidator.item(kind: .summary, text: "Summary",
                                                  sourceIDs: [], segments: [segment()])
        XCTAssertNil(noSource.sourceRange)
    }

    @Test func testAtomicStore() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = MeetingStore(directory: directory)
        var record = MeetingRecord(sourcePath: "/tmp/source.wav", segments: [try segment()],
                                   backend: "fluid", modelRevision: "test")
        try store.save(record)
        record.renameSpeaker("speaker_1", to: "Alex")
        try store.save(record)
        XCTAssertEqual(try MeetingStore(directory: directory).load(record.id).speakerNames["speaker_1"], "Alex")
        XCTAssertThrowsError(try store.load(UUID()))
    }

    @Test func testImportRejection() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        XCTAssertThrowsError(try MediaValidator.validate(root.appendingPathComponent("missing.wav")))
        let txt = root.appendingPathComponent("source.txt")
        try Data("keep".utf8).write(to: txt)
        XCTAssertThrowsError(try MediaValidator.validate(txt))
        XCTAssertEqual(try Data(contentsOf: txt), Data("keep".utf8))
    }

    @Test func testCorrections() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = MeetingStore(directory: directory)
        var record = MeetingRecord(sourcePath: "/tmp/source.wav", segments: [try segment()],
                                   backend: "fluid", modelRevision: "test")
        record.renameSpeaker("speaker_2", to: "Pat")
        try record.reassignSegment("s1", to: "speaker_2")
        try store.save(record)
        let loaded = try store.load(record.id)
        XCTAssertEqual(loaded.speakerNames["speaker_2"], "Pat")
        XCTAssertEqual(loaded.segments[0].speakerID, "speaker_2")
        XCTAssertEqual(loaded.sourcePath, "/tmp/source.wav")
    }

    @Test func testMinutesValidation() throws {
        let s = try segment()
        XCTAssertThrowsError(try MinutesValidator.item(kind: .decision, text: "bad",
                                                         sourceIDs: ["unknown"], segments: [s]))
        XCTAssertThrowsError(try MinutesValidator.item(kind: .action, text: "bad",
                                                         sourceIDs: ["s1"], owner: "speaker_2",
                                                         segments: [s]))
        let item = try MinutesValidator.item(kind: .action, text: "good",
                                              sourceIDs: ["s1"], owner: "speaker_1",
                                              segments: [s])
        XCTAssertEqual(item.ownerSpeakerID, "speaker_1")
    }

    @Test func testBackendConfiguration() throws {
        let config = MeetingConfiguration(transcriber: "fluid")
        XCTAssertEqual(try config.selectedBackend(override: nil), .fluid)
        XCTAssertEqual(try config.selectedBackend(override: "whisper"), .whisper)
        XCTAssertThrowsError(try config.selectedBackend(override: "unknown"))
        XCTAssertThrowsError(try MeetingConfiguration(transcriber: "bad").selectedBackend(override: nil))
    }

    @Test func testTranscriptOnly() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fixtureDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("tests/fixtures")
        let reference = try JSONDecoder().decode(FixtureReference.self, from: Data(contentsOf:
            fixtureDirectory.appendingPathComponent("synthetic_meeting_reference.json")))
        let store = MeetingStore(directory: directory)
        let record = try MeetingImporter(store: store).importMedia(
            fixtureDirectory.appendingPathComponent("synthetic_meeting.wav"),
            backend: .fluid, transcriber: FixtureTranscriber(reference: reference))
        XCTAssertEqual(record.segments.count, 5)
        XCTAssertTrue(record.reviewItems.isEmpty)
        let persisted = try store.load(record.id)
        XCTAssertTrue(persisted.reviewItems.isEmpty)
        XCTAssertThrowsError(try MeetingImporter(store: store).importMedia(
            fixtureDirectory.appendingPathComponent("missing.wav"),
            backend: .fluid, transcriber: FixtureTranscriber(reference: reference)))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path).count, 1)
    }

    @Test func testChairCorrections() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = MeetingStore(directory: directory)
        let first = try segment("s1", speaker: "speaker_1")
        let second = try segment("s2", speaker: "speaker_2")
        var record = MeetingRecord(sourcePath: "/tmp/source.wav", segments: [first, second],
                                   backend: "fluid", modelRevision: "test")
        try record.assignSpeakerName("speaker_2", to: " Ada ")
        try record.moveSegment("s1", to: "speaker_2")
        XCTAssertThrowsError(try record.assignSpeakerName("speaker_3", to: "Unknown"))
        XCTAssertThrowsError(try record.moveSegment("s1", to: "speaker_3"))
        XCTAssertThrowsError(try record.moveSegment("missing", to: "speaker_2"))
        try store.save(record)
        let loaded = try store.load(record.id)
        XCTAssertEqual(loaded.speakerNames["speaker_2"], "Ada")
        XCTAssertEqual(loaded.segments[0].speakerID, "speaker_2")
        XCTAssertEqual(loaded.segments[0].range, first.range)
    }

    @Test func testOptionalMinutes() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fixtureDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("tests/fixtures")
        let reference = try JSONDecoder().decode(FixtureReference.self, from: Data(contentsOf:
            fixtureDirectory.appendingPathComponent("synthetic_meeting_reference.json")))
        let store = MeetingStore(directory: directory)
        let record = try MeetingImporter(store: store).importMedia(
            fixtureDirectory.appendingPathComponent("synthetic_meeting.wav"),
            backend: .fluid, transcriber: FixtureTranscriber(reference: reference))
        let summarized = try MeetingSummarizer(store: store).summarize(record.id,
            generator: FixtureSummaryGenerator(reference: reference),
            modelRevision: "synthetic-reference-v1", fixtureDerived: true)
        XCTAssertEqual(summarized.reviewItems.count, 4)
        XCTAssertTrue(summarized.speakerNames.isEmpty)
        XCTAssertEqual(summarized.reviewItems.first?.kind, .summary)
        XCTAssertThrowsError(try MinutesValidator.item(kind: .decision, text: "bad",
            sourceIDs: ["missing"], segments: record.segments))
    }

    @Test func testLanguageCompatibility() throws {
        let config = MeetingConfiguration(fluidModelVersion: "v2")
        XCTAssertEqual(try config.selectedLanguage(override: nil), .en)
        XCTAssertEqual(try config.selectedLanguage(override: "pl"), .pl)
        XCTAssertEqual(try config.selectedLanguage(override: "auto"), .auto)
        XCTAssertThrowsError(try config.selectedLanguage(override: "de"))
        XCTAssertThrowsError(try config.selectedFluidVersion(for: .pl))
        XCTAssertThrowsError(try config.selectedFluidVersion(for: .auto))
        XCTAssertEqual(try MeetingConfiguration(fluidModelVersion: "v3")
            .selectedFluidVersion(for: .pl), .v3)
        XCTAssertThrowsError(try MeetingConfiguration.validateWhisperModel(
            "/tmp/ggml-base.en.bin", language: .pl))
        try MeetingConfiguration.validateWhisperModel(
            "/tmp/ggml-base.bin", language: .pl)
    }
}
