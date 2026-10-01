import Foundation
import MeetingCore

private let help = """
meeting-summarizer import <local.wav> [--transcriber fluid|whisper]
  [--settings settings.json] [--store directory]
  [--fixture-reference reference.json]

Models and external adapter executables must be staged locally. Import never
downloads models or sends a recording to a service. --fixture-reference is
only for deterministic synthetic test data.
"""

@main
struct MeetingCLI {
    static func main() {
        do { try run(Array(CommandLine.arguments.dropFirst())) }
        catch {
            FileHandle.standardError.write(Data("\(error.localizedDescription)\n".utf8))
            exit(2)
        }
    }

    static func run(_ args: [String]) throws {
        if args.isEmpty || args == ["--help"] || args == ["help"] {
            print(help)
            return
        }
        guard args.first == "import", args.count >= 2 else {
            throw MeetingError.adapterFailure("Usage: \(help)")
        }
        let media = URL(fileURLWithPath: args[1]).standardizedFileURL
        var options: [String: String] = [:]
        var index = 2
        while index < args.count {
            guard args[index].hasPrefix("--"), index + 1 < args.count else {
                throw MeetingError.adapterFailure("Invalid CLI option")
            }
            options[args[index]] = args[index + 1]
            index += 2
        }
        let valid = Set(["--transcriber", "--settings", "--store", "--fixture-reference"])
        guard options.keys.allSatisfy(valid.contains) else {
            throw MeetingError.adapterFailure("Unknown CLI option")
        }
        let settingsURL = options["--settings"].map { URL(fileURLWithPath: $0) }
        let config = try MeetingConfiguration.load(from: settingsURL)
        let backend = try config.selectedBackend(override: options["--transcriber"])
        let defaultStore = FileManager.default.urls(for: .applicationSupportDirectory,
                                                    in: .userDomainMask)[0]
            .appendingPathComponent("MeetingSummarizer/Records", isDirectory: true)
        let directory = URL(fileURLWithPath: options["--store"] ?? config.storeDirectory
                            ?? defaultStore.path, isDirectory: true)
        let transcriber: any Transcribing
        let minutes: any MinutesGenerating
        if let fixturePath = options["--fixture-reference"] {
            let reference = try JSONDecoder().decode(FixtureReference.self,
                from: Data(contentsOf: URL(fileURLWithPath: fixturePath)))
            transcriber = FixtureTranscriber(reference: reference)
            minutes = FixtureMinutesGenerator(reference: reference)
        } else if backend == .whisper {
            guard let model = config.whisperModelPath,
                  let executable = config.whisperExecutable else {
                throw MeetingError.missingModel("whisper")
            }
            transcriber = WhisperProcessTranscriber(executable: executable, modelPath: model)
            minutes = EmptyMinutesGenerator()
        } else {
            guard let model = config.fluidModelDirectory,
                  let executable = config.fluidExecutable else {
                throw MeetingError.missingModel("fluid")
            }
            transcriber = FluidProcessTranscriber(executable: executable, modelDirectory: model)
            minutes = EmptyMinutesGenerator()
        }
        let record = try MeetingImporter(store: MeetingStore(directory: directory))
            .importMedia(media, backend: backend, transcriber: transcriber, minutes: minutes)
        print(record.id.uuidString)
    }
}
