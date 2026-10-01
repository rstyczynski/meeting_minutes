import Foundation

public enum MeetingError: Error, LocalizedError, Equatable {
    case invalidRange
    case missingMedia
    case unsupportedMedia
    case invalidBackend(String)
    case missingModel(String)
    case missingRecord
    case invalidSource(String)
    case unsupportedOwner(String)
    case adapterFailure(String)

    public var errorDescription: String? {
        switch self {
        case .invalidRange: "Invalid source time range"
        case .missingMedia: "Media file does not exist"
        case .unsupportedMedia: "Unsupported media format (expected WAV)"
        case .invalidBackend(let name): "Invalid transcription backend: \(name)"
        case .missingModel(let name): "Missing local model for \(name)"
        case .missingRecord: "Meeting record does not exist"
        case .invalidSource(let id): "Unknown source segment: \(id)"
        case .unsupportedOwner(let id): "Unsupported owner: \(id)"
        case .adapterFailure(let message): "Adapter failed: \(message)"
        }
    }
}

public struct SourceRange: Codable, Sendable, Equatable {
    public let startSeconds: Double
    public let endSeconds: Double

    public init(startSeconds: Double, endSeconds: Double) throws {
        guard startSeconds.isFinite, endSeconds.isFinite,
              startSeconds >= 0, endSeconds > startSeconds else {
            throw MeetingError.invalidRange
        }
        self.startSeconds = startSeconds
        self.endSeconds = endSeconds
    }
}

public struct TranscriptSegment: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let range: SourceRange
    public var speakerID: String?
    public let text: String

    public init(id: String, range: SourceRange, speakerID: String?, text: String) {
        self.id = id
        self.range = range
        self.speakerID = speakerID
        self.text = text
    }
}

public enum ReviewKind: String, Codable, Sendable {
    case summary, decision, action, openQuestion
}

public struct ReviewItem: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let kind: ReviewKind
    public let text: String
    public let sourceSegmentIDs: [String]
    public let sourceRange: SourceRange?
    public let ownerSpeakerID: String?

    public init(id: UUID = UUID(), kind: ReviewKind, text: String,
                sourceSegmentIDs: [String], sourceRange: SourceRange?,
                ownerSpeakerID: String? = nil) {
        self.id = id
        self.kind = kind
        self.text = text
        self.sourceSegmentIDs = sourceSegmentIDs
        self.sourceRange = sourceRange
        self.ownerSpeakerID = ownerSpeakerID
    }
}

public struct MeetingRecord: Codable, Sendable, Identifiable {
    public let id: UUID
    public let sourcePath: String
    public var segments: [TranscriptSegment]
    public var speakerNames: [String: String]
    public var reviewItems: [ReviewItem]
    public let backend: String
    public let modelRevision: String
    public let processingParameters: [String: String]

    public init(id: UUID = UUID(), sourcePath: String,
                segments: [TranscriptSegment], speakerNames: [String: String] = [:],
                reviewItems: [ReviewItem] = [], backend: String,
                modelRevision: String, processingParameters: [String: String] = [:]) {
        self.id = id
        self.sourcePath = sourcePath
        self.segments = segments
        self.speakerNames = speakerNames
        self.reviewItems = reviewItems
        self.backend = backend
        self.modelRevision = modelRevision
        self.processingParameters = processingParameters
    }

    public mutating func renameSpeaker(_ id: String, to name: String) {
        speakerNames[id] = name
    }

    public mutating func reassignSegment(_ id: String, to speakerID: String) throws {
        guard let index = segments.firstIndex(where: { $0.id == id }) else {
            throw MeetingError.invalidSource(id)
        }
        segments[index].speakerID = speakerID
    }
}

public enum MinutesValidator {
    public static func item(kind: ReviewKind, text: String, sourceIDs: [String],
                            owner: String? = nil, segments: [TranscriptSegment]) throws -> ReviewItem {
        let byID = Dictionary(uniqueKeysWithValues: segments.map { ($0.id, $0) })
        for id in sourceIDs where byID[id] == nil { throw MeetingError.invalidSource(id) }
        if let owner, !sourceIDs.contains(where: { byID[$0]?.speakerID == owner }) {
            throw MeetingError.unsupportedOwner(owner)
        }
        let ranges = sourceIDs.compactMap { byID[$0]?.range }
        let range = try ranges.isEmpty ? nil : SourceRange(
            startSeconds: ranges.map(\.startSeconds).min()!,
            endSeconds: ranges.map(\.endSeconds).max()!
        )
        return ReviewItem(kind: kind, text: text, sourceSegmentIDs: sourceIDs,
                          sourceRange: range, ownerSpeakerID: owner)
    }
}
