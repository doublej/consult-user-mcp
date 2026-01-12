import AppKit
import SwiftUI

// MARK: - Window Size Observer

extension Notification.Name {
    static let dialogContentSizeChanged = Notification.Name("dialogContentSizeChanged")
}

class WindowSizeObserver: NSObject {
    private weak var window: NSWindow?
    private weak var hostingView: NSView?
    private weak var bgView: NSView?
    private let minWidth: CGFloat
    private let minHeight: CGFloat
    private let maxHeight: CGFloat
    private var notificationObserver: NSObjectProtocol?

    init(window: NSWindow, hostingView: NSView, bgView: NSView, minWidth: CGFloat, minHeight: CGFloat, maxHeight: CGFloat) {
        self.window = window
        self.hostingView = hostingView
        self.bgView = bgView
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        super.init()

        notificationObserver = NotificationCenter.default.addObserver(
            forName: .dialogContentSizeChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateWindowSize()
        }
    }

    private func updateWindowSize() {
        guard let window = window, let hostingView = hostingView, let bgView = bgView else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let fittingSize = hostingView.fittingSize
            let newWidth = max(self.minWidth, fittingSize.width) + 16
            let newHeight = min(max(fittingSize.height + 16, self.minHeight), self.maxHeight)

            let currentFrame = window.frame
            if abs(currentFrame.height - newHeight) < 1 { return }

            let newY = currentFrame.origin.y + currentFrame.height - newHeight
            let newFrame = NSRect(x: currentFrame.origin.x, y: newY, width: newWidth, height: newHeight)
            let newHostingFrame = NSRect(x: 8, y: 8, width: newWidth - 16, height: newHeight - 16)
            let newBgFrame = NSRect(x: 0, y: 0, width: newWidth, height: newHeight)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                context.allowsImplicitAnimation = true
                window.animator().setFrame(newFrame, display: true)
                hostingView.animator().frame = newHostingFrame
                bgView.animator().frame = newBgFrame
            }
        }
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - Dialog Manager

class DialogManager {
    static let shared = DialogManager()
    private var clientName = "MCP"
    private var userSettings = UserSettings.load()

    func setClientName(_ name: String) {
        clientName = name
    }

    /// Returns the effective position - user setting always overrides passed-in position
    private func effectivePosition(_ requestedPosition: String) -> String {
        return userSettings.position
    }

    private func buildTitle(_ baseTitle: String) -> String {
        "\(clientName)"
    }

    private func createWindow(width: CGFloat, height: CGFloat) -> (NSWindow, DraggableView) {
        let window = BorderlessWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.acceptsMouseMovedEvents = true

        let bgView = DraggableView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        window.contentView = bgView

        return (window, bgView)
    }

    private var sizeObserver: WindowSizeObserver?

    private func createAutoSizedWindow<Content: View>(
        content: Content,
        minWidth: CGFloat = 420,
        minHeight: CGFloat = 300,
        maxHeightRatio: CGFloat = 0.85
    ) -> (NSWindow, NSHostingView<Content>, DraggableView) {
        let hostingView = NSHostingView(rootView: content)

        let screenHeight = NSScreen.main?.visibleFrame.height ?? 800
        let maxHeight = screenHeight * maxHeightRatio

        hostingView.layout()  // Force SwiftUI layout pass before measuring
        let fittingSize = hostingView.fittingSize
        let width = max(minWidth, fittingSize.width) + 16
        let height = min(max(fittingSize.height + 16, minHeight), maxHeight)

        let (window, bgView) = createWindow(width: width, height: height)

        hostingView.frame = NSRect(x: 8, y: 8, width: width - 16, height: height - 16)
        bgView.addSubview(hostingView)

        sizeObserver = WindowSizeObserver(
            window: window,
            hostingView: hostingView,
            bgView: bgView,
            minWidth: minWidth,
            minHeight: minHeight,
            maxHeight: maxHeight
        )

        return (window, hostingView, bgView)
    }

