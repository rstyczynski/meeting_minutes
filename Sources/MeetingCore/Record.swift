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
    case summary, decision, action, task, openQuestion
}

public struct ReviewItem: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let kind: ReviewKind
    public let text: String
    public let sourceSegmentIDs: [String]
    public let sourceRange: SourceRange?
    public let ownerSpeakerID: String?
    public let topicID: String?
    public let dueDate: String?
    public let ownerMissing: Bool?
    public let dueDateMissing: Bool?

    public init(id: UUID = UUID(), kind: ReviewKind, text: String,
                sourceSegmentIDs: [String], sourceRange: SourceRange?,
                ownerSpeakerID: String? = nil, topicID: String? = nil,
                dueDate: String? = nil, ownerMissing: Bool? = nil,
                dueDateMissing: Bool? = nil) {
        self.id = id
        self.kind = kind
        self.text = text
        self.sourceSegmentIDs = sourceSegmentIDs
        self.sourceRange = sourceRange
        self.ownerSpeakerID = ownerSpeakerID
        self.topicID = topicID
        self.dueDate = dueDate
        self.ownerMissing = ownerMissing
        self.dueDateMissing = dueDateMissing
    }
}

public struct QualityWarning: Codable, Sendable, Equatable {
    public let range: SourceRange
    public let speakerID: String?
    public let reason: String

    public init(range: SourceRange, speakerID: String?, reason: String) {
        self.range = range
        self.speakerID = speakerID
        self.reason = reason
    }
}

public struct TranscriptCorrection: Codable, Sendable, Equatable {
    public let segmentID: String
    public let originalText: String
    public let correctedText: String
    public let audioReviewedAt: Date
    public let note: String?

    public init(segmentID: String, originalText: String, correctedText: String,
                audioReviewedAt: Date, note: String? = nil) {
        self.segmentID = segmentID
        self.originalText = originalText
        self.correctedText = correctedText
        self.audioReviewedAt = audioReviewedAt
        self.note = note
    }
}

public struct MeetingRecord: Codable, Sendable, Identifiable {
    public let id: UUID
    public let sourcePath: String
    public var segments: [TranscriptSegment]
    public var speakerNames: [String: String]
    public var reviewItems: [ReviewItem]
    public var qualityWarnings: [QualityWarning]?
    public let backend: String
    public let modelRevision: String
    public var processingParameters: [String: String]
    public var cleanedTranscript: TranscriptCleanupResult?
    public var topics: [MeetingTopic]?
    public var topicAssignments: [TopicAssignment]?
    public var transcriptCorrections: [TranscriptCorrection]?

    public init(id: UUID = UUID(), sourcePath: String,
                segments: [TranscriptSegment], speakerNames: [String: String] = [:],
                reviewItems: [ReviewItem] = [], qualityWarnings: [QualityWarning]? = nil,
                backend: String,
                modelRevision: String, processingParameters: [String: String] = [:]) {
        self.id = id
        self.sourcePath = sourcePath
        self.segments = segments
        self.speakerNames = speakerNames
        self.reviewItems = reviewItems
        self.qualityWarnings = qualityWarnings
        self.backend = backend
        self.modelRevision = modelRevision
        self.processingParameters = processingParameters
        self.cleanedTranscript = nil
        self.topics = nil
        self.topicAssignments = nil
        self.transcriptCorrections = nil
    }

    public mutating func renameSpeaker(_ id: String, to name: String) {
        speakerNames[id] = name
    }

    public mutating func correctTranscript(_ segmentID: String, to correctedText: String,
                                           audioReviewed: Bool, note: String? = nil,
                                           at date: Date = Date()) throws {
        guard audioReviewed else {
            throw MeetingError.adapterFailure("Listen to the source audio before correcting text")
        }
        guard let segment = segments.first(where: { $0.id == segmentID }) else {
            throw MeetingError.invalidSource(segmentID)
        }
        let text = correctedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let current = transcriptCorrections?.last(where: { $0.segmentID == segmentID })?
            .correctedText ?? segment.text
        guard !text.isEmpty, text != current else {
            throw MeetingError.adapterFailure("Correction must supply different, nonempty text")
        }
        var corrections = transcriptCorrections ?? []
        corrections.append(TranscriptCorrection(segmentID: segmentID,
            originalText: segment.text, correctedText: text, audioReviewedAt: date,
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines)))
        transcriptCorrections = corrections
        // A later correction invalidates derived minutes until they are regenerated.
        reviewItems = []
        cleanedTranscript = nil
        topics = nil
        topicAssignments = nil
        processingParameters.removeValue(forKey: "topicCoverage")
    }

    public mutating func assignSpeakerName(_ id: String, to name: String) throws {
        guard segments.contains(where: { $0.speakerID == id }) else {
            throw MeetingError.adapterFailure("Unknown speaker ID: \(id)")
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MeetingError.adapterFailure("Speaker name cannot be empty")
        }
        speakerNames[id] = trimmed
    }

    public mutating func moveSegment(_ id: String, to speakerID: String) throws {
        guard segments.contains(where: { $0.speakerID == speakerID }) else {
            throw MeetingError.adapterFailure("Unknown speaker ID: \(speakerID)")
        }
        try reassignSegment(id, to: speakerID)
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
                            owner: String? = nil, segments: [TranscriptSegment],
                            topicID: String? = nil, dueDate: String? = nil,
                            ownerMissing: Bool? = nil,
                            dueDateMissing: Bool? = nil) throws -> ReviewItem {
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
                          sourceRange: range, ownerSpeakerID: owner, topicID: topicID,
                          dueDate: dueDate, ownerMissing: ownerMissing,
                          dueDateMissing: dueDateMissing)
    }
}
