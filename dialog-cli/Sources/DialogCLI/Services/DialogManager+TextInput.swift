import AppKit

extension DialogManager {
    /// Parse markdown to NSAttributedString (matches SwiftUI MarkdownText patterns)
    private func parseMarkdownToAttributedString(_ input: String, font: NSFont, color: NSColor) -> NSAttributedString {
        let result = NSMutableAttributedString(string: input, attributes: [
            .font: font,
            .foregroundColor: color
        ])

        // Links: [text](url)
        if let linkRegex = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)") {
            let matches = linkRegex.matches(in: result.string, range: NSRange(location: 0, length: result.length))
            for match in matches.reversed() {
                guard match.numberOfRanges >= 3 else { continue }
                let textRange = match.range(at: 1)
                let urlRange = match.range(at: 2)
                let linkText = (result.string as NSString).substring(with: textRange)
                let urlString = (result.string as NSString).substring(with: urlRange)
                if let url = URL(string: urlString) {
                    let replacement = NSMutableAttributedString(string: linkText, attributes: [
                        .font: font,
                        .foregroundColor: Theme.accentBlue,
                        .link: url
                    ])
                    result.replaceCharacters(in: match.range, with: replacement)
                }
            }
        }

        // Bold: **text**
        if let boldRegex = try? NSRegularExpression(pattern: "\\*\\*([^*]+)\\*\\*") {
            while let match = boldRegex.firstMatch(in: result.string, range: NSRange(location: 0, length: result.length)) {
                guard match.numberOfRanges >= 2 else { break }
                let textRange = match.range(at: 1)
                let boldText = (result.string as NSString).substring(with: textRange)
                let boldFont = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
                let replacement = NSAttributedString(string: boldText, attributes: [
                    .font: boldFont,
                    .foregroundColor: color
                ])
                result.replaceCharacters(in: match.range, with: replacement)
            }
        }

        // Italic: *text* (single asterisks only)
        if let italicRegex = try? NSRegularExpression(pattern: "(?<!\\*)\\*([^*]+)\\*(?!\\*)") {
            while let match = italicRegex.firstMatch(in: result.string, range: NSRange(location: 0, length: result.length)) {
                guard match.numberOfRanges >= 2 else { break }
                let textRange = match.range(at: 1)
                let italicText = (result.string as NSString).substring(with: textRange)
                let italicFont = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
                let replacement = NSAttributedString(string: italicText, attributes: [
                    .font: italicFont,
                    .foregroundColor: color
                ])
                result.replaceCharacters(in: match.range, with: replacement)
            }
        }

        // Inline code: `code`
        if let codeRegex = try? NSRegularExpression(pattern: "`([^`]+)`") {
            while let match = codeRegex.firstMatch(in: result.string, range: NSRange(location: 0, length: result.length)) {
                guard match.numberOfRanges >= 2 else { break }
                let textRange = match.range(at: 1)
                let codeText = (result.string as NSString).substring(with: textRange)
                let monoFont = NSFont.monospacedSystemFont(ofSize: font.pointSize - 1, weight: .regular)
                let replacement = NSAttributedString(string: codeText, attributes: [
                    .font: monoFont,
                    .foregroundColor: color,
                    .backgroundColor: Theme.inputBackground
                ])
                result.replaceCharacters(in: match.range, with: replacement)
            }
        }

        return result
    }

    func textInput(_ request: TextInputRequest) -> TextInputResponse {
        let snoozeCheck = UserSettings.isSnoozeActive()
        if snoozeCheck.active, let remaining = snoozeCheck.remainingSeconds {
            return TextInputResponse(dialogType: "textInput", answer: nil, cancelled: false, dismissed: false, comment: nil, snoozed: true, snoozeMinutes: nil, remainingSeconds: remaining, feedbackText: nil, instruction: snoozeActiveInstruction(remaining: remaining))
        }

        NSApp.setActivationPolicy(.accessory)

        var result: TextInputResponse?
        let windowWidth: CGFloat = 420

        let bodyFont = NSFont.systemFont(ofSize: 13)
        let bodyMaxWidth = windowWidth - 48
        let bodyAttrString = parseMarkdownToAttributedString(request.body, font: bodyFont, color: Theme.textSecondary)
        let bodySize = bodyAttrString.boundingRect(
            with: NSSize(width: bodyMaxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        let bodyHeight = max(20, ceil(bodySize.height) + 8)

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

        // Body (with markdown support)
        yPos -= titleToBody + bodyHeight
        let bodyLabel = NSTextField(labelWithAttributedString: bodyAttrString)
        bodyLabel.frame = NSRect(x: 24, y: yPos, width: bodyMaxWidth, height: bodyHeight)
        bodyLabel.alignment = .center
        bodyLabel.maximumNumberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.allowsEditingTextAttributes = true
        bodyLabel.isSelectable = true
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

        inputField.textField.nextKeyView = cancelButton
        cancelButton.nextKeyView = submitButton
        submitButton.nextKeyView = inputField.textField
        window.initialFirstResponder = inputField.textField

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        playShowSound()

        let modes: [RunLoop.Mode] = [.default, .modalPanel]
        RunLoop.current.perform(inModes: modes) {
            window.makeFirstResponder(inputField.textField)
        }

        let keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Block action keys during cooldown
            if CooldownManager.shared.shouldBlockKey(event.keyCode) {
                return nil
            }

            if event.keyCode == KeyCode.returnKey {
                result = TextInputResponse(dialogType: "textInput", answer: inputField.textField.stringValue, cancelled: false, dismissed: false, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
                NSApp.stopModal()
                return nil
            } else if event.keyCode == KeyCode.escape {
                result = TextInputResponse(dialogType: "textInput", answer: nil, cancelled: true, dismissed: false, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
                NSApp.stopModal()
                return nil
            }
            return event
        }
        defer {
            if let monitor = keyMonitor { NSEvent.removeMonitor(monitor) }
            FocusManager.shared.reset()
            window.close()
        }

        NSApp.runModal(for: window)

        let response = result ?? TextInputResponse(dialogType: "textInput", answer: nil, cancelled: true, dismissed: true, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)

        // Record to history (skip if snoozed)
        if response.snoozed != true {
            let entry = HistoryEntry(
                id: UUID(),
                timestamp: Date(),
                clientName: getClientName(),
                dialogType: "textInput",
                questionSummary: request.body,
                answer: response.answer,
                cancelled: response.cancelled,
                snoozed: false
            )
            HistoryManager.append(entry: entry)
        }

        return response
    }
}
