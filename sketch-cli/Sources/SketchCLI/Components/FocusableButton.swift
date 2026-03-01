import AppKit
import SwiftUI

struct FocusableButton: NSViewRepresentable {
    let title: String
    let isPrimary: Bool
    let action: () -> Void

    func makeNSView(context: Context) -> FocusableButtonView {
        let view = FocusableButtonView()
        view.title = title
        view.isPrimary = isPrimary
        view.onAction = action
        return view
    }

    func updateNSView(_ nsView: FocusableButtonView, context: Context) {
        nsView.title = title
        nsView.isPrimary = isPrimary
        nsView.onAction = action
        nsView.needsDisplay = true
    }
}

class FocusableButtonView: NSView {
    var title: String = ""
    var isPrimary: Bool = false
    var onAction: (() -> Void)?

    private var isHovered = false
    private var isPressed = false
    private var trackingArea: NSTrackingArea?

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: 48)
    }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        isPressed = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        isPressed = true
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let wasPressed = isPressed
        isPressed = false
        needsDisplay = true
        if wasPressed && isHovered {
            onAction?()
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 76 { // Return / numpad Enter
            onAction?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds
        let path = NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12)

        fillColor.setFill()
        path.fill()

        if !isPrimary {
            Theme.border.setStroke()
            path.lineWidth = 1
            path.stroke()
        }

        let font = NSFont.systemFont(
            ofSize: 15,
            weight: isPrimary ? .semibold : .medium
        )
        let textColor = isPrimary ? Theme.textPrimary : Theme.textSecondary
        let displayTitle = isPrimary ? "\(title)  \u{23CE}" : title

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let size = displayTitle.size(withAttributes: attrs)
        let textRect = NSRect(
            x: (rect.width - size.width) / 2,
            y: (rect.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
        displayTitle.draw(in: textRect, withAttributes: attrs)
    }

    private var fillColor: NSColor {
        if isPrimary {
            if isPressed { return Theme.accentBlueDark }
            if isHovered { return Theme.accentBlue.blended(withFraction: 0.1, of: .white) ?? Theme.accentBlue }
            return Theme.accentBlue
        } else {
            if isPressed { return Theme.cardSelected }
            if isHovered { return Theme.cardHover }
            return Theme.cardBackground
        }
    }
}
