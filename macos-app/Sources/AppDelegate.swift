import SwiftUI
import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var debugMenu: NSMenu!
    private var contextMenu: NSMenu!
    private var snoozeObserver: AnyCancellable?
    private var updateObserver: AnyCancellable?
    private var isPresentingUpdateDecision = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        loadAppIcon()
        setupStatusItem()
        setupDebugMenu()
        setupContextMenu()
        observeSnooze()
        observeSnoozeEnd()
        observeUpdateAvailable()
        observeProjectNotifications()
        checkBasePromptUpdate()
        checkForUpdatesAutomatically()
        TweakBroadcastServer.shared.start()
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
        let hasUpdate = DialogSettings.shared.updateAvailable != nil
        let iconName = isSnoozed ? "moon.zzz.fill" : "bubble.left.and.bubble.right"

        guard let baseImage = NSImage(systemSymbolName: iconName, accessibilityDescription: isSnoozed ? "Snooze Active" : "Settings") else { return }

        if hasUpdate && !isSnoozed {
            button.image = addBadgeDot(to: baseImage)
            button.contentTintColor = nil
        } else {
            baseImage.isTemplate = !isSnoozed
            button.image = baseImage
            button.contentTintColor = isSnoozed ? .orange : nil
        }
    }

    private func addBadgeDot(to image: NSImage) -> NSImage {
        let size = image.size
        let badged = NSImage(size: size, flipped: false) { rect in
            // Draw base image tinted for menu bar (adapts to light/dark mode)
            NSColor.labelColor.set()
            image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
            rect.fill(using: .sourceAtop)

            let dotSize: CGFloat = 5
            let dotRect = NSRect(x: size.width - dotSize - 0.5, y: size.height - dotSize - 0.5, width: dotSize, height: dotSize)
            NSColor.systemOrange.setFill()
            NSBezierPath(ovalIn: dotRect).fill()

            return true
        }
        badged.isTemplate = false
        return badged
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
        } else if DialogSettings.shared.updateAvailable != nil {
            showSettingsWindow(section: .updates)
        } else {
            showSettingsWindow()
        }
    }

    // MARK: - Settings Window

    private func showSettingsWindow(section: SettingsSection? = nil) {
        SettingsWindowController.shared.showWindow(section: section)
        checkForUpdatesAutomatically()
    }

    // MARK: - Debug Menu

    private func addDebugMenuItem(_ menu: NSMenu, title: String, action: Selector, key: String = "") {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
    }

    private func setupDebugMenu() {
        debugMenu = NSMenu()

        let headerItem = NSMenuItem(title: "Debug Dialogs", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        debugMenu.addItem(headerItem)
        debugMenu.addItem(NSMenuItem.separator())

        addDebugMenuItem(debugMenu, title: "Test Confirmation", action: #selector(testConfirm), key: "1")

        let chooseItem = NSMenuItem(title: "Test Multiple Choice", action: nil, keyEquivalent: "")
        let chooseSubmenu = NSMenu()
        addDebugMenuItem(chooseSubmenu, title: "Single Select", action: #selector(testChooseSingle))
        addDebugMenuItem(chooseSubmenu, title: "With Descriptions", action: #selector(testChooseWithDescriptions))
        addDebugMenuItem(chooseSubmenu, title: "Multi Select", action: #selector(testChooseMulti))
        chooseItem.submenu = chooseSubmenu
        debugMenu.addItem(chooseItem)

        let textItem = NSMenuItem(title: "Test Text Input", action: nil, keyEquivalent: "")
        let textSubmenu = NSMenu()
        addDebugMenuItem(textSubmenu, title: "Plain", action: #selector(testTextInput))
        addDebugMenuItem(textSubmenu, title: "Password", action: #selector(testTextInputPassword))
        addDebugMenuItem(textSubmenu, title: "Markdown", action: #selector(testTextInputMarkdown))
        textItem.submenu = textSubmenu
        debugMenu.addItem(textItem)

        let questionsItem = NSMenuItem(title: "Test Questions", action: nil, keyEquivalent: "")
        let questionsSubmenu = NSMenu()
        addDebugMenuItem(questionsSubmenu, title: "Wizard", action: #selector(testQuestionsWizard))
        addDebugMenuItem(questionsSubmenu, title: "Wizard Mixed", action: #selector(testQuestionsWizardMixed))
        addDebugMenuItem(questionsSubmenu, title: "Accordion", action: #selector(testQuestionsAccordion))
        addDebugMenuItem(questionsSubmenu, title: "Accordion Mixed", action: #selector(testQuestionsAccordionMixed))
        questionsItem.submenu = questionsSubmenu
        debugMenu.addItem(questionsItem)

        addDebugMenuItem(debugMenu, title: "Test Tweak", action: #selector(testTweak), key: "6")
        addDebugMenuItem(debugMenu, title: "Test Notification", action: #selector(testNotifyTool), key: "4")
        addDebugMenuItem(debugMenu, title: "Test Update Notification", action: #selector(testNotifyUpdate), key: "5")

        debugMenu.addItem(NSMenuItem.separator())

        addDebugMenuItem(debugMenu, title: "Run All Tests", action: #selector(testAll), key: "a")
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
        clientName: String? = nil,
        projectPath: String? = nil,
        completion: ((String) -> Void)? = nil
    ) {
        let cliPath = dialogCliPath()

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: cliPath)
            process.arguments = [command, json]
            var env: [String: String] = [:]
            if let clientName = clientName {
                env["MCP_CLIENT_NAME"] = clientName
            }
            if let projectPath = projectPath {
                env["MCP_PROJECT_PATH"] = projectPath
            }
            process.environment = ProcessInfo.processInfo.environment.merging(env) { _, new in new }

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

    private func projectRoot() -> String? {
        // #filePath resolves at compile time → .../macos-app/Sources/AppDelegate.swift
        let sourceDir = (#filePath as NSString).deletingLastPathComponent // Sources/
        let macosApp = (sourceDir as NSString).deletingLastPathComponent // macos-app/
        let root = (macosApp as NSString).deletingLastPathComponent // project root
        guard FileManager.default.fileExists(atPath: "\(root)/test-cases/cases") else { return nil }
        return root
    }

    private func loadTestCase(category: String, name: String) -> (json: String, projectPath: String?)? {
        guard let root = projectRoot() else { return nil }
        let filePath = "\(root)/test-cases/cases/\(category)/\(name).json"
        guard let data = FileManager.default.contents(atPath: filePath),
              let json = String(data: data, encoding: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        let projectPath = dict["projectPath"] as? String
        return (json: json, projectPath: projectPath)
    }

    // MARK: - Test Actions

    @objc private func testConfirm() {
        guard let tc = loadTestCase(category: "confirm", name: "basic") else { return }
        runDialogCli(command: "confirm", json: tc.json, projectPath: tc.projectPath)
    }

    @objc private func testChooseSingle() {
        guard let tc = loadTestCase(category: "choose", name: "single-select") else { return }
        runDialogCli(command: "choose", json: tc.json, projectPath: tc.projectPath)
    }

    @objc private func testChooseWithDescriptions() {
        guard let tc = loadTestCase(category: "choose", name: "with-descriptions") else { return }
        runDialogCli(command: "choose", json: tc.json, projectPath: tc.projectPath)
    }

    @objc private func testChooseMulti() {
        guard let tc = loadTestCase(category: "choose", name: "multi-select") else { return }
        runDialogCli(command: "choose", json: tc.json, projectPath: tc.projectPath)
    }

    @objc private func testTextInput() {
        guard let tc = loadTestCase(category: "text-input", name: "basic") else { return }
        runDialogCli(command: "textInput", json: tc.json, projectPath: tc.projectPath)
    }

    @objc private func testTextInputPassword() {
        guard let tc = loadTestCase(category: "text-input", name: "password") else { return }
        runDialogCli(command: "textInput", json: tc.json, projectPath: tc.projectPath)
    }

    @objc private func testTextInputMarkdown() {
        guard let tc = loadTestCase(category: "text-input", name: "markdown") else { return }
        runDialogCli(command: "textInput", json: tc.json, projectPath: tc.projectPath)
    }

    @objc private func testQuestionsWizard() {
        guard let tc = loadTestCase(category: "questions", name: "wizard-basic") else { return }
        runDialogCli(command: "questions", json: tc.json, projectPath: tc.projectPath)
    }

    @objc private func testQuestionsWizardMixed() {
        guard let tc = loadTestCase(category: "questions", name: "wizard-mixed") else { return }
        runDialogCli(command: "questions", json: tc.json, projectPath: tc.projectPath)
    }

    @objc private func testQuestionsAccordion() {
        guard let tc = loadTestCase(category: "questions", name: "accordion-basic") else { return }
        runDialogCli(command: "questions", json: tc.json, projectPath: tc.projectPath)
    }

    @objc private func testQuestionsAccordionMixed() {
        guard let tc = loadTestCase(category: "questions", name: "accordion-mixed") else { return }
        runDialogCli(command: "questions", json: tc.json, projectPath: tc.projectPath)
    }

    @objc private func testTweak() {
        // Copy companion CSS to /tmp so tweak can find it
        if let root = projectRoot() {
            let src = "\(root)/test-cases/cases/tweak/basic.css"
            let dst = "/tmp/tweak-test.css"
            try? FileManager.default.removeItem(atPath: dst)
            try? FileManager.default.copyItem(atPath: src, toPath: dst)
        }
        guard let tc = loadTestCase(category: "tweak", name: "basic") else { return }
        runDialogCli(command: "tweak", json: tc.json, projectPath: tc.projectPath)
    }

    @objc private func testNotifyTool() {
        guard let tc = loadTestCase(category: "notify", name: "basic") else { return }
        runDialogCli(command: "notify", json: tc.json, projectPath: tc.projectPath)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { self.testChooseWithDescriptions() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { self.testChooseMulti() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { self.testTextInput() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.5) { self.testTextInputPassword() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 9.0) { self.testTextInputMarkdown() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.5) { self.testQuestionsWizard() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) { self.testQuestionsAccordion() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 13.5) { self.testTweak() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) { self.testNotifyTool() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 16.0) { self.testNotifyUpdate() }
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

    // MARK: - Base Prompt Update Check

    private func checkBasePromptUpdate() {
        // Targets with an outdated versioned prompt
        let outdatedTargets = InstallTarget.allCases.filter { target in
            target.supportsBasePrompt && ClaudeMdInstaller.isUpdateAvailable(for: target)
        }

        // Targets with a file but no prompt detected at all
        let missingTargets = InstallTarget.allCases.filter { target in
            target.supportsBasePrompt
                && ClaudeMdInstaller.detectExisting(for: target)
                && ClaudeMdInstaller.detectInstalledInfo(for: target) == nil
        }

        if !outdatedTargets.isEmpty {
            promptOutdatedUpdate(targets: outdatedTargets)
        } else if !missingTargets.isEmpty {
            promptMissingInstall(targets: missingTargets)
        }
    }

    private func promptOutdatedUpdate(targets: [InstallTarget]) {
        let targetNames = targets.map(\.displayName).joined(separator: " and ")
        let installedVersion = targets.compactMap { ClaudeMdInstaller.detectInstalledInfo(for: $0)?.version }.first ?? "?"

        let body = "The usage hints in your \(targetNames) instructions are outdated (v\(installedVersion) → v\(ClaudeMdInstaller.bundledVersion)).\n\nWould you like to update them now?"

        let payload: [String: Any] = [
            "body": body,
            "title": "Usage Hints Update",
            "confirmLabel": "Update now",
            "cancelLabel": "Skip",
            "position": DialogSettings.shared.position.rawValue
        ]

        guard let json = encodeJSON(payload) else { return }

        runDialogCli(command: "confirm", json: json, clientName: "Consult User MCP") { [weak self] output in
            guard let data = output.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let confirmed = json["confirmed"] as? Bool, confirmed else { return }

            self?.performPromptUpdate(targets: targets, mode: .update)
        }
    }

    private func promptMissingInstall(targets: [InstallTarget]) {
        let targetNames = targets.map(\.displayName).joined(separator: " and ")
        let fileNames = targets.compactMap { $0.claudeMdPath?.components(separatedBy: "/").last }.joined(separator: ", ")

        let body = "No usage hints detected in your \(targetNames) instructions.\n\nEarlier versions of the prompt may need to be removed manually from \(fileNames).\n\nInstall the latest hints (v\(ClaudeMdInstaller.bundledVersion)) and open the file for review?"

        let payload: [String: Any] = [
            "body": body,
            "title": "Usage Hints Missing",
            "confirmLabel": "Install & Open",
            "cancelLabel": "Skip",
            "position": DialogSettings.shared.position.rawValue
        ]

        guard let json = encodeJSON(payload) else { return }

        runDialogCli(command: "confirm", json: json, clientName: "Consult User MCP") { [weak self] output in
            guard let data = output.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let confirmed = json["confirmed"] as? Bool, confirmed else { return }

            self?.performPromptUpdate(targets: targets, mode: .appendSection)

            // Open files for manual review
            for target in targets {
                if let path = target.claudeMdExpandedPath {
                    NSWorkspace.shared.open(URL(fileURLWithPath: path))
                }
            }
        }
    }

    private func performPromptUpdate(targets: [InstallTarget], mode: BasePromptInstallMode) {
        var updated: [String] = []
        var failed: [String] = []

        for target in targets {
            do {
                try ClaudeMdInstaller.install(for: target, mode: mode)
                updated.append(target.displayName)
            } catch {
                failed.append(target.displayName)
            }
        }

        if !updated.isEmpty {
            let names = updated.joined(separator: ", ")
            showPaneNotification(
                title: "Usage Hints Installed",
                body: "Installed v\(ClaudeMdInstaller.bundledVersion) for \(names)."
            )
        }
        if !failed.isEmpty {
            let names = failed.joined(separator: ", ")
            showPaneNotification(
                title: "Install Failed",
                body: "Could not install hints for \(names). Try manually via Settings → Install."
            )
        }
    }

    // MARK: - Auto Update Check

    private func checkForUpdatesAutomatically() {
        performUpdateCheck(isAutomatic: true)
    }

    // MARK: - Snooze Observer

    private func observeUpdateAvailable() {
        updateObserver = DialogSettings.shared.$updateAvailable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusIcon()
            }
    }

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
