import Foundation

public struct TopicDraft: Codable, Sendable {
    public let topicID: String
    public let text: String
    public let evidenceQuote: String
    public let sourceUtteranceIDs: [String]
    enum CodingKeys: String, CodingKey {
        case topicID = "topic_id", text
        case evidenceQuote = "evidence_quote"
        case sourceUtteranceIDs = "source_utterance_ids"
    }
}

public struct DraftCandidate: Codable, Sendable {
    public let topicID: String
    public let kind: ReviewKind
    public let text: String
    public let evidenceQuote: String
    public let sourceUtteranceIDs: [String]
    public let ownerSpeakerID: String?
    public let dueDate: String?
    enum CodingKeys: String, CodingKey {
        case topicID = "topic_id"
        case kind, text
        case evidenceQuote = "evidence_quote"
        case sourceUtteranceIDs = "source_utterance_ids"
        case ownerSpeakerID = "owner_speaker_id"
        case dueDate = "due_date"
    }
}

public struct MultiStageModelResult: Codable, Sendable {
    public let topics: [MeetingTopic]
    public let assignments: [TopicAssignment]
    public let summaries: [TopicDraft]
    public let candidates: [DraftCandidate]
}

public struct MultiStageDraft: Sendable {
    public let cleanup: TranscriptCleanupResult
    public let topics: [MeetingTopic]
    public let assignments: [TopicAssignment]
    public let reviewItems: [ReviewItem]
    public let coverage: TopicCoverageReport
}

/// Validates model structure and citations before any draft reaches the store.
/// Factual entailment still requires content review; stored items remain drafts.
public enum MultiStageMinutesValidator {
    public static func validate(_ result: MultiStageModelResult,
                                cleanup: TranscriptCleanupResult,
                                segments: [TranscriptSegment]) throws -> MultiStageDraft {
        let routed = cleanup.utterances.flatMap(\.sourceSegmentIDs) + cleanup.artifactSegmentIDs
        guard routed.count == segments.count,
              Set(routed) == Set(segments.map(\.id)) else {
            throw MeetingError.adapterFailure("Cleanup did not account for every raw segment")
        }
        let coverage = try TopicCoverage.validate(cleanup: cleanup, topics: result.topics,
                                                  assignments: result.assignments)
        let byUtterance = Dictionary(uniqueKeysWithValues: cleanup.utterances.map { ($0.id, $0) })
        let assignmentMap = Dictionary(uniqueKeysWithValues:
            result.assignments.map { ($0.utteranceID, Set($0.topicIDs)) })
        guard result.topics.allSatisfy({ topic in
            !topic.sourceUtteranceIDs.isEmpty &&
            topic.sourceUtteranceIDs.allSatisfy { byUtterance[$0] != nil &&
                assignmentMap[$0]?.contains(topic.id) == true }
        }) else {
            throw MeetingError.adapterFailure("Topic proposal citations contradict assignment")
        }
        guard result.summaries.count == result.topics.count,
              Set(result.summaries.map(\.topicID)) == Set(result.topics.map(\.id)) else {
            throw MeetingError.adapterFailure("Every topic needs exactly one cited summary")
        }
        var items: [ReviewItem] = []
        var topics = result.topics
        for summary in result.summaries {
            let IDs = try sourceIDs(summary.sourceUtteranceIDs, topicID: summary.topicID,
                                    byUtterance: byUtterance, assignmentMap: assignmentMap)
            guard !summary.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw MeetingError.adapterFailure("Empty topic summary")
            }
            try validateQuote(summary.evidenceQuote, from: summary.sourceUtteranceIDs,
                              byUtterance: byUtterance)
            items.append(try MinutesValidator.item(kind: .summary, text: summary.text,
                sourceIDs: IDs, segments: segments, topicID: summary.topicID))
            let topicIndex = topics.firstIndex { $0.id == summary.topicID }!
            topics[topicIndex].summary = summary.text
            topics[topicIndex].sourceUtteranceIDs = summary.sourceUtteranceIDs
        }
        for candidate in result.candidates {
            guard candidate.kind != .summary else {
                throw MeetingError.adapterFailure("Summary supplied as extracted candidate")
            }
            guard result.topics.contains(where: { $0.id == candidate.topicID }) else {
                throw MeetingError.adapterFailure("Candidate has unknown topic")
            }
            let IDs = try sourceIDs(candidate.sourceUtteranceIDs, topicID: candidate.topicID,
                                    byUtterance: byUtterance, assignmentMap: assignmentMap)
            guard !candidate.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  candidate.text.count <= 800 else {
                throw MeetingError.adapterFailure("Empty or oversized extracted item")
            }
            try validateQuote(candidate.evidenceQuote, from: candidate.sourceUtteranceIDs,
                              byUtterance: byUtterance)
            guard evidenceSupportsType(candidate.kind, quote: candidate.evidenceQuote) else {
                throw MeetingError.adapterFailure("Extracted item type lacks an explicit source signal")
            }
            let speakers = Set(segments.filter { IDs.contains($0.id) }.compactMap(\.speakerID))
            guard candidate.ownerSpeakerID == nil || speakers.contains(candidate.ownerSpeakerID!) else {
                throw MeetingError.adapterFailure("Candidate owner has no cited speech")
            }
            let dueDate = candidate.dueDate.flatMap {
                candidate.evidenceQuote.contains($0) ? $0 : nil
            }
            items.append(try MinutesValidator.item(kind: candidate.kind, text: candidate.text,
                sourceIDs: IDs, owner: candidate.ownerSpeakerID, segments: segments,
                topicID: candidate.topicID, dueDate: dueDate,
                ownerMissing: candidate.kind == .task ? candidate.ownerSpeakerID == nil : nil,
                dueDateMissing: candidate.kind == .task ? dueDate == nil : nil))
        }
        return MultiStageDraft(cleanup: cleanup, topics: topics,
                               assignments: result.assignments, reviewItems: items,
                               coverage: coverage)
    }

    private static func sourceIDs(_ utteranceIDs: [String], topicID: String,
                                  byUtterance: [String: CleanedUtterance],
                                  assignmentMap: [String: Set<String>]) throws -> [String] {
        guard !utteranceIDs.isEmpty, Set(utteranceIDs).count == utteranceIDs.count,
              utteranceIDs.allSatisfy({ byUtterance[$0] != nil &&
                  assignmentMap[$0]?.contains(topicID) == true }) else {
            throw MeetingError.adapterFailure("Invalid or unassigned source utterance IDs")
        }
        return utteranceIDs.flatMap { byUtterance[$0]!.sourceSegmentIDs }
    }

    private static func validateQuote(_ quote: String, from IDs: [String],
                                      byUtterance: [String: CleanedUtterance]) throws {
        let normalizedQuote = quote.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let supported = IDs.compactMap { byUtterance[$0]?.text }
            .map { $0.split(whereSeparator: \.isWhitespace).joined(separator: " ") }
            .contains { $0.contains(normalizedQuote) }
        guard normalizedQuote.count >= 8, supported else {
            throw MeetingError.adapterFailure("Evidence quote is not verbatim in cited utterances")
        }
    }

    private static func evidenceSupportsType(_ kind: ReviewKind, quote: String) -> Bool {
        let lower = quote.folding(options: [.caseInsensitive, .diacriticInsensitive],
                                  locale: Locale(identifier: "en_US_POSIX"))
        switch kind {
        case .summary: return false
        case .decision:
            return ["decid", "approv", "accepted", "rejected", "voted",
                    "przyjet", "zatwierdz", "pozytywnie opiniuje", "nie slysze sprzeciwu"]
                .contains(where: lower.contains)
        case .action, .task:
            return ["i will", "we will", "i shall", "we shall", "zobowiazuje sie",
                    "przygotuje", "wysle", "przeslemy", "bedziemy chcieli",
                    "zostanie przygotowan"].contains(where: lower.contains)
                && !["please present", "poprosze", "przechodzimy", "we will now"]
                    .contains(where: lower.contains)
        case .openQuestion: return quote.contains("?")
        }
    }
}

