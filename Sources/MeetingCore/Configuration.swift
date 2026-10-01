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
    public var storeDirectory: String?

    public init(transcriber: String = "fluid", fluidModelDirectory: String? = nil,
                whisperModelPath: String? = nil, fluidExecutable: String? = nil,
                whisperExecutable: String? = nil, storeDirectory: String? = nil) {
        self.transcriber = transcriber
        self.fluidModelDirectory = fluidModelDirectory
        self.whisperModelPath = whisperModelPath
        self.fluidExecutable = fluidExecutable
        self.whisperExecutable = whisperExecutable
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
