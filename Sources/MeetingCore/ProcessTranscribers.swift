import Foundation

private func runProcess(_ executable: String, _ arguments: [String]) throws -> Data {
    guard FileManager.default.isExecutableFile(atPath: executable) else {
        throw MeetingError.adapterFailure("Executable unavailable: \(executable)")
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    let output = Pipe()
    let errors = Pipe()
    process.standardOutput = output
    process.standardError = errors
    try process.run()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    let errorData = errors.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        let message = String(decoding: errorData, as: UTF8.self)
        throw MeetingError.adapterFailure(String(message.prefix(500)))
    }
    return data
}

public struct WhisperProcessTranscriber: Transcribing {
    public let executable: String
    public let modelPath: String
    public init(executable: String, modelPath: String) {
        self.executable = executable
        self.modelPath = modelPath
    }

    public func transcribe(_ media: URL) throws -> TranscriptionResult {
        guard FileManager.default.fileExists(atPath: modelPath) else {
            throw MeetingError.missingModel("whisper")
        }
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("meeting-whisper-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: base.appendingPathExtension("json")) }
        _ = try runProcess(executable, ["-m", modelPath, "-f", media.path,
                                        "-oj", "-of", base.path, "-np"])
        let bytes = try Data(contentsOf: base.appendingPathExtension("json"))
        let decoded = try JSONDecoder().decode(WhisperOutput.self, from: bytes)
        let segments = try decoded.transcription.enumerated().map { index, entry in
            TranscriptSegment(id: "segment_\(index + 1)",
                              range: try SourceRange(
                                  startSeconds: Double(entry.offsets.from) / 1000,
                                  endSeconds: Double(entry.offsets.to) / 1000),
                              speakerID: nil, text: entry.text.trimmingCharacters(in: .whitespaces))
        }
        return TranscriptionResult(segments: segments,
                                   modelRevision: URL(fileURLWithPath: modelPath).lastPathComponent,
                                   parameters: ["engine": "whisper.cpp"])
    }
}

private struct WhisperOutput: Decodable {
    struct Entry: Decodable {
        struct Offsets: Decodable { let from: Int; let to: Int }
        let offsets: Offsets
        let text: String
    }
    let transcription: [Entry]
}

public struct FluidProcessTranscriber: Transcribing {
    public let executable: String
    public let modelDirectory: String
    public init(executable: String, modelDirectory: String) {
        self.executable = executable
        self.modelDirectory = modelDirectory
    }

    public func transcribe(_ media: URL) throws -> TranscriptionResult {
        guard FileManager.default.fileExists(atPath: modelDirectory) else {
            throw MeetingError.missingModel("fluid")
        }
        let outputFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("meeting-fluid-\(UUID().uuidString)")
            .appendingPathExtension("json")
        defer { try? FileManager.default.removeItem(at: outputFile) }
        _ = try runProcess(executable, ["--model-dir", modelDirectory,
                                        "--input", media.path,
                                        "--output-json", outputFile.path])
        let bytes = try Data(contentsOf: outputFile)
        let decoded = try JSONDecoder().decode(FluidOutput.self, from: bytes)
        let segments = try decoded.segments.enumerated().map { index, entry in
            TranscriptSegment(id: "segment_\(index + 1)",
                              range: try SourceRange(startSeconds: entry.start,
                                                     endSeconds: entry.end),
                              speakerID: entry.speaker,
                              text: entry.text.trimmingCharacters(in: .whitespaces))
        }
        return TranscriptionResult(segments: segments, modelRevision: decoded.modelRevision,
                                   parameters: ["engine": "FluidAudio"])
    }
}

private struct FluidOutput: Decodable {
    struct Entry: Decodable {
        let start: Double
        let end: Double
        let speaker: String?
        let text: String
    }
    let modelRevision: String
    let segments: [Entry]
}
