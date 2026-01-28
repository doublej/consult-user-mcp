import SwiftUI
import AppKit

// MARK: - Focusable Button (NSViewRepresentable)

struct FocusableButton: NSViewRepresentable {
    let title: String
    let isPrimary: Bool
    let isDestructive: Bool
    let isDisabled: Bool
    let showReturnHint: Bool
    let action: () -> Void

    init(title: String, isPrimary: Bool = false, isDestructive: Bool = false, isDisabled: Bool = false, showReturnHint: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isPrimary = isPrimary
        self.isDestructive = isDestructive
        self.isDisabled = isDisabled
        self.showReturnHint = showReturnHint
        self.action = action
    }

    func makeNSView(context: Context) -> FocusableButtonView {
        let view = FocusableButtonView()
        view.title = title
        view.isPrimary = isPrimary
        view.isDestructive = isDestructive
        view.isDisabled = isDisabled
        view.showReturnHint = showReturnHint
        view.onClick = action
        return view
    }

    func updateNSView(_ nsView: FocusableButtonView, context: Context) {
        nsView.title = title
        nsView.isPrimary = isPrimary
        nsView.isDestructive = isDestructive
        nsView.isDisabled = isDisabled
        nsView.showReturnHint = showReturnHint
        nsView.onClick = action
        nsView.needsDisplay = true
    }
}

// MARK: - Focusable Button View (AppKit)

class FocusableButtonView: NSView {
    var title: String = ""
    var isPrimary: Bool = false
    var isDestructive: Bool = false
    var isDisabled: Bool = false
    var showReturnHint: Bool = false
    var onClick: (() -> Void)?

    private var isHovered = false
    private var isPressed = false
    private var trackingArea: NSTrackingArea?

    // Cooldown state to prevent accidental activation
    private var cooldownProgress: CGFloat = 1  // 0 to 1
    private var cooldownTimer: DispatchSourceTimer?
    private var cooldownObserver: NSObjectProtocol?
    private var isCoolingDown: Bool { CooldownManager.shared.isCoolingDown }

    override var acceptsFirstResponder: Bool { !isDisabled }
    override var canBecomeKeyView: Bool { !isDisabled }
    override var mouseDownCanMoveWindow: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // System focus ring support
    override var focusRingType: NSFocusRingType {
        get { .exterior }
        set { /* ignore - always use exterior */ }
    }

    override func drawFocusRingMask() {
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 12, yRadius: 12)
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
            FocusManager.shared.registerButton(self)
            startObservingCooldown()
            syncCooldown()
        } else {
            FocusManager.shared.unregister(self)
            stopObservingCooldown()
            stopCooldownUpdates()
            cooldownProgress = 1
        }
    }

    deinit {
        FocusManager.shared.unregister(self)
        stopObservingCooldown()
        stopCooldownUpdates()
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

    private func startObservingCooldown() {
        guard cooldownObserver == nil else { return }
        cooldownObserver = NotificationCenter.default.addObserver(
            forName: .cooldownDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.syncCooldown()
        }
    }

    private func stopObservingCooldown() {
        if let observer = cooldownObserver {
            NotificationCenter.default.removeObserver(observer)
            cooldownObserver = nil
        }
    }

    private func syncCooldown() {
        if CooldownManager.shared.isCoolingDown {
            cooldownProgress = CGFloat(CooldownManager.shared.progress)
            startCooldownUpdates()
        } else {
            cooldownProgress = 1
            stopCooldownUpdates()
        }
        needsDisplay = true
    }

    private func startCooldownUpdates() {
        guard cooldownTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 1.0 / 60.0)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let progress = CooldownManager.shared.progress
            self.cooldownProgress = CGFloat(progress)
            self.needsDisplay = true
            if progress >= 1 {
                self.stopCooldownUpdates()
            }
        }
        timer.resume()
        cooldownTimer = timer
    }

    private func stopCooldownUpdates() {
        cooldownTimer?.cancel()
        cooldownTimer = nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        setupTracking()
    }

    override func mouseEntered(with event: NSEvent) {
        guard !isDisabled else { return }
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        isPressed = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        guard !isDisabled else { return }
        isPressed = true
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard !isDisabled else { return }
        guard !isCoolingDown else {
            isPressed = false
            needsDisplay = true
            return
        }
        if isPressed && isHovered {
            onClick?()
        }
        isPressed = false
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        guard !isDisabled else {
            super.keyDown(with: event)
            return
        }
        guard !isCoolingDown else { return }
        if event.keyCode == KeyCode.space || event.keyCode == KeyCode.returnKey {
            onClick?()
        } else {
            super.keyDown(with: event)
        }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: 48)
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12)

        // Background
        var bgColor: NSColor
        if isDisabled {
            bgColor = Theme.cardBackground.withAlphaComponent(0.5)
        } else if isPrimary {
            if isPressed {
                bgColor = Theme.accentBlueDark
            } else if isHovered {
                bgColor = Theme.accentBlue.blended(withFraction: 0.1, of: .white) ?? Theme.accentBlue
            } else {
                bgColor = Theme.accentBlue
            }
        } else if isDestructive {
            if isPressed {
                bgColor = Theme.accentRed.withAlphaComponent(0.4)
            } else if isHovered {
                bgColor = Theme.accentRed.withAlphaComponent(0.3)
            } else {
                bgColor = Theme.accentRed.withAlphaComponent(0.2)
            }
        } else {
            if isPressed {
                bgColor = Theme.cardSelected
            } else if isHovered {
                bgColor = Theme.cardHover
            } else {
                bgColor = Theme.cardBackground
            }
        }

        // Grey out during cooldown
        if isCoolingDown {
            bgColor = bgColor.withAlphaComponent(0.4)
        }

        bgColor.setFill()
        path.fill()

        // Border for non-primary buttons
        if !isPrimary {
            Theme.border.setStroke()
            path.lineWidth = 1
            path.stroke()
        }

        // Cooldown progress bar
        if isCoolingDown {
            let barHeight: CGFloat = 3
            let barInset: CGFloat = 8
            let barY = rect.minY + 6
            let maxWidth = rect.width - (barInset * 2)
            let barWidth = maxWidth * cooldownProgress

            let barRect = NSRect(
                x: rect.minX + barInset,
                y: barY,
                width: barWidth,
                height: barHeight
            )
            let barPath = NSBezierPath(roundedRect: barRect, xRadius: 1.5, yRadius: 1.5)
            let barColor = isPrimary ? NSColor.white.withAlphaComponent(0.7) : Theme.accentBlue.withAlphaComponent(0.6)
            barColor.setFill()
            barPath.fill()
        }

        // Text
        var textColor: NSColor
        if isDisabled {
            textColor = Theme.textMuted
        } else if isPrimary {
            textColor = .white
        } else if isDestructive {
            textColor = Theme.accentRed
        } else {
            textColor = Theme.textPrimary
        }

        // Dim text during cooldown
        if isCoolingDown {
            textColor = textColor.withAlphaComponent(0.5)
        }

        let font = NSFont.systemFont(ofSize: 15, weight: isPrimary ? .semibold : .medium)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        var displayText = title
        if showReturnHint && isPrimary && !isDisabled {
            displayText += " ⏎"
        }

        let size = (displayText as NSString).size(withAttributes: attrs)
        let textRect = NSRect(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2,
            width: size.width,
            height: size.height
        )

        (displayText as NSString).draw(in: textRect, withAttributes: attrs)
    }
}

