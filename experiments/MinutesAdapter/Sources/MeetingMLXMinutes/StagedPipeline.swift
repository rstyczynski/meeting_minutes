import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

struct StageInput: Decodable {
    struct Utterance: Decodable {
        let id: String
        let speakerID: String?
        let speakerName: String?
        let startSeconds: Double
        let endSeconds: Double
        let text: String
    }
    let utterances: [Utterance]
}

enum StageGate {
    static func reconcile(topics: [[String: Any]], assignments: inout [[String: Any]]) throws -> Int {
        var count = 0
        for topic in topics {
            guard let id = topic["id"] as? String,
                  let citedIDs = topic["source_utterance_ids"] as? [String] else {
                throw StageError.invalid("Invalid topic proposal during reconciliation")
            }
            for cited in citedIDs {
                guard let index = assignments.firstIndex(where: {
                    $0["utteranceID"] as? String == cited
                }), var ids = assignments[index]["topicIDs"] as? [String] else {
                    throw StageError.invalid("Topic citation is not in assignment input")
                }
                if !ids.contains(id) {
                    ids.append(id)
                    assignments[index]["topicIDs"] = ids
                    count += 1
                }
            }
        }
        return count
    }

    static func items(_ raw: String) throws -> [String: Any] {
        let trimmed = normalizedJSON(raw)
        guard trimmed.utf8.count <= 64_000,
              let data = trimmed.data(using: .utf8) else {
            throw StageError.invalid("Items response is oversized")
        }
        let value = try JSONSerialization.jsonObject(with: data)
        if let object = value as? [String: Any] { return object }
        if let array = value as? [[String: Any]] { return ["items": array] }
        throw StageError.invalid("Items response must be an object or array")
    }

    static func eligible(kind: String, quote: String) -> Bool {
        let lower = quote.folding(options: [.caseInsensitive, .diacriticInsensitive],
                                  locale: Locale(identifier: "en_US_POSIX"))
        switch kind {
        case "decision":
            return ["decid", "approv", "accepted", "rejected", "voted",
                    "przyjet", "zatwierdz", "pozytywnie opiniuje", "nie slysze sprzeciwu"]
                .contains(where: lower.contains)
        case "action", "task":
            let commitment = ["i will", "we will", "i shall", "we shall",
                              "zobowiazuje sie", "przygotuje", "wysle", "przeslemy",
                              "bedziemy chcieli", "zostanie przygotowan"]
                .contains(where: lower.contains)
            let invitation = ["please present", "poprosze", "przechodzimy", "we will now"]
                .contains(where: lower.contains)
            return commitment && !invitation
        case "openQuestion": return quote.contains("?")
        default: return false
        }
    }

    static func mayContainItem(_ text: String) -> Bool {
        let lower = text.folding(options: [.caseInsensitive, .diacriticInsensitive],
                                 locale: Locale(identifier: "en_US_POSIX"))
        return lower.contains("?") ||
            ["decid", "approv", "accepted", "rejected", "voted", "przyjet",
             "zatwierdz", "pozytywnie opiniuje", "nie slysze sprzeciwu",
             "i will", "we will", "i shall", "we shall", "zobowiazuje sie",
             "przygotuje", "wysle", "przeslemy", "bedziemy chcieli"]
                .contains(where: lower.contains)
    }

