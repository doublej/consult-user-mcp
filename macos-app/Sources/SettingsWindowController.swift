import SwiftUI
import AppKit

final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?
    private let minSize = NSSize(width: 680, height: 600)

    private let frameKey = "SettingsWindowFrame"

    private init() {}

    func showWindow(section: SettingsSection? = nil) {
        if let section = section {
            DialogSettings.shared.pendingSettingsSection = section
        }

        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let contentView = MainSettingsView()
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Consult User MCP"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.minSize = minSize
        window.setContentSize(minSize)

        restoreFrame(window)

        window.delegate = WindowDelegate.shared
        window.makeKeyAndOrderFront(nil)

        self.window = window
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeWindow() {
        window?.close()
        window = nil
    }

    private func restoreFrame(_ window: NSWindow) {
        if let frameString = UserDefaults.standard.string(forKey: frameKey) {
            let frame = NSRectFromString(frameString)
            if frame.width >= minSize.width && frame.height >= minSize.height {
                window.setFrame(frame, display: true)
                return
            }
        }
        window.center()
    }

    func saveFrame() {
        guard let window = window else { return }
        let frameString = NSStringFromRect(window.frame)
        UserDefaults.standard.set(frameString, forKey: frameKey)
    }
}

// MARK: - Window Delegate

private final class WindowDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowDelegate()

    func windowWillClose(_ notification: Notification) {
        SettingsWindowController.shared.saveFrame()
    }

    func windowDidResize(_ notification: Notification) {
        SettingsWindowController.shared.saveFrame()
    }

    func windowDidMove(_ notification: Notification) {
        SettingsWindowController.shared.saveFrame()
    }
}