// MARK: - Focusable Text Field (NSViewRepresentable)

struct FocusableTextField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    let onSubmit: (() -> Void)?

    init(placeholder: String = "", text: Binding<String>, onSubmit: (() -> Void)? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.onSubmit = onSubmit
    }

    func makeNSView(context: Context) -> FocusableTextFieldView {
        let view = FocusableTextFieldView()
        view.placeholder = placeholder
        view.text = text
        view.onTextChange = { newText in
            DispatchQueue.main.async {
                self.text = newText
            }
        }
        view.onSubmit = onSubmit
        return view
    }

    func updateNSView(_ nsView: FocusableTextFieldView, context: Context) {
        nsView.placeholder = placeholder
        if nsView.text != text {
            nsView.text = text
        }
        nsView.onTextChange = { newText in
            DispatchQueue.main.async {
                self.text = newText
            }
        }
        nsView.onSubmit = onSubmit
    }
}

// MARK: - Focusable Text Field View (AppKit)

class FocusableTextFieldView: NSView, NSTextFieldDelegate {
    var placeholder: String = "" {
        didSet { textField.placeholderString = placeholder }
    }
    var text: String {
        get { textField.stringValue }
        set { textField.stringValue = newValue }
    }
    var onTextChange: ((String) -> Void)?
    var onSubmit: (() -> Void)?

    private let textField = NSTextField()
    private var trackingArea: NSTrackingArea?

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // System focus ring support
    override var focusRingType: NSFocusRingType {
        get { .exterior }
        set { /* ignore */ }
    }

    override func drawFocusRingMask() {
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 10, yRadius: 10)
        path.fill()
    }

    override var focusRingMaskBounds: NSRect { bounds }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupTextField()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupTextField() {
        textField.isEditable = true
        textField.isSelectable = true
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.font = NSFont.systemFont(ofSize: 15)
        textField.textColor = Theme.textPrimary
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

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

    override func becomeFirstResponder() -> Bool {
        window?.makeFirstResponder(textField)
        needsDisplay = true
        return true
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(textField)
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: 48)
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10)

        // Background
        Theme.inputBackground.setFill()
        path.fill()

        // Border
        let isFocused = window?.firstResponder == textField || window?.firstResponder == textField.currentEditor()
        let borderColor = isFocused ? Theme.accentBlue : Theme.border
        borderColor.setStroke()
        path.lineWidth = isFocused ? 2 : 1
        path.stroke()
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidChange(_ obj: Notification) {
        onTextChange?(textField.stringValue)
        needsDisplay = true
    }

    func controlTextDidBeginEditing(_ obj: Notification) {
        needsDisplay = true
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        needsDisplay = true
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            onSubmit?()
            return true
        }
        return false
    }
}