    static func object(_ raw: String) throws -> [String: Any] {
        let text = normalizedJSON(raw)
        guard text.utf8.count <= 64_000,
              let data = text.data(using: .utf8),
              let value = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw StageError.invalid("Response is not a bounded JSON object")
        }
        return value
    }

    private static func normalizedJSON(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```json") { text = String(text.dropFirst(7)) }
        else if text.hasPrefix("```") { text = String(text.dropFirst(3)) }
        if text.hasSuffix("```") { text = String(text.dropLast(3)) }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasSuffix("}.") || text.hasSuffix("].") { text.removeLast() }
        return text
    }

    static func strings(_ value: Any?, allowed: Set<String>, required: Bool = true) throws -> [String] {
        guard let ids = value as? [String], (!required || !ids.isEmpty),
              Set(ids).count == ids.count, ids.allSatisfy(allowed.contains) else {
            throw StageError.invalid("Missing, duplicate, or unknown source IDs")
        }
        return ids
    }

    static func text(_ value: Any?, limit: Int = 800) throws -> String {
        guard let text = value as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              text.count <= limit else { throw StageError.invalid("Empty or oversized text") }
        return text
    }

    static func quote(_ value: Any?, IDs: [String], source: [String: String],
                      salvage: Bool = false) throws -> String {
        guard let quote = value as? String, (8...250).contains(quote.count) else {
            throw StageError.invalid("evidence_quote must be a short 8–250 character excerpt")
        }
        let normalized = quote.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let supported = IDs.compactMap { source[$0] }
            .map { $0.split(whereSeparator: \.isWhitespace).joined(separator: " ") }
            .contains { $0.contains(normalized) }
        if normalized.count >= 8, supported { return quote }
        guard salvage else {
            throw StageError.invalid("Evidence quote must be verbatim within one cited utterance; shorten the quote and cite that utterance")
        }
        let words = normalized.split(separator: " ").map(String.init)
        var best = ""
        var bestWords = 0
        for id in IDs {
            guard let cited = source[id] else { continue }
            let text = cited.split(whereSeparator: \.isWhitespace).joined(separator: " ")
            for start in words.indices {
                if start + 6 > words.count { continue }
                for end in (start + 6)...words.count {
                    let candidate = words[start..<end].joined(separator: " ")
                    if candidate.count <= 250, end - start > bestWords,
                       text.contains(candidate) {
                        best = candidate
                        bestWords = end - start
                    }
                }
            }
        }
        guard bestWords >= 6, best.count >= 24 else {
            throw StageError.invalid("No substantial exact excerpt remains in cited utterances")
        }
        FileHandle.standardError.write(Data("Shortened unsupported evidence quote to \(bestWords) exact source words\n".utf8))
        return best
    }
}

enum StageError: Error, LocalizedError {
    case invalid(String)
    var errorDescription: String? {
        if case .invalid(let reason) = self { return reason }
        return nil
    }
}

