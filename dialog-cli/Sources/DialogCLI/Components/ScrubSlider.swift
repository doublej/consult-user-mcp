import AppKit
import SwiftUI

// MARK: - ScrubSlider (SwiftUI wrapper)

struct ScrubSlider: NSViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let isDisabled: Bool

    func makeNSView(context: Context) -> ScrubSliderView {
        let view = ScrubSliderView()
        view.value = value
        view.range = range
        view.isDisabled = isDisabled
        view.onValueChanged = { newValue in
            DispatchQueue.main.async { value = newValue }
        }
        return view
    }

    func updateNSView(_ nsView: ScrubSliderView, context: Context) {
        nsView.range = range
        nsView.isDisabled = isDisabled
        if !nsView.isDragging { nsView.value = value }
        nsView.needsDisplay = true
    }
}

// MARK: - ScrubSliderView (NSView)

final class ScrubSliderView: NSView {
    var value: Double = 0
    var range: ClosedRange<Double> = 0...1
    var isDisabled: Bool = false
    var onValueChanged: ((Double) -> Void)?

    private(set) var isDragging = false
    private var dragStartX: CGFloat = 0
    private var dragStartY: CGFloat = 0
    private var dragStartValue: Double = 0
    private var isHoveringThumb = false

    private let trackHeight: CGFloat = 4
    private let thumbRadius: CGFloat = 7

    override var isFlipped: Bool { false }
    override var acceptsFirstResponder: Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: thumbRadius * 2 + 4)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let trackY = bounds.midY - trackHeight / 2
        let trackRect = CGRect(x: thumbRadius, y: trackY, width: trackWidth, height: trackHeight)
        let cornerRadius = trackHeight / 2

        // Track background
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.1).cgColor)
        let bgPath = CGPath(roundedRect: trackRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        ctx.addPath(bgPath)
        ctx.fillPath()

        // Filled portion
        let fraction = CGFloat(normalized)
        let fillWidth = max(0, trackWidth * fraction)
        let fillRect = CGRect(x: thumbRadius, y: trackY, width: fillWidth, height: trackHeight)
        let fillColor = isDisabled
            ? NSColor.gray.withAlphaComponent(0.3).cgColor
            : NSColor(red: 0.35, green: 0.6, blue: 1.0, alpha: 0.6).cgColor
        ctx.setFillColor(fillColor)
        let fillPath = CGPath(roundedRect: fillRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        ctx.addPath(fillPath)
        ctx.fillPath()

        // Thumb
        let thumbX = thumbRadius + trackWidth * fraction
        let thumbY = bounds.midY
        let thumbRect = CGRect(
            x: thumbX - thumbRadius,
            y: thumbY - thumbRadius,
            width: thumbRadius * 2,
            height: thumbRadius * 2
        )

        let thumbColor = isDisabled
            ? NSColor.gray.withAlphaComponent(0.5)
            : NSColor.white
        ctx.setFillColor(thumbColor.cgColor)
        ctx.fillEllipse(in: thumbRect)

        // Thumb border
        ctx.setStrokeColor(NSColor.black.withAlphaComponent(0.15).cgColor)
        ctx.setLineWidth(0.5)
        ctx.strokeEllipse(in: thumbRect)
    }

    // MARK: - Mouse handling

    override func mouseDown(with event: NSEvent) {
        guard !isDisabled else { return }
        let loc = convert(event.locationInWindow, from: nil)

        // If clicking on track (not thumb), jump to position first
        if !thumbHitTest(loc) {
            let clickedValue = valueForX(loc.x)
            value = clamp(clickedValue)
            onValueChanged?(value)
        }

        isDragging = true
        dragStartX = loc.x
        dragStartY = loc.y
        dragStartValue = value
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragging, !isDisabled else { return }
        let loc = convert(event.locationInWindow, from: nil)

        let deltaX = loc.x - dragStartX
        let verticalDistance = abs(loc.y - dragStartY)
        let sensitivity = 1.0 / (1.0 + verticalDistance / 40.0)

        let rangeSpan = range.upperBound - range.lowerBound
        guard trackWidth > 0, rangeSpan > 0 else { return }

        let newValue = dragStartValue + Double(deltaX / trackWidth) * rangeSpan * sensitivity
        value = clamp(newValue)
        onValueChanged?(value)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
        needsDisplay = true
    }

    // MARK: - Cursor

    override func resetCursorRects() {
        discardCursorRects()
        if isDisabled { return }
        addCursorRect(bounds, cursor: .openHand)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.activeInActiveApp, .mouseMoved, .mouseEnteredAndExited],
            owner: self
        ))
    }

    // MARK: - Helpers

    private var trackWidth: CGFloat {
        max(0, bounds.width - thumbRadius * 2)
    }

    private var normalized: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return (value - range.lowerBound) / span
    }

    private func valueForX(_ x: CGFloat) -> Double {
        let fraction = Double((x - thumbRadius) / trackWidth)
        let span = range.upperBound - range.lowerBound
        return range.lowerBound + fraction * span
    }

    private func clamp(_ v: Double) -> Double {
        min(max(v, range.lowerBound), range.upperBound)
    }

    private func thumbHitTest(_ point: CGPoint) -> Bool {
        let fraction = CGFloat(normalized)
        let thumbX = thumbRadius + trackWidth * fraction
        let thumbY = bounds.midY
        let dx = point.x - thumbX
        let dy = point.y - thumbY
        return dx * dx + dy * dy <= (thumbRadius + 4) * (thumbRadius + 4)
    }
}
