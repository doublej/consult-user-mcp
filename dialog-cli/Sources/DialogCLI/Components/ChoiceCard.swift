import SwiftUI
import AppKit

// MARK: - Focusable Choice Card (NSViewRepresentable)

struct FocusableChoiceCard: NSViewRepresentable {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let isMultiSelect: Bool
    let onTap: () -> Void

    func makeNSView(context: Context) -> FocusableChoiceCardView {
        let view = FocusableChoiceCardView()
        view.title = title
        view.subtitle = subtitle
        view.isSelected = isSelected
        view.isMultiSelect = isMultiSelect
        view.onTap = onTap
        return view
    }

    func updateNSView(_ nsView: FocusableChoiceCardView, context: Context) {
        nsView.title = title
        nsView.subtitle = subtitle
        nsView.isSelected = isSelected
        nsView.isMultiSelect = isMultiSelect
        nsView.onTap = onTap
        nsView.needsDisplay = true
    }
}

// MARK: - Focusable Choice Card View (AppKit)

class FocusableChoiceCardView: NSView {
    var title: String = "" { didSet { invalidateCachedSizes() } }
    var subtitle: String? { didSet { invalidateCachedSizes() } }
    var isSelected: Bool = false
    var isMultiSelect: Bool = false
    var onTap: (() -> Void)?

    private var isHovered = false
    private var isPressed = false
    private var trackingArea: NSTrackingArea?
    private var lastBoundsWidth: CGFloat = 0

    // Cached size calculations
    private var cachedTitleSize: NSSize?
    private var cachedSubtitleSize: NSSize?
    private var cachedContentWidth: CGFloat = 0

    private static let titleFont = NSFont.systemFont(ofSize: 14, weight: .semibold)
    private static let subtitleFont = NSFont.systemFont(ofSize: 12, weight: .regular)

    private func invalidateCachedSizes() {
        cachedTitleSize = nil
        cachedSubtitleSize = nil
    }

