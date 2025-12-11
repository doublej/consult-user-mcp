import SwiftUI

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

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if let icnsURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: icnsURL) {
            NSApp.applicationIconImage = icon
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bubble.left.and.bubble.right", accessibilityDescription: "Speak Settings")
            button.target = self
            button.action = #selector(handleClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 540)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(rootView: SettingsView())

        setupDebugMenu()
        setupPulseNotificationObserver()
    }

    private func setupPulseNotificationObserver() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handlePulseNotification),
            name: NSNotification.Name("com.consult-user-mcp.pulse"),
            object: nil
        )
    }

    @objc private func handlePulseNotification(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.testShader()
        }
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

        let shaderItem = NSMenuItem(title: "Test Shader Pulse", action: #selector(testShader), keyEquivalent: "6")
        shaderItem.target = self
        debugMenu?.addItem(shaderItem)

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
        // Get the executable path and navigate to sibling dialog-cli folder
        let executablePath = Bundle.main.executablePath ?? ""

        // From: /path/to/consult-user-mcp/macos-app/.build/debug/SpeakSettings
        // To:   /path/to/consult-user-mcp/dialog-cli/dialog-cli
        var path = (executablePath as NSString).deletingLastPathComponent

        // Go up from .build/debug or .build/release
        if path.contains("/.build/") {
            while !path.hasSuffix("/macos-app") && path.count > 1 {
                path = (path as NSString).deletingLastPathComponent
            }
            path = (path as NSString).deletingLastPathComponent + "/dialog-cli/dialog-cli"
        }

        if FileManager.default.fileExists(atPath: path) {
            return path
        }

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

    private var shaderWindow: ShaderOverlayWindow?

    @objc func testShader() {
        guard let button = statusItem?.button,
              let screen = NSScreen.main else { return }

        let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero
        let originX = (buttonFrame.midX) / screen.frame.width
        let originY = 1.0 - (buttonFrame.midY / screen.frame.height)

        shaderWindow = ShaderOverlayWindow(origin: CGPoint(x: originX, y: originY))
        shaderWindow?.makeKeyAndOrderFront(nil)
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
