import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

struct Input: Decodable {
    struct Segment: Decodable {
        let id: String
        let speakerID: String?
        let speakerName: String?
        let startSeconds: Double
        let endSeconds: Double
        let text: String
    }
    let segments: [Segment]
}

private struct Output: Encodable {
    let modelRevision: String
    let promptRevision: String
    let response: String
}

@main
struct MeetingMLXMinutes {
    enum ValidationDecision {
        case accepted
        case repair(String)
        case rejected(String)
    }

    static func main() async {
        do {
            let args = Array(CommandLine.arguments.dropFirst())
            guard args.count == 3 else {
                throw NSError(domain: "MeetingMLXMinutes", code: 2,
                              userInfo: [NSLocalizedDescriptionKey:
                                "Usage: meeting-mlx-minutes MODEL_DIRECTORY INPUT_JSON OUTPUT_JSON"])
            }
            let modelDirectory = URL(fileURLWithPath: args[0], isDirectory: true)
            let input = try JSONDecoder().decode(Input.self,
                from: Data(contentsOf: URL(fileURLWithPath: args[1])))
            guard !input.segments.isEmpty else {
                throw NSError(domain: "MeetingMLXMinutes", code: 3,
                              userInfo: [NSLocalizedDescriptionKey: "No transcript segments"])
            }
            let transcript = input.segments.map { segment in
                let label = segment.speakerName.map {
                    "\(segment.speakerID ?? "unknown") / \($0)"
                } ?? segment.speakerID ?? "unknown"
                return "SOURCE_ID=\(segment.id) | SPEAKER=\(label) | TIME=\(segment.startSeconds)-\(segment.endSeconds)s | TEXT=\(segment.text)"
            }.joined(separator: "\n")
            let instructions = """
                Select short, exact transcript quotations for a source-grounded draft.
                Return one JSON object with keys summary (object), decisions (array),
                actions (array), and open_questions (array). Every object must have
                text (a verbatim contiguous quotation from the cited transcript)
                and source_ids (one or two exact SOURCE_ID values). Never paraphrase.
                A SPEAKER value such as S1 is never a SOURCE_ID. For example,
                cite source_12 as ["source_12"], never ["S1"]. If a claim has no
                exact source, omit the claim.
                An action may have owner_speaker_id (canonical speaker ID, not a name) only
                if the cited text explicitly states the owner. Use supplied speaker names
                only where available. Do not invent facts, people, owners, dates, or source
                IDs. Return at most one decision, one action, and one open question.
                Keep every quotation short, ideally under 25 words. An introduction, an agenda,
                a request for someone to speak, or a transition to the next topic is not
                a decision or an action. A decision needs an explicit acceptance,
                rejection, vote, or no-objection conclusion. An action needs an explicit
                future commitment, not a request made during this meeting. Include an
                open question only when a speaker actually asked it and it remained
                unanswered; do not invent questions from agenda topics. If evidence is
                absent or uncertain, return empty arrays. The summary must be a
                short, verbatim quotation from one source chunk, with its source_id.
                Do not explain or infer what the quotation means.
                Use this exact JSON shape, replacing the example words and IDs:
                {"summary":{"text":"exact quote","source_ids":["source_1"]},
                "decisions":[{"text":"exact quote","source_ids":["source_2"]}],
                "actions":[],"open_questions":[]}
                Never put SOURCE_ID inside text. A quote spanning two source chunks
                must cite both IDs in source_ids.
                Return JSON only, without Markdown fences.
                """
            let model = try await loadModelContainer(
                from: modelDirectory, using: #huggingFaceTokenizerLoader())
            let session = ChatSession(model, instructions: instructions,
                generateParameters: .init(maxTokens: 1024, temperature: 0))
            var response = try await session.respond(to: transcript)
            validationLoop: for attempt in 0..<3 {
                let decision = validationStep(response, segments: input.segments, attempt: attempt)
                try recordDiagnostic(response: response, decision: decision, attempt: attempt,
                                     modelRevision: modelDirectory.lastPathComponent)
                switch decision {
                case .accepted: break validationLoop
                case .repair(let prompt): response = try await session.respond(to: prompt)
                case .rejected(let reason):
                    throw NSError(domain: "MeetingMLXMinutes", code: 4,
                                  userInfo: [NSLocalizedDescriptionKey: reason])
                }
            }
            let output = Output(modelRevision: modelDirectory.lastPathComponent,
                                promptRevision: "minutes-v3-evidence", response: response)
            try JSONEncoder().encode(output).write(
                to: URL(fileURLWithPath: args[2]), options: .atomic)
        } catch {
            FileHandle.standardError.write(Data("\(error.localizedDescription)\n".utf8))
            exit(2)
        }
    }

    private static func recordDiagnostic(response: String, decision: ValidationDecision,
                                         attempt: Int, modelRevision: String) throws {
        guard let directory = ProcessInfo.processInfo.environment["MEETING_MINUTES_DIAGNOSTICS_DIR"]
                .flatMap({ $0.isEmpty ? nil : $0 }) else { return }
        let status: String
        switch decision {
        case .accepted: status = "accepted"
        case .repair: status = "repair"
        case .rejected(let reason): status = "rejected: \(reason)"
        }
        let destination = URL(fileURLWithPath: directory, isDirectory: true)
        try FileManager.default.createDirectory(at: destination,
                                                withIntermediateDirectories: true)
        let record = ["modelRevision": modelRevision,
                      "promptRevision": "minutes-v3-evidence",
                      "attempt": String(attempt), "validation": status,
                      "response": response]
        try JSONEncoder().encode(record).write(
            to: destination.appendingPathComponent("minutes_attempt_\(attempt).json"),
            options: .atomic)
    }

    static func validationStep(_ response: String, segments: [Input.Segment],
                               attempt: Int) -> ValidationDecision {
            let sourceIDs = Set(segments.map(\.id))
                let invalid = invalidSourceIDs(in: response, valid: sourceIDs)
                let validSchema = hasEvidenceSchema(response)
                let unsupportedQuotes = validSchema
                    ? quotationErrors(in: response, segments: segments) : []
                if validSchema && invalid.isEmpty && unsupportedQuotes.isEmpty { return .accepted }
                guard attempt < 2 else {
                    return .rejected("Model response failed validation after two repair prompts: schema=\(validSchema); invalid IDs=\(invalid.joined(separator: ",")); quotes=\(unsupportedQuotes.joined(separator: "; "))")
                }
                let validList = segments.map(\.id).joined(separator: ", ")
                return .repair("""
                    Your previous response failed technical validation.
                    JSON/schema valid: \(validSchema). Invalid source IDs:
                    \(invalid.joined(separator: ", ")). Quote/citation errors:
                    \(unsupportedQuotes.joined(separator: "; ")). Rewrite it as valid JSON
                    in this exact shape:
                    {"summary":{"text":"verbatim quote","source_ids":["source_1"]},
                    "decisions":[],"actions":[],"open_questions":[]}
                    Each array item must be an object with text and source_ids, never
                    a string. Put IDs in source_ids, never inside text. Cite every
                    source chunk needed for the full verbatim quote, using at most
                    two source_ids. Shorten a quotation if it spans more chunks.
                    Available IDs: \(validList).
                    Omit unsupported items. Return only the JSON object.
                    """)
    }

    private static func invalidSourceIDs(in response: String, valid: Set<String>) -> [String] {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let content = trimmed.hasPrefix("```json")
            ? String(trimmed.dropFirst(7).dropLast(trimmed.hasSuffix("```") ? 3 : 0))
            : trimmed
        guard let data = content.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [] }
        let entries = ["decisions", "actions", "open_questions"]
            .flatMap { object[$0] as? [[String: Any]] ?? [] }
        let summary = object["summary"] as? [String: Any]
        let cited = entries.flatMap { $0["source_ids"] as? [String] ?? [] }
            + (summary?["source_ids"] as? [String] ?? [])
        return Array(Set(cited.filter { !valid.contains($0) })).sorted()
    }