    private func calculateSizes(for width: CGFloat) -> (title: NSSize, subtitle: NSSize?) {
        let contentWidth = width - 68
        if cachedContentWidth == contentWidth, let titleSize = cachedTitleSize {
            return (titleSize, cachedSubtitleSize)
        }

        cachedContentWidth = contentWidth
        let titleAttrs: [NSAttributedString.Key: Any] = [.font: Self.titleFont]
        cachedTitleSize = (title as NSString).boundingRect(
            with: NSSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            attributes: titleAttrs
        ).size

        if let sub = subtitle, !sub.isEmpty {
            let subAttrs: [NSAttributedString.Key: Any] = [.font: Self.subtitleFont]
            cachedSubtitleSize = (sub as NSString).boundingRect(
                with: NSSize(width: contentWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin],
                attributes: subAttrs
            ).size
        } else {
            cachedSubtitleSize = nil
        }

        return (cachedTitleSize!, cachedSubtitleSize)
    }

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }

    // System focus ring support
    override var focusRingType: NSFocusRingType {
        get { .exterior }
        set { }
    }

    override func drawFocusRingMask() {
        let path = NSBezierPath(roundedRect: bounds, xRadius: 10, yRadius: 10)
        path.fill()
    }

    override var focusRingMaskBounds: NSRect { bounds }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupTracking()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            FocusManager.shared.register(self)
        } else {
            FocusManager.shared.unregister(self)
        }
    }

    deinit {
        FocusManager.shared.unregister(self)
    }

    private func setupTracking() {
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        setupTracking()
    }

    override func layout() {
        super.layout()
        if lastBoundsWidth != bounds.width {
            lastBoundsWidth = bounds.width
            invalidateIntrinsicContentSize()
        }
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
        if isPressed && isHovered {
            onTap?()
        }
        isPressed = false
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == KeyCode.space {
            onTap?()
        } else {
            super.keyDown(with: event)
        }
    }

    override var intrinsicContentSize: NSSize {
        // Use a reasonable default width if bounds.width is 0
        let width = bounds.width > 0 ? bounds.width : 300
        let (titleSize, subtitleSize) = calculateSizes(for: width)
        var height = titleSize.height + 24
        if let subSize = subtitleSize {
            height += subSize.height + 4
        }
        return NSSize(width: NSView.noIntrinsicMetric, height: max(48, height))
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds
        let path = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10)

        // Background
        let bgColor: NSColor
        if isSelected {
            bgColor = Theme.accentBlue.withAlphaComponent(0.25)
        } else if isPressed {
            bgColor = Theme.cardSelected
        } else if isHovered {
            bgColor = Theme.cardHover
        } else {
            bgColor = Theme.cardBackground
        }

        bgColor.setFill()
        path.fill()

        // Border
        let borderColor = isSelected ? Theme.accentBlue : Theme.border
        borderColor.setStroke()
        path.lineWidth = isSelected ? 2 : 1
        path.stroke()

        // Content area
        let contentX: CGFloat = 16
        let indicatorSize: CGFloat = 24
        let indicatorX = rect.width - 16 - indicatorSize
        let contentWidth = indicatorX - contentX - 12

        // Use cached sizes
        let (titleSize, subtitleSize) = calculateSizes(for: rect.width)

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Self.titleFont,
            .foregroundColor: Theme.textPrimary
        ]

        var textY: CGFloat
        if let sub = subtitle, !sub.isEmpty, let subSize = subtitleSize {
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: Self.subtitleFont,
                .foregroundColor: Theme.textSecondary
            ]

            let totalHeight = titleSize.height + 4 + subSize.height
            textY = (rect.height - totalHeight) / 2

            let titleDrawRect = NSRect(x: contentX, y: rect.height - textY - titleSize.height, width: contentWidth, height: titleSize.height)
            (title as NSString).draw(in: titleDrawRect, withAttributes: titleAttrs)

            let subDrawRect = NSRect(x: contentX, y: rect.height - textY - titleSize.height - 4 - subSize.height, width: contentWidth, height: subSize.height)
            (sub as NSString).draw(in: subDrawRect, withAttributes: subtitleAttrs)
        } else {
            textY = (rect.height - titleSize.height) / 2
            let titleDrawRect = NSRect(x: contentX, y: textY, width: contentWidth, height: titleSize.height)
            (title as NSString).draw(in: titleDrawRect, withAttributes: titleAttrs)
        }

        // Draw indicator (checkbox or radio)
        let indicatorY = (rect.height - indicatorSize) / 2
        let indicatorRect = NSRect(x: indicatorX, y: indicatorY, width: indicatorSize, height: indicatorSize)

        if isMultiSelect {
            // Checkbox
            let checkPath = NSBezierPath(roundedRect: indicatorRect, xRadius: 4, yRadius: 4)
            if isSelected {
                Theme.accentBlue.setFill()
                checkPath.fill()
                // Draw checkmark
                let checkmark = NSBezierPath()
                let cx = indicatorRect.midX
                let cy = indicatorRect.midY
                checkmark.move(to: NSPoint(x: cx - 5, y: cy))
                checkmark.line(to: NSPoint(x: cx - 1, y: cy - 4))
                checkmark.line(to: NSPoint(x: cx + 5, y: cy + 4))
                NSColor.white.setStroke()
                checkmark.lineWidth = 2
                checkmark.lineCapStyle = .round
                checkmark.lineJoinStyle = .round
                checkmark.stroke()
            } else {
                Theme.border.setStroke()
                checkPath.lineWidth = 2
                checkPath.stroke()
            }
        } else {
            // Radio button
            let radioPath = NSBezierPath(ovalIn: indicatorRect)
            (isSelected ? Theme.accentBlue : Theme.border).setStroke()
            radioPath.lineWidth = 2
            radioPath.stroke()

            if isSelected {
                let innerRect = indicatorRect.insetBy(dx: 6, dy: 6)
                let innerPath = NSBezierPath(ovalIn: innerRect)
                Theme.accentBlue.setFill()
                innerPath.fill()
            }
        }
    }
}
