import AppKit
import SwiftUI

/// Declarative key bindings supplied by each dialog. Anything left at the
/// default closure means "the router should use its built-in fallback".
/// Arrow / Tab handlers return `true` when they consumed the event.
struct DialogKeyBindings {
    var canSubmit: () -> Bool = { false }
    var onSubmit: () -> Void = {}
    var onCancel: () -> Void = {}
    var onArrowLeft: (() -> Bool)? = nil
    var onArrowRight: (() -> Bool)? = nil
    var onArrowUp: (() -> Bool)? = nil
    var onArrowDown: (() -> Bool)? = nil
    var onTab: ((NSEvent.ModifierFlags) -> Bool)? = nil
}

/// Owns the `NSEvent` keyDown monitor for a dialog and runs every dialog
/// type through the same fixed pipeline.
enum DialogKeyRouter {
    static func install(
        bindings: DialogKeyBindings,
        currentDialogType: String,
        onAskDifferently: ((String) -> Void)?,
        expandedTool: Binding<DialogToolbar.ToolbarTool?>,
        isFeedbackPaneOpen: @escaping () -> Bool,
        showReportOverlay: Binding<Bool>,
        toggleSnooze: @escaping () -> Void,
        openFeedback: @escaping () -> Void,
        closePane: @escaping () -> Void,
        dismissOverlay: @escaping () -> Void
    ) -> KeyboardNavigationMonitor {
        KeyboardNavigationMonitor { keyCode, modifiers in
            // 1. Cooldown swallows everything it cares about.
            if CooldownManager.shared.shouldBlockKey(keyCode) {
                return true
            }

            // 2. Escape: report overlay → feedback pane → snooze panel → cancel.
            if keyCode == KeyCode.escape {
                if showReportOverlay.wrappedValue {
                    dismissOverlay()
                    return true
                }
                if isFeedbackPaneOpen() {
                    closePane()
                    return true
                }
                if expandedTool.wrappedValue == .snooze {
                    toggleSnooze()
                    return true
                }
                bindings.onCancel()
                return true
            }

            // While the report overlay owns the window, hand every other key
            // to its first responder.
            if showReportOverlay.wrappedValue {
                return false
            }

            let editingText = KeyboardContext.isEditingText

            // 3a. ⌘F opens the feedback pane regardless of first-responder
            //     context — text-input dialogs need a chord because the
            //     plain-`f` hotkey reaches the field.
            if keyCode == KeyCode.f
                && modifiers.contains(.command)
                && !isFeedbackPaneOpen() {
                openFeedback()
                return true
            }

            // 3. While editing text only Return / Tab and ⌘-shortcuts reach
            //    the rest of the pipeline; plain character hotkeys must go
            //    to the field.
            if editingText
                && keyCode != KeyCode.returnKey
                && keyCode != KeyCode.tab
                && !modifiers.contains(.command) {
                if !isArrow(keyCode) {
                    return false
                }
            }

            // 4. Character hotkeys (only when not editing text).
            if !editingText {
                if keyCode == KeyCode.s && expandedTool.wrappedValue != .snooze {
                    toggleSnooze()
                    return true
                }
                if keyCode == KeyCode.f && !isFeedbackPaneOpen() {
                    openFeedback()
                    return true
                }
                if keyCode == KeyCode.a && onAskDifferently != nil {
                    if let type = AskDifferentlyMenuHelper.show(currentDialogType: currentDialogType) {
                        onAskDifferently?(type)
                    }
                    return true
                }
            }

            // 5. Return: feedback pane editor gets to insert newlines; otherwise
            //    submit if the dialog is in a submittable state.
            if keyCode == KeyCode.returnKey {
                if isFeedbackPaneOpen() && editingText {
                    return false
                }
                if bindings.canSubmit() {
                    bindings.onSubmit()
                    return true
                }
                return false
            }

            // 6. Tab / Shift+Tab: dialog-specific handler first, then
            //    FocusManager. While editing text we only honor a custom
            //    handler — otherwise AppKit moves focus naturally.
            if keyCode == KeyCode.tab {
                if let handler = bindings.onTab, handler(modifiers) {
                    return true
                }
                if editingText {
                    return false
                }
                if modifiers.contains(.shift) {
                    FocusManager.shared.focusPrevious()
                } else {
                    FocusManager.shared.focusNext()
                }
                return true
            }

            // 7. Arrow keys: dialog handler first (returns true if it
            //    consumed the event), then FocusManager up/down default.
            switch keyCode {
            case KeyCode.leftArrow:
                if let handler = bindings.onArrowLeft, handler() { return true }
                return false
            case KeyCode.rightArrow:
                if let handler = bindings.onArrowRight, handler() { return true }
                return false
            case KeyCode.upArrow:
                if let handler = bindings.onArrowUp, handler() { return true }
                if editingText { return false }
                FocusManager.shared.focusPreviousContent()
                return true
            case KeyCode.downArrow:
                if let handler = bindings.onArrowDown, handler() { return true }
                if editingText { return false }
                FocusManager.shared.focusNextContent()
                return true
            default:
                return false
            }
        }
    }

    private static func isArrow(_ keyCode: UInt16) -> Bool {
        keyCode == KeyCode.leftArrow
            || keyCode == KeyCode.rightArrow
            || keyCode == KeyCode.upArrow
            || keyCode == KeyCode.downArrow
    }
}
