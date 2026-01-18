import SwiftUI
import AppKit
import Combine

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

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        debugMenu.addItem(quitItem)
    }

    // MARK: - Dialog CLI (preserved logic)

    private func dialogCliPath() -> String {
        let fm = FileManager.default
        let execDir = (Bundle.main.executablePath ?? "") as NSString

        // 1. Check same folder as executable (bundled app)
        let bundledPath = execDir.deletingLastPathComponent + "/dialog-cli"
        if fm.fileExists(atPath: bundledPath) { return bundledPath }

        // 2. Check dev build path (swift build)
        var devPath = execDir.deletingLastPathComponent as String
        if devPath.contains("/.build/") {
            while !devPath.hasSuffix("/macos-app") && devPath.count > 1 {
                devPath = (devPath as NSString).deletingLastPathComponent
            }
            devPath = (devPath as NSString).deletingLastPathComponent + "/dialog-cli/dialog-cli"
            if fm.fileExists(atPath: devPath) { return devPath }
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
        {"message":"This is a test confirmation dialog.\\n\\nDo you want to proceed with the test?","title":"Confirmation Test","confirmLabel":"Yes, proceed","cancelLabel":"Cancel","position":"\(settings.position.rawValue)"}
        """
        runDialogCli(command: "confirm", json: json)
    }

    @objc private func testChoose() {
        let settings = DialogSettings.shared
        let json = """
        {"prompt":"Select your preferred option from the list below:","choices":["Option Alpha","Option Beta","Option Gamma","Option Delta"],"descriptions":["First choice with description","Second choice - recommended","Third alternative option","Fourth fallback option"],"allowMultiple":false,"position":"\(settings.position.rawValue)"}
        """
        runDialogCli(command: "choose", json: json)
    }

    @objc private func testTextInput() {
        let settings = DialogSettings.shared
        let json = """
        {"prompt":"Enter your feedback or comments:","title":"Text Input Test","defaultValue":"Sample text...","hidden":false,"position":"\(settings.position.rawValue)"}
        """
        runDialogCli(command: "textInput", json: json)
    }

    @objc private func testNotify() {
        let json = """
        {"message":"This is a test notification from Consult User MCP.","title":"Notification Test","subtitle":"Debug Mode","sound":true}
        """
        runDialogCli(command: "notify", json: json)
    }

    @objc private func testAll() {
        testConfirm()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.testChoose() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.testTextInput() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { self.testNotify() }
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
