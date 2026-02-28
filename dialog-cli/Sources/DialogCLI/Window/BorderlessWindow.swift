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
