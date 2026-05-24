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

// MARK: - Feedback Pane

/// Slide-out pane bound to a single feedback draft (either the consult-level
/// note or a specific question). The pane stays "armed" while text is in the
/// draft; closing simply hides it.
struct FeedbackPane: View {
    let title: String
    @Binding var draft: String
    let onClose: () -> Void
    let onClear: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            header
            editor
            footer
        }
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
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Note")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.Colors.textMuted)
                    .textCase(.uppercase)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
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

    private var editor: some View {
        FeedbackEditor(text: $draft)
            .background(Theme.Colors.inputBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Theme.Colors.border.opacity(0.6), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity)
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
                Text("Done")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.Colors.accentBlue)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Feedback Editor (NSTextView-backed multi-line)

struct FeedbackEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
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

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
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
