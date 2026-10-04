import SwiftUI

/// Both windows operate on the same recording and media clock.
struct ReviewAudioTimeline: View {
    @ObservedObject var playback: ReviewPlayback
    @State private var scrubbing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Slider(value: Binding(get: {
                min(playback.displayPositionSeconds, max(playback.durationSeconds, 0.001))
            }, set: { value in
                if scrubbing { playback.preview(to: value) }
                else { playback.seek(to: value) } // Keyboard and accessibility adjustments also seek.
            }), in: 0...max(playback.durationSeconds, 0.001)) { editing in
                if editing {
                    scrubbing = true
                    playback.beginScrubbing()
                } else {
                    scrubbing = false
                    playback.finishScrubbing()
                }
            }
            .disabled(playback.durationSeconds <= 0)
            .accessibilityLabel("Audio position")
            .accessibilityIdentifier("audioPosition")
            Text(String(format: "%.2f / %.2f s", playback.displayPositionSeconds, playback.durationSeconds))
                .font(.caption.monospacedDigit())
            Text("Drag to mark transcript text and seek. Selecting text also seeks and pauses. Play resumes.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
