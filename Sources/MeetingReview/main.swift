import Foundation
import MeetingCore
import SwiftUI
import AVFoundation

private struct ReviewScreen: View {
    let record: MeetingRecord
    @State private var player: AVPlayer
    @State private var playbackMessage = "Ready to play local audio"
    @State private var playbackToken = UUID()

    init(record: MeetingRecord) {
        self.record = record
        _player = State(initialValue: AVPlayer(url: URL(fileURLWithPath: record.sourcePath)))
    }

    private func playRange(_ range: SourceRange, label: String) {
        let token = UUID()
        playbackToken = token
        player.seek(to: CMTime(seconds: range.startSeconds, preferredTimescale: 600))
        player.play()
        playbackMessage = String(format: "Playing %@ from %.1f s", label,
                                 range.startSeconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + range.endSeconds - range.startSeconds) {
            guard playbackToken == token else { return }
            player.pause()
            playbackMessage = String(format: "Stopped at %.1f s", range.endSeconds)
        }
    }

    private func latestCorrection(for segmentID: String) -> TranscriptCorrection? {
        record.transcriptCorrections?.last { $0.segmentID == segmentID }
    }

    var body: some View {
        HStack(spacing: 18) {
            List(record.segments) { segment in
                Button {
                    playRange(segment.range, label: "transcript")
                } label: {
                    VStack(alignment: .leading) {
                        let correction = latestCorrection(for: segment.id)
                        Text(record.speakerNames[segment.speakerID ?? ""]
                             ?? segment.speakerID ?? "Speaker")
                            .font(.headline)
                        Text(correction?.correctedText ?? segment.text)
                        if let correction {
                            Text("ASR original: \(correction.originalText)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(segment.id).font(.caption).foregroundStyle(.secondary)
                        Text(String(format: "%.1f–%.1f s", segment.range.startSeconds,
                                    segment.range.endSeconds)).font(.caption)
                    }
                }
            }
            VStack(alignment: .leading) {
                Text(URL(fileURLWithPath: record.sourcePath).lastPathComponent)
                    .font(.subheadline)
                HStack {
                    Button("Play") {
                        playbackToken = UUID()
                        player.play()
                        playbackMessage = "Playing local audio"
                    }
                    Button("Pause") {
                        playbackToken = UUID()
                        player.pause()
                        playbackMessage = "Paused"
                    }
                }
                Text(playbackMessage).font(.caption)
                Text("Meeting \(record.id.uuidString)").font(.headline)
                List(record.reviewItems) { item in
                    VStack(alignment: .leading) {
                        Text(item.kind.rawValue.capitalized).font(.headline)
                        if let topicID = item.topicID,
                           let topic = record.topics?.first(where: { $0.id == topicID }) {
                            Text(topic.title).font(.subheadline)
                        }
                        Text(item.text)
                        if let owner = item.ownerSpeakerID {
                            Text("Owner: \(record.speakerNames[owner] ?? owner)")
                                .font(.subheadline)
                        }
                        if item.ownerMissing == true { Text("Owner needs review").font(.caption) }
                        if let dueDate = item.dueDate { Text("Due: \(dueDate)").font(.caption) }
                        else if item.dueDateMissing == true {
                            Text("Due date needs review").font(.caption)
                        }
                        if let range = item.sourceRange {
                            Button("Play source") {
                                playRange(range, label: "source")
                            }
                        }
                    }
                }
                if let warnings = record.qualityWarnings, !warnings.isEmpty {
                    Text("Audio to review").font(.headline)
                    List(Array(warnings.enumerated()), id: \.offset) { _, warning in
                        VStack(alignment: .leading) {
                            Text(warning.speakerID.flatMap { record.speakerNames[$0] }
                                 ?? warning.speakerID ?? "Uncertain speaker")
                                .font(.subheadline)
                            Text(warning.reason)
                            Button(String(format: "Play %.1f–%.1f s",
                                          warning.range.startSeconds,
                                          warning.range.endSeconds)) {
                                playRange(warning.range, label: "warning")
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
