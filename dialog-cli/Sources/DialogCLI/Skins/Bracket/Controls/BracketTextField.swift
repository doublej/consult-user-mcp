import AppKit
import SwiftUI

/// Tracks whether a caret currently sits in any field on the surface, which is
/// what lets the hint strip stop advertising a shortcut that would type a
/// letter instead (§10.4).
final class CaretTracker: ObservableObject {
    @Published var isEditing = false
}

/// The shared single-line input (§3.14).
///
/// Chrome is SwiftUI, the field itself is a real `NSTextField` so the caret,
/// selection, secure entry and standard editing all behave. Focus reads through
/// the same amber caret as every other control — here it sits inside the well's
/// leading edge — and the well's border warms with it.
struct BracketTextField: View {
    var placeholder: String
    var isSecure: Bool = false
    @Binding var text: String
    var selectAllOnFocus: Bool = false
    var autofocus: Bool = false
    var onFocusChange: (Bool) -> Void = { _ in }

    @State private var isFocused = false

    var body: some View {
        HStack(spacing: 0) {
            FocusCaret(height: 16, visible: isFocused)
                .padding(.leading, 11)
                .padding(.trailing, 9)

            BracketFieldRepresentable(
                text: $text,
                placeholder: placeholder,
                isSecure: isSecure,
                selectAllOnFocus: selectAllOnFocus,
                autofocus: autofocus,
                onFocusChange: { focused in
                    isFocused = focused
                    onFocusChange(focused)
                }
            )
            .frame(height: 18)
            .padding(.trailing, 12)
        }
        .frame(height: 34)
        .background(
            RoundedRectangle(cornerRadius: BracketStyle.Radius.button, style: .continuous)
                .fill(BracketStyle.well)
        )
        .overlay(
            RoundedRectangle(cornerRadius: BracketStyle.Radius.button, style: .continuous)
                .strokeBorder(
                    isFocused ? BracketStyle.amber.opacity(0.55) : BracketStyle.line,
                    lineWidth: 1
                )
        )
    }
}

struct BracketFieldRepresentable: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isSecure: Bool
    var selectAllOnFocus: Bool
    var autofocus: Bool = false
    var onFocusChange: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSTextField {
        let field: NSTextField = isSecure ? NSSecureTextField() : NSTextField()
        field.delegate = context.coordinator
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = BracketStyle.sans(BracketStyle.Size.body, .medium)
        field.textColor = NSColor(hex: 0xF2F2F4)
        field.usesSingleLineMode = true
        field.lineBreakMode = .byClipping
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        field.stringValue = text
        field.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: BracketStyle.sans(BracketStyle.Size.body, .regular),
                .foregroundColor: NSColor(hex: 0x98989F, alpha: 0.6),
            ]
        )
        FocusManager.shared.registerContent(field)
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.parent = self
        if field.stringValue != text {
            field.stringValue = text
        }
        if autofocus, !context.coordinator.didAutofocus, field.window != nil {
            context.coordinator.didAutofocus = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                field.window?.makeFirstResponder(field)
            }
        }
    }

    static func dismantleNSView(_ field: NSTextField, coordinator: Coordinator) {
        FocusManager.shared.unregister(field)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: BracketFieldRepresentable
        private var hasSelectedOnce = false
        var didAutofocus = false

        init(_ parent: BracketFieldRepresentable) {
            self.parent = parent
        }

        func controlTextDidBeginEditing(_ notification: Notification) {
            parent.onFocusChange(true)
            guard parent.selectAllOnFocus, !hasSelectedOnce,
                  let field = notification.object as? NSTextField else { return }
            hasSelectedOnce = true
            // §3.14 — a prefilled value opens with its text selected, so the
            // first keystroke replaces it.
            field.currentEditor()?.selectAll(nil)
        }

        func controlTextDidEndEditing(_ notification: Notification) {
            parent.onFocusChange(false)
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            parent.text = field.stringValue
        }
    }
}
