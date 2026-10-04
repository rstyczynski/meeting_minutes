import Foundation
import Testing
@testable import MeetingCore

struct MultiStageTests {
    private func segment(_ id: String, _ start: Double, _ end: Double,
                         _ speaker: String?, _ text: String) throws -> TranscriptSegment {
        try TranscriptSegment(id: id,
            range: SourceRange(startSeconds: start, endSeconds: end),
            speakerID: speaker, text: text)
    }

    @Test func testTranscriptCleaning() throws {
        let source = [
            try segment("a", 252.0, 253.2, "S2", "35 867 mln."),
            try segment("b", 253.2, 253.44, nil, "Na"),
            try segment("c", 253.44, 255.0, "S2", "realizację projektów"),
            try segment("d", 560.0, 562.0, "S1", "panią prezes poproszę o"),
            try segment("e", 562.32, 563.0, nil, "przedstawienie"),
            try segment("f", 563.32, 564.0, nil, "tego"),
            try segment("g", 564.0, 565.0, nil, "budżetu"),
        ]
        let cleaned = try TranscriptCleaner.prepare(source)
        #expect(cleaned.candidates.first(where: { $0.segmentID == "b" })?.disposition == .bridge)
        #expect(cleaned.candidates.first(where: { $0.segmentID == "e" })?.disposition == .joinPrevious)
        #expect(cleaned.candidates.first(where: { $0.segmentID == "f" })?.disposition == .joinPrevious)
        #expect(cleaned.candidates.first(where: { $0.segmentID == "g" })?.disposition == .joinPrevious)
        #expect(cleaned.utterances.contains { $0.sourceSegmentIDs == ["a", "b", "c"] })
        #expect(cleaned.utterances.contains { $0.sourceSegmentIDs == ["d", "e", "f", "g"] })
        #expect(cleaned.utterances.flatMap(\.sourceSegmentIDs).sorted() == source.map(\.id).sorted())
        #expect(source[1].speakerID == nil)
    }

    @Test func testTopicCoverage() throws {
        let source = [try segment("a", 1, 2, "S1", "Budget"),
                      try segment("b", 3, 4, "S2", "Deadline")]
        let cleaned = try TranscriptCleaner.prepare(source)
        let topics = [MeetingTopic(id: "t1", title: "Budget"),
                      MeetingTopic(id: "t2", title: "Schedule")]
        let complete = cleaned.utterances.map {
            TopicAssignment(utteranceID: $0.id, topicIDs: ["t1", "t2"])
        }
        let report = try TopicCoverage.validate(cleanup: cleaned,
                                                 topics: topics, assignments: complete)
        #expect(report.coveredUtterances == 2)
        #expect(report.totalUtterances == 2)
        #expect(report.fraction == 1)
        #expect(throws: Error.self) {
            try TopicCoverage.validate(cleanup: cleaned, topics: topics,
                                       assignments: Array(complete.prefix(1)))
        }
        #expect(throws: Error.self) {
            try TopicCoverage.validate(cleanup: cleaned, topics: topics,
                assignments: [TopicAssignment(utteranceID: cleaned.utterances[0].id,
                                              topicIDs: ["unknown"]), complete[1]])
        }
    }

    @Test func testExtractedItemKeepsItsOriginTopic() throws {
        let source = [try segment("a", 1, 3, "S1", "We approved the budget.")]
        let cleaned = try TranscriptCleaner.prepare(source)
        let payload = """
        {"topics":[
          {"id":"t1","title":"Agenda","sourceUtteranceIDs":["utt_1"]},
          {"id":"t2","title":"Budget opinion","sourceUtteranceIDs":["utt_1"]}],
         "assignments":[{"utteranceID":"utt_1","topicIDs":["t1","t2"]}],
         "summaries":[
          {"topic_id":"t1","text":"The agenda included the budget.","evidence_quote":"We approved the budget.","source_utterance_ids":["utt_1"]},
          {"topic_id":"t2","text":"The budget was approved.","evidence_quote":"We approved the budget.","source_utterance_ids":["utt_1"]}],
         "candidates":[{"topic_id":"t2","kind":"decision","text":"The budget was approved.","evidence_quote":"We approved the budget.","source_utterance_ids":["utt_1"]}]}
        """
        let result = try JSONDecoder().decode(MultiStageModelResult.self, from: Data(payload.utf8))
        let draft = try MultiStageMinutesValidator.validate(result, cleanup: cleaned,
                                                             segments: source)
        #expect(draft.reviewItems.last?.topicID == "t2")
    }

    @Test func testIsolatedTokenReview() throws {
        let source = [
            try segment("a", 1.0, 2.0, "S1", "We approved"),
            try segment("b", 2.0, 2.2, nil, "the"),
            try segment("c", 2.2, 3.0, "S1", "budget."),
            try segment("d", 6.0, 6.2, nil, "Yes"),
        ]
        let cleaned = try TranscriptCleaner.prepare(source)
        let bridge = try #require(cleaned.candidates.first { $0.segmentID == "b" })
        #expect(bridge.previousSegmentID == "a")
        #expect(bridge.nextSegmentID == "c")
        #expect(bridge.disposition == .bridge)
        #expect(cleaned.candidates.first(where: { $0.segmentID == "d" })?.disposition == .unresolved)
        #expect(cleaned.hasUnresolvedCandidates)
    }

    @Test func testAudioReviewedTextCorrectionIsReversible() throws {
        let raw = try segment("a", 1, 2, "S1", "thirty five million")
        var record = MeetingRecord(sourcePath: "/tmp/source.wav", segments: [raw],
                                   backend: "fluid", modelRevision: "test")
        record.reviewItems = [try MinutesValidator.item(kind: .summary,
            text: "Old draft", sourceIDs: ["a"], segments: record.segments)]
        #expect(throws: Error.self) {
            try record.correctTranscript("a", to: "thirty five billion", audioReviewed: false)
        }
        try record.correctTranscript("a", to: "thirty five billion", audioReviewed: true,
                                     note: "checked at 1–2 seconds")
        #expect(record.segments[0].text == "thirty five million")
        #expect(record.reviewItems.isEmpty)
        #expect(try TranscriptCleaner.prepare(record.segments,
            corrections: record.transcriptCorrections ?? []).utterances[0].text == "thirty five billion")
        try record.correctTranscript("a", to: "thirty five million", audioReviewed: true,
                                     note: "restored after second listen")
        #expect(record.transcriptCorrections?.count == 2)
        #expect(try TranscriptCleaner.prepare(record.segments,
            corrections: record.transcriptCorrections ?? []).utterances[0].text == raw.text)
    }
}
