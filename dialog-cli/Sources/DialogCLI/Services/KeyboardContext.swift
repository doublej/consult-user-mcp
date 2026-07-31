import AppKit

/// Single source of truth for "is the user editing a text field right now?".
///
/// Walks the full responder chain (not just the leaf) so that wrappers like
/// `FocusableTextFieldView` — which can briefly hold first responder before
/// forwarding to their internal `NSTextField` — are still recognized as
/// text-editing surfaces. This is what stops character hotkeys (`s`, `f`, `a`)
/// from firing while typing in an "Other" field.
enum KeyboardContext {
    /// The window whose first responder decides this.
    ///
    /// `NSApp.keyWindow` alone is not it. It is nil whenever the application
    /// is not active, and a dialog cannot always make itself active — behind
    /// a full-screen app, mid Space-switch, spawned from a background agent,
    /// or with a system alert holding the foreground. The field is still
    /// first responder in all of those; only the *window* has lost key
    /// status.
    ///
    /// Reading it as "not editing" meant every letter typed into a field was
    /// answered as the shortcut it is outside one: a path beginning with `s`
    /// opened the snooze tray, an `f` opened the note pane, and the answer
    /// came back with the characters missing.
    /// `modalWindow` is the precise fallback: every dialog runs through
    /// `runModal(for:)`, so it is this dialog and nothing else. The same
    /// pairing is already used by the toolbar and the report overlay.
    private static var editingWindow: NSWindow? {
        NSApp.keyWindow ?? NSApp.modalWindow
    }

    static var isEditingText: Bool {
        guard let window = editingWindow else { return false }
        var current: NSResponder? = window.firstResponder
        while let responder = current {
            if responder is NSTextView { return true }
            if let tf = responder as? NSTextField, tf.isEditable { return true }
            if responder is FocusableTextFieldView { return true }
            current = responder.nextResponder
        }
        return false
    }
}
