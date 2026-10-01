import Foundation
import MeetingCore
import SwiftUI
import AVKit

private struct ReviewScreen: View {
    let record: MeetingRecord
    @State private var player: AVPlayer

    init(record: MeetingRecord) {
        self.record = record
        _player = State(initialValue: AVPlayer(url: URL(fileURLWithPath: record.sourcePath)))
    }

    var body: some View {
        HStack(spacing: 18) {
            List(record.segments) { segment in
                Button {
                    player.seek(to: CMTime(seconds: segment.range.startSeconds,
                                           preferredTimescale: 600))
                    player.play()
                } label: {
                    VStack(alignment: .leading) {
                        Text(record.speakerNames[segment.speakerID ?? ""]
                             ?? segment.speakerID ?? "Speaker")
                            .font(.headline)
                        Text(segment.text)
                        Text(String(format: "%.1f–%.1f s", segment.range.startSeconds,
                                    segment.range.endSeconds)).font(.caption)
                    }
                }
            }
            VStack(alignment: .leading) {
                VideoPlayer(player: player).frame(minWidth: 320, minHeight: 180)
                Text("Meeting \(record.id.uuidString)").font(.headline)
                List(record.reviewItems) { item in
                    VStack(alignment: .leading) {
                        Text(item.kind.rawValue.capitalized).font(.headline)
                        Text(item.text)
                        if let range = item.sourceRange {
                            Button("Play source") {
                                player.seek(to: CMTime(seconds: range.startSeconds,
                                                       preferredTimescale: 600))
                                player.play()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 850, minHeight: 500)
    }
}

@main
struct MeetingReviewApp: App {
    private let record: MeetingRecord?
    private let error: String?

    init() {
        let args = Array(CommandLine.arguments.dropFirst())
        if let raw = args.first, let id = UUID(uuidString: raw) {
            let defaultStore = FileManager.default.urls(for: .applicationSupportDirectory,
                                                        in: .userDomainMask)[0]
                .appendingPathComponent("MeetingSummarizer/Records", isDirectory: true)
            let storeURL: URL
            if let index = args.firstIndex(of: "--store"), index + 1 < args.count {
                storeURL = URL(fileURLWithPath: args[index + 1], isDirectory: true)
            } else {
                storeURL = defaultStore
            }
            do {
                record = try MeetingStore(directory: storeURL).load(id)
                error = nil
            } catch {
                record = nil
                self.error = error.localizedDescription
            }
        } else {
            record = nil
            error = "Pass a meeting record ID as the first argument."
        }
    }

    var body: some Scene {
        WindowGroup {
            if let record { ReviewScreen(record: record) }
            else { Text(error ?? "Unable to open meeting").padding() }
        }
    }
}
