import SwiftUI
import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var debugMenu: NSMenu!
    private var contextMenu: NSMenu!
    private var snoozeObserver: AnyCancellable?
    private var isPresentingUpdateDecision = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        loadAppIcon()
        setupStatusItem()
        setupDebugMenu()
        setupContextMenu()
        observeSnooze()
        observeSnoozeEnd()
        observeProjectNotifications()
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

        let isOptionClick = event.modifierFlags.contains(.option)

        if isOptionClick {
            statusItem.menu = debugMenu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else if event.type == .rightMouseUp {
            statusItem.menu = contextMenu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            showSettingsWindow()
        }
    }

    // MARK: - Settings Window

    private func showSettingsWindow() {
        SettingsWindowController.shared.showWindow()
        checkForUpdatesAutomatically()
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

        let chooseItem = NSMenuItem(title: "Test Multiple Choice", action: nil, keyEquivalent: "")
        let chooseSubmenu = NSMenu()

        let chooseSingle = NSMenuItem(title: "Single Select", action: #selector(testChooseSingle), keyEquivalent: "")
        chooseSingle.target = self
        chooseSubmenu.addItem(chooseSingle)

        let chooseMulti = NSMenuItem(title: "Multi Select", action: #selector(testChooseMulti), keyEquivalent: "")
        chooseMulti.target = self
        chooseSubmenu.addItem(chooseMulti)

        let chooseMultiDesc = NSMenuItem(title: "Multi Select + Descriptions", action: #selector(testChooseMultiDescriptions), keyEquivalent: "")
        chooseMultiDesc.target = self
        chooseSubmenu.addItem(chooseMultiDesc)

        chooseItem.submenu = chooseSubmenu
        debugMenu.addItem(chooseItem)

        let textItem = NSMenuItem(title: "Test Text Input", action: nil, keyEquivalent: "")
        let textSubmenu = NSMenu()

        let textPlain = NSMenuItem(title: "Plain", action: #selector(testTextInput), keyEquivalent: "")
        textPlain.target = self
        textSubmenu.addItem(textPlain)

        let textPassword = NSMenuItem(title: "Password", action: #selector(testTextInputPassword), keyEquivalent: "")
        textPassword.target = self
        textSubmenu.addItem(textPassword)

        let textMarkdown = NSMenuItem(title: "Markdown", action: #selector(testTextInputMarkdown), keyEquivalent: "")
        textMarkdown.target = self
        textSubmenu.addItem(textMarkdown)

        textItem.submenu = textSubmenu
        debugMenu.addItem(textItem)

        let questionsItem = NSMenuItem(title: "Test Questions", action: nil, keyEquivalent: "")
        let questionsSubmenu = NSMenu()

        let questionsWizard = NSMenuItem(title: "Wizard", action: #selector(testQuestionsWizard), keyEquivalent: "")
        questionsWizard.target = self
        questionsSubmenu.addItem(questionsWizard)

        let questionsAccordion = NSMenuItem(title: "Accordion", action: #selector(testQuestionsAccordion), keyEquivalent: "")
        questionsAccordion.target = self
        questionsSubmenu.addItem(questionsAccordion)

        questionsItem.submenu = questionsSubmenu
        debugMenu.addItem(questionsItem)

        let notifyToolItem = NSMenuItem(title: "Test Notification", action: #selector(testNotifyTool), keyEquivalent: "4")
        notifyToolItem.target = self
        debugMenu.addItem(notifyToolItem)

        let notifyUpdateItem = NSMenuItem(title: "Test Update Notification", action: #selector(testNotifyUpdate), keyEquivalent: "5")
        notifyUpdateItem.target = self
        debugMenu.addItem(notifyUpdateItem)

        debugMenu.addItem(NSMenuItem.separator())

        let allItem = NSMenuItem(title: "Run All Tests", action: #selector(testAll), keyEquivalent: "a")
        allItem.target = self
        debugMenu.addItem(allItem)
    }

    private func setupContextMenu() {
        contextMenu = NSMenu()

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        contextMenu.addItem(settingsItem)

        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "u")
        updateItem.target = self
        contextMenu.addItem(updateItem)

        contextMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        contextMenu.addItem(quitItem)
    }

    // MARK: - Open Settings

    @objc private func openSettings() {
        showSettingsWindow()
    }

    // MARK: - Project Notifications

    private func observeProjectNotifications() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleProjectNotification(_:)),
            name: NSNotification.Name("com.consult-user-mcp.project"),
            object: nil
        )
    }

    @objc private func handleProjectNotification(_ notification: Notification) {
        guard let path = notification.userInfo?["path"] as? String else { return }
        DispatchQueue.main.async {
            ProjectManager.shared.addOrUpdate(path: path)
        }
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

    private func runDialogCli(
        command: String,
        json: String,
        clientName: String = "Debug",
        completion: ((String) -> Void)? = nil
    ) {
        let cliPath = dialogCliPath()

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: cliPath)
            process.arguments = [command, json]
            process.environment = ProcessInfo.processInfo.environment.merging(["MCP_CLIENT_NAME": clientName]) { _, new in new }

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

    private func showPaneNotification(title: String, body: String, sound: Bool = true, clientName: String = "Consult User MCP") {
        let payload: [String: Any] = [
            "body": body,
            "title": title,
            "sound": sound
        ]

        guard let json = encodeJSON(payload) else { return }
        runDialogCli(command: "notify", json: json, clientName: clientName)
    }

    private func encodeJSON(_ payload: [String: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }

    // MARK: - Test Actions

    @objc private func testConfirm() {
        let settings = DialogSettings.shared
        let json = """
        {"body":"This is a test confirmation dialog.\\n\\nDo you want to proceed with the test?","title":"Confirmation Test","confirmLabel":"Yes, proceed","cancelLabel":"Cancel","position":"\(settings.position.rawValue)"}
        """
        runDialogCli(command: "confirm", json: json)
    }

    @objc private func testChooseSingle() {
        let settings = DialogSettings.shared
        let json = """
        {"body":"Select your preferred option from the list below:","choices":["Option Alpha","Option Beta","Option Gamma","Option Delta"],"descriptions":["First choice with description","Second choice - recommended","Third alternative option","Fourth fallback option"],"allowMultiple":false,"position":"\(settings.position.rawValue)"}
        """
        runDialogCli(command: "choose", json: json)
    }

    @objc private func testChooseMulti() {
        let settings = DialogSettings.shared
        let json = """
        {"body":"Select one or more features to enable:","choices":["Authentication","Database","API Endpoints","Logging"],"allowMultiple":true,"position":"\(settings.position.rawValue)"}
        """
        runDialogCli(command: "choose", json: json)
    }

    @objc private func testChooseMultiDescriptions() {
        let settings = DialogSettings.shared
        let json = """
        {"body":"Select one or more features to enable:","choices":["Authentication","Database","API Endpoints","Logging"],"descriptions":["OAuth2 + JWT tokens","PostgreSQL with migrations","REST + GraphQL","Structured JSON output"],"allowMultiple":true,"position":"\(settings.position.rawValue)"}
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

    @objc private func testTextInputPassword() {
        let settings = DialogSettings.shared
        let json = """
        {"body":"Enter your API key:","title":"API Configuration","defaultValue":"","hidden":true,"position":"\(settings.position.rawValue)"}
        """
        runDialogCli(command: "textInput", json: json)
    }

    @objc private func testTextInputMarkdown() {
        let settings = DialogSettings.shared
        let json = """
        {"body":"Provide a **commit message** for the changes.\\n\\nUse `conventional commits` format (e.g. `feat:`, `fix:`).\\n\\nSee [docs](https://conventionalcommits.org) for details.","title":"Commit Message","defaultValue":"","hidden":false,"position":"\(settings.position.rawValue)"}
        """
        runDialogCli(command: "textInput", json: json)
    }

    @objc private func testQuestionsWizard() {
        let settings = DialogSettings.shared
        let json = """
        {"questions":[{"id":"language","question":"What programming language?","options":[{"label":"TypeScript","description":"Strongly typed JavaScript"},{"label":"Python","description":"Dynamic scripting language"},{"label":"Go","description":"Fast compiled language"}],"type":"choice","multiSelect":false},{"id":"framework","question":"Which framework?","options":[{"label":"Express","description":"Minimal Node.js framework"},{"label":"FastAPI","description":"Modern Python API framework"},{"label":"Gin","description":"High-performance Go framework"}],"type":"choice","multiSelect":false}],"mode":"wizard","position":"\(settings.position.rawValue)"}
        """
        runDialogCli(command: "questions", json: json)
    }

    @objc private func testQuestionsAccordion() {
        let settings = DialogSettings.shared
        let json = """
        {"questions":[{"id":"database","question":"Select database type:","options":[{"label":"PostgreSQL","description":"Advanced relational database"},{"label":"MongoDB","description":"Document-oriented NoSQL"},{"label":"Redis","description":"In-memory key-value store"}],"type":"choice","multiSelect":false},{"id":"auth","question":"Authentication method:","options":[{"label":"OAuth 2.0","description":"Third-party providers"},{"label":"JWT","description":"Stateless tokens"},{"label":"Session","description":"Server-side sessions"}],"type":"choice","multiSelect":true},{"id":"hosting","question":"Deployment platform:","options":[{"label":"AWS","description":"Amazon Web Services"},{"label":"Vercel","description":"Edge-first platform"},{"label":"Self-hosted","description":"Your own infrastructure"}],"type":"choice","multiSelect":false}],"mode":"accordion","position":"\(settings.position.rawValue)"}
        """
        runDialogCli(command: "questions", json: json)
    }

    @objc private func testNotifyTool() {
        showPaneNotification(
            title: "Notification Test",
            body: "This is a test notification from Consult User MCP.",
            sound: true,
            clientName: "Debug"
        )
    }

    @objc private func testNotifyUpdate() {
        guard let mockZipURL = URL(string: "https://github.com/doublej/consult-user-mcp/releases/latest") else { return }
        let release = UpdateManager.Release(version: "9.9.9-test", zipURL: mockZipURL)
        DialogSettings.shared.updateAvailable = release
        presentUpdateDecisionDialog(for: release)
    }

    @objc private func testAll() {
        testConfirm()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.testChooseSingle() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.testChooseMulti() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { self.testChooseMultiDescriptions() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { self.testTextInput() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.5) { self.testTextInputPassword() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 9.0) { self.testTextInputMarkdown() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.5) { self.testQuestionsWizard() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) { self.testQuestionsAccordion() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 13.5) { self.testNotifyTool() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 14.5) { self.testNotifyUpdate() }
    }

    // MARK: - Update

    @objc private func checkForUpdates() {
        performUpdateCheck(isAutomatic: false)
    }

    private func performUpdateCheck(isAutomatic: Bool) {
        if isAutomatic && !DialogSettings.shared.shouldAutoCheckForUpdates {
            return
        }

        UpdateManager.shared.checkForUpdatesWithDetails(
            includePrerelease: DialogSettings.shared.includePrereleaseUpdates
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let checkResult):
                    DialogSettings.shared.recordUpdateCheck(latestVersion: checkResult.remoteVersion)
                    DialogSettings.shared.updateAvailable = checkResult.release

                    guard let release = checkResult.release else {
                        if !isAutomatic {
                            self.showUpToDateAlert()
                        }
                        return
                    }

                    if isAutomatic && !DialogSettings.shared.shouldPromptForUpdate(version: release.version) {
                        return
                    }

                    self.presentUpdateDecisionDialog(for: release)
                case .failure(let error):
                    if !isAutomatic {
                        self.showAlert(title: "Update Check Failed", message: error.localizedDescription)
                    }
                }
            }
        }
    }

    private func presentUpdateDecisionDialog(for release: UpdateManager.Release) {
        if isPresentingUpdateDecision {
            return
        }
        isPresentingUpdateDecision = true

        let reminderLabel = DialogSettings.shared.updateReminderInterval.label
        let choices = [
            "Yes, update now",
            "Remind me again in \(reminderLabel)",
            "I'll do it manually later"
        ]
        let body = "Consult User MCP v\(release.version) is available. You have v\(UpdateManager.shared.currentVersion).\n\nHow do you want to proceed?"

        let payload: [String: Any] = [
            "body": body,
            "choices": choices,
            "allowMultiple": false,
            "position": DialogSettings.shared.position.rawValue
        ]

        guard let json = encodeJSON(payload) else {
            isPresentingUpdateDecision = false
            return
        }

        runDialogCli(command: "choose", json: json, clientName: "Consult User MCP") { [weak self] output in
            guard let self = self else { return }
            self.isPresentingUpdateDecision = false
            self.handleUpdateDecision(output: output, release: release)
        }
    }

    private func handleUpdateDecision(output: String, release: UpdateManager.Release) {
        guard let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            DialogSettings.shared.remindAboutUpdateUsingPreference()
            return
        }

        if let snoozed = json["snoozed"] as? Bool, snoozed {
            if let remaining = json["remainingSeconds"] as? Double {
                DialogSettings.shared.remindAboutUpdate(after: remaining)
            } else if let minutes = json["snoozeMinutes"] as? Double {
                DialogSettings.shared.remindAboutUpdate(after: minutes * 60)
            } else {
                DialogSettings.shared.remindAboutUpdateUsingPreference()
            }
            return
        }

        if let cancelled = json["cancelled"] as? Bool, cancelled {
            DialogSettings.shared.remindAboutUpdateUsingPreference()
            return
        }

        let answerValue = json["answer"]
        let answer: String?
        if let single = answerValue as? String {
            answer = single
        } else if let multiple = answerValue as? [String], let first = multiple.first {
            answer = first
        } else {
            answer = nil
        }

        switch answer {
        case "Yes, update now":
            DialogSettings.shared.clearUpdateReminderState()
            downloadAndInstall(release)
        case "Remind me again in \(DialogSettings.shared.updateReminderInterval.label)":
            DialogSettings.shared.remindAboutUpdateUsingPreference()
        case "Remind me again in 1 hour":
            DialogSettings.shared.remindAboutUpdate(hours: 1) // Backward-compat with older choice labels
        case "Remind me again in 24 hours":
            DialogSettings.shared.remindAboutUpdate(hours: 24) // Backward-compat with older choice labels
        case "I'll do it manually later":
            DialogSettings.shared.ignoreUpdate(version: release.version)
        default:
            DialogSettings.shared.remindAboutUpdateUsingPreference()
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

    private func checkForUpdatesAutomatically() {
        performUpdateCheck(isAutomatic: true)
    }

    // MARK: - Snooze Observer

    private func observeSnooze() {
        snoozeObserver = DialogSettings.shared.$snoozeRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusIcon()
            }
    }

    private func observeSnoozeEnd() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSnoozeEnd),
            name: .snoozeDidEnd,
            object: nil
        )
    }

    @objc private func handleSnoozeEnd() {
        let manager = SnoozedRequestsManager.shared
        guard manager.count > 0 else { return }

        let requests = manager.requests
        let count = requests.count
        let lines = requests.suffix(5).map { req in
            "\(req.clientName) (\(req.dialogType)): \(String(req.summary.prefix(80)))"
        }
        var body = lines.joined(separator: "\n")
        if count > 5 {
            body += "\n...and \(count - 5) more"
        }

        showPaneNotification(
            title: "Snooze Ended — \(count) Missed Dialog\(count == 1 ? "" : "s")",
            body: body,
            sound: true,
            clientName: "Consult User MCP"
        )

        manager.clear()
    }
}
