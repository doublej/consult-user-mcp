import AppKit
import SwiftUI
import AVFoundation

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
        NSApp.setActivationPolicy(.accessory)

        var result: ConfirmResponse?
        let windowWidth: CGFloat = 420
        let windowHeight: CGFloat = 360

        let (window, contentView) = createWindow(width: windowWidth, height: windowHeight)

        // Create SwiftUI dialog
        let swiftUIDialog = SwiftUIConfirmDialog(
            title: request.title,
            message: request.message,
            confirmLabel: request.confirmLabel,
            cancelLabel: request.cancelLabel,
            onConfirm: {
                result = ConfirmResponse(dialogType: "confirm", confirmed: true, cancelled: false, dismissed: false, answer: request.confirmLabel, comment: nil)
                NSApp.stopModal()
            },
            onCancel: {
                result = ConfirmResponse(dialogType: "confirm", confirmed: false, cancelled: false, dismissed: false, answer: request.cancelLabel, comment: nil)
                NSApp.stopModal()
            }
        )

        // Embed SwiftUI in NSHostingView
        let hostingView = NSHostingView(rootView: swiftUIDialog)
        hostingView.frame = NSRect(x: 8, y: 8, width: windowWidth - 16, height: windowHeight - 16)
        contentView.addSubview(hostingView)

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSApp.runModal(for: window)
        window.close()

        return result ?? ConfirmResponse(dialogType: "confirm", confirmed: false, cancelled: true, dismissed: true, answer: nil, comment: nil)
    }

    // MARK: - Choose Dialog (SwiftUI)

    func choose(_ request: ChooseRequest) -> ChoiceResponse {
        NSApp.setActivationPolicy(.accessory)

        var result: ChoiceResponse?
        let windowWidth: CGFloat = 420
        let windowHeight: CGFloat = 520

        let (window, contentView) = createWindow(width: windowWidth, height: windowHeight)

        // Create SwiftUI dialog
        let swiftUIDialog = SwiftUIChooseDialog(
            prompt: request.prompt,
            choices: request.choices,
            descriptions: request.descriptions,
            allowMultiple: request.allowMultiple,
            defaultSelection: request.defaultSelection,
            onComplete: { selectedIndices in
                if selectedIndices.isEmpty {
                    result = ChoiceResponse(dialogType: "choose", answer: nil, cancelled: true, dismissed: false, description: nil, descriptions: nil, comment: nil)
                } else if request.allowMultiple {
                    let selected = selectedIndices.sorted().map { request.choices[$0] }
                    let descs = selectedIndices.sorted().map { request.descriptions?[safe: $0] }
                    result = ChoiceResponse(dialogType: "choose", answer: .multiple(selected), cancelled: false, dismissed: false, description: nil, descriptions: descs, comment: nil)
                } else if let idx = selectedIndices.first {
                    result = ChoiceResponse(dialogType: "choose", answer: .single(request.choices[idx]), cancelled: false, dismissed: false, description: request.descriptions?[safe: idx], descriptions: nil, comment: nil)
                }
                NSApp.stopModal()
            },
            onCancel: {
                result = ChoiceResponse(dialogType: "choose", answer: nil, cancelled: true, dismissed: false, description: nil, descriptions: nil, comment: nil)
                NSApp.stopModal()
            }
        )

        // Embed SwiftUI in NSHostingView
        let hostingView = NSHostingView(rootView: swiftUIDialog)
        hostingView.frame = NSRect(x: 8, y: 8, width: windowWidth - 16, height: windowHeight - 16)
        contentView.addSubview(hostingView)

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSApp.runModal(for: window)
        window.close()

        return result ?? ChoiceResponse(dialogType: "choose", answer: nil, cancelled: true, dismissed: true, description: nil, descriptions: nil, comment: nil)
    }

    // MARK: - Text Input Dialog (Full AppKit with Modern Design)

    func textInput(_ request: TextInputRequest) -> TextInputResponse {
        NSApp.setActivationPolicy(.accessory)

        var result: TextInputResponse?
        let windowWidth: CGFloat = 420

        // Calculate prompt height dynamically
        let promptFont = NSFont.systemFont(ofSize: 13)
        let promptAttrs: [NSAttributedString.Key: Any] = [.font: promptFont]
        let promptMaxWidth = windowWidth - 48
        let promptSize = (request.prompt as NSString).boundingRect(
            with: NSSize(width: promptMaxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: promptAttrs
        )
        let promptHeight = max(20, ceil(promptSize.height) + 8)

        // Calculate total window height based on content
        let topPadding: CGFloat = 32
        let iconSize: CGFloat = 56
        let iconToTitle: CGFloat = 20
        let titleHeight: CGFloat = 28
        let titleToPrompt: CGFloat = 12
        let promptToInput: CGFloat = 32
        let inputHeight: CGFloat = 48
        let inputToButtons: CGFloat = 28
        let buttonHeight: CGFloat = 48
        let bottomPadding: CGFloat = 24

        let windowHeight = topPadding + iconSize + iconToTitle + titleHeight + titleToPrompt + promptHeight + promptToInput + inputHeight + inputToButtons + buttonHeight + bottomPadding

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

        // Prompt (wrapping text)
        yPos -= titleToPrompt + promptHeight
        let promptLabel = NSTextField(wrappingLabelWithString: request.prompt)
        promptLabel.frame = NSRect(x: 24, y: yPos, width: promptMaxWidth, height: promptHeight)
        promptLabel.font = promptFont
        promptLabel.textColor = Theme.textSecondary
        promptLabel.alignment = .center
        promptLabel.maximumNumberOfLines = 0
        promptLabel.lineBreakMode = .byWordWrapping
        contentView.addSubview(promptLabel)

        // Text Field
        yPos -= promptToInput + inputHeight
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

        let cancelButton = ModernButton(title: "Cancel", isPrimary: false)
        cancelButton.frame = NSRect(x: sideMargin + 8, y: bottomPadding, width: buttonWidth, height: buttonHeight)
        contentView.addSubview(cancelButton)

        let submitButton = ModernButton(title: "Submit ⏎", isPrimary: true)
        submitButton.frame = NSRect(x: sideMargin + buttonWidth + buttonSpacing + 8, y: bottomPadding, width: buttonWidth, height: buttonHeight)
        contentView.addSubview(submitButton)

        submitButton.onClick = {
            result = TextInputResponse(dialogType: "textInput", answer: inputField.textField.stringValue, cancelled: false, dismissed: false, comment: nil)
            NSApp.stopModal()
        }

        cancelButton.onClick = {
            result = TextInputResponse(dialogType: "textInput", answer: nil, cancelled: true, dismissed: false, comment: nil)
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
                result = TextInputResponse(dialogType: "textInput", answer: inputField.textField.stringValue, cancelled: false, dismissed: false, comment: nil)
                NSApp.stopModal()
                return nil
            } else if event.keyCode == 53 { // Escape
                result = TextInputResponse(dialogType: "textInput", answer: nil, cancelled: true, dismissed: false, comment: nil)
                NSApp.stopModal()
                return nil
            }
            return event
        }

        NSApp.runModal(for: window)
        if let monitor = keyMonitor { NSEvent.removeMonitor(monitor) }
        window.close()

        return result ?? TextInputResponse(dialogType: "textInput", answer: nil, cancelled: true, dismissed: true, comment: nil)
    }

    // MARK: - Notify (using osascript for bundle-free notifications)

    func notify(_ request: NotifyRequest) -> NotifyResponse {
        let title = buildTitle(request.title)
        var script = "display notification \"\(escapeForAppleScript(request.message))\" with title \"\(escapeForAppleScript(title))\""
        if let subtitle = request.subtitle {
            script += " subtitle \"\(escapeForAppleScript(subtitle))\""
        }
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

    // MARK: - Speak

    func speak(_ request: SpeakRequest) -> SpeakResponse {
        let semaphore = DispatchSemaphore(value: 0)
        let speechDelegate = SpeechCompletionDelegate { semaphore.signal() }

        let synth = AVSpeechSynthesizer()
        synth.delegate = speechDelegate

        let utterance = AVSpeechUtterance(string: request.text)
        let normalizedRate = Float(request.rate - 50) / 450.0
        utterance.rate = max(AVSpeechUtteranceMinimumSpeechRate, min(AVSpeechUtteranceMaximumSpeechRate, normalizedRate))

        if let voiceName = request.voice {
            let voices = AVSpeechSynthesisVoice.speechVoices()
            if let voice = voices.first(where: { $0.name.lowercased().contains(voiceName.lowercased()) }) {
                utterance.voice = voice
            }
        }

        synth.speak(utterance)
        semaphore.wait()

        // Keep references alive until speech completes
        _ = synth
        _ = speechDelegate

        return SpeakResponse(dialogType: "speak", success: true)
    }

    // MARK: - Multi-Question Dialog

    func questions(_ request: QuestionsRequest) -> QuestionsResponse {
        NSApp.setActivationPolicy(.accessory)

        var result: QuestionsResponse?
        let windowWidth: CGFloat = 460
        let windowHeight: CGFloat = 560

        let (window, contentView) = createWindow(width: windowWidth, height: windowHeight)

        // Convert answers from Set<Int> to response format
        func buildResponse(answers: [String: Set<Int>], cancelled: Bool, dismissed: Bool) -> QuestionsResponse {
            var responseAnswers: [String: StringOrStrings] = [:]
            var completedCount = 0

            for question in request.questions {
                if let indices = answers[question.id], !indices.isEmpty {
                    completedCount += 1
                    let labels = indices.sorted().map { question.options[$0].label }
                    if question.multiSelect {
                        responseAnswers[question.id] = .multiple(labels)
                    } else if let first = labels.first {
                        responseAnswers[question.id] = .single(first)
                    }
                }
            }

            return QuestionsResponse(dialogType: "questions", answers: responseAnswers, cancelled: cancelled, dismissed: dismissed, completedCount: completedCount)
        }

        let onComplete: ([String: Set<Int>]) -> Void = { answers in
            result = buildResponse(answers: answers, cancelled: false, dismissed: false)
            NSApp.stopModal()
        }

        let onCancel: () -> Void = {
            result = QuestionsResponse(dialogType: "questions", answers: [:], cancelled: true, dismissed: false, completedCount: 0)
            NSApp.stopModal()
        }

        // Create appropriate dialog based on mode
        let hostingView: NSHostingView<AnyView>
        switch request.mode {
        case "wizard":
            hostingView = NSHostingView(rootView: AnyView(
                SwiftUIWizardDialog(
                    questions: request.questions,
                    onComplete: onComplete,
                    onCancel: onCancel
                )
            ))
        case "accordion":
            hostingView = NSHostingView(rootView: AnyView(
                SwiftUIAccordionDialog(
                    questions: request.questions,
                    onComplete: onComplete,
                    onCancel: onCancel
                )
            ))
        default: // "questionnaire"
            hostingView = NSHostingView(rootView: AnyView(
                SwiftUIQuestionnaireDialog(
                    questions: request.questions,
                    onComplete: onComplete,
                    onCancel: onCancel
                )
            ))
        }

        hostingView.frame = NSRect(x: 8, y: 8, width: windowWidth - 16, height: windowHeight - 16)
        contentView.addSubview(hostingView)

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSApp.runModal(for: window)
        window.close()

        return result ?? QuestionsResponse(dialogType: "questions", answers: [:], cancelled: true, dismissed: true, completedCount: 0)
    }
}
