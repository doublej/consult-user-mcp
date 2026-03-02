import AppKit

class BorderlessWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    var onUndoRequested: (() -> Void)?
    var onRedoRequested: (() -> Void)?
    var onAcceptRequested: (() -> Void)?

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        self.autorecalculatesKeyViewLoop = true
    }

    override func keyDown(with event: NSEvent) {
        let cmdPressed = event.modifierFlags.contains(.command)
        let shiftPressed = event.modifierFlags.contains(.shift)

        if event.keyCode == 53 { // ESC
            NSApp.stopModal(withCode: .cancel)
        } else if event.keyCode == 36 || event.keyCode == 76 { // Return / numpad Enter
            onAcceptRequested?()
        } else if cmdPressed && shiftPressed && event.charactersIgnoringModifiers == "z" {
            onRedoRequested?()
        } else if cmdPressed && event.charactersIgnoringModifiers == "z" {
            onUndoRequested?()
        } else {
            super.keyDown(with: event)
        }
    }
}

class DraggableView: NSView {
    override var mouseDownCanMoveWindow: Bool { false }

    private let edgeMargin: CGFloat = 8

    struct Edge: OptionSet {
        let rawValue: Int
        static let left   = Edge(rawValue: 1 << 0)
        static let right  = Edge(rawValue: 1 << 1)
        static let top    = Edge(rawValue: 1 << 2)
        static let bottom = Edge(rawValue: 1 << 3)
    }

    // Claim mouse events in the edge zone so NSHostingView doesn't swallow them
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard bounds.contains(point) else { return nil }
        if !hitEdge(at: point).isEmpty { return self }
        return super.hitTest(point)
    }

    // Window-managed cursor rects — reliable even with SwiftUI subviews
    override func resetCursorRects() {
        let m = edgeMargin
        let w = bounds.width
        let h = bounds.height
        // Edges
        addCursorRect(NSRect(x: 0, y: m, width: m, height: h - 2 * m), cursor: .resizeLeftRight)
        addCursorRect(NSRect(x: w - m, y: m, width: m, height: h - 2 * m), cursor: .resizeLeftRight)
        addCursorRect(NSRect(x: m, y: 0, width: w - 2 * m, height: m), cursor: .resizeUpDown)
        addCursorRect(NSRect(x: m, y: h - m, width: w - 2 * m, height: m), cursor: .resizeUpDown)
        // Corners
        addCursorRect(NSRect(x: 0, y: 0, width: m, height: m), cursor: .crosshair)
        addCursorRect(NSRect(x: w - m, y: 0, width: m, height: m), cursor: .crosshair)
        addCursorRect(NSRect(x: 0, y: h - m, width: m, height: m), cursor: .crosshair)
        addCursorRect(NSRect(x: w - m, y: h - m, width: m, height: m), cursor: .crosshair)
    }

    private func hitEdge(at point: NSPoint) -> Edge {
        var edge = Edge()
        if point.x < edgeMargin { edge.insert(.left) }
        if point.x > bounds.width - edgeMargin { edge.insert(.right) }
        if point.y < edgeMargin { edge.insert(.bottom) }
        if point.y > bounds.height - edgeMargin { edge.insert(.top) }
        return edge
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let edge = hitEdge(at: point)
        guard !edge.isEmpty, let window else { return super.mouseDown(with: event) }

        let startMouse = NSEvent.mouseLocation
        let startFrame = window.frame
        let minSize = window.minSize

        while true {
            guard let next = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) else { break }
            if next.type == .leftMouseUp { break }

            let mouse = NSEvent.mouseLocation
            let dx = mouse.x - startMouse.x
            let dy = mouse.y - startMouse.y
            var f = startFrame

            if edge.contains(.right) { f.size.width = max(minSize.width, startFrame.width + dx) }
            if edge.contains(.left) {
                let w = max(minSize.width, startFrame.width - dx)
                f.origin.x = startFrame.maxX - w; f.size.width = w
            }
            if edge.contains(.top) { f.size.height = max(minSize.height, startFrame.height + dy) }
            if edge.contains(.bottom) {
                let h = max(minSize.height, startFrame.height - dy)
                f.origin.y = startFrame.maxY - h; f.size.height = h
            }

            window.setFrame(f, display: true)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 8, dy: 8)
        let path = NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12)
        Theme.windowBackground.setFill()
        path.fill()
    }
}
