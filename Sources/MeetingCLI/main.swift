import Foundation
import MeetingCore

private let help = """
meeting-summarizer transcribe <local.wav> --transcriber fluid|whisper
  [--language en|pl|auto]
  [--settings settings.json] [--store directory] [--fixture-reference reference.json]
meeting-summarizer transcribe correct <record-id> <segment-id> <corrected-text>
  --audio-reviewed yes [--note explanation] [--store directory]
meeting-summarizer recognize <record-id> --diarizer fluid
  [--settings settings.json] [--store directory] [--fixture-reference reference.json]
meeting-summarizer recognize name <record-id> <speaker-id> <display-name> [--store directory]
meeting-summarizer recognize move <record-id> <segment-id> <speaker-id> [--store directory]
meeting-summarizer summarize <record-id> --summarizer mlx
  [--pipeline multi-stage|legacy] [--settings settings.json] [--store directory]
  [--fixture-reference reference.json]
meeting-summarizer inspect-cleanup <record-id> [--store directory]

Transcribe creates a transcript-only record. Recognize and summarize are
independent optional steps. --fixture-reference uses invented test data only.
Models and executables must be staged locally; runtime never downloads them.
The legacy import command remains available for compatibility.
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
        guard let command = args.first else { return }
        switch command {
        case "transcribe":
            if args.dropFirst().first == "correct" {
                try correctTranscript(Array(args.dropFirst(2)))
            } else {
                try transcribe(Array(args.dropFirst()), legacyImport: false)
            }
        case "import": try transcribe(Array(args.dropFirst()), legacyImport: true)
        case "recognize": try recognize(Array(args.dropFirst()))
        case "summarize": try summarize(Array(args.dropFirst()))
        case "inspect-cleanup": try inspectCleanup(Array(args.dropFirst()))
        default: throw MeetingError.adapterFailure("Usage: \(help)")
        }
    }

    private static func options(_ args: [String], positional: Int,
                                allowed: Set<String>) throws -> ([String], [String: String]) {
        guard args.count >= positional else { throw MeetingError.adapterFailure("Usage: \(help)") }
        let values = Array(args.prefix(positional))
        var result: [String: String] = [:]
        var index = positional
        while index < args.count {
            guard args[index].hasPrefix("--"), index + 1 < args.count,
                  allowed.contains(args[index]), result[args[index]] == nil else {
                throw MeetingError.adapterFailure("Invalid CLI option")
            }
            result[args[index]] = args[index + 1]
            index += 2
        }
        return (values, result)
    }

    private static func context(_ values: [String: String]) throws -> (MeetingConfiguration, MeetingStore) {
        let settingsURL = values["--settings"].map { URL(fileURLWithPath: $0) }
        let config = try MeetingConfiguration.load(from: settingsURL)
        let defaultStore = FileManager.default.urls(for: .applicationSupportDirectory,
                                                    in: .userDomainMask)[0]
            .appendingPathComponent("MeetingSummarizer/Records", isDirectory: true)
        let directory = URL(fileURLWithPath: values["--store"] ?? config.storeDirectory
                            ?? defaultStore.path, isDirectory: true)
        return (config, MeetingStore(directory: directory))
    }

    private static func reference(_ values: [String: String]) throws -> FixtureReference? {
        guard let path = values["--fixture-reference"] else { return nil }
        return try JSONDecoder().decode(FixtureReference.self,
            from: Data(contentsOf: URL(fileURLWithPath: path)))
    }

    private static func recordID(_ raw: String) throws -> UUID {
        guard let id = UUID(uuidString: raw) else {
            throw MeetingError.adapterFailure("Invalid record ID")
        }
        return id
    }

    private static func transcribe(_ args: [String], legacyImport: Bool) throws {
        let (parts, values) = try options(args, positional: 1,
            allowed: ["--transcriber", "--language", "--settings", "--store", "--fixture-reference"])
        let media = URL(fileURLWithPath: parts[0]).standardizedFileURL
        try MediaValidator.validate(media)
        let (config, store) = try context(values)
        let backend = try config.selectedBackend(override: values["--transcriber"])
        let language = try config.selectedLanguage(override: values["--language"])
        let fixture = try reference(values)
        let transcriber: any Transcribing
        if let fixture {
            transcriber = FixtureTranscriber(reference: fixture)
        } else if backend == .whisper {
            guard let model = config.whisperModelPath,
                  let executable = config.whisperExecutable else {
                throw MeetingError.missingModel("whisper")
            }
            try MeetingConfiguration.validateWhisperModel(model, language: language)
            transcriber = WhisperProcessTranscriber(executable: executable, modelPath: model,
                                                    language: language,
                                                    useGPU: config.whisperUseGPU ?? true)
        } else {
            guard let model = config.fluidModelDirectory,
                  let executable = config.fluidExecutable else {
                throw MeetingError.missingModel("fluid")
            }
            let version = try config.selectedFluidVersion(for: language)
            transcriber = FluidProcessTranscriber(executable: executable, modelDirectory: model,
                                                  modelVersion: version, language: language)
        }
        let minutes: any MinutesGenerating = legacyImport && fixture != nil
            ? FixtureMinutesGenerator(reference: fixture!) : EmptyMinutesGenerator()
        let record = try MeetingImporter(store: store).importMedia(
            media, backend: backend, transcriber: transcriber, minutes: minutes,
            requestedLanguage: language)
        print(record.id.uuidString)
    }

    private static func correctTranscript(_ args: [String]) throws {
        let (parts, values) = try options(args, positional: 3,
            allowed: ["--audio-reviewed", "--note", "--settings", "--store"])
        guard values["--audio-reviewed"] == "yes" else {
            throw MeetingError.adapterFailure("Use --audio-reviewed yes after listening to the source range")
        }
        let (_, store) = try context(values)
        let id = try recordID(parts[0])
        var record = try store.load(id)
        try record.correctTranscript(parts[1], to: parts[2], audioReviewed: true,
                                     note: values["--note"])
        try store.save(record)
        print(id.uuidString)
    }

    private static func recognize(_ args: [String]) throws {
        if let edit = args.first, edit == "name" || edit == "move" {
            let (parts, values) = try options(Array(args.dropFirst()), positional: 3,
                                                allowed: ["--store", "--settings"])
            let (_, store) = try context(values)
            let id = try recordID(parts[0])
            var record = try store.load(id)
            if edit == "name" {
                try record.assignSpeakerName(parts[1], to: parts[2])
            } else {
                try record.moveSegment(parts[1], to: parts[2])
            }
            try store.save(record)
            print(id.uuidString)
            return
        }
        let (parts, values) = try options(args, positional: 1,
            allowed: ["--diarizer", "--settings", "--store", "--fixture-reference"])
        guard values["--diarizer"] ?? "fluid" == "fluid" else {
            throw MeetingError.adapterFailure("Unsupported diarizer")
        }
        let id = try recordID(parts[0])
        let (config, store) = try context(values)
        let diarizer: any Diarizing
        if let fixture = try reference(values) {
            diarizer = FixtureDiarizer(reference: fixture)
        } else {
            guard let model = config.fluidDiarizerModelDirectory,
                  let executable = config.fluidDiarizerExecutable else {
                throw MeetingError.missingModel("fluid diarizer")
            }
            diarizer = FluidProcessDiarizer(executable: executable, modelDirectory: model)
        }
        _ = try MeetingRecognizer(store: store).recognize(id, diarizer: diarizer)
        print(id.uuidString)
    }

    private static func summarize(_ args: [String]) throws {
        let (parts, values) = try options(args, positional: 1,
            allowed: ["--summarizer", "--pipeline", "--settings", "--store", "--fixture-reference"])
        guard values["--summarizer"] ?? "mlx" == "mlx" else {
            throw MeetingError.adapterFailure("Unsupported summarizer")
        }
        let id = try recordID(parts[0])
        let (config, store) = try context(values)
        let existing = try store.load(id)
        let fixture = try reference(values)
        let pipeline = values["--pipeline"] ?? "multi-stage"
        guard ["multi-stage", "legacy"].contains(pipeline) else {
            throw MeetingError.adapterFailure("Unsupported minutes pipeline")
        }
        if fixture == nil && pipeline == "multi-stage" {
            guard let model = config.mlxModelDirectory,
                  let executable = config.mlxExecutable else {
                throw MeetingError.missingModel("mlx")
            }
            let generator = MLXMultiStageMinutesGenerator(executable: executable,
                modelDirectory: model, speakerNames: existing.speakerNames,
                corrections: existing.transcriptCorrections ?? [])
            _ = try MeetingSummarizer(store: store).summarize(id, generator: generator,
                modelRevision: URL(fileURLWithPath: model).lastPathComponent)
            print(id.uuidString)
            return
        }
        let generator: any MinutesGenerating
        let revision: String
        if let fixture {
            generator = FixtureSummaryGenerator(reference: fixture)
            revision = "synthetic-reference-v1"
        } else {
            guard let model = config.mlxModelDirectory,
                  let executable = config.mlxExecutable else {
                throw MeetingError.missingModel("mlx")
            }
            generator = MLXProcessMinutesGenerator(executable: executable,
                modelDirectory: model, speakerNames: existing.speakerNames)
            revision = URL(fileURLWithPath: model).lastPathComponent
        }
        _ = try MeetingSummarizer(store: store).summarize(
            id, generator: generator, modelRevision: revision, fixtureDerived: fixture != nil)
        print(id.uuidString)
    }

    private static func inspectCleanup(_ args: [String]) throws {
        let (parts, values) = try options(args, positional: 1,
                                           allowed: ["--settings", "--store"])
        let (_, store) = try context(values)
        let record = try store.load(try recordID(parts[0]))
        let cleanup = try TranscriptCleaner.prepare(record.segments,
                                                    corrections: record.transcriptCorrections ?? [])
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let json = try encoder.encode(cleanup)
        FileHandle.standardOutput.write(json)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }
}
