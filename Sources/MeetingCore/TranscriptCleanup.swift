import Foundation

public enum CleanupDisposition: String, Codable, Sendable {
    case joinPrevious, joinNext, bridge, retainIndependent, artifact, unresolved
}

public struct CleanupCandidate: Codable, Sendable, Equatable {
    public let segmentID: String
    public let previousSegmentID: String?
    public let nextSegmentID: String?
    public let disposition: CleanupDisposition
    public let proposedSpeakerID: String?
    public let reason: String
}

public struct CleanedUtterance: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let sourceSegmentIDs: [String]
    public let range: SourceRange
    public let speakerID: String?
    public let text: String
    public let boundaryReason: String?
}

public struct TranscriptCleanupResult: Codable, Sendable, Equatable {
    public let utterances: [CleanedUtterance]
    public let candidates: [CleanupCandidate]
    public let artifactSegmentIDs: [String]

    public var hasUnresolvedCandidates: Bool {
        candidates.contains { $0.disposition == .unresolved }
    }
}

/// A conservative, reversible reading layer over immutable ASR segments.
/// A context-only bridge is recorded as a proposal; no raw speaker label or
/// word is rewritten, and suspected artifacts are never discarded by rule.
public enum TranscriptCleaner {
    public static func prepare(_ segments: [TranscriptSegment],
                               corrections: [TranscriptCorrection] = [],
                               rangeCorrections: [TranscriptRangeCorrection] = [],
                               policy: TranscriptCleanupPolicy = TranscriptCleanupPolicy()) throws -> TranscriptCleanupResult {
        try policy.validate()
        guard !segments.isEmpty else { throw MeetingError.adapterFailure("No transcript segments") }
        let ordered = segments.enumerated().sorted {
            if $0.element.range.startSeconds == $1.element.range.startSeconds {
                return $0.offset < $1.offset
            }
            return $0.element.range.startSeconds < $1.element.range.startSeconds
        }.map(\.element)
        guard Set(ordered.map(\.id)).count == ordered.count,
              ordered.allSatisfy({ !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw MeetingError.adapterFailure("Duplicate segment ID or empty ASR text")
        }

        let byID = Dictionary(uniqueKeysWithValues: ordered.map { ($0.id, $0) })
        guard RangeProjection.active(rangeCorrections).allSatisfy({
            !$0.sourceSegmentIDs.isEmpty && Set($0.sourceSegmentIDs).isSubset(of: Set(byID.keys))
        }) else { throw MeetingError.adapterFailure("Range correction cites missing source parts") }
        for correction in corrections {
            guard let original = byID[correction.segmentID],
                  original.text == correction.originalText,
                  !correction.correctedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw MeetingError.adapterFailure("Invalid transcript correction source")
            }
        }
        let latest = Dictionary(corrections.map { ($0.segmentID, $0.correctedText) },
                                uniquingKeysWith: { _, new in new })
        let readingText = ordered.map { latest[$0.id] ?? $0.text }

        var effectiveSpeakers = ordered.map(\.speakerID)
        var candidates: [CleanupCandidate] = []
        for index in ordered.indices where policy.proposeNeighborSpeakers {
            let segment = ordered[index]
            let previous = index > 0 ? ordered[index - 1] : nil
            let next = index + 1 < ordered.count ? ordered[index + 1] : nil
            let previousSpeaker = index > 0 ? effectiveSpeakers[index - 1] : nil
            let nextSpeaker = next?.speakerID
            let wordCount = readingText[index].split(whereSeparator: \.isWhitespace).count
            let previousGap = previous.map { segment.range.startSeconds - $0.range.endSeconds }
            let nextGap = next.map { $0.range.startSeconds - segment.range.endSeconds }
            let nearPrevious = previousGap.map { (-policy.maximumOverlapSeconds...policy.maximumNeighborGapSeconds).contains($0) } ?? false
            let nearNext = nextGap.map { (-policy.maximumOverlapSeconds...policy.maximumNeighborGapSeconds).contains($0) } ?? false
            let labeledNeighbor = previousSpeaker != nil || nextSpeaker != nil
            let briefSwitch = (!policy.preserveSpeakerChanges || segment.speakerID == nil)
                && wordCount <= policy.maximumCandidateWords && previousSpeaker != nil
                && previousSpeaker == nextSpeaker
                && segment.speakerID != previousSpeaker && nearPrevious && nearNext
            let unknownContinuation = segment.speakerID == nil && labeledNeighbor
                && (wordCount <= policy.maximumCandidateWords || (nearPrevious && !nearNext) || (!nearPrevious && nearNext))
            guard briefSwitch || unknownContinuation else { continue }

            let disposition: CleanupDisposition
            let speaker: String?
            let reason: String
            if let left = previousSpeaker, left == nextSpeaker,
               nearPrevious && nearNext {
                disposition = .bridge
                speaker = left
                reason = "Same labeled speaker on both sides; both gaps satisfy the configured neighbor limits"
            } else if let left = previousSpeaker, nearPrevious,
                      (nextSpeaker != left || !nearNext),
                      (previousGap ?? .infinity) <= policy.maximumOneSidedGapSeconds {
                disposition = .joinPrevious
                speaker = left
                reason = "Continuous with previous labeled speech; following turn differs or is distant"
            } else if let right = nextSpeaker, nearNext,
                      (previousSpeaker != right || !nearPrevious),
                      (nextGap ?? .infinity) <= policy.maximumOneSidedGapSeconds {
                disposition = .joinNext
                speaker = right
                reason = "Continuous with following labeled speech; preceding turn differs or is distant"
            } else {
                disposition = previous != nil && next != nil ? .retainIndependent : .unresolved
                speaker = segment.speakerID
                reason = disposition == .retainIndependent
                    ? "Both neighbors checked; no safe reassignment, so source words retain their original speaker label"
                    : "A recording boundary requires audio or operator review"
            }
            if disposition != .unresolved && disposition != .retainIndependent {
                effectiveSpeakers[index] = speaker
            }
            candidates.append(CleanupCandidate(segmentID: segment.id,
                previousSegmentID: previous?.id, nextSegmentID: next?.id,
                disposition: disposition, proposedSpeakerID: speaker, reason: reason))
        }

        var groups: [[Int]] = []
        for index in ordered.indices {
            if let last = groups.indices.last,
               policy.grouping == .speakerTurns,
               effectiveSpeakers[groups[last].last!] == effectiveSpeakers[index],
               (effectiveSpeakers[index] != nil || policy.mergeUnassignedSegments),
               ordered[index].range.startSeconds - ordered[groups[last].last!].range.endSeconds < policy.longSilenceBoundarySeconds,
               policy.maximumReadingGapSeconds.map({
                   ordered[index].range.startSeconds - ordered[groups[last].last!].range.endSeconds <= $0
               }) ?? true,
               policy.maximumReadingBlockSeconds.map({
                   ordered[index].range.endSeconds - ordered[groups[last].first!].range.startSeconds <= $0
               }) ?? true {
                // Long silence ends a turn even for the same voice; duration caps stay opt-in.
                groups[last].append(index)
            } else {
                groups.append([index])
            }
        }
        let utterances = try groups.enumerated().map { number, indices in
            let first = ordered[indices[0]]
            let last = ordered[indices[indices.count - 1]]
            let precedingIndex = indices[0] - 1
            let gap = precedingIndex >= 0 ? first.range.startSeconds - ordered[precedingIndex].range.endSeconds : 0
            let boundary = gap >= policy.longSilenceBoundarySeconds
                ? String(format: "New segment after %.2f s without a timed speech part (longSilenceBoundarySeconds: %.2f s)", gap, policy.longSilenceBoundarySeconds)
                : nil
            return CleanedUtterance(id: "utt_\(number + 1)",
                sourceSegmentIDs: indices.map { ordered[$0].id },
                range: try SourceRange(startSeconds: first.range.startSeconds,
                                       endSeconds: last.range.endSeconds),
                speakerID: effectiveSpeakers[indices[0]],
                text: try RangeProjection.project(ids: indices.map { ordered[$0].id },
                    texts: indices.map { readingText[$0] }, history: rangeCorrections).text,
                boundaryReason: boundary)
        }
        return TranscriptCleanupResult(utterances: utterances,
                                       candidates: candidates, artifactSegmentIDs: [])
    }
}
