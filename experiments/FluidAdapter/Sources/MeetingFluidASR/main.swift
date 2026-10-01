import Foundation
import FluidAudio

private struct Output: Encodable {
    struct Segment: Encodable {
        let start: Double
        let end: Double
        let speaker: String?
        let text: String
    }
    let modelRevision: String
    let segments: [Segment]
}

@main
struct FluidASR {
    static func main() async {
        do {
            let args = Array(CommandLine.arguments.dropFirst())
            if args.first == "--download-models", args.count == 2 {
                let root = URL(fileURLWithPath: args[1], isDirectory: true)
                let repository = root.appendingPathComponent("parakeet-tdt-0.6b-v2", isDirectory: true)
                _ = try await AsrModels.download(to: repository, version: .v2)
                guard FileManager.default.fileExists(atPath: repository
                    .appendingPathComponent("parakeet_vocab.json").path) else {
                    throw NSError(domain: "FluidASR", code: 3,
                                  userInfo: [NSLocalizedDescriptionKey: "Model download did not create the expected repository directory"])
                }
                print(repository.path)
                return
            }
            guard let modelIndex = args.firstIndex(of: "--model-dir"), modelIndex + 1 < args.count,
                  let inputIndex = args.firstIndex(of: "--input"), inputIndex + 1 < args.count,
                  let outputIndex = args.firstIndex(of: "--output-json"), outputIndex + 1 < args.count else {
                throw NSError(domain: "FluidASR", code: 2,
                              userInfo: [NSLocalizedDescriptionKey: "Usage: meeting-fluid-asr --model-dir DIR --input FILE --output-json FILE | --download-models ROOT"])
            }
            let modelDir = URL(fileURLWithPath: args[modelIndex + 1], isDirectory: true)
            let input = URL(fileURLWithPath: args[inputIndex + 1])
            let outputFile = URL(fileURLWithPath: args[outputIndex + 1])
            let models = try AsrModels.loadLocal(from: modelDir, version: .v2)
            let manager = AsrManager()
            try await manager.loadModels(models)
            var decoderState = try TdtDecoderState()
            let result = try await manager.transcribe(input, decoderState: &decoderState)
            let wordTimings = buildWordTimings(from: result.tokenTimings ?? [])
            let segments: [Output.Segment]
            if wordTimings.isEmpty {
                segments = [Output.Segment(start: 0, end: max(result.duration, 0.001),
                                           speaker: nil, text: result.text)]
            } else {
                segments = wordTimings.map {
                    Output.Segment(start: $0.startTime, end: max($0.endTime, $0.startTime + 0.001),
                                   speaker: nil, text: $0.word)
                }
            }
            let output = Output(modelRevision: modelDir.lastPathComponent,
                                segments: segments)
            let bytes = try JSONEncoder().encode(output)
            try bytes.write(to: outputFile, options: .atomic)
        } catch {
            FileHandle.standardError.write(Data("\(error.localizedDescription)\n".utf8))
            exit(2)
        }
    }

}
