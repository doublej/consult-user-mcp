import SwiftUI
import AppKit

// MARK: - Feedback Target

/// Identifies which slot the feedback pane is bound to. Single-question
/// dialogs use `.global`; forms use `.question(id)` per question, plus
/// `.global` for a consult-level note.
enum FeedbackTarget: Equatable {
    case global
    case question(id: String)

    var questionId: String? {
        if case .question(let id) = self { return id }
        return nil
    }
}

// MARK: - Feedback Subject

/// Describes the prompt the user is annotating. Drives the prominent
/// header card so the user (and a glance-from-across-the-room view) can
/// see exactly what the note is attached to.
struct FeedbackSubject {
    enum Kind {
        case question
        case dialog
        case form
    }

    let kind: Kind
    /// Optional reminder text shown in the subject card. `nil`/empty hides
    /// the card entirely — used by single-question dialogs (body already on
    /// screen) and forms without a `body` field.
    let text: String?

    var caption: String {
        switch kind {
        case .question: return "Note on this question"
        case .dialog: return "Note on this dialog"
        case .form: return "Note on this form"
        }
    }

    var icon: String {
        switch kind {
        case .question: return "questionmark.bubble"
        case .dialog: return "bubble.left"
        case .form: return "list.bullet.rectangle"
        }
    }
}

// MARK: - Feedback Pane

/// Slide-out pane bound to a single feedback draft (either the consult-level
/// note or a specific question). The pane stays "armed" while text is in the
/// draft; closing simply hides it.
struct FeedbackPane: View {
    let subject: FeedbackSubject
    @Binding var draft: String
    let onClose: () -> Void
    let onClear: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    /// Single-question dialogs (`.dialog`) already render the prompt
    /// directly above the dialog body, so the subject card would just
    /// duplicate the text. Forms (`.form`) only show the card when the
    /// dialog passed an explicit body; falling back to the app title was
    /// gibberish ("Note on this form: MCP"). Per-question subjects always
    /// show — they narrow a multi-question form to one prompt.
    private var shouldShowSubjectCard: Bool {
        switch subject.kind {
        case .dialog:
            return false
        case .form:
            guard let text = subject.text else { return false }
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .question:
            return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if shouldShowSubjectCard {
                subjectCard
            }
            editorSection
            footer
        }
        // Fixed width, deliberately: a flexible range here made the container
        // HStack resolve wider than NSHostingView.fittingSize (the window is
        // sized from ideals, but at render time the HStack splits the proposal
        // evenly and the pane accepted more while the content column refused
        // less than its minWidth) — the 30pt overflow escaped the unclipped
        // hosting view and broke the card edges.
        .frame(width: 360)
        .background(Theme.Colors.cardBackground)
        .overlay(
            Rectangle()
                .fill(Theme.Colors.border.opacity(0.5))
                .frame(width: 1),
            alignment: .leading
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: subject.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.Colors.accentBlue)
                Text(subject.caption)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.Colors.accentBlue)
                    .textCase(.uppercase)
                    .kerning(0.4)
            }

            Spacer(minLength: 0)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.Colors.textMuted)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle().fill(Theme.Colors.cardHover.opacity(0.5))
                    )
            }
            .buttonStyle(.plain)
            .help("Close pane (Esc)")
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var subjectCard: some View {
        if let raw = subject.text {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.Colors.accentBlue)
                    .frame(width: 3)

                Text(AttributedString(MarkdownParser.parse(
                    raw,
                    fontSize: 14,
                    color: NSColor(Theme.Colors.textPrimary),
                    alignment: .left
                )))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .textSelection(.enabled)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, maxHeight: 80, alignment: .topLeading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.Colors.accentBlue.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Theme.Colors.accentBlue.opacity(0.25), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your note")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Theme.Colors.textMuted)
                .textCase(.uppercase)
                .padding(.leading, 2)

            FeedbackEditor(text: $draft)
                .background(Theme.Colors.inputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Theme.Colors.border.opacity(0.6), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(minHeight: 180)
        }
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button(action: onClear) {
                Text("Clear")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Theme.Colors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(draft.isEmpty)
            .opacity(draft.isEmpty ? 0.4 : 1.0)

            Spacer()

            Button(action: onClose) {
                Text("Close")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Theme.Colors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help("Close pane (note is preserved)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Feedback Editor (NSTextView-backed multi-line)

/// Multi-line text editor backed by NSTextView. Important: every NSView in
/// this stack must override `mouseDownCanMoveWindow` to `false` — the
/// dialog window's `DraggableView` background otherwise eats clicks before
/// the text view can become first responder.
struct FeedbackEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    func makeNSView(context: Context) -> FeedbackEditorScrollView {
        let textView = FeedbackEditorTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.textColor = Theme.textPrimary
        textView.insertionPointColor = Theme.accentBlue
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.delegate = context.coordinator
        textView.string = text
        textView.autoresizingMask = [.width]

        let scrollView = FeedbackEditorScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = true
        return scrollView
    }

    func updateNSView(_ scrollView: FeedbackEditorScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            self._text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
        }
    }
}

/// NSTextView that refuses to participate in window dragging so clicks
/// land on the text view itself.
final class FeedbackEditorTextView: NSTextView {
    override var mouseDownCanMoveWindow: Bool { false }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    /// Take focus the instant the pane lands in the window — synchronously,
    /// not via an async hop — so keystrokes racing the pane-open animation
    /// reach the editor instead of a stale first responder.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
}

/// NSScrollView wrapper — also has to refuse window-drag so clicks
/// reaching the scroll area first don't slip up to `DraggableView`.
final class FeedbackEditorScrollView: NSScrollView {
    override var mouseDownCanMoveWindow: Bool { false }
}
