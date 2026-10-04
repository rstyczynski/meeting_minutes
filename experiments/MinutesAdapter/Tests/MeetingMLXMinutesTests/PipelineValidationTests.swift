import Foundation
import Testing
@testable import MeetingMLXMinutes

struct PipelineValidationTests {
    @Test func testStageValidation() throws {
        #expect(throws: Error.self) { try StageGate.object("{\"topics\":[") }
        #expect(try StageGate.object("{\"topics\":[]}. ")["topics"] is [Any])
        #expect(throws: Error.self) {
            try StageGate.strings(["utt_1", "invented"], allowed: ["utt_1"])
        }
        #expect(throws: Error.self) {
            try StageGate.strings(["utt_1", "utt_1"], allowed: ["utt_1"])
        }
        #expect(throws: Error.self) {
            try StageGate.quote("invented conclusion", IDs: ["utt_1"],
                                source: ["utt_1": "We approved the budget."])
        }
        let accepted = try StageGate.quote("approved the budget", IDs: ["utt_1"],
                                           source: ["utt_1": "We approved the budget."])
        #expect(accepted == "approved the budget")
        let longQuote = "The budget was approved. We will prepare the revised schedule for everyone tomorrow."
        let source = ["utt_1": "The budget was approved.",
                      "utt_2": "We will prepare the revised schedule for everyone tomorrow."]
        #expect(throws: Error.self) {
            try StageGate.quote(longQuote, IDs: ["utt_1", "utt_2"], source: source)
        }
        #expect(try StageGate.quote(longQuote, IDs: ["utt_1", "utt_2"],
                                    source: source, salvage: true) ==
                "We will prepare the revised schedule for everyone tomorrow.")
        #expect(try StageGate.quote("um so that's kind of our our brief.", IDs: ["utt_3"],
            source: ["utt_3": "Um so that's kind of our our brief."], salvage: true) ==
            "so that's kind of our our brief.")
        #expect(try StageGate.items("[]")["items"] is [[String: Any]])
        #expect(!StageGate.eligible(kind: "decision", quote: "This is our kickoff meeting"))
        #expect(!StageGate.eligible(kind: "action", quote: "So that's David, isn't it?"))
        #expect(StageGate.eligible(kind: "decision", quote: "We approved the budget"))
        var assignments: [[String: Any]] = [["utteranceID": "utt_1", "topicIDs": ["t1"]]]
        let seeded = try StageGate.reconcile(
            topics: [["id": "t2", "source_utterance_ids": ["utt_1"]]],
            assignments: &assignments)
        #expect(seeded == 1)
        #expect(Set(assignments[0]["topicIDs"] as? [String] ?? []) == ["t1", "t2"])
    }
}
