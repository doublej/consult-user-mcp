import SwiftUI
import AppKit

// MARK: - Auto-Sizing ScrollView

/// A ScrollView that reports its content height so `NSHostingView.fittingSize`
/// returns the correct value for window auto-sizing.
///
/// Plain `ScrollView` has flexible intrinsic size, causing `fittingSize` to return
/// a compressed height. This wrapper measures the actual content height (unconstrained
/// inside the scroll area) and sets `.frame(minHeight:)` so `fittingSize` includes
/// the real content size. When the window is capped at maxHeight the scroll still works.
struct AutoSizingScrollView<Content: View>: View {
    @ViewBuilder let content: Content
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        ScrollView {
            content
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: ContentHeightKey.self, value: geo.size.height)
                    }
                )
        }
        .frame(idealHeight: contentHeight > 0 ? contentHeight : nil)
        .layoutPriority(-1)
        .onPreferenceChange(ContentHeightKey.self) { height in
            guard abs(height - contentHeight) > 1 else { return }
            contentHeight = height
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .dialogContentSizeChanged, object: nil)
            }
        }
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Report Feedback Button (top-left corner)

struct ReportFeedbackButton: View {
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "ladybug")
                    .font(.system(size: 9, weight: .medium))
                Text("Feedback")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isHovered ? Theme.Colors.accentRed : Theme.Colors.textMuted)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(isHovered ? Theme.Colors.accentRed.opacity(0.12) : Color.clear)
                    .overlay(
                        Capsule()
                            .strokeBorder(isHovered ? Theme.Colors.accentRed.opacity(0.3) : Theme.Colors.border.opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help("Report a bug or give feedback")
    }
}

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

// MARK: - Selectable Text (Simple)

struct SelectableText: View {
    let text: String
    let font: NSFont
    let color: NSColor
    let alignment: NSTextAlignment

    init(
        _ text: String,
        fontSize: CGFloat = 13,
        weight: NSFont.Weight = .regular,
        color: Color = Theme.Colors.textPrimary,
        alignment: NSTextAlignment = .left
    ) {
        self.text = text
        self.font = NSFont.systemFont(ofSize: fontSize, weight: weight)
        self.color = NSColor(color)
        self.alignment = alignment
    }

    private var attributedString: NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        return NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ])
    }

    var body: some View {
        SelectableTextView(attributedString, alignment: alignment)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Selectable Text View

/// NSScrollView subclass that reports its text content height as intrinsic content size,
/// so SwiftUI allocates the correct amount of space during layout.
///
/// On first layout SwiftUI queries `intrinsicContentSize` before the view has a
/// width, so text reports single-line height. `setFrameSize` detects when the
/// width becomes known and re-invalidates so the window can resize to fit.
class IntrinsicTextScrollView: NSScrollView {
    private var lastKnownWidth: CGFloat = 0

    override var intrinsicContentSize: NSSize {
        guard let textView = documentView as? NSTextView,
              let container = textView.textContainer,
              let layoutManager = textView.layoutManager else {
            return NSSize(width: NSView.noIntrinsicMetric, height: 0)
        }
        layoutManager.ensureLayout(for: container)
        let height = layoutManager.usedRect(for: container).height
        return NSSize(width: NSView.noIntrinsicMetric, height: height)
    }

    override func setFrameSize(_ newSize: NSSize) {
        let widthChanged = abs(newSize.width - lastKnownWidth) > 1
        super.setFrameSize(newSize)
        if widthChanged && newSize.width > 0 {
            lastKnownWidth = newSize.width
            DispatchQueue.main.async { [weak self] in
                self?.invalidateIntrinsicContentSize()
                NotificationCenter.default.post(name: .dialogContentSizeChanged, object: nil)
            }
        }
    }
}

struct SelectableTextView: NSViewRepresentable {
    let attributedString: NSAttributedString
    let alignment: NSTextAlignment

    init(_ attributedString: NSAttributedString, alignment: NSTextAlignment = .center) {
        self.attributedString = attributedString
        self.alignment = alignment
    }

    func makeNSView(context: Context) -> IntrinsicTextScrollView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.required, for: .vertical)

        let scrollView = IntrinsicTextScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true

        return scrollView
    }

    func updateNSView(_ scrollView: IntrinsicTextScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        textView.textStorage?.setAttributedString(attributedString)
        textView.alignment = alignment
        textView.sizeToFit()
        scrollView.invalidateIntrinsicContentSize()
    }
}

// MARK: - Markdown Text

struct MarkdownText: View {
    let text: String
    let fontSize: CGFloat
    let color: NSColor
    let alignment: NSTextAlignment

    init(
        _ text: String,
        fontSize: CGFloat = 13,
        color: Color = Theme.Colors.textSecondary,
        alignment: NSTextAlignment = .center
    ) {
        self.text = text
        self.fontSize = fontSize
        self.color = NSColor(color)
        self.alignment = alignment
    }

