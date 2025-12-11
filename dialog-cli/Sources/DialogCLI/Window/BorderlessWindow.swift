import AppKit

// MARK: - Borderless Window that Accepts Keyboard

class BorderlessWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC key
            NSApp.stopModal(withCode: .cancel)
        } else {
            super.keyDown(with: event)
        }
    }

    override func cancelOperation(_ sender: Any?) {
        NSApp.stopModal(withCode: .cancel)
    }
}
