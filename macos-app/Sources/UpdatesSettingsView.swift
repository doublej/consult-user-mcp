import SwiftUI
import AppKit

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
                    description: "Check for new versions and install updates"
                )

                currentVersionSection
                updateStatusSection

                Spacer()
            }
            .padding(24)
        }
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Current Version

    private var currentVersionSection: some View {
        SettingsSectionContainer(title: "Current Version") {
            HStack(spacing: 20) {
                appIcon

                VStack(alignment: .leading, spacing: 10) {
                    Text("Consult User MCP")
                        .font(.system(size: 17, weight: .semibold))

                    versionGrid
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var appIcon: some View {
        Group {
            if let icnsURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
               let icon = NSImage(contentsOf: icnsURL) {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var versionGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
            versionGridRow("App", VersionInfo.app)
            versionGridRow("MCP Server", VersionInfo.mcp)
            versionGridRow("Dialog CLI", VersionInfo.cli)
            versionGridRow("Base Prompt", VersionInfo.baseprompt)
        }
    }

    @ViewBuilder
    private func versionGridRow(_ label: String, _ version: String) -> some View {
        GridRow {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text("v\(version)")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
        }
    }

    // MARK: - Update Status

    private var updateStatusSection: some View {
        SettingsSectionContainer(title: "Updates") {
            VStack(spacing: 0) {
                statusRow
                    .padding(20)
                    .frame(maxWidth: .infinity)

                if let progress = settings.updateDownloadProgress {
                    Divider()
                    VStack(spacing: 8) {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
    }

    private var statusRow: some View {
        HStack(spacing: 20) {
            statusIcon
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                statusText
                statusSubtext
            }

            Spacer(minLength: 16)

            actionButton
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if settings.updateCheckInProgress || isDownloading {
            ProgressView()
                .controlSize(.regular)
        } else if settings.updateAvailable != nil {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.orange)
        } else {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
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
            Text("v\(VersionInfo.app) · \(lastCheckText)")
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

        UpdateManager.shared.checkForUpdatesWithDetails { result in
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
