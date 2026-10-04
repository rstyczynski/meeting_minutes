import Foundation
import MeetingCore
import SwiftUI
import AVFoundation
import AppKit

private final class ReviewAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // A SwiftPM executable is launched from Terminal rather than a bundled app.
        // Give it a normal app presence and bring its SwiftUI window forward.
        NSApp.setActivationPolicy(.regular)
        DispatchQueue.main.async {
            NSApp.activate()
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
}

private struct ReviewScreen: View {
    let record: MeetingRecord
    private let readingView: TranscriptCleanupResult?
    private let readingError: String?
    @State private var player: AVPlayer
    @State private var playbackMessage = "Ready to play local audio"
    @State private var playbackToken = UUID()

    init(record: MeetingRecord) {
        self.record = record
        _player = State(initialValue: AVPlayer(url: URL(fileURLWithPath: record.sourcePath)))
        do {
            readingView = try TranscriptCleaner.prepare(record.segments,
                corrections: record.transcriptCorrections ?? [],
                policy: record.transcriptCleanupPolicy ?? TranscriptCleanupPolicy())
            readingError = nil
        } catch {
            readingView = nil
            readingError = error.localizedDescription
        }
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
            VStack(alignment: .leading, spacing: 8) {
                Text("Transcript").font(.title2.bold())
                Text("Readable utterances; source words and timestamps remain in the saved record.")
                    .font(.caption).foregroundStyle(.secondary)
                if let readingView {
                    let proposedIDs = Set(readingView.candidates.compactMap { candidate in
                        switch candidate.disposition {
                        case .bridge, .joinPrevious, .joinNext: candidate.segmentID
                        default: nil
                        }
                    })
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(readingView.utterances) { utterance in
                                let proposed = utterance.sourceSegmentIDs.contains {
                                    proposedIDs.contains($0)
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(record.speakerNames[utterance.speakerID ?? ""]
                                             ?? utterance.speakerID ?? "Unassigned speaker")
                                            .font(.headline)
                                        Spacer()
                                        Text(String(format: "%.1f–%.1f s",
                                                    utterance.range.startSeconds,
                                                    utterance.range.endSeconds))
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Text(utterance.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    if proposed {
                                        Text("Speaker join proposed; verify against audio")
                                            .font(.caption).foregroundStyle(.orange)
                                    }
                                    HStack {
                                        Text("\(utterance.sourceSegmentIDs.count) timed source parts")
                                            .font(.caption).foregroundStyle(.secondary)
                                        Spacer()
                                        Button("Play this utterance") {
                                            playRange(utterance.range, label: "transcript")
                                        }
                                    }
                                    DisclosureGroup("Source words and correction IDs") {
                                        ForEach(utterance.sourceSegmentIDs, id: \.self) { id in
                                            if let segment = record.segments.first(where: { $0.id == id }) {
                                                let correction = latestCorrection(for: id)
                                                HStack(alignment: .top) {
                                                    Text(id).font(.caption.monospaced())
                                                    Text(correction?.correctedText ?? segment.text)
                                                    if correction != nil {
                                                        Text("ASR: \(segment.text)")
                                                            .foregroundStyle(.secondary)
                                                    }
                                                    Spacer()
                                                    Button(String(format: "%.1f s", segment.range.startSeconds)) {
                                                        playRange(segment.range, label: id)
                                                    }
                                                }
                                                .font(.caption)
                                            }
                                        }
                                    }
                                    .font(.caption)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                } else {
                    Text("Unable to prepare readable transcript: \(readingError ?? "Unknown error")")
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                ScrollView {
                  LazyVStack(alignment: .leading) {
                   ForEach(record.reviewItems) { item in
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
                  }
                }
                if let warnings = record.qualityWarnings, !warnings.isEmpty {
                    Text("Audio to review").font(.headline)
                    ScrollView {
                     LazyVStack(alignment: .leading) {
                      ForEach(Array(warnings.enumerated()), id: \.offset) { _, warning in
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .frame(minWidth: 850, minHeight: 500)
    }
}

@main
struct MeetingReviewApp: App {
    @NSApplicationDelegateAdaptor(ReviewAppDelegate.self) private var appDelegate
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
