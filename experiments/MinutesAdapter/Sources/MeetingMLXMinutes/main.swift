import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

private struct Input: Decodable {
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
                return "\(segment.id) [\(label), \(segment.startSeconds)-\(segment.endSeconds)s]: \(segment.text)"
            }.joined(separator: "\n")
            let instructions = """
                Produce meeting minutes from only the provided transcript. Return a JSON object
                with keys summary (string), decisions (array), actions (array), and
                open_questions (array). Each decision, action, and open question must have
                text (string) and source_ids (array of exact input segment IDs).
                An action may have owner_speaker_id (canonical speaker ID, not a name) only
                if the cited text explicitly states the owner. Use supplied speaker names
                only where available. Do not invent facts, people, owners, dates, or source
                IDs. Cite at most three exact source IDs for each item. Return at most two
                decisions, two actions, and two open questions. An introduction, an agenda,
                or a proposed goal is not a decision or an action. If evidence is absent,
                return empty arrays. Keep the summary to two sentences.
                Return JSON only, without Markdown fences.
                """
            let model = try await loadModelContainer(
                from: modelDirectory, using: #huggingFaceTokenizerLoader())
            let session = ChatSession(model, instructions: instructions,
                generateParameters: .init(maxTokens: 1024, temperature: 0))
            let response = try await session.respond(to: transcript)
            let output = Output(modelRevision: modelDirectory.lastPathComponent,
                                promptRevision: "minutes-v1", response: response)
            try JSONEncoder().encode(output).write(
                to: URL(fileURLWithPath: args[2]), options: .atomic)
        } catch {
            FileHandle.standardError.write(Data("\(error.localizedDescription)\n".utf8))
            exit(2)
        }
    }
}
