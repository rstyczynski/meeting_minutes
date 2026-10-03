import Foundation
import Testing
@testable import MeetingMLXMinutes

struct ResponseValidationTests {
    private let source = Input.Segment(id: "source_1", speakerID: "S1", speakerName: nil,
                                       startSeconds: 1, endSeconds: 2,
                                       text: "We approved the budget.")
    private let good = """
    {"summary":{"text":"We approved the budget.","source_ids":["source_1"]},
    "decisions":[],"actions":[],"open_questions":[]}
    """

    @Test func repairsMalformedJSONOnce() {
        let first = MeetingMLXMinutes.validationStep("{\"summary\":", segments: [source], attempt: 0)
        guard case .repair(let prompt) = first else {
            Issue.record("Expected a repair prompt")
            return
        }
        #expect(prompt.contains("JSON/schema valid: false"))
        guard case .accepted = MeetingMLXMinutes.validationStep(good, segments: [source], attempt: 1)
        else { Issue.record("Expected repaired response to pass"); return }
    }

    @Test func checksSourceIDsAndQuotation() {
        let wrong = """
        {"summary":{"text":"We approved a different plan.","source_ids":["source_9"]},
        "decisions":[],"actions":[],"open_questions":[]}
        """
        let first = MeetingMLXMinutes.validationStep(wrong, segments: [source], attempt: 0)
        guard case .repair(let prompt) = first else {
            Issue.record("Expected source repair prompt")
            return
        }
        #expect(prompt.contains("source_9"))
        #expect(prompt.contains("Quote/citation errors"))
    }

    @Test func rejectsAfterTwoRepairs() {
        guard case .repair = MeetingMLXMinutes.validationStep("not json", segments: [source], attempt: 0)
        else { Issue.record("Expected first repair"); return }
        guard case .repair = MeetingMLXMinutes.validationStep("still not json", segments: [source], attempt: 1)
        else { Issue.record("Expected second repair"); return }
        guard case .rejected(let reason) = MeetingMLXMinutes.validationStep("still not json", segments: [source], attempt: 2)
        else { Issue.record("Expected final rejection"); return }
        #expect(reason.contains("after two repair prompts"))
    }

    @Test func rejectsExcessiveCitationsAndMissingFields() {
        let wrong = """
        {"summary":{"text":"We approved the budget.","source_ids":["source_1","source_1","source_1"]},
        "decisions":[],"actions":[]}
        """
        guard case .repair = MeetingMLXMinutes.validationStep(wrong, segments: [source], attempt: 0)
        else { Issue.record("Expected schema repair"); return }
    }
}
