import SwiftUI
import Combine

@main
struct ConsultUserMCPApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var debugMenu: NSMenu?
    private var snoozeObserver: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if let icnsURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: icnsURL) {
            NSApp.applicationIconImage = icon
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if let image = NSImage(systemSymbolName: "bubble.left.and.bubble.right", accessibilityDescription: "Speak Settings") {
                image.isTemplate = true
                button.image = image
            }
            button.target = self
            button.action = #selector(handleClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover = NSPopover()
        popover?.behavior = .transient
        popover?.animates = true
        let hostingController = NSHostingController(rootView: SettingsView())
        hostingController.sizingOptions = [.preferredContentSize]
        popover?.contentViewController = hostingController

        setupDebugMenu()
        setupSnoozeObserver()
    }

    private func setupSnoozeObserver() {
        snoozeObserver = DialogSettings.shared.$snoozeRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] remaining in
                self?.updateStatusIcon(snoozed: remaining > 0)
            }
    }

    private func updateStatusIcon(snoozed: Bool) {
        guard let button = statusItem?.button else { return }
        let iconName = snoozed ? "moon.zzz.fill" : "bubble.left.and.bubble.right"
        if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: snoozed ? "Snooze Active" : "Settings") {
            image.isTemplate = !snoozed
            button.image = image
        }
        button.contentTintColor = snoozed ? .orange : nil
    }

    private func setupDebugMenu() {
        debugMenu = NSMenu()

        let headerItem = NSMenuItem(title: "Debug Dialogs", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        debugMenu?.addItem(headerItem)
        debugMenu?.addItem(NSMenuItem.separator())

        let confirmItem = NSMenuItem(title: "Test Confirmation", action: #selector(testConfirm), keyEquivalent: "1")
        confirmItem.target = self
        debugMenu?.addItem(confirmItem)

        let chooseItem = NSMenuItem(title: "Test Multiple Choice", action: #selector(testChoose), keyEquivalent: "2")
        chooseItem.target = self
        debugMenu?.addItem(chooseItem)

        let textItem = NSMenuItem(title: "Test Text Input", action: #selector(testTextInput), keyEquivalent: "3")
        textItem.target = self
        debugMenu?.addItem(textItem)

        let notifyItem = NSMenuItem(title: "Test Notification", action: #selector(testNotify), keyEquivalent: "4")
        notifyItem.target = self
        debugMenu?.addItem(notifyItem)

        let ttsItem = NSMenuItem(title: "Test TTS", action: #selector(testTts), keyEquivalent: "5")
        ttsItem.target = self
        debugMenu?.addItem(ttsItem)

        debugMenu?.addItem(NSMenuItem.separator())

        let allItem = NSMenuItem(title: "Run All Tests", action: #selector(testAll), keyEquivalent: "a")
        allItem.target = self
        debugMenu?.addItem(allItem)

        debugMenu?.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        debugMenu?.addItem(quitItem)
    }

    @objc func handleClick(sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            if let menu = debugMenu {
                statusItem?.menu = menu
                statusItem?.button?.performClick(nil)
                statusItem?.menu = nil
            }
        } else {
            togglePopover()
        }
    }

    @objc func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Dialog CLI Path

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
        print("Using dialog-cli at: \(cliPath)")
        print("Running: \(command) with JSON: \(json)")

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: cliPath)
            process.arguments = [command, json]
            process.environment = ProcessInfo.processInfo.environment.merging(["MCP_CLIENT_NAME": "Debug"]) { _, new in new }

            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe

            do {
                try process.run()
                process.waitUntilExit()

                let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outData, encoding: .utf8) ?? ""
                let errOutput = String(data: errData, encoding: .utf8) ?? ""

                DispatchQueue.main.async {
                    if !errOutput.isEmpty {
                        print("Dialog stderr: \(errOutput)")
                    }
                    print("Dialog result: \(output)")
                    completion?(output)
                }
            } catch {
                DispatchQueue.main.async {
                    print("Dialog error: \(error)")
                }
            }
        }
    }

    // MARK: - Test Actions

    @objc func testConfirm() {
        let settings = DialogSettings.shared
        let json = """
        {"message":"This is a test confirmation dialog.\\n\\nDo you want to proceed with the test?","title":"Confirmation Test","confirmLabel":"Yes, proceed","cancelLabel":"Cancel","position":"\(settings.position.rawValue)"}
        """
        runDialogCli(command: "confirm", json: json)
    }

    @objc func testChoose() {
        let settings = DialogSettings.shared
        let json = """
        {"prompt":"Select your preferred option from the list below:","choices":["Option Alpha","Option Beta","Option Gamma","Option Delta"],"descriptions":["First choice with description","Second choice - recommended","Third alternative option","Fourth fallback option"],"allowMultiple":false,"position":"\(settings.position.rawValue)"}
        """
        runDialogCli(command: "choose", json: json)
    }

    @objc func testTextInput() {
        let settings = DialogSettings.shared
        let json = """
        {"prompt":"Enter your feedback or comments:","title":"Text Input Test","defaultValue":"Sample text...","hidden":false,"position":"\(settings.position.rawValue)"}
        """
        runDialogCli(command: "textInput", json: json)
    }

    @objc func testNotify() {
        let json = """
        {"message":"This is a test notification from Consult User MCP.","title":"Notification Test","subtitle":"Debug Mode","sound":true}
        """
        runDialogCli(command: "notify", json: json)
    }

    @objc func testTts() {
        let settings = DialogSettings.shared
        let json = """
        {"text":"Hello! This is a test of the speech synthesis feature.","voice":null,"rate":\(Int(settings.speechRate))}
        """
        runDialogCli(command: "tts", json: json)
    }

    @objc func testAll() {
        testConfirm()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.testChoose()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.testTextInput()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            self.testNotify()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.testTts()
        }
    }
}
