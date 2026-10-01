import Foundation

public struct SpeakerTurn: Sendable {
    public let range: SourceRange
    public let speakerID: String

    public init(range: SourceRange, speakerID: String) {
        self.range = range
        self.speakerID = speakerID
    }
}

public struct DiarizationResult: Sendable {
    public let turns: [SpeakerTurn]
    public let warnings: [QualityWarning]
    public let modelRevision: String

    public init(turns: [SpeakerTurn], warnings: [QualityWarning] = [],
                modelRevision: String) {
        self.turns = turns
        self.warnings = warnings
        self.modelRevision = modelRevision
    }
}

public protocol Diarizing {
    func diarize(_ media: URL) throws -> DiarizationResult
}

public struct FixtureDiarizer: Diarizing {
    public let reference: FixtureReference
    public init(reference: FixtureReference) { self.reference = reference }

    public func diarize(_ media: URL) throws -> DiarizationResult {
        let turns = try reference.turns.map {
            SpeakerTurn(range: try SourceRange(startSeconds: $0.startSeconds,
                                               endSeconds: $0.endSeconds),
                        speakerID: $0.speaker)
        }
        return DiarizationResult(turns: turns, modelRevision: "synthetic-reference-v1")
    }
}

public struct FluidProcessDiarizer: Diarizing {
    public let executable: String
    public let modelDirectory: String

    public init(executable: String, modelDirectory: String) {
        self.executable = executable
        self.modelDirectory = modelDirectory
    }

    public func diarize(_ media: URL) throws -> DiarizationResult {
        guard FileManager.default.fileExists(atPath: modelDirectory) else {
            throw MeetingError.missingModel("fluid diarizer")
        }
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("meeting-diarization-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: output) }
        _ = try runProcess(executable, ["--diarize", "--model-dir", modelDirectory,
                                        "--input", media.path, "--output-json", output.path])
        let decoded = try JSONDecoder().decode(FluidDiarizationOutput.self,
                                               from: Data(contentsOf: output))
        let turns = try decoded.segments.map {
            SpeakerTurn(range: try SourceRange(startSeconds: $0.start,
                                               endSeconds: $0.end), speakerID: $0.speaker)
        }
        let warnings = try decoded.warnings.map {
            QualityWarning(range: try SourceRange(startSeconds: $0.start,
                                                  endSeconds: $0.end),
                           speakerID: $0.speaker, reason: $0.reason)
        }
        return DiarizationResult(turns: turns, warnings: warnings,
                                 modelRevision: decoded.modelRevision)
    }
}

private struct FluidDiarizationOutput: Decodable {
    struct Turn: Decodable {
        let start: Double
        let end: Double
        let speaker: String
    }
    struct Warning: Decodable {
        let start: Double
        let end: Double
        let speaker: String?
        let reason: String
    }
    let modelRevision: String
    let segments: [Turn]
    let warnings: [Warning]
}

public struct MeetingRecognizer {
    public let store: MeetingStore
    public init(store: MeetingStore) { self.store = store }

    @discardableResult
    public func recognize(_ id: UUID, diarizer: any Diarizing) throws -> MeetingRecord {
        var record = try store.load(id)
        let media = URL(fileURLWithPath: record.sourcePath)
        try MediaValidator.validate(media)
        let result = try diarizer.diarize(media)
        guard !result.turns.isEmpty else {
            throw MeetingError.adapterFailure("No speaker turns")
        }
        for index in record.segments.indices {
            let segment = record.segments[index]
            let ranked = result.turns.map { turn in
                (turn, max(0, min(turn.range.endSeconds, segment.range.endSeconds)
                       - max(turn.range.startSeconds, segment.range.startSeconds)))
            }
            if let best = ranked.max(by: { $0.1 < $1.1 }), best.1 > 0 {
                record.segments[index].speakerID = best.0.speakerID
            }
        }
        record.qualityWarnings = result.warnings
        record.processingParameters["diarizer"] = "fluid"
        record.processingParameters["diarizerRevision"] = result.modelRevision
        try store.save(record)
        return record
    }
}
