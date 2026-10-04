import AVFoundation
import Foundation
import MeetingCore

@MainActor
final class ReviewPlayback: ObservableObject {
    @Published private(set) var message = "Ready to play local audio"
    @Published private(set) var positionSeconds = 0.0
    @Published private(set) var durationSeconds = 0.0
    private let player: AVPlayer
    private var positionObserver: Any?
    private var request: Task<Void, Never>?
    private var observers: [Any] = []
    private var token = UUID()

    init(url: URL) {
        player = AVPlayer(url: url)
        positionObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self, time.seconds.isFinite else { return }
                self.positionSeconds = max(0, time.seconds)
            }
        }
        Task { [weak self] in
            guard let self, let asset = player.currentItem?.asset else { return }
            do {
                let duration = try await asset.load(.duration).seconds
                guard duration.isFinite, duration > 0 else { throw MeetingError.missingMedia }
                durationSeconds = duration
            } catch { message = "Unable to load audio duration: \(error.localizedDescription)" }
        }
    }

    func seek(to seconds: Double) {
        pause()
        guard seconds.isFinite, durationSeconds > 0 else {
            message = "Audio position is unavailable"
            return
        }
        let target = min(durationSeconds, max(0, seconds))
        let current = token
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] success in
            Task { @MainActor in
                guard let self, self.token == current else { return }
                if success {
                    self.positionSeconds = target
                    self.message = String(format: "Paused at %.2f s · press Play to continue", target)
                } else { self.message = "Unable to seek to audio position" }
            }
        }
    }

    func pause() {
        token = UUID()
        request?.cancel(); request = nil
        player.currentItem?.cancelPendingSeeks()
        player.pause()
        for observer in observers { player.removeTimeObserver(observer) }
        observers = []
        message = "Paused"
    }
    func playAll() {
        pause()
        player.play()
        message = "Playing local audio"
    }
    func play(_ source: SourceRange, label: String, context: PlaybackContext = PlaybackContext(beforeSeconds: 0, afterSeconds: 0)) {
        pause()
        let current = token
        message = "Loading source audio…"
        request = Task { [weak self] in
            guard let self else { return }
            do {
                guard let item = player.currentItem else { throw MeetingError.missingMedia }
                let duration = try await item.asset.load(.duration).seconds
                let range = try context.range(around: source, duration: duration)
                guard !Task.isCancelled, token == current else { return }
                let start = CMTime(seconds: range.startSeconds, preferredTimescale: 600)
                let ready = await withCheckedContinuation { continuation in
                    player.seek(to: start, toleranceBefore: .zero, toleranceAfter: .zero) { success in
                        continuation.resume(returning: success)
                    }
                }
                guard !Task.isCancelled, token == current else { return }
                guard ready else { throw MeetingError.adapterFailure("Unable to seek to source audio") }
                let stop = CMTime(seconds: range.endSeconds, preferredTimescale: 600)
                let finish: @Sendable () -> Void = { [weak self] in
                    Task { @MainActor in
                        guard let self, self.token == current else { return }
                        self.pause()
                        self.message = String(format: "Stopped at %.2f s", range.endSeconds)
                    }
                }
                observers.append(player.addBoundaryTimeObserver(forTimes: [NSValue(time: stop)], queue: .main, using: finish))
                // A periodic observer also handles a boundary missed by the media engine.
                observers.append(player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.05, preferredTimescale: 600), queue: .main) { time in
                    if time >= stop { finish() }
                })
                player.play()
                message = String(format: "Playing %@: %.2f–%.2f s (source %.2f–%.2f s)",
                    label, range.startSeconds, range.endSeconds, source.startSeconds, source.endSeconds)
            } catch {
                guard token == current, !Task.isCancelled else { return }
                message = "Unable to play source audio: \(error.localizedDescription)"
            }
        }
    }
}
