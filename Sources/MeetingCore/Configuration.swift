import Foundation

public enum TranscriptionBackend: String, Codable, Sendable {
    case fluid, whisper
}

public enum TranscriptionLanguage: String, Codable, Sendable {
    case en, pl, auto
}

public enum FluidModelVersion: String, Codable, Sendable {
    case v2, v3
}

public struct MeetingConfiguration: Codable, Sendable {
    public var transcriptCleanup: TranscriptCleanupPolicy?
    public var transcriber: String
    public var fluidModelDirectory: String?
    public var fluidModelVersion: String?
    public var whisperModelPath: String?
    public var fluidExecutable: String?
    public var whisperExecutable: String?
    public var whisperUseGPU: Bool?
    public var fluidDiarizerModelDirectory: String?
    public var fluidDiarizerExecutable: String?
    public var mlxModelDirectory: String?
    public var mlxExecutable: String?
    public var storeDirectory: String?

    public init(transcriber: String = "fluid", fluidModelDirectory: String? = nil,
                whisperModelPath: String? = nil, fluidExecutable: String? = nil,
                whisperExecutable: String? = nil,
                fluidDiarizerModelDirectory: String? = nil,
                fluidDiarizerExecutable: String? = nil,
                mlxModelDirectory: String? = nil, mlxExecutable: String? = nil,
                storeDirectory: String? = nil, fluidModelVersion: String? = nil,
                whisperUseGPU: Bool? = nil, transcriptCleanup: TranscriptCleanupPolicy? = nil) {
        self.transcriptCleanup = transcriptCleanup
        self.transcriber = transcriber
        self.fluidModelDirectory = fluidModelDirectory
        self.fluidModelVersion = fluidModelVersion
        self.whisperModelPath = whisperModelPath
        self.fluidExecutable = fluidExecutable
        self.whisperExecutable = whisperExecutable
        self.whisperUseGPU = whisperUseGPU
        self.fluidDiarizerModelDirectory = fluidDiarizerModelDirectory
        self.fluidDiarizerExecutable = fluidDiarizerExecutable
        self.mlxModelDirectory = mlxModelDirectory
        self.mlxExecutable = mlxExecutable
        self.storeDirectory = storeDirectory
    }

    public func selectedBackend(override: String?) throws -> TranscriptionBackend {
        let name = override ?? transcriber
        guard let backend = TranscriptionBackend(rawValue: name) else {
            throw MeetingError.invalidBackend(name)
        }
        return backend
    }

    public func selectedLanguage(override: String?) throws -> TranscriptionLanguage {
        let name = override ?? "en"
        guard let language = TranscriptionLanguage(rawValue: name) else {
            throw MeetingError.adapterFailure("Unsupported transcription language: \(name); use en, pl, or auto")
        }
        return language
    }

    public func selectedFluidVersion(for language: TranscriptionLanguage) throws -> FluidModelVersion {
        let name = fluidModelVersion ?? "v2"
        guard let version = FluidModelVersion(rawValue: name) else {
            throw MeetingError.adapterFailure("Unsupported Fluid model version: \(name)")
        }
        guard version == .v3 || language == .en else {
            throw MeetingError.adapterFailure("Fluid Parakeet v2 is English only; configure v3 for \(language.rawValue)")
        }
        return version
    }

    public static func validateWhisperModel(_ path: String, language: TranscriptionLanguage) throws {
        let name = URL(fileURLWithPath: path).lastPathComponent.lowercased()
        if language != .en && (name.contains(".en.") || name.hasSuffix(".en")) {
            throw MeetingError.adapterFailure("Whisper .en model is English only; configure a multilingual model for \(language.rawValue)")
        }
    }

    public static func load(from url: URL?) throws -> MeetingConfiguration {
        guard let url else { return MeetingConfiguration() }
        return try JSONDecoder().decode(MeetingConfiguration.self, from: Data(contentsOf: url))
    }
}
