import SwiftUI
import AppKit
import Combine
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var debugMenu: NSMenu!
    private var snoozeObserver: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        loadAppIcon()
        setupStatusItem()
        setupPopover()
        setupDebugMenu()
        observeSnooze()
        setupNotifications()
        checkForUpdatesAutomatically()
    }

    // MARK: - App Icon

    private func loadAppIcon() {
        if let icnsURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: icnsURL) {
            NSApp.applicationIconImage = icon
        }
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateStatusIcon()
            button.action = #selector(handleClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
    }

    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }

        let isSnoozed = DialogSettings.shared.snoozeRemaining > 0
        let iconName = isSnoozed ? "moon.zzz.fill" : "bubble.left.and.bubble.right"

        if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: isSnoozed ? "Snooze Active" : "Settings") {
            image.isTemplate = !isSnoozed
            button.image = image
        }
        button.contentTintColor = isSnoozed ? .orange : nil
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            statusItem.menu = debugMenu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            togglePopover()
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = DialogSettings.shared.animationsEnabled

        let hostingController = NSHostingController(rootView: SettingsView())
        hostingController.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hostingController
    }

    private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
            checkForUpdatesAutomatically()
        }
    }

    // MARK: - Debug Menu

    private func setupDebugMenu() {
        debugMenu = NSMenu()

        let headerItem = NSMenuItem(title: "Debug Dialogs", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        debugMenu.addItem(headerItem)
        debugMenu.addItem(NSMenuItem.separator())

        let confirmItem = NSMenuItem(title: "Test Confirmation", action: #selector(testConfirm), keyEquivalent: "1")
        confirmItem.target = self
        debugMenu.addItem(confirmItem)

        let chooseItem = NSMenuItem(title: "Test Multiple Choice", action: #selector(testChoose), keyEquivalent: "2")
        chooseItem.target = self
        debugMenu.addItem(chooseItem)

        let textItem = NSMenuItem(title: "Test Text Input", action: #selector(testTextInput), keyEquivalent: "3")
        textItem.target = self
        debugMenu.addItem(textItem)

        let notifyItem = NSMenuItem(title: "Test Notification", action: #selector(testNotify), keyEquivalent: "4")
        notifyItem.target = self
        debugMenu.addItem(notifyItem)

        debugMenu.addItem(NSMenuItem.separator())

        let allItem = NSMenuItem(title: "Run All Tests", action: #selector(testAll), keyEquivalent: "a")
        allItem.target = self
        debugMenu.addItem(allItem)

        debugMenu.addItem(NSMenuItem.separator())

        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "u")
        updateItem.target = self
        debugMenu.addItem(updateItem)

        debugMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        debugMenu.addItem(quitItem)
    }

    // MARK: - Dialog CLI (preserved logic)

    private func dialogCliPath() -> String {
        let fm = FileManager.default

        // 1. Check Resources folder (bundled app)
        if let resourcePath = Bundle.main.resourcePath {
            let bundledPath = (resourcePath as NSString).appendingPathComponent("dialog-cli/dialog-cli")
            if fm.fileExists(atPath: bundledPath) { return bundledPath }
        }

        // 2. Check dev build path (swift build)
        if let execPath = Bundle.main.executablePath {
            var devPath = (execPath as NSString).deletingLastPathComponent
            if devPath.contains("/.build/") {
                while !devPath.hasSuffix("/macos-app") && devPath.count > 1 {
                    devPath = (devPath as NSString).deletingLastPathComponent
                }
                let cliPath = (devPath as NSString)
                    .deletingLastPathComponent
                    .appending("/dialog-cli/.build/debug/DialogCLI")
                if fm.fileExists(atPath: cliPath) { return cliPath }
            }
        }

        // 3. Fallback
        return "/usr/local/bin/dialog-cli"
    }

    private func runDialogCli(command: String, json: String, completion: ((String) -> Void)? = nil) {
        let cliPath = dialogCliPath()

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: cliPath)
            process.arguments = [command, json]
            process.environment = ProcessInfo.processInfo.environment.merging(["MCP_CLIENT_NAME": "Debug"]) { _, new in new }

            let outPipe = Pipe()
            process.standardOutput = outPipe

            do {
                try process.run()
                process.waitUntilExit()

                let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outData, encoding: .utf8) ?? ""

                DispatchQueue.main.async {
                    completion?(output)
                }
            } catch {
                // Error ignored - debug menu tests only
            }
        }
    }

    // MARK: - Test Actions

    @objc private func testConfirm() {
        let settings = DialogSettings.shared
        let json = """
        {"body":"This is a test confirmation dialog.\\n\\nDo you want to proceed with the test?","title":"Confirmation Test","confirmLabel":"Yes, proceed","cancelLabel":"Cancel","position":"\(settings.position.rawValue)"}
        """
        runDialogCli(command: "confirm", json: json)
    }

    @objc private func testChoose() {
        let settings = DialogSettings.shared
        let json = """
        {"body":"Select your preferred option from the list below:","choices":["Option Alpha","Option Beta","Option Gamma","Option Delta"],"descriptions":["First choice with description","Second choice - recommended","Third alternative option","Fourth fallback option"],"allowMultiple":false,"position":"\(settings.position.rawValue)"}
        """
        runDialogCli(command: "choose", json: json)
    }

    @objc private func testTextInput() {
        let settings = DialogSettings.shared
        let json = """
        {"body":"Enter your feedback or comments:","title":"Text Input Test","defaultValue":"Sample text...","hidden":false,"position":"\(settings.position.rawValue)"}
        """
        runDialogCli(command: "textInput", json: json)
    }

    @objc private func testNotify() {
        let json = """
        {"body":"This is a test notification from Consult User MCP.","title":"Notification Test","sound":true}
        """
        runDialogCli(command: "notify", json: json)
    }

    @objc private func testAll() {
        testConfirm()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.testChoose() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.testTextInput() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { self.testNotify() }
    }

    // MARK: - Update

    @objc private func checkForUpdates() {
        UpdateManager.shared.checkForUpdates { [weak self] result in
            DispatchQueue.main.async {
                self?.handleUpdateResult(result)
            }
        }
    }

    private func handleUpdateResult(_ result: Result<UpdateManager.Release?, Error>) {
        switch result {
        case .success(let release):
            if let release = release {
                showUpdateAvailableAlert(release)
            } else {
                showUpToDateAlert()
            }
        case .failure(let error):
            showAlert(title: "Update Check Failed", message: error.localizedDescription)
        }
    }

    private func showUpdateAvailableAlert(_ release: UpdateManager.Release) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "Version \(release.version) is available. You have \(UpdateManager.shared.currentVersion)."
        alert.addButton(withTitle: "Update")
        alert.addButton(withTitle: "Later")
        alert.alertStyle = .informational

        if alert.runModal() == .alertFirstButtonReturn {
            downloadAndInstall(release)
        }
    }

    private func showUpToDateAlert() {
        showAlert(title: "Up to Date", message: "You're running the latest version (\(UpdateManager.shared.currentVersion)).")
    }

    private func downloadAndInstall(_ release: UpdateManager.Release) {
        let alert = NSAlert()
        alert.messageText = "Downloading Update..."
        alert.informativeText = "Please wait while the update downloads."
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational
        alert.buttons.first?.isHidden = true

        let window = alert.window
        alert.beginSheetModal(for: NSApp.keyWindow ?? window) { _ in }

        UpdateManager.shared.downloadUpdate(from: release.zipURL) { [weak self] result in
            DispatchQueue.main.async {
                NSApp.keyWindow?.endSheet(window)
                self?.handleDownloadResult(result)
            }
        }
    }

    private func handleDownloadResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let zipPath):
            do {
                try UpdateManager.shared.installUpdate(zipPath: zipPath)
            } catch {
                showAlert(title: "Install Failed", message: error.localizedDescription)
            }
        case .failure(let error):
            showAlert(title: "Download Failed", message: error.localizedDescription)
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational
        alert.runModal()
    }

    // MARK: - Auto Update Check

    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func checkForUpdatesAutomatically() {
        guard DialogSettings.shared.shouldAutoCheckForUpdates else { return }

        UpdateManager.shared.checkForUpdatesWithDetails { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let checkResult):
                    DialogSettings.shared.recordUpdateCheck(latestVersion: checkResult.remoteVersion)
                    DialogSettings.shared.updateAvailable = checkResult.release

                    if let release = checkResult.release {
                        self?.showUpdateNotification(version: release.version)
                    }
                case .failure:
                    break
                }
            }
        }
    }

    private func showUpdateNotification(version: String) {
        let content = UNMutableNotificationContent()
        content.title = "Update Available"
        content.body = "Consult User MCP v\(version) is available. Click to update."
        content.sound = .default
        content.categoryIdentifier = "UPDATE_AVAILABLE"

        let request = UNNotificationRequest(identifier: "update-available", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Snooze Observer

    private func observeSnooze() {
        snoozeObserver = DialogSettings.shared.$snoozeRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusIcon()
            }
    }
}

// MARK: - Notification Delegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.identifier == "update-available" {
            DispatchQueue.main.async { [weak self] in
                if let release = DialogSettings.shared.updateAvailable {
                    self?.showUpdateAvailableAlert(release)
                }
            }
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
