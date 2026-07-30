import AppKit

// MARK: - Draggable Window Background

class DraggableView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    /// Highlight shown while an image is held over the window. Drawn here
    /// rather than in SwiftUI because this view is the drop target — the
    /// feedback and the thing accepting the drop should not be able to
    /// disagree about whether a drop is live.
    private var isReceivingDrop = false {
        didSet { if oldValue != isReceivingDrop { needsDisplay = true } }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes(AttachmentStore.acceptedTypes)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes(AttachmentStore.acceptedTypes)
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 8, dy: 8)
        let path = NSBezierPath(roundedRect: rect, xRadius: Theme.cornerRadius, yRadius: Theme.cornerRadius)
        Theme.windowBackground.setFill()
        path.fill()

        guard isReceivingDrop else { return }
        Theme.accentBlue.withAlphaComponent(0.12).setFill()
        path.fill()
        Theme.accentBlue.setStroke()
        path.lineWidth = 2
        path.stroke()
    }

    // MARK: - Dropping

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard carriesImage(sender) else { return [] }
        isReceivingDrop = true
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isReceivingDrop = false
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        isReceivingDrop = false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isReceivingDrop = false
        let board = sender.draggingPasteboard

        if let urls = board.readObjects(forClasses: [NSURL.self]) as? [URL], !urls.isEmpty {
            return AttachmentStore.shared.add(fileURLs: urls) > 0
        }
        // A drag straight out of another app — a browser image, a Preview
        // selection — arrives as bitmap data with no file behind it.
        if let data = board.data(forType: .png) {
            return AttachmentStore.shared.add(data: data, mimeType: "image/png", name: "Dropped image")
        }
        if let data = board.data(forType: .tiff), let image = NSImage(data: data) {
            return AttachmentStore.shared.add(image: image, name: "Dropped image")
        }
        return false
    }

    /// Checked on entry so a drag of something unusable never lights the
    /// window up and then refuses the drop.
    private func carriesImage(_ sender: NSDraggingInfo) -> Bool {
        let board = sender.draggingPasteboard
        if board.data(forType: .png) != nil || board.data(forType: .tiff) != nil { return true }
        guard let urls = board.readObjects(forClasses: [NSURL.self]) as? [URL] else { return false }
        return urls.contains { NSImage(contentsOf: $0) != nil }
    }
}