public struct MLXMultiStageMinutesGenerator {
    public let executable: String
    public let modelDirectory: String
    public let speakerNames: [String: String]
    public let corrections: [TranscriptCorrection]

    public init(executable: String, modelDirectory: String,
                speakerNames: [String: String], corrections: [TranscriptCorrection] = []) {
        self.executable = executable
        self.modelDirectory = modelDirectory
        self.speakerNames = speakerNames
        self.corrections = corrections
    }

    public func generate(from segments: [TranscriptSegment]) throws -> MultiStageDraft {
        guard FileManager.default.fileExists(atPath: modelDirectory) else {
            throw MeetingError.missingModel("mlx")
        }
        guard !segments.isEmpty else { throw MeetingError.adapterFailure("No transcript segments") }
        let duration = segments.map(\.range.endSeconds).max()! - segments.map(\.range.startSeconds).min()!
        guard duration <= 600 else {
            throw MeetingError.adapterFailure("minutes input exceeds prototype limit (600 seconds)")
        }
        let cleanup = try TranscriptCleaner.prepare(segments, corrections: corrections)
        guard !cleanup.hasUnresolvedCandidates else {
            throw MeetingError.adapterFailure("Transcript cleanup needs review of unresolved candidates")
        }
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("meeting-staged-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let inputURL = root.appendingPathComponent("input.json")
        let outputURL = root.appendingPathComponent("output.json")
        let input = StageInput(utterances: cleanup.utterances.map {
            StageInput.Utterance(id: $0.id, speakerID: $0.speakerID,
                speakerName: $0.speakerID.flatMap { speakerNames[$0] },
                startSeconds: $0.range.startSeconds, endSeconds: $0.range.endSeconds,
                text: $0.text)
        })
        try JSONEncoder().encode(input).write(to: inputURL, options: .atomic)
        _ = try runProcess(executable, [modelDirectory, inputURL.path, outputURL.path,
                                        "--multi-stage"])
        let result: MultiStageModelResult
        do {
            result = try JSONDecoder().decode(MultiStageModelResult.self,
                                              from: Data(contentsOf: outputURL))
        } catch {
            throw MeetingError.adapterFailure("Multi-stage output schema: \(error)")
        }
        return try MultiStageMinutesValidator.validate(result, cleanup: cleanup,
                                                       segments: segments)
    }
}

private struct StageInput: Encodable {
    struct Utterance: Encodable {
        let id: String
        let speakerID: String?
        let speakerName: String?
        let startSeconds: Double
        let endSeconds: Double
        let text: String
    }
    let utterances: [Utterance]
}

extension MeetingSummarizer {
    @discardableResult
    public func summarize(_ id: UUID, generator: MLXMultiStageMinutesGenerator,
                          modelRevision: String) throws -> MeetingRecord {
        var record = try store.load(id)
        let draft = try generator.generate(from: record.segments)
        record.reviewItems = draft.reviewItems
        record.cleanedTranscript = draft.cleanup
        record.topics = draft.topics
        record.topicAssignments = draft.assignments
        record.processingParameters["minutesModelRevision"] = modelRevision
        record.processingParameters["minutesSource"] = "local-model"
        record.processingParameters["minutesPipeline"] = "multi-stage-v1"
        record.processingParameters["topicCoverage"] = "\(draft.coverage.coveredUtterances)/\(draft.coverage.totalUtterances)"
        try store.save(record)
        return record
    }
}
