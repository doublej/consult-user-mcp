import SwiftUI
import AppKit

// MARK: - Project Badge

struct ProjectBadge: View {
    let projectName: String
    let projectPath: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "folder.fill")
                .font(.system(size: 9))
            Text(projectName)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .fixedSize(horizontal: true, vertical: false)
        .foregroundColor(Theme.Colors.textMuted)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Theme.Colors.cardBackground)
                .overlay(
                    Capsule()
                        .strokeBorder(Theme.Colors.border.opacity(0.5), lineWidth: 1)
                )
        )
        .help(projectPath)
    }
}

// MARK: - Markdown Text

struct MarkdownText: View {
    let text: String
    let font: Font
    let color: Color

    init(_ text: String, font: Font = .system(size: 13), color: Color = Theme.Colors.textSecondary) {
        self.text = text
        self.font = font
        self.color = color
    }

    var body: some View {
        Text(parseMarkdown(text))
            .font(font)
            .foregroundColor(color)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .tint(Theme.Colors.accentBlue)
    }

    private func parseMarkdown(_ input: String) -> AttributedString {
        var result = AttributedString(input)
        let str = String(result.characters)

        // Links: [text](url) - process first to avoid conflicts
        if let linkRegex = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)") {
            let matches = linkRegex.matches(in: str, range: NSRange(str.startIndex..., in: str))
            for match in matches.reversed() {
                guard let fullRange = Range(match.range, in: str),
                      let textRange = Range(match.range(at: 1), in: str),
                      let urlRange = Range(match.range(at: 2), in: str) else { continue }
                let linkText = String(str[textRange])
                let urlString = String(str[urlRange])
                if let attrRange = result.range(of: String(str[fullRange])),
                   let url = URL(string: urlString) {
                    var replacement = AttributedString(linkText)
                    replacement.link = url
                    replacement.foregroundColor = Theme.Colors.accentBlue
                    result.replaceSubrange(attrRange, with: replacement)
                }
            }
        }

        // Bold: **text**
        if let boldRegex = try? NSRegularExpression(pattern: "\\*\\*([^*]+)\\*\\*") {
            var currentStr = String(result.characters)
            var matches = boldRegex.matches(in: currentStr, range: NSRange(currentStr.startIndex..., in: currentStr))
            while !matches.isEmpty {
                let match = matches[0]
                guard let fullRange = Range(match.range, in: currentStr),
                      let textRange = Range(match.range(at: 1), in: currentStr) else { break }
                let boldText = String(currentStr[textRange])
                if let attrRange = result.range(of: String(currentStr[fullRange])) {
                    var replacement = AttributedString(boldText)
                    replacement.font = font.bold()
                    result.replaceSubrange(attrRange, with: replacement)
                }
                currentStr = String(result.characters)
                matches = boldRegex.matches(in: currentStr, range: NSRange(currentStr.startIndex..., in: currentStr))
            }
        }

        // Italic: *text* (single asterisks only)
        if let italicRegex = try? NSRegularExpression(pattern: "(?<!\\*)\\*([^*]+)\\*(?!\\*)") {
            var currentStr = String(result.characters)
            var matches = italicRegex.matches(in: currentStr, range: NSRange(currentStr.startIndex..., in: currentStr))
            while !matches.isEmpty {
                let match = matches[0]
                guard let fullRange = Range(match.range, in: currentStr),
                      let textRange = Range(match.range(at: 1), in: currentStr) else { break }
                let italicText = String(currentStr[textRange])
                if let attrRange = result.range(of: String(currentStr[fullRange])) {
                    var replacement = AttributedString(italicText)
                    replacement.font = font.italic()
                    result.replaceSubrange(attrRange, with: replacement)
                }
                currentStr = String(result.characters)
                matches = italicRegex.matches(in: currentStr, range: NSRange(currentStr.startIndex..., in: currentStr))
            }
        }

        // Inline code: `code` - use monospace font
        if let codeRegex = try? NSRegularExpression(pattern: "`([^`]+)`") {
            var currentStr = String(result.characters)
            var matches = codeRegex.matches(in: currentStr, range: NSRange(currentStr.startIndex..., in: currentStr))
            while !matches.isEmpty {
                let match = matches[0]
                guard let fullRange = Range(match.range, in: currentStr),
                      let textRange = Range(match.range(at: 1), in: currentStr) else { break }
                let codeText = String(currentStr[textRange])
                if let attrRange = result.range(of: String(currentStr[fullRange])) {
                    var replacement = AttributedString(codeText)
                    replacement.font = .system(size: 12, design: .monospaced)
                    replacement.backgroundColor = Theme.Colors.inputBackground
                    result.replaceSubrange(attrRange, with: replacement)
                }
                currentStr = String(result.characters)
                matches = codeRegex.matches(in: currentStr, range: NSRange(currentStr.startIndex..., in: currentStr))
            }
        }

        return result
    }
}

// MARK: - Dialog Header (Composable)

struct DialogHeader: View {
    let icon: String
    let iconColor: Color
    let title: String
    let bodyText: String?

    init(icon: String, title: String, body: String? = nil, iconColor: Color = Theme.Colors.accentBlue) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.bodyText = body
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            .padding(.top, 28)
            .padding(.bottom, 16)

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .frame(width: 372, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)

