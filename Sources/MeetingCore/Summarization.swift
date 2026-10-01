import Foundation

public struct FixtureSummaryGenerator: MinutesGenerating {
    public let reference: FixtureReference
    public init(reference: FixtureReference) { self.reference = reference }

    public func generate(from segments: [TranscriptSegment]) throws -> [ReviewItem] {
        let summary = try MinutesValidator.item(
            kind: .summary,
            text: "The group planned a same-recording comparison of two transcription engines.",
            sourceIDs: ["turn_3"], segments: segments)
        return try [summary] + FixtureMinutesGenerator(reference: reference)
            .generate(from: segments)
    }
}

public struct MLXProcessMinutesGenerator: MinutesGenerating {
    public let executable: String
    public let modelDirectory: String
    public let speakerNames: [String: String]

    public init(executable: String, modelDirectory: String,
                speakerNames: [String: String]) {
        self.executable = executable
        self.modelDirectory = modelDirectory
        self.speakerNames = speakerNames
    }

    public func generate(from segments: [TranscriptSegment]) throws -> [ReviewItem] {
        guard FileManager.default.fileExists(atPath: modelDirectory) else {
            throw MeetingError.missingModel("mlx")
        }
        guard !segments.isEmpty else { throw MeetingError.adapterFailure("No transcript segments") }
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("meeting-minutes-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let inputURL = root.appendingPathComponent("input.json")
        let outputURL = root.appendingPathComponent("output.json")
        // Word-level ASR can produce hundreds of IDs in a short meeting.
        // Give the model bounded source chunks and expand its citations back
        // to the original persisted segments before validation.
        var groups: [[TranscriptSegment]] = []
        if segments.count <= 40 {
            groups = segments.map { [$0] }
        } else {
            for segment in segments {
                if let last = groups.indices.last,
                   let first = groups[last].first,
                   groups[last].count < 16,
                   first.speakerID == segment.speakerID,
                   segment.range.endSeconds - first.range.startSeconds <= 8 {
                    groups[last].append(segment)
                } else {
                    groups.append([segment])
                }
            }
        }
        var sourceMap: [String: [String]] = [:]
        let input = ModelInput(segments: groups.enumerated().map { index, group in
            let id = segments.count <= 40 ? group[0].id : "source_\(index + 1)"
            sourceMap[id] = group.map(\.id)
            return ModelInput.Segment(
                id: id, speakerID: group[0].speakerID,
                speakerName: group[0].speakerID.flatMap { speakerNames[$0] },
                startSeconds: group[0].range.startSeconds,
                endSeconds: group[group.count - 1].range.endSeconds,
                text: group.map(\.text).joined(separator: " "))
        })
        try JSONEncoder().encode(input).write(to: inputURL, options: .atomic)
        _ = try runProcess(executable, [modelDirectory, inputURL.path, outputURL.path])
        let wrapper = try JSONDecoder().decode(ModelOutput.self,
                                               from: Data(contentsOf: outputURL))
        let content = wrapper.response.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = content.hasPrefix("```json")
            ? String(content.dropFirst(7).dropLast(content.hasSuffix("```") ? 3 : 0))
            : content
        let parsed = try JSONDecoder().decode(ModelMinutes.self, from: Data(cleaned.utf8))
        guard !parsed.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MeetingError.adapterFailure("Minutes summary is empty")
        }
        var items = [try MinutesValidator.item(kind: .summary, text: parsed.summary,
                                               sourceIDs: [], segments: segments)]
        for entry in parsed.decisions {
            items.append(try MinutesValidator.item(kind: .decision, text: entry.text,
                sourceIDs: expand(entry.sourceIDs, through: sourceMap), segments: segments))
        }
        for entry in parsed.actions {
            let supportedOwner = entry.ownerSpeakerID.flatMap { candidate in
                segments.contains(where: { $0.speakerID == candidate }) ? candidate : nil
            }
            items.append(try MinutesValidator.item(kind: .action, text: entry.text,
                sourceIDs: expand(entry.sourceIDs, through: sourceMap),
                owner: supportedOwner, segments: segments))
        }
        for entry in parsed.openQuestions {
            items.append(try MinutesValidator.item(kind: .openQuestion, text: entry.text,
                sourceIDs: expand(entry.sourceIDs, through: sourceMap), segments: segments))
        }
        return items
    }

    private func expand(_ IDs: [String], through map: [String: [String]]) -> [String] {
        IDs.flatMap { map[$0] ?? map["source_\($0)"] ?? [$0] }
    }
}

private struct ModelInput: Encodable {
    struct Segment: Encodable {
        let id: String
        let speakerID: String?
        let speakerName: String?
        let startSeconds: Double
        let endSeconds: Double
        let text: String
    }
    let segments: [Segment]
}

private struct ModelOutput: Decodable {
    let response: String
}

private struct ModelMinutes: Decodable {
    struct Entry: Decodable {
        let text: String
        let sourceIDs: [String]
        let ownerSpeakerID: String?
        enum CodingKeys: String, CodingKey {
            case text
            case sourceIDs = "source_ids"
            case ownerSpeakerID = "owner_speaker_id"
        }
    }
    let summary: String
    let decisions: [Entry]
    let actions: [Entry]
    let openQuestions: [Entry]
    enum CodingKeys: String, CodingKey {
        case summary, decisions, actions
        case openQuestions = "open_questions"
    }
}

public struct MeetingSummarizer {
    public let store: MeetingStore
    public init(store: MeetingStore) { self.store = store }

    @discardableResult
    public func summarize(_ id: UUID, generator: any MinutesGenerating,
                          modelRevision: String, fixtureDerived: Bool = false) throws -> MeetingRecord {
        var record = try store.load(id)
        let items = try generator.generate(from: record.segments)
        record.reviewItems = items
        record.processingParameters["minutesModelRevision"] = modelRevision
        record.processingParameters["minutesSource"] = fixtureDerived ? "fixture" : "local-model"
        try store.save(record)
        return record
    }
}
