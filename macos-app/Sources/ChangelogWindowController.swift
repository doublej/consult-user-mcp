import SwiftUI
import AppKit

final class ChangelogWindowController {
    static let shared = ChangelogWindowController()

    fileprivate var window: NSWindow?
    fileprivate var onDismiss: (() -> Void)?
    private let frameKey = "ChangelogWindowFrame"
    private let windowSize = NSSize(width: 480, height: 500)
    private let minSize = NSSize(width: 480, height: 400)

    private init() {}

    var isOpen: Bool { window != nil }

    func showWindow(
        currentVersion: String,
        targetVersion: String,
        release: UpdateManager.Release? = nil,
        expandSections: Bool = false,
        onDismiss: (() -> Void)? = nil
    ) {
        // Always recreate to reflect new parameters
        window?.close()

        NSApp.setActivationPolicy(.regular)

        let view = ChangelogView(
            currentVersion: currentVersion,
            targetVersion: targetVersion,
            expandSections: expandSections,
            showUpdateButton: release != nil,
            onUpdate: { [weak self] in
                guard let release else { return }
                self?.triggerUpdate(release)
            },
            onDismiss: { [weak self] in self?.window?.close() }
        )

        self.onDismiss = onDismiss

        let hostingController = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "What's New"
        window.styleMask = [.titled, .closable, .resizable]
        window.minSize = minSize
        window.setContentSize(windowSize)

        restoreFrame(window)

        window.delegate = ChangelogWindowDelegate.shared
        window.makeKeyAndOrderFront(nil)

        self.window = window
        NSApp.activate(ignoringOtherApps: true)
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
        guard let window else { return }
        UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: frameKey)
    }

    private func triggerUpdate(_ release: UpdateManager.Release) {
        onDismiss = nil // Don't fire reminder — user chose to update
        window?.close()

        let settings = DialogSettings.shared
        settings.updateDownloadProgress = 0
        settings.updateStatus = "Downloading..."

        UpdateManager.shared.downloadUpdate(
            from: release.zipURL,
            progress: { progress in settings.updateDownloadProgress = progress },
            completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let zipPath):
                        settings.updateStatus = "Installing..."
                        try? UpdateManager.shared.installUpdate(zipPath: zipPath)
                    case .failure:
                        settings.updateDownloadProgress = nil
                        settings.updateStatus = nil
                    }
                }
            }
        )
    }
}

// MARK: - Window Delegate

private final class ChangelogWindowDelegate: NSObject, NSWindowDelegate {
    static let shared = ChangelogWindowDelegate()

    func windowWillClose(_ notification: Notification) {
        let controller = ChangelogWindowController.shared
        controller.saveFrame()

        let callback = controller.onDismiss
        controller.window = nil
        controller.onDismiss = nil

        callback?()

        if !SettingsWindowController.shared.isOpen {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    func windowDidResize(_ notification: Notification) {
        ChangelogWindowController.shared.saveFrame()
    }

    func windowDidMove(_ notification: Notification) {
        ChangelogWindowController.shared.saveFrame()
    }
}
