import SwiftUI

/// Both windows operate on the same recording and media clock.
struct ReviewAudioTimeline: View {
    @ObservedObject var playback: ReviewPlayback
    @State private var scrubbing = false
    @State private var target = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Slider(value: Binding(get: {
                scrubbing ? target : min(playback.positionSeconds, max(playback.durationSeconds, 0.001))
            }, set: { target = $0 }), in: 0...max(playback.durationSeconds, 0.001)) { editing in
                if editing {
                    target = playback.positionSeconds
                    scrubbing = true
                    playback.pause()
                } else {
                    scrubbing = false
                    playback.seek(to: target)
                }
            }
            .disabled(playback.durationSeconds <= 0)
            .accessibilityLabel("Audio position")
            .accessibilityIdentifier("audioPosition")
            Text(String(format: "%.2f / %.2f s", scrubbing ? target : playback.positionSeconds, playback.durationSeconds))
                .font(.caption.monospacedDigit())
            Text("Drag to seek and pause. Play continues from that position.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