    private static func hasEvidenceSchema(_ response: String) -> Bool {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let content = trimmed.hasPrefix("```json")
            ? String(trimmed.dropFirst(7).dropLast(trimmed.hasSuffix("```") ? 3 : 0))
            : trimmed
        guard let data = content.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let summary = object["summary"] as? [String: Any],
              let summaryText = summary["text"] as? String, !summaryText.isEmpty,
              let summaryIDs = summary["source_ids"] as? [String],
              (1...2).contains(summaryIDs.count)
        else { return false }
        return ["decisions", "actions", "open_questions"].allSatisfy { key in
            guard let entries = object[key] as? [[String: Any]], entries.count <= 1
            else { return false }
            return entries.allSatisfy {
                guard let text = $0["text"] as? String, !text.isEmpty,
                      let IDs = $0["source_ids"] as? [String]
                else { return false }
                return (1...2).contains(IDs.count)
            }
        }
    }

    private static func quotationErrors(in response: String,
                                        segments: [Input.Segment]) -> [String] {
        guard let data = response.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return ["response is not parseable JSON"] }
        let byID = Dictionary(uniqueKeysWithValues: segments.map { ($0.id, $0.text) })
        let summary = (object["summary"] as? [String: Any]).map { [$0] } ?? []
        let entries = summary + ["decisions", "actions", "open_questions"]
            .flatMap { object[$0] as? [[String: Any]] ?? [] }
        return entries.compactMap { entry in
            guard let quote = entry["text"] as? String,
                  let IDs = entry["source_ids"] as? [String] else { return "missing quote or IDs" }
            let cited = IDs.compactMap { byID[$0] }.joined(separator: " ")
            let normalizedQuote = quote.split(whereSeparator: \.isWhitespace).joined(separator: " ")
            let normalizedCited = cited.split(whereSeparator: \.isWhitespace).joined(separator: " ")
            guard normalizedCited.contains(normalizedQuote) else {
                return "quote is not verbatim within cited IDs \(IDs.joined(separator: ",")): \(quote.prefix(100))"
            }
            return nil
        }
    }
}
