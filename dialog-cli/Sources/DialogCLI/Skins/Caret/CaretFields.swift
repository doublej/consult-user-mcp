import AppKit
import SwiftUI

// MARK: - Single line field

/// One typed answer (§3.11). Rest, focused, masked and overflowing are the
/// four states; the field never grows and never widens the surface, so long
/// content scrolls inside it.
final class CaretFieldView: NSTextField {
    var onFocus: ((Bool) -> Void)?
    var onSubmitKey: (() -> Bool)?

    override var acceptsFirstResponder: Bool { isEnabled }
    override var canBecomeKeyView: Bool { isEnabled }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            FocusManager.shared.unregister(self)
        } else {
            FocusManager.shared.registerContent(self)
        }
    }

    override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        if ok {
            onFocus?(true)
            // A prefilled value opens with its text selected, so the first
            // keystroke replaces it. Required behaviour, not a platform gift.
            DispatchQueue.main.async { [weak self] in
                self?.currentEditor()?.selectAll(nil)
            }
        }
        return ok
    }

    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        onFocus?(false)
    }
}

final class CaretSecureFieldView: NSSecureTextField {
    var onFocus: ((Bool) -> Void)?

    override var acceptsFirstResponder: Bool { isEnabled }
    override var canBecomeKeyView: Bool { isEnabled }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            FocusManager.shared.unregister(self)
        } else {
            FocusManager.shared.registerContent(self)
        }
    }

    override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        if ok {
            onFocus?(true)
            DispatchQueue.main.async { [weak self] in
                self?.currentEditor()?.selectAll(nil)
            }
        }
        return ok
    }

    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        onFocus?(false)
    }
}

struct CaretField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var masked: Bool = false
    var autofocus: Bool = false
    var onFocus: (Bool) -> Void = { _ in }
    /// Return inside the field. The router hands the key to the first
    /// responder whenever the surface's own commit will not take it (§4.4).
    var onEnter: (() -> Void)? = nil

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CaretField
        var didAutofocus = false
        init(_ parent: CaretField) { self.parent = parent }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            guard selector == #selector(NSResponder.insertNewline(_:)), let onEnter = parent.onEnter else { return false }
            onEnter()
            return true
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            // Strictly single line: pasting several lines yields one.
            let flattened = field.stringValue.replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")
            if flattened != field.stringValue { field.stringValue = flattened }
            parent.text = flattened
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSTextField {
        let field: NSTextField = masked ? CaretSecureFieldView() : CaretFieldView()
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.isEditable = true
        field.isSelectable = true
        field.usesSingleLineMode = true
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        field.lineBreakMode = .byClipping
        field.delegate = context.coordinator
        field.stringValue = text
        apply(field, context: context)
        if let plain = field as? CaretFieldView { plain.onFocus = onFocus }
        if let secure = field as? CaretSecureFieldView { secure.onFocus = onFocus }
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.parent = self
        if field.stringValue != text { field.stringValue = text }
        apply(field, context: context)
        if let plain = field as? CaretFieldView { plain.onFocus = onFocus }
        if let secure = field as? CaretSecureFieldView { secure.onFocus = onFocus }
        if autofocus, !context.coordinator.didAutofocus, field.window != nil {
            context.coordinator.didAutofocus = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                field.window?.makeFirstResponder(field)
            }
        }
    }

    private func apply(_ field: NSTextField, context: Context) {
        let palette = context.environment.caretPalette
        field.font = CaretStyle.body
        field.textColor = NSColor(palette.ink)
        field.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [.font: CaretStyle.body, .foregroundColor: NSColor(palette.inkMuted)]
        )
    }
}

// MARK: - Note editor

/// The annotation editor. It takes the caret on the first frame it begins to
/// appear, so a key pressed while it is still arriving is typed into the note
/// rather than treated as a shortcut (§3.6).
final class CaretEditorTextView: NSTextView {
    var onFocus: ((Bool) -> Void)?

    override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        if ok { onFocus?(true) }
        return ok
    }

    override func resignFirstResponder() -> Bool {
        let ok = super.resignFirstResponder()
        if ok { onFocus?(false) }
        return ok
    }
}

struct CaretNoteEditor: NSViewRepresentable {
    @Binding var text: String
    var onFocus: (Bool) -> Void = { _ in }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CaretNoteEditor
        init(_ parent: CaretNoteEditor) { self.parent = parent }
        func textDidChange(_ notification: Notification) {
            guard let view = notification.object as? NSTextView else { return }
            parent.text = view.string
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = false
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder

        let view = CaretEditorTextView()
        view.delegate = context.coordinator
        view.isEditable = true
        view.isSelectable = true
        view.allowsUndo = true
        view.drawsBackground = false
        view.isRichText = false
        view.textContainerInset = NSSize(width: 0, height: 2)
        view.string = text
        view.onFocus = onFocus
        apply(view, context: context)

        scroll.documentView = view
        DispatchQueue.main.async {
            scroll.window?.makeFirstResponder(view)
        }
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let view = scroll.documentView as? CaretEditorTextView else { return }
        if view.string != text { view.string = text }
        view.onFocus = onFocus
        apply(view, context: context)
    }

    private func apply(_ view: NSTextView, context: Context) {
        let palette = context.environment.caretPalette
        view.font = CaretStyle.body
        view.textColor = NSColor(palette.ink)
        view.insertionPointColor = NSColor(palette.caret)
    }
}

// MARK: - Field chrome

/// The rule under a field. It is the same hairline the frame's arms are drawn
/// with, so a field reads as a short piece of the same structure.
struct CaretFieldRule: View {
    var focused: Bool
    var tone: Color?
    @Environment(\.caretPalette) private var palette

    var body: some View {
        Rectangle()
            .fill(tone ?? (focused ? palette.caret : palette.rail))
            .frame(height: focused ? CaretStyle.caretWidth : CaretStyle.hair)
    }
}
