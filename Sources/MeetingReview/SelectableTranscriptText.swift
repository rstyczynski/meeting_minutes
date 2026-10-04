import AppKit
import SwiftUI

/// Read-only transcript with native mouse and keyboard selection, without editing the raw text.
struct SelectableTranscriptText: NSViewRepresentable {
    let text: String
    let identifier: String
    var playbackRanges: [NSRange] = []
    let onSelection: (NSRange) -> NSRange?

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SelectableTranscriptText
        var updating = false
        var markedRanges: [NSRange] = []
        init(_ parent: SelectableTranscriptText) { self.parent = parent }
        func textViewDidChangeSelection(_ notification: Notification) {
            guard !updating, let view = notification.object as? NSTextView else { return }
            let ranges = view.selectedRanges.map(\.rangeValue)
            guard ranges.count == 1 else {
                _ = parent.onSelection(NSRange(location: NSNotFound, length: 0)); return
            }
            if let expanded = parent.onSelection(ranges[0]), expanded != ranges[0] {
                updating = true
                view.setSelectedRange(expanded)
                updating = false
            }
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> NSTextView {
        let view = NSTextView(frame: .zero)
        view.isEditable = false
        view.isSelectable = true
        view.isRichText = false
        view.drawsBackground = false
        view.font = .systemFont(ofSize: NSFont.systemFontSize)
        view.textColor = .labelColor
        view.textContainerInset = NSSize(width: 0, height: 2)
        view.textContainer?.lineFragmentPadding = 0
        view.isHorizontallyResizable = false
        view.isVerticallyResizable = true
        view.textContainer?.widthTracksTextView = true
        view.string = text
        view.delegate = context.coordinator
        view.setAccessibilityIdentifier(identifier)
        view.setAccessibilityLabel("Selectable transcript")
        return view
    }
    func updateNSView(_ view: NSTextView, context: Context) {
        context.coordinator.parent = self
        if view.string != text {
            context.coordinator.updating = true
            view.string = text
            context.coordinator.markedRanges = []
            view.setSelectedRange(NSRange(location: 0, length: 0))
            context.coordinator.updating = false
        }
        let ranges = playbackRanges.filter { $0.location >= 0 && $0.location != NSNotFound
            && $0.length > 0 && $0.location <= (text as NSString).length
            && $0.length <= (text as NSString).length - $0.location }
        guard ranges != context.coordinator.markedRanges, let manager = view.layoutManager else { return }
        manager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: NSRange(location: 0, length: (text as NSString).length))
        for range in ranges {
            manager.addTemporaryAttribute(.backgroundColor, value: NSColor.systemYellow.withAlphaComponent(0.35),
                                          forCharacterRange: range)
        }
        context.coordinator.markedRanges = ranges
        // Temporary layout attributes never alter selectedRanges or trigger the selection delegate.
        if let first = ranges.first {
            DispatchQueue.main.async { view.scrollRangeToVisible(first) }
        }
    }
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSTextView, context: Context) -> CGSize? {
        let width = proposal.width ?? 500
        guard let container = nsView.textContainer, let manager = nsView.layoutManager else { return nil }
        container.containerSize = NSSize(width: width, height: .greatestFiniteMagnitude)
        manager.ensureLayout(for: container)
        return CGSize(width: width, height: max(22, ceil(manager.usedRect(for: container).height) + 4))
    }
}
