import Foundation
import CryptoKit

/// One atomic text replacement, anchored to immutable source parts, not guessed word times.
public struct TranscriptRangeCorrection: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let sourceSegmentIDs: [String]
    public let startUTF16: Int
    public let endUTF16: Int
    public let sourceTexts: [String]
    public let originalText: String
    public let correctedText: String
    public let sourceRange: SourceRange
    public let audioReviewedAt: Date
    public let restored: Bool
    public let supersededCorrectionIDs: [UUID]?

    var key: String { sourceSegmentIDs.joined(separator: "\u{1f}") + ":\(startUTF16):\(endUTF16)" }
}

public struct TranscriptSelection: Sendable, Identifiable {
    public let id = UUID()
    public let utteranceID: String
    public let sourceSegmentIDs: [String]
    public let startUTF16: Int
    public let endUTF16: Int
    public let sourceTexts: [String]
    public let text: String
    public let originalText: String
    public let sourceRange: SourceRange
    public let revision: String
    public let isRangeCorrection: Bool
    public let displayRange: NSRange
    let storageText: String
    let replacementRange: NSRange
    let supersededCorrectionIDs: [UUID]
    var key: String { sourceSegmentIDs.joined(separator: "\u{1f}") + ":\(startUTF16):\(endUTF16)" }
}

public struct PlaybackContext: Sendable {
    public var beforeSeconds: Double
    public var afterSeconds: Double
    public init(beforeSeconds: Double = 2, afterSeconds: Double = 2) {
        self.beforeSeconds = beforeSeconds
        self.afterSeconds = afterSeconds
    }
    public func range(around source: SourceRange, duration: Double) throws -> SourceRange {
        guard beforeSeconds.isFinite, afterSeconds.isFinite,
              beforeSeconds >= 0, afterSeconds >= 0, duration.isFinite,
              duration >= source.endSeconds else {
            throw MeetingError.adapterFailure("Invalid playback context or source outside recording")
        }
        return try SourceRange(startSeconds: max(0, source.startSeconds - beforeSeconds),
                               endSeconds: min(duration, source.endSeconds + afterSeconds))
    }
}

/// Shared projection for display, inspection and minutes. UTF-16 matches AppKit selections.
enum RangeProjection {
    struct Span {
        let display: NSRange
        let ids: [String]
        let start: Int
        let end: Int
        let replacement: Bool
    }
    struct Projection { let text: String; let spans: [Span] }

    static func active(_ history: [TranscriptRangeCorrection]) -> [TranscriptRangeCorrection] {
        var latest: [String: TranscriptRangeCorrection] = [:]
        for event in history {
            let superseded = Set(event.supersededCorrectionIDs ?? [])
            latest = latest.filter { !superseded.contains($0.value.id) }
            latest[event.key] = event
        }
        return latest.values.filter { !$0.restored }
    }

    static func project(ids: [String], texts: [String], history: [TranscriptRangeCorrection]) throws -> Projection {
        let base = texts.joined(separator: " ") as NSString
        var starts: [Int] = []
        var cursor = 0
        for text in texts { starts.append(cursor); cursor += (text as NSString).length + 1 }
        var edits: [(NSRange, TranscriptRangeCorrection)] = []
        for correction in active(history) where !Set(correction.sourceSegmentIDs).isDisjoint(with: ids) {
            guard let first = ids.firstIndex(of: correction.sourceSegmentIDs.first ?? ""),
                  let last = ids.firstIndex(of: correction.sourceSegmentIDs.last ?? ""), first <= last,
                  Array(ids[first...last]) == correction.sourceSegmentIDs,
                  Array(texts[first...last]) == correction.sourceTexts,
                  correction.startUTF16 >= 0, correction.startUTF16 <= (texts[first] as NSString).length,
                  correction.endUTF16 >= 0, correction.endUTF16 <= (texts[last] as NSString).length else {
                throw MeetingError.adapterFailure("Range correction no longer fits this reading profile or source; restore it before changing boundaries")
            }
            let begin = starts[first] + correction.startUTF16
            let finish = starts[last] + correction.endUTF16
            let range = NSRange(location: begin, length: finish - begin)
            guard range.length > 0, Range(range, in: base as String) != nil,
                  base.substring(with: range) == correction.originalText else {
                throw MeetingError.adapterFailure("Invalid range correction anchors")
            }
            edits.append((range, correction))
        }
        edits.sort { $0.0.location < $1.0.location }
        var result = ""
        var spans: [Span] = []
        func appendOriginal(_ range: NSRange) {
            guard range.length > 0 else { return }
            let outputStart = (result as NSString).length
            result += base.substring(with: range)
            for index in ids.indices {
                let part = NSRange(location: starts[index], length: (texts[index] as NSString).length)
                let intersection = NSIntersectionRange(range, part)
                if intersection.length > 0 {
                    spans.append(Span(display: NSRange(location: outputStart + intersection.location - range.location,
                                                      length: intersection.length), ids: [ids[index]],
                                      start: intersection.location - part.location,
                                      end: NSMaxRange(intersection) - part.location, replacement: false))
                }
            }
        }
        cursor = 0
        for (range, edit) in edits {
            guard range.location >= cursor else { throw MeetingError.adapterFailure("Overlapping range corrections") }
            appendOriginal(NSRange(location: cursor, length: range.location - cursor))
            let start = (result as NSString).length
            result += edit.correctedText
            spans.append(Span(display: NSRange(location: start, length: (edit.correctedText as NSString).length),
                              ids: edit.sourceSegmentIDs, start: edit.startUTF16, end: edit.endUTF16, replacement: true))
            cursor = NSMaxRange(range)
        }
        appendOriginal(NSRange(location: cursor, length: base.length - cursor))
        return Projection(text: result, spans: spans)
    }
}

