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
