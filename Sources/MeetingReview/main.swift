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
    @State private var record: MeetingRecord
    private let store: MeetingStore
    @State private var readingView: TranscriptCleanupResult?
    @State private var readingError: String?
    @StateObject private var playback: ReviewPlayback
    @State private var selectedText: TranscriptSelection?
    @State private var selectionError: String?
    @State private var editingSelection: TranscriptSelection?
    @State private var contextBefore = 2.0
    @State private var contextAfter = 2.0
    @State private var correctionText = ""
    @State private var audioReviewed = false
    @State private var correctionError: String?
    @State private var correctionNotice: String?

    init(record: MeetingRecord, store: MeetingStore) {
        _record = State(initialValue: record)
        self.store = store
        _playback = StateObject(wrappedValue: ReviewPlayback(url: URL(fileURLWithPath: record.sourcePath)))
        do {
            _readingView = State(initialValue: try record.readableTranscript())
            _readingError = State(initialValue: nil)
        } catch {
            _readingView = State(initialValue: nil)
            _readingError = State(initialValue: error.localizedDescription)
        }
    }

    private func playRange(_ range: SourceRange, label: String) {
        playback.play(range, label: label)
    }

    private func latestCorrection(for segmentID: String) -> TranscriptCorrection? {
        record.transcriptCorrections?.last { $0.segmentID == segmentID }
    }

    private func selectText(_ range: NSRange, utterance: CleanedUtterance) -> NSRange? {
        guard range.length > 0, range.location != NSNotFound else {
            if selectedText?.utteranceID == utterance.id { selectedText = nil }
            selectionError = nil
            return nil
        }
        do {
            let selection = try record.transcriptSelection(utteranceID: utterance.id, range: range)
            selectedText = selection
            selectionError = nil
            return selection.displayRange
        } catch {
            selectedText = nil
            selectionError = error.localizedDescription
            return nil
        }
    }

    private func beginCorrection(_ selection: TranscriptSelection) {
        correctionText = selection.text
        audioReviewed = false
        correctionError = nil
        editingSelection = selection
        playback.pause()
    }

    private func saveCorrection(_ selection: TranscriptSelection, restore: Bool = false) {
        do {
            let updated = try store.correctTranscript(record.id, selection: selection,
                to: correctionText, audioReviewed: audioReviewed, restore: restore)
            record = updated
            readingView = try updated.readableTranscript()
            readingError = nil
            correctionNotice = "Correction saved. Original words retained; regenerate draft minutes."
            selectedText = nil
            editingSelection = nil
        } catch {
            correctionError = error.localizedDescription
        }
    }

    private func correctionEditor(_ selection: TranscriptSelection) -> some View {
        let replacement = correctionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let utterance = readingView?.utterances.first { $0.id == selection.utteranceID }?.text ?? selection.text
        let stringRange = Range(selection.displayRange, in: utterance)
        let left = stringRange.map { String(utterance[..<$0.lowerBound].suffix(120)) } ?? ""
        let right = stringRange.map { String(utterance[$0.upperBound...].prefix(120)) } ?? ""
        return VStack(alignment: .leading, spacing: 12) {
            Text("Correct selected text").font(.title2.bold())
            Text(String(format: "Source %.2f–%.2f s · %d timed parts", selection.sourceRange.startSeconds,
                        selection.sourceRange.endSeconds, selection.sourceSegmentIDs.count)).font(.caption)
            Text("Context: \(left)⟦\(selection.text)⟧\(right)").foregroundStyle(.secondary)
            Text("Selected: \(selection.text)").font(.headline)
            ScrollView { Text("Original source range: \(selection.originalText)").font(.caption) }
                .frame(maxHeight: 80)
            if selection.isRangeCorrection {
                Text("This selection touches an earlier correction. Save changes only your selected words. Restore original resets the complete source range shown above.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Text("Audio before (s)")
                TextField("Before", value: $contextBefore, format: .number).frame(width: 60)
                    .accessibilityIdentifier("contextBefore")
                Text("after (s)")
                TextField("After", value: $contextAfter, format: .number).frame(width: 60)
                    .accessibilityIdentifier("contextAfter")
            }
            HStack {
                Button("Play selection with context") {
                    audioReviewed = false
                    playback.play(selection.sourceRange, label: "selection",
                        context: PlaybackContext(beforeSeconds: contextBefore, afterSeconds: contextAfter))
                }
                Button("Pause") { playback.pause() }
            }
            ReviewAudioTimeline(playback: playback)
            Button("Play from position") { playback.playAll() }
            Text(playback.message).font(.caption)
            TextField("Corrected words", text: $correctionText, axis: .vertical)
                .lineLimit(3...8).textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("correctionText")
            Toggle("I listened to this source audio", isOn: $audioReviewed)
                .toggleStyle(.checkbox).accessibilityIdentifier("audioReviewed")
            Text("Only the selected words change. Original source and history remain saved. Regenerate draft minutes after saving.")
                .font(.caption).foregroundStyle(.secondary)
            if let correctionError { Text(correctionError).foregroundStyle(.red) }
            HStack {
                Button("Cancel") { editingSelection = nil }.keyboardShortcut(.cancelAction)
                Button("Restore original") { saveCorrection(selection, restore: true) }
                    .disabled(!audioReviewed || !selection.isRangeCorrection)
                Spacer()
                Button("Save correction") { saveCorrection(selection) }
                    .disabled(!audioReviewed || replacement.isEmpty || replacement == selection.text)
            }
        }
        .padding(24).frame(width: 650)
        .onDisappear { playback.pause() }
    }

    var body: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Transcript").font(.title2.bold())
                Text("Select a phrase in one speaker turn, then choose Correct selection. Source words and timestamps remain saved.")
                    .font(.caption).foregroundStyle(.secondary)
                if let selectionError { Text(selectionError).font(.caption).foregroundStyle(.red) }
                if let correctionNotice { Text(correctionNotice).font(.caption).foregroundStyle(.green) }
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
                                    if let reason = utterance.boundaryReason {
                                        Text(reason).font(.caption).foregroundStyle(.secondary)
                                    }
                                    SelectableTranscriptText(text: utterance.text, identifier: "transcript-\(utterance.id)") { range in
                                        selectText(range, utterance: utterance)
                                    }
                                    if proposed {
                                        Text("Speaker join proposed; verify against audio")
                                            .font(.caption).foregroundStyle(.orange)
                                    }
                                    HStack {
                                        Text("\(utterance.sourceSegmentIDs.count) timed source parts")
                                            .font(.caption).foregroundStyle(.secondary)
                                        Spacer()
                                        Button("Correct selection") {
                                            if let selectedText { beginCorrection(selectedText) }
                                        }
                                        .disabled(selectedText?.utteranceID != utterance.id)
                                        .accessibilityIdentifier("correct-\(utterance.id)")
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
                                                        playback.play(segment.range, label: id,
                                                            context: PlaybackContext(beforeSeconds: contextBefore, afterSeconds: contextAfter))
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
                        playback.playAll()
                    }
                    Button("Pause") {
                        playback.pause()
                    }
                }
                ReviewAudioTimeline(playback: playback)
                Text(playback.message).font(.caption)
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
        .sheet(item: $editingSelection) { selection in correctionEditor(selection) }
        .onDisappear { playback.pause() }
    }
}

@main
struct MeetingReviewApp: App {
    @NSApplicationDelegateAdaptor(ReviewAppDelegate.self) private var appDelegate
    private let record: MeetingRecord?
    private let error: String?
    private let storeDirectory: URL?

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
            storeDirectory = storeURL
            do {
                record = try MeetingStore(directory: storeURL).load(id)
                error = nil
            } catch {
                record = nil
                self.error = error.localizedDescription
            }
        } else {
            record = nil
            storeDirectory = nil
            error = "Pass a meeting record ID as the first argument."
        }
    }

    var body: some Scene {
        WindowGroup {
            if let record, let storeDirectory {
                ReviewScreen(record: record, store: MeetingStore(directory: storeDirectory))
            }
            else { Text(error ?? "Unable to open meeting").padding() }
        }
    }
}
