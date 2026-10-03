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
        let duration = segments.map(\.range.endSeconds).max()! - segments.map(\.range.startSeconds).min()!
        guard duration <= 600 else {
            throw MeetingError.adapterFailure("minutes input exceeds prototype limit (600 seconds)")
        }
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
        let parsed: ModelMinutes
        do {
            parsed = try JSONDecoder().decode(ModelMinutes.self, from: Data(cleaned.utf8))
        } catch {
            if let directory = ProcessInfo.processInfo.environment["MEETING_MINUTES_DIAGNOSTICS_DIR"] {
                let url = URL(fileURLWithPath: directory, isDirectory: true)
                    .appendingPathComponent("minutes-response-\(UUID().uuidString).txt")
                try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                         withIntermediateDirectories: true)
                try? Data(cleaned.prefix(65_536).utf8).write(to: url, options: .atomic)
            }
            throw MeetingError.adapterFailure("Model minutes response is not valid evidence JSON")
        }
        guard let summary = try grounded(parsed.summary, kind: .summary,
                                         through: sourceMap, segments: segments) else {
            throw MeetingError.adapterFailure("No source-grounded minutes summary")
        }
        var items = [summary]
        var withheld = 0
        for entry in parsed.decisions {
            if let item = try grounded(entry, kind: .decision, through: sourceMap, segments: segments) {
                items.append(item)
            } else { withheld += 1 }
        }
        for entry in parsed.actions {
            if let item = try grounded(entry, kind: .action, through: sourceMap, segments: segments) {
                items.append(item)
            } else { withheld += 1 }
        }
        for entry in parsed.openQuestions {
            if let item = try grounded(entry, kind: .openQuestion, through: sourceMap, segments: segments) {
                items.append(item)
            } else { withheld += 1 }
        }
        FileHandle.standardError.write(Data("Withheld \(withheld) unsupported minutes candidates\n".utf8))
        return items
    }

    private func grounded(_ entry: ModelMinutes.Entry, kind: ReviewKind,
                          through map: [String: [String]],
                          segments: [TranscriptSegment]) throws -> ReviewItem? {
        guard (1...2).contains(entry.sourceIDs.count),
              !entry.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let IDs = expand(entry.sourceIDs, through: map)
        let byID = Dictionary(uniqueKeysWithValues: segments.map { ($0.id, $0) })
        guard IDs.allSatisfy({ byID[$0] != nil }) else { return nil }
        let source = IDs.compactMap { byID[$0]?.text }.joined(separator: " ")
        let quote = Self.normalized(entry.text)
        guard Self.normalized(source).contains(quote) else { return nil }
        let lower = quote.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        switch kind {
        case .summary: break
        case .decision:
            let signals = ["decid", "approv", "accept", "reject", "voted", "no objection",
                           "nie slysze sprzeciwu", "pozytywnie opiniuje", "przyjeto", "zatwierdz"]
            guard signals.contains(where: lower.contains) else { return nil }
        case .action:
            let signals = ["i will ", "we will ", "i shall ", "we shall ",
                           "zobowiazuje sie", "przygotuje", "wysle", "przeslemy"]
            let exclusions = ["please present", "poprosze", "przechodzimy", "we will now"]
            guard signals.contains(where: lower.contains),
                  !exclusions.contains(where: lower.contains) else { return nil }
        case .openQuestion:
            guard quote.contains("?") else { return nil }
        }
        let citedSpeakers = Set(IDs.compactMap { byID[$0]?.speakerID })
        let owner = entry.ownerSpeakerID.flatMap { citedSpeakers.contains($0) ? $0 : nil }
        return try MinutesValidator.item(kind: kind, text: entry.text,
                                         sourceIDs: IDs, owner: owner, segments: segments)
    }

    private static func normalized(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
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
    let summary: Entry
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
