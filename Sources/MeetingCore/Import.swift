import Foundation

public struct TranscriptionResult: Sendable {
    public let segments: [TranscriptSegment]
    public let modelRevision: String
    public let parameters: [String: String]

    public init(segments: [TranscriptSegment], modelRevision: String,
                parameters: [String: String] = [:]) {
        self.segments = segments
        self.modelRevision = modelRevision
        self.parameters = parameters
    }
}

public protocol Transcribing {
    func transcribe(_ media: URL) throws -> TranscriptionResult
}

public protocol MinutesGenerating {
    func generate(from segments: [TranscriptSegment]) throws -> [ReviewItem]
}

public struct EmptyMinutesGenerator: MinutesGenerating {
    public init() {}
    public func generate(from segments: [TranscriptSegment]) throws -> [ReviewItem] { [] }
}

public struct MeetingImporter {
    public let store: MeetingStore
    public init(store: MeetingStore) { self.store = store }

    @discardableResult
    public func importMedia(_ media: URL, backend: TranscriptionBackend,
                            transcriber: any Transcribing,
                            minutes: any MinutesGenerating = EmptyMinutesGenerator()) throws -> MeetingRecord {
        try MediaValidator.validate(media)
        let result = try transcriber.transcribe(media)
        guard !result.segments.isEmpty else { throw MeetingError.adapterFailure("No transcript segments") }
        let items = try minutes.generate(from: result.segments)
        let record = MeetingRecord(sourcePath: media.standardizedFileURL.path,
                                   segments: result.segments, reviewItems: items,
                                   backend: backend.rawValue,
                                   modelRevision: result.modelRevision,
                                   processingParameters: result.parameters)
        try store.save(record)
        return record
    }
}

public struct FixtureReference: Decodable {
    public struct Turn: Decodable {
        public let id: String
        public let speaker: String
        public let text: String
        public let startSeconds: Double
        public let endSeconds: Double
        enum CodingKeys: String, CodingKey {
            case id, speaker, text
            case startSeconds = "start_seconds", endSeconds = "end_seconds"
        }
    }
    public struct Item: Decodable {
        public let text: String
        public let sourceTurns: [String]
        public let owner: String?
        enum CodingKeys: String, CodingKey {
            case text, owner, sourceTurns = "source_turns"
        }
    }
    public struct Minutes: Decodable {
        public let decision: Item
        public let action: Item
        public let openQuestion: Item
        enum CodingKeys: String, CodingKey {
            case decision, action, openQuestion = "open_question"
        }
    }
    public let turns: [Turn]
    public let minutes: Minutes
}

public struct FixtureTranscriber: Transcribing {
    public let reference: FixtureReference
    public init(reference: FixtureReference) { self.reference = reference }

    public func transcribe(_ media: URL) throws -> TranscriptionResult {
        let segments = try reference.turns.map {
            TranscriptSegment(id: $0.id,
                              range: try SourceRange(startSeconds: $0.startSeconds,
                                                     endSeconds: $0.endSeconds),
                              speakerID: $0.speaker, text: $0.text)
        }
        return TranscriptionResult(segments: segments, modelRevision: "synthetic-reference-v1",
                                   parameters: ["source": "fixture"])
    }
}

public struct FixtureMinutesGenerator: MinutesGenerating {
    public let reference: FixtureReference
    public init(reference: FixtureReference) { self.reference = reference }

    public func generate(from segments: [TranscriptSegment]) throws -> [ReviewItem] {
        try [
            MinutesValidator.item(kind: .decision, text: reference.minutes.decision.text,
                                  sourceIDs: reference.minutes.decision.sourceTurns, segments: segments),
            MinutesValidator.item(kind: .action, text: reference.minutes.action.text,
                                  sourceIDs: reference.minutes.action.sourceTurns,
                                  owner: reference.minutes.action.owner, segments: segments),
            MinutesValidator.item(kind: .openQuestion, text: reference.minutes.openQuestion.text,
                                  sourceIDs: reference.minutes.openQuestion.sourceTurns,
                                  segments: segments),
        ]
    }
}