extension MeetingRecord {
    public func readableTranscript() throws -> TranscriptCleanupResult {
        try TranscriptCleaner.prepare(segments, corrections: transcriptCorrections ?? [],
                                      rangeCorrections: transcriptRangeCorrections ?? [],
                                      policy: transcriptCleanupPolicy ?? TranscriptCleanupPolicy())
    }

    private func selectionRevision() throws -> String {
        struct Revision: Encodable {
            let segments: [TranscriptSegment]
            let corrections: [TranscriptCorrection]
            let ranges: [TranscriptRangeCorrection]
            let policy: TranscriptCleanupPolicy
        }
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(Revision(segments: segments, corrections: transcriptCorrections ?? [],
                                               ranges: transcriptRangeCorrections ?? [],
                                               policy: transcriptCleanupPolicy ?? TranscriptCleanupPolicy()))
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    public func transcriptSelection(utteranceID: String, range: NSRange) throws -> TranscriptSelection {
        guard let utterance = try readableTranscript().utterances.first(where: { $0.id == utteranceID }) else {
            throw MeetingError.adapterFailure("Select text within one speaker turn")
        }
        let latest = Dictionary((transcriptCorrections ?? []).map { ($0.segmentID, $0.correctedText) },
                                uniquingKeysWith: { _, new in new })
        let byID = Dictionary(uniqueKeysWithValues: segments.map { ($0.id, $0) })
        let texts = utterance.sourceSegmentIDs.map { latest[$0] ?? byID[$0]!.text }
        let projection = try RangeProjection.project(ids: utterance.sourceSegmentIDs, texts: texts,
                                                    history: transcriptRangeCorrections ?? [])
        let boundaries = Set(projection.text.indices.map { $0.utf16Offset(in: projection.text) }
                             + [(projection.text as NSString).length])
        guard range.location != NSNotFound, range.location >= 0, range.length > 0,
              range.location <= (projection.text as NSString).length,
              range.length <= (projection.text as NSString).length - range.location,
              boundaries.contains(range.location), boundaries.contains(NSMaxRange(range)) else {
            throw MeetingError.adapterFailure("Select a nonempty, valid text fragment")
        }
        // Expand the storage anchors, while the editor still targets exactly the user's text.
        var target = range
        var previous: NSRange
        repeat {
            previous = target
            for span in projection.spans where span.replacement && NSIntersectionRange(span.display, target).length > 0 {
                target = NSUnionRange(target, span.display)
            }
        } while target != previous
        let included = projection.spans.filter { NSIntersectionRange($0.display, target).length > 0 }
        guard let first = included.first, let last = included.last,
              let firstIndex = utterance.sourceSegmentIDs.firstIndex(of: first.ids.first!),
              let lastIndex = utterance.sourceSegmentIDs.firstIndex(of: last.ids.last!), firstIndex <= lastIndex else {
            throw MeetingError.adapterFailure("Selection contains no source words")
        }
        // Exclude whitespace between parts from boundary anchors, retaining inner spaces.
        let start = first.replacement ? first.start : first.start + max(0, target.location - first.display.location)
        let end = last.replacement ? last.end : last.start + min(last.display.length, NSMaxRange(target) - last.display.location)
        let ids = Array(utterance.sourceSegmentIDs[firstIndex...lastIndex])
        let sourceTexts = Array(texts[firstIndex...lastIndex])
        let base = sourceTexts.joined(separator: " ") as NSString
        let baseEnd = sourceTexts.dropLast().reduce(0) { $0 + ($1 as NSString).length + 1 } + end
        guard baseEnd > start else { throw MeetingError.adapterFailure("Selection contains no source words") }
        let original = base.substring(with: NSRange(location: start, length: baseEnd - start))
        let displayStart = first.replacement ? first.display.location : first.display.location + start - first.start
        let displayEnd = last.replacement ? NSMaxRange(last.display) : last.display.location + end - last.start
        target = NSRange(location: displayStart, length: displayEnd - displayStart)
        let selectedRange = NSIntersectionRange(range, target)
        let selected = (projection.text as NSString).substring(with: selectedRange)
        guard !selected.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MeetingError.adapterFailure("Select source words, not whitespace")
        }
        let audio = try SourceRange(startSeconds: ids.map { byID[$0]!.range.startSeconds }.min()!,
                                    endSeconds: ids.map { byID[$0]!.range.endSeconds }.max()!)
        let superseded = RangeProjection.active(transcriptRangeCorrections ?? []).filter { edit in
            included.contains { $0.replacement && $0.ids == edit.sourceSegmentIDs && $0.start == edit.startUTF16 && $0.end == edit.endUTF16 }
        }.map(\.id)
        return TranscriptSelection(utteranceID: utteranceID, sourceSegmentIDs: ids,
                                   startUTF16: start, endUTF16: end, sourceTexts: sourceTexts,
                                   text: selected, originalText: original, sourceRange: audio,
                                   revision: try selectionRevision(),
                                   isRangeCorrection: !superseded.isEmpty, displayRange: selectedRange,
                                   storageText: (projection.text as NSString).substring(with: target),
                                   replacementRange: NSRange(location: selectedRange.location - target.location, length: selectedRange.length),
                                   supersededCorrectionIDs: superseded)
    }