enum StagedPipeline {
    static func run(modelPath: String, inputPath: String, outputPath: String) async throws {
        let input = try JSONDecoder().decode(StageInput.self,
            from: Data(contentsOf: URL(fileURLWithPath: inputPath)))
        guard !input.utterances.isEmpty,
              Set(input.utterances.map(\.id)).count == input.utterances.count else {
            throw StageError.invalid("Empty or duplicate utterance input")
        }
        let source = Dictionary(uniqueKeysWithValues: input.utterances.map { ($0.id, $0.text) })
        let allIDs = Set(source.keys)
        let model = try await loadModelContainer(
            from: URL(fileURLWithPath: modelPath, isDirectory: true),
            using: #huggingFaceTokenizerLoader())
        let transcript = input.utterances.map { u in
            "\(u.id) | \(u.speakerName ?? u.speakerID ?? "Unknown") | " +
            "\(u.startSeconds)-\(u.endSeconds)s | \(u.text)"
        }.joined(separator: "\n")

        let topicInstruction = """
        Identify distinct substantive meeting topics from timed utterances.
        Return 2 to 5 broad topics for the whole excerpt. Merge closely
        related points. Do not list individual features, roles, names,
        sentences, or synonyms as separate topics. Stop after t5.
        Output only {"topics":[{"id":"t1","title":"short title",
        "source_utterance_ids":["utt_1"]}]}. Use t1,t2,... in order.
        Cite at least one exact utterance ID for every topic. Include real
        procedural topics when discussed; do not invent a catch-all topic.
        Keep titles short. Do not infer unsupported facts.
        """
        let topicsObject = try await ask(model: model, stage: "topics", instructions: topicInstruction,
                                         input: transcript) { raw, _ in
            let obj = try StageGate.object(raw)
            guard let topics = obj["topics"] as? [[String: Any]],
                  !topics.isEmpty, topics.count <= 5 else {
                throw StageError.invalid("Topic list absent or too large")
            }
            let topicIDs = topics.compactMap { $0["id"] as? String }
            guard topicIDs.count == topics.count, Set(topicIDs).count == topics.count else {
                throw StageError.invalid("Duplicate or missing topic IDs")
            }
            for (index, topic) in topics.enumerated() {
                guard topicIDs[index] == "t\(index + 1)" else {
                    throw StageError.invalid("Topic IDs must be sequential")
                }
                _ = try StageGate.text(topic["title"], limit: 100)
                _ = try StageGate.strings(topic["source_utterance_ids"], allowed: allIDs)
            }
            return obj
        }
        let topics = topicsObject["topics"] as! [[String: Any]]
        let topicIDs = Set(topics.map { $0["id"] as! String })
        let topicList = topics.map { "\($0["id"]!): \($0["title"]!)" }.joined(separator: "\n")

        var assignments: [[String: Any]] = []
        for start in stride(from: 0, to: input.utterances.count, by: 24) {
            let batch = Array(input.utterances[start..<min(start + 24, input.utterances.count)])
            let batchIDs = Set(batch.map(\.id))
            let assignmentInstruction = """
            Assign EVERY utterance to one or more substantive topics.
            Return only {"assignments":[{"utteranceID":"utt_1",
            "topicIDs":["t1"]}]}. Output each supplied utterance once.
            Never use a topic or utterance ID outside the supplied lists.
            Do not assign solely by speaker; use the spoken content.
            Topics:\n\(topicList)
            """
            let payload = batch.map { "\($0.id) | \($0.text)" }.joined(separator: "\n")
            let obj = try await ask(model: model, stage: "assignment_\(start / 24 + 1)",
                                    instructions: assignmentInstruction, input: payload) { raw, _ in
                let obj = try StageGate.object(raw)
                guard let rows = obj["assignments"] as? [[String: Any]],
                      rows.count == batch.count,
                      Set(rows.compactMap { $0["utteranceID"] as? String }) == batchIDs else {
                    throw StageError.invalid("Incomplete utterance-to-topic coverage")
                }
                for row in rows {
                    _ = try StageGate.strings(row["topicIDs"], allowed: topicIDs)
                }
                return obj
            }
            assignments += obj["assignments"] as! [[String: Any]]
        }
        // The topic proposal already cited source utterances. Keep those
        // citations as assignments when the separate assignment pass omitted
        // the same topic; this reconciles two explicit model outputs.
        let seededAssignments = try StageGate.reconcile(topics: topics,
                                                         assignments: &assignments)
        FileHandle.standardError.write(Data("Reconciled \(seededAssignments) topic proposal citations into assignments\n".utf8))
        let assignmentMap = Dictionary(uniqueKeysWithValues: assignments.map {
            ($0["utteranceID"] as! String, Set($0["topicIDs"] as! [String]))
        })
        var summaries: [[String: Any]] = []
        var candidates: [[String: Any]] = []
        for topic in topics {
            let topicID = topic["id"] as! String
            let title = topic["title"] as! String
            let scoped = input.utterances.filter { assignmentMap[$0.id]?.contains(topicID) == true }
            let scopedIDs = Set(scoped.map(\.id))
            guard !scoped.isEmpty else { throw StageError.invalid("Topic has no assigned utterances") }
            let payload = scoped.map { "\($0.id) | \($0.text)" }.joined(separator: "\n")
            let summaryInstruction = """
            Summarize the topic “\(title)” in one or two clear sentences.
            Paraphrase; do not present a quotation as the summary. Output only
            {"text":"factual topic summary","source_utterance_ids":["utt_1"],
            "evidence_quote":"exact contiguous words from cited utterance"}.
            Keep evidence_quote to 8–30 words and under 250 characters.
            Cite utterance IDs from this topic. The evidence_quote must be
            verbatim and support the summary. Omit unsupported detail.
            """
            let summary = try await ask(model: model, stage: "summary_\(topicID)",
                                        instructions: summaryInstruction, input: payload) { raw, attempt in
                var obj = try StageGate.object(raw)
                _ = try StageGate.text(obj["text"])
                let IDs = try StageGate.strings(obj["source_utterance_ids"], allowed: scopedIDs)
                obj["evidence_quote"] = try StageGate.quote(obj["evidence_quote"], IDs: IDs,
                                                              source: source, salvage: attempt == 2)
                return obj
            }
            summaries.append(["topic_id": topicID, "text": summary["text"]!,
                              "source_utterance_ids": summary["source_utterance_ids"]!,
                              "evidence_quote": summary["evidence_quote"]!])

            let itemSources = scoped.filter { StageGate.mayContainItem($0.text) }
            if itemSources.isEmpty { continue }
            let itemIDs = Set(itemSources.map(\.id))
            let itemPayload = itemSources.map { "\($0.id) | \($0.text)" }.joined(separator: "\n")
            let extractionInstruction = """
            Extract only explicit decisions, future commitments, tasks from
            commitments, and still-open questions for topic “\(title)”.
            An agenda item, request to speak, or proposal is not a decision.
            A budget amount being reported is not a committee decision.
            A task requires a cited future commitment. Omit uncertainty.
            Return at most three items total. Do not enumerate budget lines.
            Return only {"items":[{"kind":"decision|action|task|openQuestion",
            "text":"brief factual statement","source_utterance_ids":["utt_1"],
            "evidence_quote":"exact contiguous source words",
            "owner_speaker_id":null,"due_date":null}]}.
            Keep each evidence_quote to 8–30 words and under 250 characters.
            Use [] when no qualifying item exists. Owner and due date may be
            non-null only when the cited words explicitly support them.
            Never invent a person, date, item, or source ID.
            """
            let extracted = try await ask(model: model, stage: "items_\(topicID)",
                                          instructions: extractionInstruction, input: itemPayload) { raw, attempt in
                let obj = try StageGate.items(raw)
                guard let items = obj["items"] as? [[String: Any]], items.count <= 3 else {
                    throw StageError.invalid("Items array absent or too large")
                }
                var retained: [[String: Any]] = []
                for var item in items {
                    guard let kind = item["kind"] as? String,
                          ["decision", "action", "task", "openQuestion"].contains(kind) else {
                        throw StageError.invalid("Unknown item type")
                    }
                    _ = try StageGate.text(item["text"])
                    let IDs = try StageGate.strings(item["source_utterance_ids"], allowed: itemIDs)
                    guard let quote = item["evidence_quote"] as? String,
                          StageGate.eligible(kind: kind, quote: quote) else { continue }
                    item["evidence_quote"] = try StageGate.quote(quote, IDs: IDs,
                        source: source, salvage: attempt == 2)
                    if let owner = item["owner_speaker_id"] as? String {
                        let speakers = Set(scoped.filter { IDs.contains($0.id) }.compactMap(\.speakerID))
                        guard speakers.contains(owner) else {
                            throw StageError.invalid("Owner lacks cited speech")
                        }
                    }
                    if let date = item["due_date"] as? String {
                        guard date.count <= 40 else { throw StageError.invalid("Invalid due date") }
                    }
                    item["topic_id"] = topicID
                    retained.append(item)
                }
                FileHandle.standardError.write(Data("\(topicID): withheld \(items.count - retained.count) unsupported item candidates\n".utf8))
                return ["items": retained]
            }
            candidates += extracted["items"] as! [[String: Any]]
        }
        let topicRecords: [[String: Any]] = topics.map {
            ["id": $0["id"]!, "title": $0["title"]!,
             "sourceUtteranceIDs": $0["source_utterance_ids"]!]
        }
        let output: [String: Any] = ["topics": topicRecords, "assignments": assignments,
                                     "summaries": summaries, "candidates": candidates]
        try JSONSerialization.data(withJSONObject: output, options: [.sortedKeys])
            .write(to: URL(fileURLWithPath: outputPath), options: .atomic)
    }

    private static func ask(model: ModelContainer, stage: String,
                            instructions: String, input: String,
                            validate: (String, Int) throws -> [String: Any]) async throws -> [String: Any] {
        let session = ChatSession(model, instructions: instructions,
                                  generateParameters: .init(maxTokens: stage == "topics" ? 512 :
                                    (stage.hasPrefix("items_") ? 768 : 1536),
                                                            temperature: 0))
        var response = try await session.respond(to: input)
        for attempt in 0...2 {
            do {
                let object = try validate(response, attempt)
                try diagnostic(stage: stage, attempt: attempt, response: response,
                               result: "accepted")
                return object
            } catch {
                try diagnostic(stage: stage, attempt: attempt, response: response,
                               result: error.localizedDescription)
                guard attempt < 2 else {
                    throw StageError.invalid("\(stage) failed after two repairs: \(error.localizedDescription)")
                }
                response = try await session.respond(to: """
                    Your \(stage) response failed validation: \(error.localizedDescription).
                    Correct your previous answer using only the supplied transcript
                    and IDs. Follow the original JSON shape exactly. Output JSON only.
                    """)
            }
        }
        throw StageError.invalid("Unreachable stage failure")
    }

    private static func diagnostic(stage: String, attempt: Int, response: String,
                                   result: String) throws {
        guard let path = ProcessInfo.processInfo.environment["MEETING_MINUTES_DIAGNOSTICS_DIR"] else {
            return
        }
        let root = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let record: [String: Any] = ["promptRevision": "minutes-v4.1-multistage",
                                     "stage": stage, "attempt": attempt,
                                     "validation": result, "response": response]
        try JSONSerialization.data(withJSONObject: record, options: [.sortedKeys])
            .write(to: root.appendingPathComponent("\(stage)_attempt_\(attempt).json"),
                   options: .atomic)
    }
}
