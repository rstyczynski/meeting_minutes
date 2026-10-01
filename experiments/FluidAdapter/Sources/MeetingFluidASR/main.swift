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

private struct DiarizationOutput: Encodable {
    struct Segment: Encodable {
        let start: Double
        let end: Double
        let speaker: String
    }
    let modelRevision: String
    let segments: [Segment]
    let speakerMedianRMS: [String: Double]
    let warningThresholdRMS: Double
    let warnings: [QualityWarning]
}

private struct QualityWarning: Encodable {
    let start: Double
    let end: Double
    let speaker: String
    let reason: String
}

private func median(_ values: [Double]) -> Double {
    let sorted = values.sorted()
    guard !sorted.isEmpty else { return 0 }
    let middle = sorted.count / 2
    return sorted.count.isMultiple(of: 2)
        ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
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
            if args.first == "--download-diarizer-models", args.count == 2 {
                let root = URL(fileURLWithPath: args[1], isDirectory: true)
                let manager = OfflineDiarizerManager()
                try await manager.prepareModels(directory: root)
                print(root.path)
                return
            }
            if args.first == "--diarize" {
                guard let modelIndex = args.firstIndex(of: "--model-dir"), modelIndex + 1 < args.count,
                      let inputIndex = args.firstIndex(of: "--input"), inputIndex + 1 < args.count,
                      let outputIndex = args.firstIndex(of: "--output-json"), outputIndex + 1 < args.count else {
                    throw NSError(domain: "FluidASR", code: 2,
                                  userInfo: [NSLocalizedDescriptionKey: "Usage: meeting-fluid-asr --diarize --model-dir DIR --input FILE --output-json FILE"])
                }
                let modelDir = URL(fileURLWithPath: args[modelIndex + 1], isDirectory: true)
                let input = URL(fileURLWithPath: args[inputIndex + 1])
                let outputFile = URL(fileURLWithPath: args[outputIndex + 1])
                let models = try await OfflineDiarizerModels.load(from: modelDir)
                let manager = OfflineDiarizerManager()
                manager.initialize(models: models)
                let result = try await manager.process(input)
                let samples = try AudioConverter().resampleAudioFile(input)
                let rate = 16_000.0
                let measured = result.segments.compactMap { segment -> (String, Double, Double, Double)? in
                    let start = Double(segment.startTimeSeconds)
                    let end = Double(segment.endTimeSeconds)
                    let first = max(0, min(samples.count, Int(start * rate)))
                    let last = max(first, min(samples.count, Int(end * rate)))
                    guard last - first >= Int(rate / 2) else { return nil }
                    var squares = 0.0
                    for sample in samples[first..<last] {
                        let value = Double(sample)
                        squares += value * value
                    }
                    return (segment.speakerId, start, end,
                            (squares / Double(last - first)).squareRoot())
                }
                let grouped = Dictionary(grouping: measured, by: { $0.0 })
                let medians = grouped.mapValues { median($0.map(\.3)) }
                let threshold = median(Array(medians.values)) * 0.5
                let affected = Set(medians.compactMap { $0.value < threshold ? $0.key : nil })
                let warnings = measured.filter { affected.contains($0.0) }.map {
                    QualityWarning(start: $0.1, end: $0.2, speaker: $0.0,
                                   reason: "Low speech level relative to other detected speakers; review source audio")
                }
                let output = DiarizationOutput(
                    modelRevision: modelDir.lastPathComponent,
                    segments: result.segments.map {
                        DiarizationOutput.Segment(start: Double($0.startTimeSeconds),
                                                  end: Double($0.endTimeSeconds),
                                                  speaker: $0.speakerId)
                    },
                    speakerMedianRMS: medians,
                    warningThresholdRMS: threshold,
                    warnings: warnings)
                try JSONEncoder().encode(output).write(to: outputFile, options: .atomic)
                return
            }
            guard let modelIndex = args.firstIndex(of: "--model-dir"), modelIndex + 1 < args.count,
                  let inputIndex = args.firstIndex(of: "--input"), inputIndex + 1 < args.count,
                  let outputIndex = args.firstIndex(of: "--output-json"), outputIndex + 1 < args.count else {
                throw NSError(domain: "FluidASR", code: 2,
                              userInfo: [NSLocalizedDescriptionKey: "Usage: meeting-fluid-asr --model-dir DIR --input FILE --output-json FILE | --download-models ROOT | --download-diarizer-models ROOT | --diarize --model-dir DIR --input FILE --output-json FILE"])
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
