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
        if event.keyCode == KeyCode.escape {
            NSApp.stopModal(withCode: .cancel)
        } else {
            super.keyDown(with: event)
        }
    }

    override func cancelOperation(_ sender: Any?) {
        NSApp.stopModal(withCode: .cancel)
    }
}
