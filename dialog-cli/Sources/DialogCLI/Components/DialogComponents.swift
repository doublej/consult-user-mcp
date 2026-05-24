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
                Text("Report")
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
        .help("Report a bug or suggestion")
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

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        DispatchQueue.main.async { [weak self] in
            self?.invalidateIntrinsicContentSize()
        }
    }

    override func setFrameSize(_ newSize: NSSize) {
        let widthChanged = abs(newSize.width - lastKnownWidth) > 1
        super.setFrameSize(newSize)
        if widthChanged && newSize.width > 0 {
            lastKnownWidth = newSize.width
            invalidateIntrinsicContentSize()
            DispatchQueue.main.async {
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

// MARK: - Markdown Parser

enum MarkdownParser {
    static let linkRegex = try! NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)")
    static let boldRegex = try! NSRegularExpression(pattern: "\\*\\*([^*]+)\\*\\*")
    static let italicRegex = try! NSRegularExpression(pattern: "(?<!\\*)\\*([^*]+)\\*(?!\\*)")
    static let codeRegex = try! NSRegularExpression(pattern: "`([^`]+)`")

    static func parse(
        _ input: String,
        fontSize: CGFloat = 13,
        color: NSColor = NSColor(Theme.Colors.textSecondary),
        alignment: NSTextAlignment = .center
    ) -> NSAttributedString {
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
        let linkMatches = linkRegex.matches(in: str, range: NSRange(str.startIndex..., in: str))
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
        applyInlinePattern(boldRegex, to: result) { range in
            result.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: fontSize), range: range)
        }

        // Italic: *text*
        applyInlinePattern(italicRegex, to: result) { range in
            if let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask) as NSFont? {
                result.addAttribute(.font, value: italicFont, range: range)
            }
        }

        // Inline code: `code`
        applyInlinePattern(codeRegex, to: result) { range in
            let monoFont = NSFont.monospacedSystemFont(ofSize: fontSize - 1, weight: .regular)
            result.addAttribute(.font, value: monoFont, range: range)
            result.addAttribute(.backgroundColor, value: NSColor(Theme.Colors.inputBackground), range: range)
        }

        return result
    }

    private static func applyInlinePattern(
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

            let newRange = NSRange(location: match.range.location, length: innerText.count)
            apply(newRange)

            currentStr = attrString.string
            matches = regex.matches(in: currentStr, range: NSRange(currentStr.startIndex..., in: currentStr))
        }
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

    var body: some View {
        SelectableTextView(MarkdownParser.parse(text, fontSize: fontSize, color: color, alignment: alignment), alignment: alignment)
            .fixedSize(horizontal: false, vertical: true)
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
                let hasBlockContent = text.contains("\n")
                let alignment: NSTextAlignment = hasBlockContent ? .left : .center
                Text(AttributedString(MarkdownParser.parse(text, alignment: alignment)))
                    .textSelection(.enabled)
                    .tint(Theme.Colors.accentBlue)
                    .frame(idealWidth: 380, maxWidth: .infinity, alignment: hasBlockContent ? .leading : .center)
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
            .frame(height: 48)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Feedback Controller

/// Passed to every dialog body so it can open the feedback pane or query
/// whether a target already has draft text. The dialog uses this in three
/// places: the toolbar button, the keyboard shortcut, and (for forms) the
/// per-question affordance. Also carries the snooze-toolbar expansion
/// binding so the dialog can wire `DialogToolbar` without owning that state.
struct FeedbackController {
    let currentTarget: FeedbackTarget?
    let openFeedback: (FeedbackTarget) -> Void
    let hasFeedback: (FeedbackTarget) -> Bool
    let expandedTool: Binding<DialogToolbar.ToolbarTool?>
}

// MARK: - Dialog Container (Composable)

struct DialogContainer<Content: View>: View {
    let bindings: DialogKeyBindings
    let currentDialogType: String
    let dialogPosition: DialogPosition
    let globalFeedbackSubject: FeedbackSubject
    let onAskDifferently: ((String) -> Void)?
    let feedbackBindingForQuestion: ((String) -> Binding<String>)?
    let contentBuilder: (FeedbackController) -> Content

    @State private var keyboardMonitor: KeyboardNavigationMonitor?
    @State private var feedbackTarget: FeedbackTarget?
    @State private var globalDraft: String = ""
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
        bindings: DialogKeyBindings = DialogKeyBindings(),
        currentDialogType: String = "",
        dialogPosition: DialogPosition = .center,
        globalFeedbackSubject: FeedbackSubject,
        onAskDifferently: ((String) -> Void)? = nil,
        feedbackBindingForQuestion: ((String) -> Binding<String>)? = nil,
        @ViewBuilder content: @escaping (FeedbackController) -> Content
    ) {
        self.bindings = bindings
        self.currentDialogType = currentDialogType
        self.dialogPosition = dialogPosition
        self.globalFeedbackSubject = globalFeedbackSubject
        self.onAskDifferently = onAskDifferently
        self.feedbackBindingForQuestion = feedbackBindingForQuestion
        self.contentBuilder = content
    }

    /// Edge the feedback pane should slide in from. `.left` dialog → pane on
    /// the right; `.right` dialog → pane on the left; `.center` → default
    /// trailing unless the dialog is closer to the right edge of the screen.
    private var paneEdge: Edge {
        switch dialogPosition {
        case .left:
            return .trailing
        case .right:
            return .leading
        case .center:
            guard let screen = NSScreen.main else { return .trailing }
            let screenMid = screen.visibleFrame.midX
            return screenMid > screen.visibleFrame.midX ? .leading : .trailing
        }
    }

    private var currentFeedbackSubject: FeedbackSubject {
        guard let target = feedbackTarget else { return globalFeedbackSubject }
        switch target {
        case .global:
            return globalFeedbackSubject
        case .question(let id):
            let text = DialogManager.shared.questionLabelLookup?(id) ?? "(this question)"
            return FeedbackSubject(kind: .question, text: text)
        }
    }

    private var feedbackBinding: Binding<String> {
        guard let target = feedbackTarget else {
            return Binding(get: { "" }, set: { _ in })
        }
        switch target {
        case .global:
            return Binding(
                get: { globalDraft },
                set: { globalDraft = $0 }
            )
        case .question(let id):
            if let resolver = feedbackBindingForQuestion {
                return resolver(id)
            }
            return Binding(get: { "" }, set: { _ in })
        }
    }

    private var controller: FeedbackController {
        FeedbackController(
            currentTarget: feedbackTarget,
            openFeedback: { target in setFeedbackTarget(target) },
            hasFeedback: { target in
                switch target {
                case .global:
                    return !globalDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                case .question(let id):
                    let value = feedbackBindingForQuestion?(id).wrappedValue ?? ""
                    return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
            },
            expandedTool: $expandedTool
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            if paneEdge == .leading, feedbackTarget != nil {
                paneView
                    .transition(reduceMotion ? .identity : .move(edge: .leading))
            }

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

                contentBuilder(controller)
            }

            if paneEdge == .trailing, feedbackTarget != nil {
                paneView
                    .transition(reduceMotion ? .identity : .move(edge: .trailing))
            }
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
        .animation(reduceMotion ? nil : .easeOut(duration: Theme.Animation.overlay), value: showReportOverlay)
        .onAppear {
            FocusManager.shared.reset()
            DialogManager.shared.globalFeedbackBinding = Binding(
                get: { globalDraft },
                set: { globalDraft = $0 }
            )
            setupKeyboardNavigation()
            DispatchQueue.main.asyncAfter(deadline: .now() + Theme.Timing.focusAfterAppear) {
                FocusManager.shared.focusFirst()
            }
            if let pane = DialogManager.shared.testPane {
                if pane == "snooze" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Theme.Timing.testPaneReveal) {
                        toggleSnooze()
                    }
                } else if pane == "feedback" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Theme.Timing.testPaneReveal) {
                        setFeedbackTarget(.global)
                    }
                }
            }
        }
        .onDisappear {
            keyboardMonitor = nil
            DialogManager.shared.globalFeedbackBinding = nil
            FocusManager.shared.reset()
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissReportOverlay)) { _ in
            dismissOverlay()
        }
    }

    @ViewBuilder
    private var paneView: some View {
        FeedbackPane(
            subject: currentFeedbackSubject,
            draft: feedbackBinding,
            onClose: { closePane() },
            onClear: { feedbackBinding.wrappedValue = "" }
        )
    }

    private func setFeedbackTarget(_ target: FeedbackTarget) {
        let willClose = feedbackTarget == target
        if reduceMotion {
            feedbackTarget = willClose ? nil : target
        } else {
            withAnimation(.easeOut(duration: Theme.Animation.overlay)) {
                feedbackTarget = willClose ? nil : target
            }
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .dialogContentSizeChanged, object: nil)
        }
        // Focus is handled inside FeedbackEditor — it grabs first responder
        // on its first updateNSView, so the editor is ready to type into.
    }

    private func closePane() {
        if reduceMotion {
            feedbackTarget = nil
        } else {
            withAnimation(.easeOut(duration: Theme.Animation.overlay)) {
                feedbackTarget = nil
            }
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .dialogContentSizeChanged, object: nil)
        }
    }

    private func toggleSnooze() {
        let next: DialogToolbar.ToolbarTool? = expandedTool == .snooze ? nil : .snooze
        if reduceMotion {
            expandedTool = next
        } else {
            withAnimation(.easeOut(duration: Theme.Animation.overlay)) {
                expandedTool = next
            }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + Theme.Timing.focusAfterAppear) {
            FocusManager.shared.focusFirst()
        }
    }

    private func setupKeyboardNavigation() {
        keyboardMonitor = DialogKeyRouter.install(
            bindings: bindings,
            currentDialogType: currentDialogType,
            onAskDifferently: onAskDifferently,
            expandedTool: $expandedTool,
            isFeedbackPaneOpen: { feedbackTarget != nil },
            showReportOverlay: $showReportOverlay,
            toggleSnooze: { toggleSnooze() },
            openFeedback: { setFeedbackTarget(.global) },
            closePane: { closePane() },
            dismissOverlay: { dismissOverlay() }
        )
    }
}