    public mutating func correctTranscript(_ selection: TranscriptSelection, to replacement: String,
                                          audioReviewed: Bool, restore: Bool = false) throws {
        guard audioReviewed else { throw MeetingError.adapterFailure("Listen to the source audio before correcting text") }
        guard selection.revision == (try selectionRevision()) else {
            throw MeetingError.adapterFailure("Transcript changed; select the fragment again")
        }
        let active = RangeProjection.active(transcriptRangeCorrections ?? [])
        let ordered = segments.enumerated().sorted {
            $0.element.range.startSeconds == $1.element.range.startSeconds
                ? $0.offset < $1.offset : $0.element.range.startSeconds < $1.element.range.startSeconds
        }.map(\.element)
        let positions = Dictionary(uniqueKeysWithValues: ordered.enumerated().map { ($0.element.id, $0.offset) })
        func precedes(_ id: String, _ offset: Int, _ otherID: String, _ otherOffset: Int) -> Bool {
            positions[id]! == positions[otherID]! ? offset < otherOffset : positions[id]! < positions[otherID]!
        }
        guard !active.contains(where: {
            !selection.supersededCorrectionIDs.contains($0.id) && $0.key != selection.key
                && precedes($0.sourceSegmentIDs.first!, $0.startUTF16, selection.sourceSegmentIDs.last!, selection.endUTF16)
                && precedes(selection.sourceSegmentIDs.first!, selection.startUTF16, $0.sourceSegmentIDs.last!, $0.endUTF16)
        }) else {
            throw MeetingError.adapterFailure("Selection overlaps an existing correction; edit or restore that correction first")
        }
        let selectedReplacement = replacement.trimmingCharacters(in: .whitespacesAndNewlines)
        guard restore ? selection.isRangeCorrection : (!selectedReplacement.isEmpty && selectedReplacement != selection.text) else {
            throw MeetingError.adapterFailure("Correction must change selected text; restore requires an existing range correction")
        }
        let text = restore ? selection.originalText : (selection.storageText as NSString)
            .replacingCharacters(in: selection.replacementRange, with: selectedReplacement)
        let event = TranscriptRangeCorrection(id: UUID(), sourceSegmentIDs: selection.sourceSegmentIDs,
            startUTF16: selection.startUTF16, endUTF16: selection.endUTF16,
            sourceTexts: selection.sourceTexts, originalText: selection.originalText,
            correctedText: text, sourceRange: selection.sourceRange, audioReviewedAt: Date(), restored: restore,
            supersededCorrectionIDs: selection.supersededCorrectionIDs)
        transcriptRangeCorrections = (transcriptRangeCorrections ?? []) + [event]
        reviewItems = []; cleanedTranscript = nil; topics = nil; topicAssignments = nil
        for key in ["topicCoverage", "minutesModelRevision", "minutesSource", "minutesPipeline"] {
            processingParameters.removeValue(forKey: key)
        }
    }
}
