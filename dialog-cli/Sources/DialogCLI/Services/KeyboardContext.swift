import AppKit

/// Single source of truth for "is the user editing a text field right now?".
///
/// Walks the full responder chain (not just the leaf) so that wrappers like
/// `FocusableTextFieldView` — which can briefly hold first responder before
/// forwarding to their internal `NSTextField` — are still recognized as
/// text-editing surfaces. This is what stops character hotkeys (`s`, `f`, `a`)
/// from firing while typing in an "Other" field.
enum KeyboardContext {
    static var isEditingText: Bool {
        guard let window = NSApp.keyWindow else { return false }
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
