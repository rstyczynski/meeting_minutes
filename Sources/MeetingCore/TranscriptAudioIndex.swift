import Foundation

/// A displayed span keeps the precision of its source; corrected words do not get invented times.
public struct TranscriptAudioSpan: Sendable, Equatable {
    public enum Precision: Sendable { case sourcePart, correctedRange }
    public let utteranceID: String
    public let displayRange: NSRange
    public let sourceSegmentIDs: [String]
    public let sourceRange: SourceRange
    public let precision: Precision
}

/// Immutable index, rebuilt after record changes rather than on every playback tick.
public struct TranscriptAudioIndex: Sendable {
    public let reading: TranscriptCleanupResult
    public let spans: [TranscriptAudioSpan]
    private let sourceRanges: [String: SourceRange]
    private let texts: [String: String]
    private let boundaries: [String: Set<Int>]

    public init(record: MeetingRecord) throws {
        reading = try record.readableTranscript()
        let sourceByID = Dictionary(uniqueKeysWithValues: record.segments.map { ($0.id, $0.range) })
        sourceRanges = sourceByID
        let rawTexts = Dictionary(uniqueKeysWithValues: record.segments.map { ($0.id, $0.text) })
        let corrections = Dictionary((record.transcriptCorrections ?? []).map { ($0.segmentID, $0.correctedText) },
                                     uniquingKeysWith: { _, latest in latest })
        var mapped: [TranscriptAudioSpan] = []
        var displayed: [String: String] = [:]
        var valid: [String: Set<Int>] = [:]
        for utterance in reading.utterances {
            let parts = try utterance.sourceSegmentIDs.map { id -> String in
                guard let text = corrections[id] ?? rawTexts[id] else {
                    throw MeetingError.adapterFailure("Transcript has an unknown source part")
                }
                return text
            }
            let projection = try RangeProjection.project(ids: utterance.sourceSegmentIDs, texts: parts,
                                                        history: record.transcriptRangeCorrections ?? [])
            guard projection.text == utterance.text else {
                throw MeetingError.adapterFailure("Audio mapping does not match the displayed transcript")
            }
            displayed[utterance.id] = projection.text
            valid[utterance.id] = Set(projection.text.indices.map { $0.utf16Offset(in: projection.text) }
                                     + [(projection.text as NSString).length])
            for span in projection.spans where span.display.length > 0 {
                let ranges = try span.ids.map { id -> SourceRange in
                    guard let range = sourceByID[id] else {
                        throw MeetingError.adapterFailure("Audio mapping has an unknown source part")
                    }
                    return range
                }
                guard let start = ranges.map(\.startSeconds).min(), let end = ranges.map(\.endSeconds).max() else {
                    throw MeetingError.adapterFailure("Audio mapping has no source interval")
                }
                mapped.append(TranscriptAudioSpan(utteranceID: utterance.id, displayRange: span.display,
                    sourceSegmentIDs: span.ids, sourceRange: try SourceRange(startSeconds: start, endSeconds: end),
                    precision: span.replacement ? .correctedRange : .sourcePart))
            }
        }
        spans = mapped
        texts = displayed
        boundaries = valid
    }

    /// Intervals are start-inclusive/end-exclusive. Gaps inside corrected ranges also stay unmarked.
    public func highlights(at seconds: Double) throws -> [TranscriptAudioSpan] {
        guard seconds.isFinite, seconds >= 0 else {
            throw MeetingError.adapterFailure("Invalid audio position")
        }
        return spans.filter { span in
            seconds >= span.sourceRange.startSeconds && seconds < span.sourceRange.endSeconds
                && span.sourceSegmentIDs.contains { id in
                    guard let part = sourceRanges[id] else { return false }
                    return seconds >= part.startSeconds && seconds < part.endSeconds
                }
        }
    }

    /// Position-based mapping distinguishes repeated words and rejects broken Unicode selections.
    public func sourceStart(utteranceID: String, range: NSRange) throws -> Double {
        guard let text = texts[utteranceID], let valid = boundaries[utteranceID],
              range.location != NSNotFound, range.location >= 0, range.length > 0,
              range.location <= (text as NSString).length,
              range.length <= (text as NSString).length - range.location,
              valid.contains(range.location), valid.contains(NSMaxRange(range)),
              !(text as NSString).substring(with: range).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let start = spans.lazy.filter({ $0.utteranceID == utteranceID
                  && NSIntersectionRange($0.displayRange, range).length > 0 }).map(\.sourceRange.startSeconds).min() else {
            throw MeetingError.adapterFailure("Select a nonempty fragment with source audio")
        }
        return start
    }
}
