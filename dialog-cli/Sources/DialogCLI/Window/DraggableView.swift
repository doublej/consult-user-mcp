import AppKit

// MARK: - Draggable Window Background

class DraggableView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 8, dy: 8)
        let path = NSBezierPath(roundedRect: rect, xRadius: Theme.cornerRadius, yRadius: Theme.cornerRadius)
        Theme.windowBackground.setFill()
        path.fill()
    }
}
