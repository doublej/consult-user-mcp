import AppKit

// MARK: - Borderless Window that Accepts Keyboard

class BorderlessWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        self.autorecalculatesKeyViewLoop = true
    }

    /// AppKit will not order a window front on behalf of an application that
    /// cannot become active, and `makeKeyAndOrderFront` says nothing when it
    /// declines — the process just runs its modal loop against a window that
    /// was never mapped, and waits for an answer to a question nobody was
    /// shown.
    ///
    /// That is the standing state inside the test VM, where no application
    /// owns the foreground. It is why `notify` and `preview` were the only
    /// surfaces that ever appeared there: they order front regardless, and
    /// everything else came through here. It is also reachable on a real Mac
    /// any time activation is refused — during a Space switch, under a
    /// full-screen app, from a background agent.
    ///
    /// Ordering front regardless afterwards costs nothing when activation did
    /// work, and is the difference between a dialog and no dialog when it did
    /// not. Taking key the same way keeps the keyboard working on the window
    /// we just forced up.
    override func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        if !isVisible { orderFrontRegardless() }
        if !isKeyWindow { makeKey() }
    }

    /// Where a press that is allowed to move the window started, in window
    /// coordinates. Cleared the moment the drag begins or the button goes up.
    private var dragAnchor: NSPoint?

    /// The window moves itself, rather than asking AppKit to move it.
    ///
    /// `isMovableByWindowBackground` is set and every view under the pointer
    /// still answers `mouseDownCanMoveWindow` with true — measured across the
    /// whole surface — and from macOS 26 onwards AppKit no longer starts a
    /// drag from that, so a borderless dialog could not be moved at all. The
    /// flag is the only thing that stopped working; the policy it encoded is
    /// intact, so it is still the policy used here. A control that refuses to
    /// participate (`Buttons`, `ChoiceCard`, the note editor) refuses this the
    /// same way, and a control that tracks the mouse itself drains the drag
    /// through `nextEvent` before it ever reaches this method.
    ///
    /// The drag only starts once the pointer has actually travelled, so a
    /// press and release on the same spot is still delivered as a click.
    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            if !isKeyWindow {
                makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            dragAnchor = canMoveWindow(from: contentView?.hitTest(event.locationInWindow))
                ? event.locationInWindow
                : nil
        case .leftMouseDragged:
            if let anchor = dragAnchor,
               hypot(event.locationInWindow.x - anchor.x, event.locationInWindow.y - anchor.y) > 3 {
                dragAnchor = nil
                performDrag(with: event)
                return
            }
        case .leftMouseUp:
            dragAnchor = nil
        default:
            break
        }
        super.sendEvent(event)
    }

    /// Text being edited is never a drag handle: the field editor is an
    /// `NSTextView` that does not override the flag, and selecting a value by
    /// dragging through it has to keep working.
    private func canMoveWindow(from view: NSView?) -> Bool {
        guard let view else { return false }
        if view is NSTextField || view is NSTextView { return false }
        return view.mouseDownCanMoveWindow
    }

    override func keyDown(with event: NSEvent) {
        // Block action keys during cooldown
        if CooldownManager.shared.shouldBlockKey(event.keyCode) {
            return
        }

        if event.keyCode == KeyCode.escape {
            if ReportIssueOverlayManager.shared.isShowing {
                NotificationCenter.default.post(name: .dismissReportOverlay, object: nil)
            } else {
                NSApp.stopModal(withCode: .cancel)
            }
        } else {
            super.keyDown(with: event)
        }
    }

    override func cancelOperation(_ sender: Any?) {
        // Block ESC via cancelOperation during cooldown
        if CooldownManager.shared.isCoolingDown {
            return
        }
        if ReportIssueOverlayManager.shared.isShowing {
            NotificationCenter.default.post(name: .dismissReportOverlay, object: nil)
        } else {
            NSApp.stopModal(withCode: .cancel)
        }
    }
}
