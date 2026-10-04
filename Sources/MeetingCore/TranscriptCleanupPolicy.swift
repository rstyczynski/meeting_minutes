import Foundation

/// Shared, persisted controls for the reversible reading layer, not ASR decoding.
public struct TranscriptCleanupPolicy: Codable, Sendable, Equatable {
    public enum Grouping: String, Codable, Sendable { case speakerTurns, sourceParts }
    public var grouping: Grouping = .speakerTurns
    public var mergeUnassignedSegments = true
    public var proposeNeighborSpeakers = true
    public var preserveSpeakerChanges = true
    public var maximumCandidateWords = 1
    public var maximumNeighborGapSeconds = 1.5
    public var maximumOverlapSeconds = 0.15
    public var maximumOneSidedGapSeconds = 0.5
    public var maximumReadingBlockSeconds: Double?
    public var maximumReadingGapSeconds: Double?
    public var longSilenceBoundarySeconds = 10.0

    public init() {}

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case grouping, mergeUnassignedSegments, proposeNeighborSpeakers, preserveSpeakerChanges, maximumCandidateWords
        case maximumNeighborGapSeconds, maximumOverlapSeconds, maximumOneSidedGapSeconds
        case maximumReadingBlockSeconds, maximumReadingGapSeconds, longSilenceBoundarySeconds
    }
    private struct AnyKey: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    public init(from decoder: any Decoder) throws {
        self.init()
        let all = try decoder.container(keyedBy: AnyKey.self)
        let known = Set(CodingKeys.allCases.map(\.rawValue))
        guard all.allKeys.allSatisfy({ known.contains($0.stringValue) }) else {
            throw MeetingError.adapterFailure("Unknown transcriptCleanup setting")
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        grouping = try c.decodeIfPresent(Grouping.self, forKey: .grouping) ?? grouping
        mergeUnassignedSegments = try c.decodeIfPresent(Bool.self, forKey: .mergeUnassignedSegments) ?? mergeUnassignedSegments
        proposeNeighborSpeakers = try c.decodeIfPresent(Bool.self, forKey: .proposeNeighborSpeakers) ?? proposeNeighborSpeakers
        preserveSpeakerChanges = try c.decodeIfPresent(Bool.self, forKey: .preserveSpeakerChanges) ?? preserveSpeakerChanges
        maximumCandidateWords = try c.decodeIfPresent(Int.self, forKey: .maximumCandidateWords) ?? maximumCandidateWords
        maximumNeighborGapSeconds = try c.decodeIfPresent(Double.self, forKey: .maximumNeighborGapSeconds) ?? maximumNeighborGapSeconds
        maximumOverlapSeconds = try c.decodeIfPresent(Double.self, forKey: .maximumOverlapSeconds) ?? maximumOverlapSeconds
        maximumOneSidedGapSeconds = try c.decodeIfPresent(Double.self, forKey: .maximumOneSidedGapSeconds) ?? maximumOneSidedGapSeconds
        maximumReadingBlockSeconds = try c.decodeIfPresent(Double.self, forKey: .maximumReadingBlockSeconds)
        maximumReadingGapSeconds = try c.decodeIfPresent(Double.self, forKey: .maximumReadingGapSeconds)
        longSilenceBoundarySeconds = try c.decodeIfPresent(Double.self, forKey: .longSilenceBoundarySeconds) ?? longSilenceBoundarySeconds
        try validate()
    }

    public func validate() throws {
        let gaps = [maximumNeighborGapSeconds, maximumOverlapSeconds, maximumOneSidedGapSeconds]
        guard longSilenceBoundarySeconds.isFinite, longSilenceBoundarySeconds > 0,
              maximumCandidateWords >= 1, gaps.allSatisfy({ $0.isFinite && $0 >= 0 }),
              maximumOneSidedGapSeconds <= maximumNeighborGapSeconds,
              maximumReadingBlockSeconds.map({ $0.isFinite && $0 > 0 }) ?? true,
              maximumReadingGapSeconds.map({ $0.isFinite && $0 >= 0 }) ?? true else {
            throw MeetingError.adapterFailure("Invalid transcriptCleanup limits: use finite nonnegative gaps, positive long-silence threshold, block duration and candidate word count; one-sided gap must not exceed neighbor gap")
        }
    }
}