            if let text = bodyText {
                MarkdownText(text)
                    .frame(width: 372, alignment: .center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Dialog Footer (Composable)

struct DialogFooter: View {
    let hints: [KeyboardHint]
    let buttons: [DialogButton]

    struct DialogButton: Identifiable {
        let id = UUID()
        let title: String
        let isPrimary: Bool
        let isDestructive: Bool
        let isDisabled: Bool
        let showReturnHint: Bool
        let action: () -> Void

        init(_ title: String, isPrimary: Bool = false, isDestructive: Bool = false, isDisabled: Bool = false, showReturnHint: Bool = false, action: @escaping () -> Void) {
            self.title = title
            self.isPrimary = isPrimary
            self.isDestructive = isDestructive
            self.isDisabled = isDisabled
            self.showReturnHint = showReturnHint
            self.action = action
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            KeyboardHintsView(hints: hints)
            HStack(spacing: 10) {
                ForEach(buttons) { button in
                    FocusableButton(
                        title: button.title,
                        isPrimary: button.isPrimary,
                        isDestructive: button.isDestructive,
                        isDisabled: button.isDisabled,
                        showReturnHint: button.showReturnHint,
                        action: button.action
                    )
                    .frame(height: 48)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Dialog Container (Composable)

struct DialogContainer<Content: View>: View {
    let onEscape: (() -> Void)?
    let keyHandler: ((UInt16, NSEvent.ModifierFlags) -> Bool)?
    let currentDialogType: String
    let onAskDifferently: ((String) -> Void)?
    let contentBuilder: (Binding<DialogToolbar.ToolbarTool?>) -> Content

    @State private var keyboardMonitor: KeyboardNavigationMonitor?
    @State private var expandedTool: DialogToolbar.ToolbarTool?

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private var projectName: String? {
        DialogManager.shared.getProjectName()
    }

    private var projectPath: String? {
        DialogManager.shared.getProjectPath()
    }

    init(
        onEscape: (() -> Void)? = nil,
        keyHandler: ((UInt16, NSEvent.ModifierFlags) -> Bool)? = nil,
        currentDialogType: String = "",
        onAskDifferently: ((String) -> Void)? = nil,
        @ViewBuilder content: @escaping (Binding<DialogToolbar.ToolbarTool?>) -> Content
    ) {
        self.onEscape = onEscape
        self.keyHandler = keyHandler
        self.currentDialogType = currentDialogType
        self.onAskDifferently = onAskDifferently
        self.contentBuilder = content
    }

    var body: some View {
        VStack(spacing: 0) {
            if let name = projectName, let path = projectPath {
                HStack {
                    Spacer(minLength: 0)
                    ProjectBadge(projectName: name, projectPath: path)
                }
                .padding(.leading, 12)
                .padding(.top, 12)
                .padding(.trailing, 12)
            }

            contentBuilder($expandedTool)
        }
        .background(Color.clear)
        .onAppear {
            FocusManager.shared.reset()
            setupKeyboardNavigation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                FocusManager.shared.focusFirst()
            }
        }
        .onDisappear {
            keyboardMonitor = nil
            FocusManager.shared.reset()
        }
    }

    private func toggleTool(_ tool: DialogToolbar.ToolbarTool) {
        if reduceMotion {
            expandedTool = expandedTool == tool ? nil : tool
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                expandedTool = expandedTool == tool ? nil : tool
            }
        }
    }

    private func setupKeyboardNavigation() {
        keyboardMonitor = KeyboardNavigationMonitor { keyCode, modifiers in
            // Universal cooldown check — blocks rapid keypresses for all keys
            if CooldownManager.shared.shouldBlockKey(keyCode) {
                return true
            }
            if keyCode == KeyCode.escape && expandedTool != nil {
                toggleTool(expandedTool!)
                return true
            }
            // Skip character hotkeys when a text field is being edited
            let isEditingText = NSApp.keyWindow?.firstResponder is NSTextView
            if !isEditingText && keyCode == KeyCode.s && expandedTool != .snooze {
                toggleTool(.snooze)
                return true
            }
            if !isEditingText && keyCode == KeyCode.f && expandedTool != .feedback {
                toggleTool(.feedback)
                return true
            }
            if !isEditingText && keyCode == KeyCode.a && onAskDifferently != nil {
                if let type = AskDifferentlyMenuHelper.show(currentDialogType: currentDialogType) {
                    onAskDifferently?(type)
                }
                return true
            }
            if keyCode == KeyCode.returnKey && expandedTool == .feedback {
                return false
            }

            // Let custom handler try next
            if let handler = keyHandler, handler(keyCode, modifiers) {
                return true
            }

            // Default navigation via FocusManager
            switch keyCode {
            case KeyCode.tab:
                if modifiers.contains(.shift) {
                    FocusManager.shared.focusPrevious()
                } else {
                    FocusManager.shared.focusNext()
                }
                return true
            case KeyCode.downArrow:
                FocusManager.shared.focusNextContent()
                return true
            case KeyCode.upArrow:
                FocusManager.shared.focusPreviousContent()
                return true
            default:
                break
            }

            return false
        }
    }
}
