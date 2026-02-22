import SwiftUI

// MARK: - Version Info

enum VersionInfo {
    static var app: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    static var cli: String {
        guard let url = Bundle.main.url(
            forResource: "VERSION",
            withExtension: nil,
            subdirectory: "dialog-cli"
        ),
        let content = try? String(contentsOf: url, encoding: .utf8) else {
            return "?"
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var mcp: String {
        guard let url = Bundle.main.url(
            forResource: "package",
            withExtension: "json",
            subdirectory: "mcp-server"
        ),
        let data = try? Data(contentsOf: url),
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let version = json["version"] as? String else {
            return "?"
        }
        return version
    }

    static var baseprompt: String {
        ClaudeMdInstaller.bundledVersion
    }

    static var displayString: String {
        "App \(app) · MCP \(mcp) · CLI \(cli) · Prompt \(baseprompt)"
    }
}

// MARK: - Updates Settings View

struct UpdatesSettingsView: View {
    @ObservedObject private var settings = DialogSettings.shared
    @State private var promptUpdateResult: [String: Bool] = [:]

    private var isDownloading: Bool {
        settings.updateDownloadProgress != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsPageHeader(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Updates",
                    description: "Configure automatic checks and install updates"
                )

                updateAutomationSection
                updateStatusSection
                promptUpdateSection

                Spacer()
            }
            .padding(24)
        }
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Update Status

    private var updateAutomationSection: some View {
        SettingsSectionContainer(title: "Automation") {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    icon: "arrow.triangle.2.circlepath.circle",
                    title: "Check for updates automatically",
                    subtitle: "Run background checks on your chosen cadence",
                    isOn: $settings.autoCheckForUpdatesEnabled
                )

                Divider().padding(.leading, 40)

                SettingsRowWithControl(
                    icon: "calendar",
                    title: "Check cadence",
                    subtitle: "How often automatic checks should run"
                ) {
                    Picker("", selection: $settings.updateCheckCadence) {
                        ForEach(UpdateCheckCadence.allCases, id: \.self) { cadence in
                            Text(cadence.label).tag(cadence)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)
                    .disabled(!settings.autoCheckForUpdatesEnabled)
                }

                Divider().padding(.leading, 40)

                SettingsRowWithControl(
                    icon: "bell.badge",
                    title: "Remind me again in",
                    subtitle: "Delay before update reminders reappear"
                ) {
                    Picker("", selection: $settings.updateReminderInterval) {
                        ForEach(UpdateReminderInterval.allCases, id: \.self) { interval in
                            Text(interval.label).tag(interval)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 90)
                }

                Divider().padding(.leading, 40)

                SettingsToggleRow(
                    icon: "flask",
                    title: "Include pre-release versions",
                    subtitle: "Show beta and preview builds",
                    isOn: $settings.includePrereleaseUpdates
                )
            }
            .padding(.vertical, 4)
        }
        .onChange(of: settings.autoCheckForUpdatesEnabled) { _, _ in settings.saveToFile() }
        .onChange(of: settings.updateCheckCadence) { _, _ in settings.saveToFile() }
        .onChange(of: settings.updateReminderInterval) { _, _ in settings.saveToFile() }
        .onChange(of: settings.includePrereleaseUpdates) { _, _ in settings.saveToFile() }
    }

    private var updateStatusSection: some View {
        SettingsSectionContainer(title: "Updates") {
            VStack(spacing: 0) {
                statusRow
                    .padding(16)

                if let progress = settings.updateDownloadProgress {
                    Divider()
                        .padding(.horizontal, 16)
                    VStack(spacing: 6) {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                }
            }
        }
    }

    private var statusRow: some View {
        HStack(spacing: 12) {
            statusIcon

            VStack(alignment: .leading, spacing: 2) {
                statusText
                statusSubtext
            }

            Spacer(minLength: 8)

            actionButton
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if settings.updateCheckInProgress || isDownloading {
            ProgressView()
                .controlSize(.small)
        } else if settings.updateAvailable != nil {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.orange)
        } else {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.green)
        }
    }

    @ViewBuilder
    private var statusText: some View {
        if isDownloading {
            Text(settings.updateStatus ?? "Downloading...")
                .font(.system(size: 13, weight: .medium))
        } else if settings.updateCheckInProgress {
            Text("Checking for updates...")
                .font(.system(size: 13, weight: .medium))
        } else if let release = settings.updateAvailable {
            Text("Update available: v\(release.version)")
                .font(.system(size: 13, weight: .medium))
        } else {
            Text("Up to date")
                .font(.system(size: 13, weight: .medium))
        }
    }

    @ViewBuilder
    private var statusSubtext: some View {
        if settings.updateDownloadProgress != nil {
            Text("Download in progress...")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        } else if settings.updateCheckInProgress {
            Text("Current: v\(VersionInfo.app)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        } else if settings.updateAvailable != nil {
            Text("You have v\(VersionInfo.app)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        } else {
            Text(lastCheckText)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    private var lastCheckText: String {
        guard let lastCheck = settings.lastUpdateCheck else {
            return "Never checked"
        }

        let interval = Date().timeIntervalSince(lastCheck)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "Checked \(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "Checked \(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "Checked \(days)d ago"
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if isDownloading {
            EmptyView()
        } else if settings.updateAvailable != nil {
            Button("Update Now") {
                performUpdate()
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button("Check for Updates") {
                checkForUpdates()
            }
            .buttonStyle(.bordered)
            .disabled(settings.updateCheckInProgress)
        }
    }

    // MARK: - Prompt Update

    private enum PromptTargetState {
        case installed(BasePromptInfo)
        case notDetected
    }

    private var promptTargets: [(target: InstallTarget, state: PromptTargetState)] {
        InstallTarget.allCases.compactMap { target in
            guard target.supportsBasePrompt, ClaudeMdInstaller.detectExisting(for: target) else { return nil }
            if let info = ClaudeMdInstaller.detectInstalledInfo(for: target) {
                return (target, .installed(info))
            }
            return (target, .notDetected)
        }
    }

    private var promptUpdateSection: some View {
        SettingsSectionContainer(title: "Usage Hints") {
            VStack(spacing: 0) {
                let targets = promptTargets
                if targets.isEmpty {
                    promptEmptyRow
                        .padding(16)
                } else {
                    ForEach(Array(targets.enumerated()), id: \.element.target) { index, entry in
                        if index > 0 {
                            Divider().padding(.leading, 40)
                        }
                        switch entry.state {
                        case .installed(let info):
                            promptRow(for: entry.target, info: info)
                                .padding(16)
                        case .notDetected:
                            promptNotDetectedRow(for: entry.target)
                                .padding(16)
                        }
                    }
                }
            }
        }
    }

    private var promptEmptyRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "text.bubble")
                .font(.system(size: 22))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("No usage hints installed")
                    .font(.system(size: 13, weight: .medium))
                Text("Install via the Install tab")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 8)
        }
    }

    // MARK: Prompt — Installed

    private func promptRow(for target: InstallTarget, info: BasePromptInfo) -> some View {
        let isOutdated = ClaudeMdInstaller.isUpdateAvailable(for: target)
        let didUpdate = promptUpdateResult[target.rawValue] == true
        let didFail = promptUpdateResult[target.rawValue] == false

        return HStack(spacing: 12) {
            promptIcon(isOutdated: isOutdated, didUpdate: didUpdate, didFail: didFail)

            VStack(alignment: .leading, spacing: 2) {
                promptTitle(target: target, info: info, isOutdated: isOutdated, didUpdate: didUpdate, didFail: didFail)
                promptSubtitle(target: target, info: info, isOutdated: isOutdated, didUpdate: didUpdate)
            }

            Spacer(minLength: 8)

            if isOutdated && !didUpdate {
                Button("Update") {
                    updatePrompt(for: target)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private func promptIcon(isOutdated: Bool, didUpdate: Bool, didFail: Bool) -> some View {
        if didFail {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.red)
        } else if didUpdate {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.green)
        } else if isOutdated {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.orange)
        } else {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.green)
        }
    }

    @ViewBuilder
    private func promptTitle(target: InstallTarget, info: BasePromptInfo, isOutdated: Bool, didUpdate: Bool, didFail: Bool) -> some View {
        if didFail {
            Text("\(target.displayName) — update failed")
                .font(.system(size: 13, weight: .medium))
        } else if didUpdate {
            Text("\(target.displayName) — updated to v\(ClaudeMdInstaller.bundledVersion)")
                .font(.system(size: 13, weight: .medium))
        } else if isOutdated {
            Text("\(target.displayName) — update available")
                .font(.system(size: 13, weight: .medium))
        } else {
            Text("\(target.displayName) — up to date")
                .font(.system(size: 13, weight: .medium))
        }
    }

    @ViewBuilder
    private func promptSubtitle(target: InstallTarget, info: BasePromptInfo, isOutdated: Bool, didUpdate: Bool) -> some View {
        if didUpdate {
            Text("Restart Claude Code to pick up changes")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        } else if isOutdated {
            Text("v\(info.version) → v\(ClaudeMdInstaller.bundledVersion)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        } else {
            Text("v\(info.version)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    private func updatePrompt(for target: InstallTarget) {
        do {
            try ClaudeMdInstaller.install(for: target, mode: .update)
            promptUpdateResult[target.rawValue] = true
        } catch {
            promptUpdateResult[target.rawValue] = false
        }
    }

    // MARK: Prompt — Not Detected

    private func promptNotDetectedRow(for target: InstallTarget) -> some View {
        let didInstall = promptUpdateResult[target.rawValue] == true
        let didFail = promptUpdateResult[target.rawValue] == false

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                if didInstall {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.green)
                } else if didFail {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.red)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    if didInstall {
                        Text("\(target.displayName) — installed v\(ClaudeMdInstaller.bundledVersion)")
                            .font(.system(size: 13, weight: .medium))
                        Text("Review the file to remove any old prompt content")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else if didFail {
                        Text("\(target.displayName) — install failed")
                            .font(.system(size: 13, weight: .medium))
                    } else {
                        Text("\(target.displayName) — not detected")
                            .font(.system(size: 13, weight: .medium))
                        Text("File exists but no versioned usage hints found")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 8)

                if !didInstall {
                    Button("Install & Open") {
                        installAndOpenPrompt(for: target)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            if !didInstall && !didFail {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                    Text("Earlier versions may need to be removed manually from \(target.claudeMdPath?.components(separatedBy: "/").last ?? "CLAUDE.md").")
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange.opacity(0.08))
                )
            }
        }
    }

    private func installAndOpenPrompt(for target: InstallTarget) {
        do {
            try ClaudeMdInstaller.install(for: target, mode: .appendSection)
            promptUpdateResult[target.rawValue] = true
            if let path = target.claudeMdExpandedPath {
                NSWorkspace.shared.open(URL(fileURLWithPath: path))
            }
        } catch {
            promptUpdateResult[target.rawValue] = false
        }
    }

    // MARK: - Actions

    private func checkForUpdates() {
        settings.updateCheckInProgress = true

        UpdateManager.shared.checkForUpdatesWithDetails(includePrerelease: settings.includePrereleaseUpdates) { result in
            DispatchQueue.main.async {
                settings.updateCheckInProgress = false

                switch result {
                case .success(let checkResult):
                    settings.recordUpdateCheck(latestVersion: checkResult.remoteVersion)
                    settings.updateAvailable = checkResult.release
                case .failure:
                    settings.updateAvailable = nil
                }
            }
        }
    }

    private func performUpdate() {
        guard let release = settings.updateAvailable else { return }

        settings.updateDownloadProgress = 0
        settings.updateStatus = "Downloading..."

        UpdateManager.shared.downloadUpdate(
            from: release.zipURL,
            progress: { progress in
                settings.updateDownloadProgress = progress
            },
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

#Preview {
    UpdatesSettingsView()
        .frame(width: 480, height: 500)
}
