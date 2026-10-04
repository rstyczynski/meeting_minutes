import Foundation

public struct MeetingTopic: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public var summary: String?
    public var sourceUtteranceIDs: [String]

    public init(id: String, title: String, summary: String? = nil,
                sourceUtteranceIDs: [String] = []) {
        self.id = id
        self.title = title
        self.summary = summary
        self.sourceUtteranceIDs = sourceUtteranceIDs
    }
}

public struct TopicAssignment: Codable, Sendable, Equatable {
    public let utteranceID: String
    public let topicIDs: [String]

    public init(utteranceID: String, topicIDs: [String]) {
        self.utteranceID = utteranceID
        self.topicIDs = topicIDs
    }
}

public struct TopicCoverageReport: Codable, Sendable, Equatable {
    public let coveredUtterances: Int
    public let totalUtterances: Int
    public let segmentCount: Int
    public var fraction: Double {
        totalUtterances == 0 ? 0 : Double(coveredUtterances) / Double(totalUtterances)
    }
}

public enum TopicCoverage {
    public static func validate(cleanup: TranscriptCleanupResult,
                                topics: [MeetingTopic],
                                assignments: [TopicAssignment]) throws -> TopicCoverageReport {
        guard !cleanup.hasUnresolvedCandidates else {
            throw MeetingError.adapterFailure("Transcript cleanup has unresolved candidates")
        }
        let topicIDs = Set(topics.map(\.id))
        guard !topicIDs.isEmpty, topicIDs.count == topics.count,
              topics.allSatisfy({ !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw MeetingError.adapterFailure("Invalid meeting topics")
        }
        let utteranceIDs = Set(cleanup.utterances.map(\.id))
        let assignmentIDs = assignments.map(\.utteranceID)
        guard !utteranceIDs.isEmpty, Set(assignmentIDs) == utteranceIDs,
              assignmentIDs.count == utteranceIDs.count,
              assignments.allSatisfy({ !$0.topicIDs.isEmpty &&
                  $0.topicIDs.allSatisfy(topicIDs.contains) }) else {
            throw MeetingError.adapterFailure("Incomplete or invalid utterance-to-topic coverage")
        }
        let allSegments = cleanup.utterances.flatMap(\.sourceSegmentIDs)
            + cleanup.artifactSegmentIDs
        guard Set(allSegments).count == allSegments.count else {
            throw MeetingError.adapterFailure("A source segment appears more than once in cleanup")
        }
        return TopicCoverageReport(coveredUtterances: assignments.count,
                                   totalUtterances: cleanup.utterances.count,
                                   segmentCount: allSegments.count)
    }
}