    // Static regex constants — compiled once, reused across all calls
    private static let linkRegex = try! NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)")
    private static let boldRegex = try! NSRegularExpression(pattern: "\\*\\*([^*]+)\\*\\*")
    private static let italicRegex = try! NSRegularExpression(pattern: "(?<!\\*)\\*([^*]+)\\*(?!\\*)")
    private static let codeRegex = try! NSRegularExpression(pattern: "`([^`]+)`")

    var body: some View {
        SelectableTextView(parseMarkdownNS(text), alignment: alignment)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func parseMarkdownNS(_ input: String) -> NSAttributedString {
        let baseFont = NSFont.systemFont(ofSize: fontSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment

        let result = NSMutableAttributedString(string: input, attributes: [
            .font: baseFont,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ])

        let str = input

        // Links: [text](url)
        let linkMatches = Self.linkRegex.matches(in: str, range: NSRange(str.startIndex..., in: str))
        for match in linkMatches.reversed() {
            guard Range(match.range, in: str) != nil,
                  let textRange = Range(match.range(at: 1), in: str),
                  let urlRange = Range(match.range(at: 2), in: str) else { continue }
            let linkText = String(str[textRange])
            let urlString = String(str[urlRange])
            if let url = URL(string: urlString) {
                let linkAttr = NSMutableAttributedString(string: linkText, attributes: [
                    .font: baseFont,
                    .foregroundColor: NSColor(Theme.Colors.accentBlue),
                    .link: url,
                    .paragraphStyle: paragraphStyle,
                ])
                result.replaceCharacters(in: match.range, with: linkAttr)
            }
        }

        // Bold: **text**
        applyInlinePatternNS(Self.boldRegex, to: result) { range in
            result.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: fontSize), range: range)
        }

        // Italic: *text*
        applyInlinePatternNS(Self.italicRegex, to: result) { range in
            if let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask) as NSFont? {
                result.addAttribute(.font, value: italicFont, range: range)
            }
        }

        // Inline code: `code`
        applyInlinePatternNS(Self.codeRegex, to: result) { range in
            let monoFont = NSFont.monospacedSystemFont(ofSize: fontSize - 1, weight: .regular)
            result.addAttribute(.font, value: monoFont, range: range)
            result.addAttribute(.backgroundColor, value: NSColor(Theme.Colors.inputBackground), range: range)
        }

        return result
    }

    private func applyInlinePatternNS(
        _ regex: NSRegularExpression,
        to attrString: NSMutableAttributedString,
        apply: (NSRange) -> Void
    ) {
        var currentStr = attrString.string
        var matches = regex.matches(in: currentStr, range: NSRange(currentStr.startIndex..., in: currentStr))

        while !matches.isEmpty {
            let match = matches[0]
            guard Range(match.range, in: currentStr) != nil,
                  let textRange = Range(match.range(at: 1), in: currentStr) else { break }

            let innerText = String(currentStr[textRange])
            let replacement = NSMutableAttributedString(string: innerText, attributes: attrString.attributes(at: match.range.location, effectiveRange: nil))

            attrString.replaceCharacters(in: match.range, with: replacement)

            // Apply the styling to the replaced range
            let newRange = NSRange(location: match.range.location, length: innerText.count)
            apply(newRange)

            currentStr = attrString.string
            matches = regex.matches(in: currentStr, range: NSRange(currentStr.startIndex..., in: currentStr))
        }
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
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)

            if let text = bodyText {
                MarkdownText(text)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 20)
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
    @State private var showReportOverlay = false
    @State private var reportScreenshot: Data?

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
            HStack {
                ReportFeedbackButton(action: captureAndShowOverlay)
                Spacer(minLength: 0)
                if let name = projectName, let path = projectPath {
                    ProjectBadge(projectName: name, projectPath: path)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            contentBuilder($expandedTool)
        }
        .overlay {
            if showReportOverlay {
                ReportIssueView(
                    screenshotData: reportScreenshot,
                    onSubmit: { description, copyToClipboard in
                        dismissOverlay()
                        GitHubReporter.openIssue(description: description,
                                                 screenshotData: reportScreenshot,
                                                 copyToClipboard: copyToClipboard)
                    },
                    onCancel: { dismissOverlay() }
                )
                .transition(reduceMotion ? .identity : .opacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: showReportOverlay)
        .onAppear {
            FocusManager.shared.reset()
            setupKeyboardNavigation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                FocusManager.shared.focusFirst()
            }
            if let pane = DialogManager.shared.testPane {
                let tool: DialogToolbar.ToolbarTool? = pane == "snooze" ? .snooze : pane == "feedback" ? .feedback : nil
                if let tool {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        toggleTool(tool)
                    }
                }
            }
        }
        .onDisappear {
            keyboardMonitor = nil
            FocusManager.shared.reset()
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissReportOverlay)) { _ in
            dismissOverlay()
        }
    }

    private func captureAndShowOverlay() {
        reportScreenshot = DialogManager.shared.captureWindowScreenshot()
        showReportOverlay = true
        ReportIssueOverlayManager.shared.isShowing = true
    }

    private func dismissOverlay() {
        showReportOverlay = false
        ReportIssueOverlayManager.shared.isShowing = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            FocusManager.shared.focusFirst()
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
            if keyCode == KeyCode.escape && showReportOverlay {
                dismissOverlay()
                return true
            }
            // When report overlay is open, pass all other keys to its first responder
            if showReportOverlay {
                return false
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
