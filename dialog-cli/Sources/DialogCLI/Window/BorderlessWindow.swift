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

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown && !isKeyWindow {
            makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        super.sendEvent(event)
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
