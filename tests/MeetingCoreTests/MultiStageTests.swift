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

    @Test func testSelectedTextCorrection() throws {
        let raw = [try segment("a", 1, 1.2, "S1", "Zażółć"),
                   try segment("b", 1.2, 1.4, "S1", "gęślą"),
                   try segment("c", 1.4, 1.6, "S1", "jaźń."),
                   try segment("d", 1.6, 2, "S1", "Zażółć gęślą jaźń."),
                   try segment("e", 2, 3, "S2", "Inny głos")]
        var record = MeetingRecord(sourcePath: "/tmp/test.wav", segments: raw,
                                   backend: "fixture", modelRevision: "test")
        let utterance = try record.readableTranscript().utterances[0]
        let first = (utterance.text as NSString).range(of: "Zażółć gęślą jaźń.")
        let selection = try record.transcriptSelection(utteranceID: utterance.id, range: first)
        #expect(selection.sourceSegmentIDs == ["a", "b", "c"])
        #expect(selection.text == "Zażółć gęślą jaźń.")
        #expect(throws: Error.self) {
            try record.correctTranscript(selection, to: "Poprawiona fraza.", audioReviewed: false)
        }
        try record.correctTranscript(selection, to: "Poprawiona fraza.", audioReviewed: true)
        #expect(try record.readableTranscript().utterances[0].text == "Poprawiona fraza. Zażółć gęślą jaźń.")
        #expect(record.segments == raw)
        #expect(try record.readableTranscript().utterances.flatMap(\.sourceSegmentIDs) == raw.map(\.id))
        #expect(throws: Error.self) {
            try record.correctTranscript(selection, to: "Stale", audioReviewed: true)
        }
        #expect(throws: Error.self) {
            try record.correctTranscript("b", to: "Conflict", audioReviewed: true)
        }
        let current = try record.readableTranscript().utterances[0]
        let partial = try record.transcriptSelection(utteranceID: current.id,
                                                      range: NSRange(location: 1, length: 2))
        #expect(partial.text == "op")
        let expanded = try record.transcriptSelection(utteranceID: current.id,
            range: (current.text as NSString).range(of: "Poprawiona fraza."))
        #expect(expanded.text == "Poprawiona fraza.")
        try record.correctTranscript(expanded, to: "Druga korekta.", audioReviewed: true)
        let edited = try record.readableTranscript().utterances[0]
        let restoring = try record.transcriptSelection(utteranceID: edited.id,
            range: (edited.text as NSString).range(of: "Druga korekta."))
        try record.correctTranscript(restoring, to: restoring.originalText,
                                     audioReviewed: true, restore: true)
        #expect(try record.readableTranscript().utterances[0].text == utterance.text)
        #expect(record.transcriptRangeCorrections?.count == 3)
        let repeated = try record.transcriptSelection(utteranceID: utterance.id,
            range: (utterance.text as NSString).range(of: "gęślą", options: .backwards))
        #expect(repeated.sourceSegmentIDs == ["d"])
        try record.correctTranscript(repeated, to: "POPRAWIONE", audioReviewed: true)
        #expect(try record.readableTranscript().utterances[0].text == "Zażółć gęślą jaźń. Zażółć POPRAWIONE jaźń.")
        let disjointText = try record.readableTranscript().utterances[0].text
        let disjoint = try record.transcriptSelection(utteranceID: utterance.id,
            range: (disjointText as NSString).range(of: "jaźń.", options: .backwards))
        try record.correctTranscript(disjoint, to: "KONIEC.", audioReviewed: true)
        #expect(try record.readableTranscript().utterances[0].text == "Zażółć gęślą jaźń. Zażółć POPRAWIONE KONIEC.")
        #expect(throws: Error.self) {
            _ = try record.transcriptSelection(utteranceID: utterance.id, range: NSRange(location: 0, length: 0))
        }
        #expect(throws: Error.self) {
            _ = try record.transcriptSelection(utteranceID: utterance.id, range: NSRange(location: 0, length: 10000))
        }
        let overlapping = try record.transcriptSelection(utteranceID: utterance.id,
            range: NSRange(location: 0, length: (try record.readableTranscript().utterances[0].text as NSString).length))
        try record.correctTranscript(overlapping, to: "Merged correction", audioReviewed: true)
        #expect(try record.readableTranscript().utterances[0].text == "Merged correction")
        #expect(record.segments == raw)
        let emoji = try segment("emoji", 0, 1, "S1", "🙂 tekst")
        let unicode = MeetingRecord(sourcePath: "/tmp/test.wav", segments: [emoji], backend: "fixture", modelRevision: "test")
        #expect(throws: Error.self) {
            _ = try unicode.transcriptSelection(utteranceID: "utt_1", range: NSRange(location: 1, length: 1))
        }
    }

    @Test func testPlaybackContext() throws {
        let target = try SourceRange(startSeconds: 1, endSeconds: 1.2)
        #expect(try PlaybackContext().range(around: target, duration: 10) == SourceRange(startSeconds: 0, endSeconds: 3.2))
        #expect(try PlaybackContext(beforeSeconds: 0, afterSeconds: 5).range(around: target, duration: 4) == SourceRange(startSeconds: 1, endSeconds: 4))
        #expect(throws: Error.self) { _ = try PlaybackContext(beforeSeconds: -1).range(around: target, duration: 10) }
        #expect(throws: Error.self) { _ = try PlaybackContext(afterSeconds: .infinity).range(around: target, duration: 10) }
        #expect(throws: Error.self) { _ = try PlaybackContext().range(around: target, duration: 0.5) }
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

        // A continuous speaker turn must survive the former 15-second cut.
        // Speaker changes still create separate blocks.
        let longerTurn = [
            try segment("long_a", 582.24, 589.68, "S3", "Bardzo dziękuję."),
            try segment("long_b", 589.68, 597.04, "S3", "Zadania związane z"),
            try segment("long_c", 597.04, 599.76, "S3", "organizacją i nadzorowaniem prac normalizacyjnych w kraju."),
            try segment("other_speaker", 600.0, 601.0, "S2", "Dziękuję."),
            try segment("after_pause", 603.0, 604.0, "S1", "Następny punkt."),
        ]
        let continuous = try TranscriptCleaner.prepare(longerTurn)
        #expect(continuous.utterances.count == 3)
        #expect(continuous.utterances[0].sourceSegmentIDs == ["long_a", "long_b", "long_c"])
        #expect(continuous.utterances[0].range.startSeconds == 582.24)
        #expect(continuous.utterances[0].range.endSeconds == 599.76)
        #expect(continuous.utterances[0].text == longerTurn.prefix(3).map(\.text).joined(separator: " "))
        #expect(continuous.utterances[1].sourceSegmentIDs == ["other_speaker"])
        #expect(continuous.utterances[2].sourceSegmentIDs == ["after_pause"])
        #expect(continuous.utterances.flatMap(\.sourceSegmentIDs) == longerTurn.map(\.id))

        let amountAcrossPause = [
            try segment("amount_a", 262.8, 263.12, "S2", "35"),
            try segment("amount_b", 264.72, 265.92, "S2", "779 milionów"),
        ]
        let amount = try TranscriptCleaner.prepare(amountAcrossPause)
        #expect(amount.utterances.count == 1)
        #expect(amount.utterances[0].text == "35 779 milionów")
        #expect(amount.utterances[0].sourceSegmentIDs == ["amount_a", "amount_b"])

        var policy = TranscriptCleanupPolicy()
        policy.maximumReadingGapSeconds = 1.5
        #expect(try TranscriptCleaner.prepare(amountAcrossPause, policy: policy).utterances.count == 2)
        policy = TranscriptCleanupPolicy()
        policy.maximumReadingBlockSeconds = 15
        #expect(try TranscriptCleaner.prepare(longerTurn, policy: policy).utterances.count == 4)
        policy = TranscriptCleanupPolicy()
        policy.grouping = .sourceParts
        #expect(try TranscriptCleaner.prepare(source, policy: policy).utterances.count == source.count)
        policy = TranscriptCleanupPolicy()
        policy.proposeNeighborSpeakers = false
        #expect(try TranscriptCleaner.prepare(source, policy: policy).candidates.isEmpty)
        let unknown = [try segment("u1", 1, 2, nil, "one"),
                       try segment("u2", 2, 3, nil, "two")]
        #expect(try TranscriptCleaner.prepare(unknown).utterances.count == 1)
        policy.mergeUnassignedSegments = false
        #expect(try TranscriptCleaner.prepare(unknown, policy: policy).utterances.count == 2)

        // Neighbor decisions change with each threshold; source parts always survive.
        let twoWords = [try segment("w1", 1, 2, "S1", "We"),
                        try segment("w2", 2, 2.2, "S2", "the new"),
                        try segment("w3", 2.2, 3, "S1", "budget")]
        policy = TranscriptCleanupPolicy()
        #expect(try TranscriptCleaner.prepare(twoWords, policy: policy).candidates.isEmpty)
        policy.preserveSpeakerChanges = false
        #expect(try TranscriptCleaner.prepare(twoWords, policy: policy).candidates.isEmpty)
        policy.maximumCandidateWords = 2
        #expect(try TranscriptCleaner.prepare(twoWords, policy: policy).candidates.first?.disposition == .bridge)
        policy.preserveSpeakerChanges = true
        #expect(try TranscriptCleaner.prepare(twoWords, policy: policy).utterances.count == 3)
        #expect(try TranscriptCleaner.prepare(twoWords, policy: policy).candidates.isEmpty)
        policy.preserveSpeakerChanges = false
        #expect(try TranscriptCleaner.prepare(twoWords, policy: policy).candidates.first?.disposition == .bridge)
        let oneWordTurn = [try segment("voice_a", 1, 2, "S1", "Budget"),
                           try segment("voice_b", 2, 2.2, "S2", "Yes"),
                           try segment("voice_c", 2.2, 3, "S1", "Schedule")]
        #expect(try TranscriptCleaner.prepare(oneWordTurn).utterances.count == 3)
        #expect(try TranscriptCleaner.prepare(oneWordTurn).candidates.isEmpty)
        let distant = [try segment("g1", 1, 2, "S1", "We"),
                       try segment("g2", 4, 4.2, nil, "the"),
                       try segment("g3", 6.2, 7, "S1", "budget")]
        policy = TranscriptCleanupPolicy()
        #expect(try TranscriptCleaner.prepare(distant, policy: policy).candidates.first?.disposition == .retainIndependent)
        policy.maximumNeighborGapSeconds = 2.1
        #expect(try TranscriptCleaner.prepare(distant, policy: policy).candidates.first?.disposition == .bridge)
        let overlapping = [try segment("o1", 1, 2, "S1", "We"),
                           try segment("o2", 1.8, 2.2, "S2", "the"),
                           try segment("o3", 2.2, 3, "S1", "budget")]
        policy = TranscriptCleanupPolicy()
        policy.preserveSpeakerChanges = false
        #expect(try TranscriptCleaner.prepare(overlapping, policy: policy).candidates.isEmpty)
        policy.maximumOverlapSeconds = 0.25
        #expect(try TranscriptCleaner.prepare(overlapping, policy: policy).candidates.first?.disposition == .bridge)
        let oneSided = [try segment("s1", 1, 2, "S1", "We approved"),
                        try segment("s2", 2.7, 3, nil, "the budget.")]
        policy = TranscriptCleanupPolicy()
        #expect(try TranscriptCleaner.prepare(oneSided, policy: policy).candidates.first?.disposition == .unresolved)
        policy.maximumOneSidedGapSeconds = 0.8
        #expect(try TranscriptCleaner.prepare(oneSided, policy: policy).candidates.first?.disposition == .joinPrevious)
        #expect(try TranscriptCleaner.prepare(oneSided, policy: policy).utterances.flatMap(\.sourceSegmentIDs) == ["s1", "s2"])
        for json in ["{\"maximumCandidateWords\":0}", "{\"maximumOverlapSeconds\":-1}",
                     "{\"maximumReadingBlockSeconds\":0}", "{\"maximumReadingGapSeconds\":-1}",
                     "{\"maximumOneSidedGapSeconds\":2}", "{\"grouping\":\"typo\"}",
                     "{\"maximumNeigborGapSeconds\":1}"] {
            #expect(throws: Error.self) {
                try JSONDecoder().decode(TranscriptCleanupPolicy.self, from: Data(json.utf8))
            }
        }
        policy.maximumOverlapSeconds = .infinity
        #expect(throws: Error.self) { try TranscriptCleaner.prepare(source, policy: policy) }
        #expect(try JSONDecoder().decode(TranscriptCleanupPolicy.self, from: Data("{}".utf8)) == TranscriptCleanupPolicy())
    }

    @Test func testLongSilenceBoundary() throws {
        let parts = [try segment("before", 146.8, 148.4, "S1", "zaczynamy."),
                     try segment("after", 181.68, 182.4, "S1", "Witam serdecznie.")]
        var policy = TranscriptCleanupPolicy()
        #expect(policy.longSilenceBoundarySeconds == 10)
        let separated = try TranscriptCleaner.prepare(parts, policy: policy)
        #expect(separated.utterances.count == 2)
        #expect(separated.utterances.map(\.speakerID) == ["S1", "S1"])
        #expect(separated.utterances.flatMap(\.sourceSegmentIDs) == parts.map(\.id))
        #expect(separated.utterances[1].boundaryReason?.contains("33.28") == true)
        policy.longSilenceBoundarySeconds = 60
        #expect(try TranscriptCleaner.prepare(parts, policy: policy).utterances.count == 1)
        let exact = [try segment("a", 0, 1, "S1", "35"),
                     try segment("b", 11, 12, "S1", "779 milionów")]
        #expect(try TranscriptCleaner.prepare(exact).utterances.count == 2)
        policy.longSilenceBoundarySeconds = 10.01
        #expect(try TranscriptCleaner.prepare(exact, policy: policy).utterances.count == 1)
        for json in ["{}", "{\"maximumReadingGapSeconds\":null}", "{\"longSilenceBoundarySeconds\":null}"] {
            #expect(try JSONDecoder().decode(TranscriptCleanupPolicy.self,
                from: Data(json.utf8)).longSilenceBoundarySeconds == 10)
        }
        for value in [0.0, -1, Double.infinity, Double.nan] {
            policy.longSilenceBoundarySeconds = value
            #expect(throws: Error.self) { try TranscriptCleaner.prepare(parts, policy: policy) }
        }
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
