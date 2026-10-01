import Foundation

public enum TranscriptionBackend: String, Codable, Sendable {
    case fluid, whisper
}

public struct MeetingConfiguration: Codable, Sendable {
    public var transcriber: String
    public var fluidModelDirectory: String?
    public var whisperModelPath: String?
    public var fluidExecutable: String?
    public var whisperExecutable: String?
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
                storeDirectory: String? = nil) {
        self.transcriber = transcriber
        self.fluidModelDirectory = fluidModelDirectory
        self.whisperModelPath = whisperModelPath
        self.fluidExecutable = fluidExecutable
        self.whisperExecutable = whisperExecutable
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

    public static func load(from url: URL?) throws -> MeetingConfiguration {
        guard let url else { return MeetingConfiguration() }
        return try JSONDecoder().decode(MeetingConfiguration.self, from: Data(contentsOf: url))
    }
}
