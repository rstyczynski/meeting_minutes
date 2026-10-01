import Foundation

public struct MeetingStore: Sendable {
    public let directory: URL

    public init(directory: URL) { self.directory = directory }

    public func save(_ record: MeetingRecord) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let bytes = try JSONEncoder().encode(record)
        try bytes.write(to: fileURL(record.id), options: .atomic)
    }

    public func load(_ id: UUID) throws -> MeetingRecord {
        let url = fileURL(id)
        guard FileManager.default.fileExists(atPath: url.path) else { throw MeetingError.missingRecord }
        return try JSONDecoder().decode(MeetingRecord.self, from: Data(contentsOf: url))
    }

    private func fileURL(_ id: UUID) -> URL {
        directory.appendingPathComponent(id.uuidString).appendingPathExtension("json")
    }
}

public enum MediaValidator {
    public static func validate(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { throw MeetingError.missingMedia }
        guard url.pathExtension.lowercased() == "wav" else { throw MeetingError.unsupportedMedia }
    }
}
