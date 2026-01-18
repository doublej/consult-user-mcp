import AppKit
import SwiftUI

// MARK: - Modern Styled Text Field (AppKit)

class StyledTextField: NSView {
    let textField: NSTextField
    private let isSecure: Bool
    private var isFocused = false
    private var focusAnimationProgress: CGFloat = 0.0
    private var animationDisplayLink: CVDisplayLink?
    private var focusAnimationTimer: Timer?

    override var mouseDownCanMoveWindow: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    init(isSecure: Bool, defaultValue: String) {
        self.isSecure = isSecure
        if isSecure {
            textField = NSSecureTextField()
        } else {
            textField = NSTextField()
        }
        super.init(frame: .zero)

        textField.stringValue = defaultValue
        textField.isEditable = true
        textField.isSelectable = true
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.font = NSFont.systemFont(ofSize: 15)
        textField.textColor = Theme.textPrimary
        textField.delegate = self

        addSubview(textField)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        textField.frame = bounds.insetBy(dx: 14, dy: 0)
        textField.frame.origin.y = (bounds.height - 22) / 2
        textField.frame.size.height = 22
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(textField)
    }

    private func animateFocusChange(to focused: Bool) {
        focusAnimationTimer?.invalidate()

        let targetProgress: CGFloat = focused ? 1.0 : 0.0
        let duration: TimeInterval = 0.12
        let startProgress = focusAnimationProgress
        let startTime = CACurrentMediaTime()

        focusAnimationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            let elapsed = CACurrentMediaTime() - startTime
            let t = min(elapsed / duration, 1.0)
            // Ease-out curve
            let easedT = 1.0 - pow(1.0 - t, 3)

            self.focusAnimationProgress = startProgress + (targetProgress - startProgress) * CGFloat(easedT)
            self.needsDisplay = true

            if t >= 1.0 {
                timer.invalidate()
                self.focusAnimationTimer = nil
                self.focusAnimationProgress = targetProgress
                self.needsDisplay = true
            }
        }
    }

    deinit {
        focusAnimationTimer?.invalidate()
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10)

        // Animated glow when focused
        if focusAnimationProgress > 0 {
            let glowRect = bounds.insetBy(dx: -2, dy: -2)
            let glowPath = NSBezierPath(roundedRect: glowRect, xRadius: 12, yRadius: 12)
            Theme.accentBlue.withAlphaComponent(0.3 * focusAnimationProgress).setFill()
            glowPath.fill()
        }

        Theme.inputBackground.setFill()
        path.fill()

        // Interpolate border color and width
        let unfocusedColor = Theme.border
        let focusedColor = Theme.accentBlue
        let borderColor = NSColor(
            red: unfocusedColor.redComponent + (focusedColor.redComponent - unfocusedColor.redComponent) * focusAnimationProgress,
            green: unfocusedColor.greenComponent + (focusedColor.greenComponent - unfocusedColor.greenComponent) * focusAnimationProgress,
            blue: unfocusedColor.blueComponent + (focusedColor.blueComponent - unfocusedColor.blueComponent) * focusAnimationProgress,
            alpha: 1.0
        )
        borderColor.setStroke()
        path.lineWidth = 1.0 + 1.5 * focusAnimationProgress
        path.stroke()
    }
}

extension StyledTextField: NSTextFieldDelegate {
    func controlTextDidBeginEditing(_ obj: Notification) {
        isFocused = true
        animateFocusChange(to: true)
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        isFocused = false
        animateFocusChange(to: false)
    }
}