    private func positionWindow(_ window: NSWindow, position: String) {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame

        let x: CGFloat
        switch position {
        case "left":
            x = screenFrame.minX + 40
        case "right":
            x = screenFrame.maxX - windowFrame.width - 40
        default:
            x = screenFrame.midX - windowFrame.width / 2
        }

        let y = screenFrame.maxY - windowFrame.height - 80
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Confirm Dialog (SwiftUI)

    func confirm(_ request: ConfirmRequest) -> ConfirmResponse {
        // Check if snooze is active - block dialog if so
        let snoozeCheck = UserSettings.isSnoozeActive()
        if snoozeCheck.active, let remaining = snoozeCheck.remainingSeconds {
            return ConfirmResponse(dialogType: "confirm", confirmed: false, cancelled: false, dismissed: false, answer: nil, comment: nil, snoozed: true, snoozeMinutes: nil, remainingSeconds: remaining, feedbackText: nil, instruction: "Snooze active. Wait \(remaining) seconds before re-asking.")
        }

        NSApp.setActivationPolicy(.accessory)

        var result: ConfirmResponse?

        let swiftUIDialog = SwiftUIConfirmDialog(
            title: request.title,
            bodyText: request.body,
            confirmLabel: request.confirmLabel,
            cancelLabel: request.cancelLabel,
            onConfirm: {
                result = ConfirmResponse(dialogType: "confirm", confirmed: true, cancelled: false, dismissed: false, answer: request.confirmLabel, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
                NSApp.stopModal()
            },
            onCancel: {
                result = ConfirmResponse(dialogType: "confirm", confirmed: false, cancelled: false, dismissed: false, answer: request.cancelLabel, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
                NSApp.stopModal()
            },
            onSnooze: { minutes in
                UserSettings.setSnooze(minutes: minutes)  // Save snooze state
                result = ConfirmResponse(dialogType: "confirm", confirmed: false, cancelled: false, dismissed: false, answer: nil, comment: nil, snoozed: true, snoozeMinutes: minutes, remainingSeconds: minutes * 60, feedbackText: nil, instruction: "Set a timer for \(minutes) minute\(minutes == 1 ? "" : "s") and re-ask this question when it fires.")
                NSApp.stopModal()
            },
            onFeedback: { feedback in
                result = ConfirmResponse(dialogType: "confirm", confirmed: false, cancelled: false, dismissed: false, answer: nil, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: feedback, instruction: nil)
                NSApp.stopModal()
            }
        )

        let (window, _, _) = createAutoSizedWindow(content: swiftUIDialog)

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Recalculate size after SwiftUI has fully rendered
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .dialogContentSizeChanged, object: nil)
        }

        NSApp.runModal(for: window)
        window.close()

        return result ?? ConfirmResponse(dialogType: "confirm", confirmed: false, cancelled: true, dismissed: true, answer: nil, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
    }

    // MARK: - Choose Dialog (SwiftUI)

    func choose(_ request: ChooseRequest) -> ChoiceResponse {
        // Check if snooze is active - block dialog if so
        let snoozeCheck = UserSettings.isSnoozeActive()
        if snoozeCheck.active, let remaining = snoozeCheck.remainingSeconds {
            return ChoiceResponse(dialogType: "choose", answer: nil, cancelled: false, dismissed: false, description: nil, descriptions: nil, comment: nil, snoozed: true, snoozeMinutes: nil, remainingSeconds: remaining, feedbackText: nil, instruction: "Snooze active. Wait \(remaining) seconds before re-asking.")
        }

        NSApp.setActivationPolicy(.accessory)

        var result: ChoiceResponse?

        let swiftUIDialog = SwiftUIChooseDialog(
            body: request.body,
            choices: request.choices,
            descriptions: request.descriptions,
            allowMultiple: request.allowMultiple,
            defaultSelection: request.defaultSelection,
            onComplete: { selectedIndices in
                if selectedIndices.isEmpty {
                    result = ChoiceResponse(dialogType: "choose", answer: nil, cancelled: true, dismissed: false, description: nil, descriptions: nil, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
                } else if request.allowMultiple {
                    let selected = selectedIndices.sorted().map { request.choices[$0] }
                    let descs = selectedIndices.sorted().map { request.descriptions?[safe: $0] }
                    result = ChoiceResponse(dialogType: "choose", answer: .multiple(selected), cancelled: false, dismissed: false, description: nil, descriptions: descs, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
                } else if let idx = selectedIndices.first {
                    result = ChoiceResponse(dialogType: "choose", answer: .single(request.choices[idx]), cancelled: false, dismissed: false, description: request.descriptions?[safe: idx], descriptions: nil, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
                }
                NSApp.stopModal()
            },
            onCancel: {
                result = ChoiceResponse(dialogType: "choose", answer: nil, cancelled: true, dismissed: false, description: nil, descriptions: nil, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
                NSApp.stopModal()
            },
            onSnooze: { minutes in
                UserSettings.setSnooze(minutes: minutes)  // Save snooze state
                result = ChoiceResponse(dialogType: "choose", answer: nil, cancelled: false, dismissed: false, description: nil, descriptions: nil, comment: nil, snoozed: true, snoozeMinutes: minutes, remainingSeconds: minutes * 60, feedbackText: nil, instruction: "Set a timer for \(minutes) minute\(minutes == 1 ? "" : "s") and re-ask this question when it fires.")
                NSApp.stopModal()
            },
            onFeedback: { feedback in
                result = ChoiceResponse(dialogType: "choose", answer: nil, cancelled: false, dismissed: false, description: nil, descriptions: nil, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: feedback, instruction: nil)
                NSApp.stopModal()
            }
        )

        let (window, _, _) = createAutoSizedWindow(content: swiftUIDialog)

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Recalculate size after SwiftUI has fully rendered
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .dialogContentSizeChanged, object: nil)
        }

        NSApp.runModal(for: window)
        window.close()

        return result ?? ChoiceResponse(dialogType: "choose", answer: nil, cancelled: true, dismissed: true, description: nil, descriptions: nil, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
    }

    // MARK: - Text Input Dialog (Full AppKit with Modern Design)

    func textInput(_ request: TextInputRequest) -> TextInputResponse {
        // Check if snooze is active - block dialog if so
        let snoozeCheck = UserSettings.isSnoozeActive()
        if snoozeCheck.active, let remaining = snoozeCheck.remainingSeconds {
            return TextInputResponse(dialogType: "textInput", answer: nil, cancelled: false, dismissed: false, comment: nil, snoozed: true, snoozeMinutes: nil, remainingSeconds: remaining, feedbackText: nil, instruction: "Snooze active. Wait \(remaining) seconds before re-asking.")
        }

        NSApp.setActivationPolicy(.accessory)

        var result: TextInputResponse?
        let windowWidth: CGFloat = 420

        // Calculate body height dynamically
        let bodyFont = NSFont.systemFont(ofSize: 13)
        let bodyAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont]
        let bodyMaxWidth = windowWidth - 48
        let bodySize = (request.body as NSString).boundingRect(
            with: NSSize(width: bodyMaxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: bodyAttrs
        )
        let bodyHeight = max(20, ceil(bodySize.height) + 8)

        // Calculate total window height based on content
        let topPadding: CGFloat = 32
        let iconSize: CGFloat = 56
        let iconToTitle: CGFloat = 20
        let titleHeight: CGFloat = 28
        let titleToBody: CGFloat = 12
        let bodyToInput: CGFloat = 32
        let inputHeight: CGFloat = 48
        let inputToButtons: CGFloat = 28
        let buttonHeight: CGFloat = 48
        let bottomPadding: CGFloat = 24

        let windowHeight = topPadding + iconSize + iconToTitle + titleHeight + titleToBody + bodyHeight + bodyToInput + inputHeight + inputToButtons + buttonHeight + bottomPadding

        let (window, contentView) = createWindow(width: windowWidth, height: windowHeight)

        var yPos = windowHeight - topPadding

        // Icon
        yPos -= iconSize
        let iconBg = NSView(frame: NSRect(x: (windowWidth - iconSize) / 2, y: yPos, width: iconSize, height: iconSize))
        iconBg.wantsLayer = true
        iconBg.layer?.backgroundColor = Theme.accentBlue.withAlphaComponent(0.15).cgColor
        iconBg.layer?.cornerRadius = iconSize / 2
        contentView.addSubview(iconBg)

        let iconImage = NSImageView(frame: NSRect(x: (windowWidth - 24) / 2, y: yPos + 16, width: 24, height: 24))
        iconImage.image = NSImage(systemSymbolName: request.hidden ? "lock.fill" : "text.cursor", accessibilityDescription: nil)
        iconImage.contentTintColor = Theme.accentBlue
        contentView.addSubview(iconImage)

        // Title
        yPos -= iconToTitle + titleHeight
        let titleLabel = NSTextField(labelWithString: request.title)
        titleLabel.frame = NSRect(x: 24, y: yPos, width: windowWidth - 48, height: titleHeight)
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = Theme.textPrimary
        titleLabel.alignment = .center
        contentView.addSubview(titleLabel)

        // Body (wrapping text)
        yPos -= titleToBody + bodyHeight
        let bodyLabel = NSTextField(wrappingLabelWithString: request.body)
        bodyLabel.frame = NSRect(x: 24, y: yPos, width: bodyMaxWidth, height: bodyHeight)
        bodyLabel.font = bodyFont
        bodyLabel.textColor = Theme.textSecondary
        bodyLabel.alignment = .center
        bodyLabel.maximumNumberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping
        contentView.addSubview(bodyLabel)

        // Text Field
        yPos -= bodyToInput + inputHeight
        let inputField = StyledTextField(isSecure: request.hidden, defaultValue: request.defaultValue)
        inputField.frame = NSRect(x: 28, y: yPos, width: windowWidth - 56, height: inputHeight)
        contentView.addSubview(inputField)

        // Keyboard hints
        let hintsLabel = NSTextField(labelWithString: "⏎ submit  •  Esc cancel")
        hintsLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        hintsLabel.textColor = Theme.textMuted
        hintsLabel.alignment = .center
        hintsLabel.frame = NSRect(x: 20, y: bottomPadding + buttonHeight + 8, width: windowWidth - 40, height: 16)
        contentView.addSubview(hintsLabel)

        // Buttons
        let buttonSpacing: CGFloat = 10
        let sideMargin: CGFloat = 20
        let buttonWidth = (windowWidth - sideMargin * 2 - buttonSpacing - 16) / 2

        let cancelButton = FocusableButtonView()
        cancelButton.title = "Cancel"
        cancelButton.isPrimary = false
        cancelButton.frame = NSRect(x: sideMargin + 8, y: bottomPadding, width: buttonWidth, height: buttonHeight)
        contentView.addSubview(cancelButton)

        let submitButton = FocusableButtonView()
        submitButton.title = "Submit"
        submitButton.isPrimary = true
        submitButton.showReturnHint = true
        submitButton.frame = NSRect(x: sideMargin + buttonWidth + buttonSpacing + 8, y: bottomPadding, width: buttonWidth, height: buttonHeight)
        contentView.addSubview(submitButton)

        submitButton.onClick = {
            result = TextInputResponse(dialogType: "textInput", answer: inputField.textField.stringValue, cancelled: false, dismissed: false, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
            NSApp.stopModal()
        }

        cancelButton.onClick = {
            result = TextInputResponse(dialogType: "textInput", answer: nil, cancelled: true, dismissed: false, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
            NSApp.stopModal()
        }

        // Set up key view loop for tab navigation
        inputField.textField.nextKeyView = cancelButton
        cancelButton.nextKeyView = submitButton
        submitButton.nextKeyView = inputField.textField
        window.initialFirstResponder = inputField.textField

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Focus text field with proper modal run loop scheduling
        let modes: [RunLoop.Mode] = [.default, .modalPanel]
        RunLoop.current.perform(inModes: modes) {
            window.makeFirstResponder(inputField.textField)
        }

        // Handle Enter to submit, Escape to cancel
        let keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 36 { // Enter/Return
                result = TextInputResponse(dialogType: "textInput", answer: inputField.textField.stringValue, cancelled: false, dismissed: false, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
                NSApp.stopModal()
                return nil
            } else if event.keyCode == 53 { // Escape
                result = TextInputResponse(dialogType: "textInput", answer: nil, cancelled: true, dismissed: false, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
                NSApp.stopModal()
                return nil
            }
            return event
        }

        NSApp.runModal(for: window)
        if let monitor = keyMonitor { NSEvent.removeMonitor(monitor) }
        window.close()

        return result ?? TextInputResponse(dialogType: "textInput", answer: nil, cancelled: true, dismissed: true, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
    }

    // MARK: - Notify (using osascript for bundle-free notifications)

    func notify(_ request: NotifyRequest) -> NotifyResponse {
        let title = buildTitle(request.title)
        var script = "display notification \"\(escapeForAppleScript(request.body))\" with title \"\(escapeForAppleScript(title))\""
        if request.sound {
            script += " sound name \"default\""
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let success: Bool
        do {
            try process.run()
            process.waitUntilExit()
            success = process.terminationStatus == 0
        } catch {
            success = false
        }

        return NotifyResponse(dialogType: "notify", success: success)
    }

    private func escapeForAppleScript(_ str: String) -> String {
        return str.replacingOccurrences(of: "\\", with: "\\\\")
                  .replacingOccurrences(of: "\"", with: "\\\"")
    }

    // MARK: - Multi-Question Dialog

    func questions(_ request: QuestionsRequest) -> QuestionsResponse {
        // Check if snooze is active - block dialog if so
        let snoozeCheck = UserSettings.isSnoozeActive()
        if snoozeCheck.active, let remaining = snoozeCheck.remainingSeconds {
            return QuestionsResponse(dialogType: "questions", answers: [:], cancelled: false, dismissed: false, completedCount: 0, snoozed: true, snoozeMinutes: nil, remainingSeconds: remaining, feedbackText: nil, instruction: "Snooze active. Wait \(remaining) seconds before re-asking.")
        }

        NSApp.setActivationPolicy(.accessory)

        var result: QuestionsResponse?

        func buildResponse(answers: [String: QuestionAnswer], cancelled: Bool, dismissed: Bool) -> QuestionsResponse {
            var responseAnswers: [String: StringOrStrings] = [:]
            var completedCount = 0

            for question in request.questions {
                if let answer = answers[question.id], !answer.isEmpty {
                    completedCount += 1
                    switch answer {
                    case .choices(let indices):
                        let labels = indices.sorted().map { question.options[$0].label }
                        if question.multiSelect {
                            responseAnswers[question.id] = .multiple(labels)
                        } else if let first = labels.first {
                            responseAnswers[question.id] = .single(first)
                        }
                    case .text(let str):
                        responseAnswers[question.id] = .single(str)
                    }
                }
            }

            return QuestionsResponse(dialogType: "questions", answers: responseAnswers, cancelled: cancelled, dismissed: dismissed, completedCount: completedCount, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
        }

        let onComplete: ([String: QuestionAnswer]) -> Void = { answers in
            result = buildResponse(answers: answers, cancelled: false, dismissed: false)
            NSApp.stopModal()
        }

        let onCancel: () -> Void = {
            result = QuestionsResponse(dialogType: "questions", answers: [:], cancelled: true, dismissed: false, completedCount: 0, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
            NSApp.stopModal()
        }

        let onSnooze: (Int) -> Void = { minutes in
            UserSettings.setSnooze(minutes: minutes)  // Save snooze state
            result = QuestionsResponse(dialogType: "questions", answers: [:], cancelled: false, dismissed: false, completedCount: 0, snoozed: true, snoozeMinutes: minutes, remainingSeconds: minutes * 60, feedbackText: nil, instruction: "Set a timer for \(minutes) minute\(minutes == 1 ? "" : "s") and re-ask this question when it fires.")
            NSApp.stopModal()
        }

        let onFeedback: (String) -> Void = { feedback in
            result = QuestionsResponse(dialogType: "questions", answers: [:], cancelled: false, dismissed: false, completedCount: 0, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: feedback, instruction: nil)
            NSApp.stopModal()
        }

        let dialogContent: AnyView
        switch request.mode {
        case "wizard":
            dialogContent = AnyView(SwiftUIWizardDialog(
                questions: request.questions,
                onComplete: onComplete,
                onCancel: onCancel,
                onSnooze: onSnooze,
                onFeedback: onFeedback
            ))
        default:
            dialogContent = AnyView(SwiftUIAccordionDialog(
                questions: request.questions,
                onComplete: onComplete,
                onCancel: onCancel,
                onSnooze: onSnooze,
                onFeedback: onFeedback
            ))
        }

        let (window, _, _) = createAutoSizedWindow(content: dialogContent, minWidth: 460)

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Recalculate size after SwiftUI has fully rendered
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .dialogContentSizeChanged, object: nil)
        }

        NSApp.runModal(for: window)
        window.close()

        return result ?? QuestionsResponse(dialogType: "questions", answers: [:], cancelled: true, dismissed: true, completedCount: 0, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
    }
}
