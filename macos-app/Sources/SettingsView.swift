import SwiftUI
import AppKit

// MARK: - Version Info

private enum VersionInfo {
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

    static var displayString: String {
        "App \(app) · MCP \(mcp) · CLI \(cli)"
    }
}

struct SettingsView: View {
    @StateObject private var settings = DialogSettings.shared
    @State private var selectedTarget: InstallTarget = .claudeCode
    @State private var showInstallGuide = false
    @State private var showHistory = false

    private let maxHeight: CGFloat = (NSScreen.main?.visibleFrame.height ?? 600) - 100

    var body: some View {
        Group {
            if showHistory {
                HistoryView(isPresented: $showHistory)
            } else if showInstallGuide {
                InstallGuideView(showInstallGuide: $showInstallGuide)
            } else {
                mainView
            }
        }
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxHeight: maxHeight)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    if settings.snoozeRemaining > 0 {
                        SnoozeBanner()
                    }

                    InstallCard(showInstallGuide: $showInstallGuide)

                    PositionSection()

                    AppearanceSection()

                    BehaviorSection()

                    HistorySection(showHistory: $showHistory)

                    UpdatesSection()
                }
                .padding(16)
            }

            footer
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text("Consult User MCP")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            Button(action: { NSApp.terminate(nil) }) {
                Image(systemName: "power")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color(.controlBackgroundColor)))
            }
            .buttonStyle(.plain)
            .help("Quit")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text(VersionInfo.displayString)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(Color(.tertiaryLabelColor))

            Spacer()

            Button(action: openGitHub) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }

    private func openGitHub() {
        if let url = URL(string: "https://github.com/doublej/consult-user-mcp") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Snooze Banner

private struct SnoozeBanner: View {
    @ObservedObject private var settings = DialogSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "moon.zzz.fill")
                    .foregroundColor(.orange)

                Text(settings.snoozeDisplayTime)
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)

                Spacer()
            }

            ProgressView(value: settings.snoozeProgress)
                .progressViewStyle(.linear)
                .tint(.orange)

            HStack {
                Spacer()
                Button("End Snooze") {
                    settings.clearSnooze()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Install Card

private struct InstallCard: View {
    @Binding var showInstallGuide: Bool

    var body: some View {
        Button(action: { showInstallGuide = true }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Install in Claude or Codex")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Configure MCP integration")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(.tertiaryLabelColor))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Position Section

private struct PositionSection: View {
    @ObservedObject private var settings = DialogSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "POSITION")

            PositionPicker(selection: $settings.position)
                .frame(maxWidth: .infinity)
                .onChange(of: settings.position) { _, _ in
                    settings.saveToFile()
                }
        }
    }
}

// MARK: - Appearance Section

private struct AppearanceSection: View {
    @ObservedObject private var settings = DialogSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "APPEARANCE")

            VStack(spacing: 0) {
                SettingRow(icon: "aspectratio", label: "Size") {
                    Picker("", selection: $settings.size) {
                        ForEach(DialogSize.allCases, id: \.self) { size in
                            Text(size.shortLabel).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                }

                Divider().padding(.leading, 28)

                SettingRow(icon: "bell", label: "Sound") {
                    Picker("", selection: $settings.soundOnShow) {
                        ForEach(SoundEffect.allCases, id: \.self) { sound in
                            Text(sound.label).tag(sound)
                        }
                    }
                    .frame(width: 80)
                }

                Divider().padding(.leading, 28)

                CompactToggle(icon: "sparkles", label: "Animations", isOn: $settings.animationsEnabled)

                Divider().padding(.leading, 28)

                CompactToggle(icon: "pin", label: "Always on Top", isOn: $settings.alwaysOnTop)
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
            )
        }
        .onChange(of: settings.size) { _, _ in settings.saveToFile() }
        .onChange(of: settings.soundOnShow) { _, _ in settings.saveToFile() }
        .onChange(of: settings.animationsEnabled) { _, _ in settings.saveToFile() }
        .onChange(of: settings.alwaysOnTop) { _, _ in settings.saveToFile() }
    }
}

// MARK: - Behavior Section

private struct BehaviorSection: View {
    @ObservedObject private var settings = DialogSettings.shared

    private var cooldownMs: Int {
        Int(settings.buttonCooldownDuration * 1000)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "BEHAVIOR")

            VStack(spacing: 0) {
                CompactToggle(
                    icon: "timer",
                    label: "Button activation delay",
                    isOn: $settings.buttonCooldownEnabled
                )

                if settings.buttonCooldownEnabled {
                    Divider().padding(.leading, 28)

                    HStack(spacing: 8) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(width: 16)

                        Slider(
                            value: $settings.buttonCooldownDuration,
                            in: 0.1...3.0,
                            step: 0.1
                        )

                        Text("\(cooldownMs) ms")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
            )
        }
        .onChange(of: settings.buttonCooldownEnabled) { _, _ in settings.saveToFile() }
        .onChange(of: settings.buttonCooldownDuration) { _, _ in settings.saveToFile() }
    }
}

// MARK: - History Section

private struct HistorySection: View {
    @ObservedObject private var historyManager = HistoryManager.shared
    @Binding var showHistory: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "HISTORY")

            Button(action: { showHistory = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 16)

                    Text("Dialog History")
                        .font(.system(size: 11))
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(historyManager.entries.count)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(.tertiaryLabelColor))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
            )
        }
    }
}

// MARK: - Updates Section

private struct UpdatesSection: View {
    @ObservedObject private var settings = DialogSettings.shared
    @State private var showingUpdateAlert = false

    private var isDownloading: Bool {
        settings.updateDownloadProgress != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "UPDATES")

            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    statusIcon
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 2) {
                        statusText
                        versionInfo
                    }

                    Spacer()

                    actionButton
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, isDownloading ? 4 : 8)

                if let progress = settings.updateDownloadProgress {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
            )
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if settings.updateCheckInProgress || isDownloading {
            ProgressView()
                .controlSize(.small)
                .scaleEffect(0.7)
        } else if settings.updateAvailable != nil {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.blue)
        } else {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
        }
    }

    @ViewBuilder
    private var statusText: some View {
        if isDownloading {
            Text(settings.updateStatus ?? "Downloading...")
                .font(.system(size: 11, weight: .medium))
        } else if settings.updateCheckInProgress {
            Text("Checking...")
                .font(.system(size: 11, weight: .medium))
        } else if let release = settings.updateAvailable {
            Text("Update available: v\(release.version)")
                .font(.system(size: 11, weight: .medium))
        } else {
            Text("Up to date")
                .font(.system(size: 11, weight: .medium))
        }
    }

    @ViewBuilder
    private var versionInfo: some View {
        if let progress = settings.updateDownloadProgress {
            Text("\(Int(progress * 100))% complete")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        } else if settings.updateCheckInProgress {
            Text("v\(VersionInfo.app)")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        } else if settings.updateAvailable != nil {
            Text("You have v\(VersionInfo.app)")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        } else {
            Text("v\(VersionInfo.app) · \(lastCheckText)")
                .font(.system(size: 9))
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
            Button("Update") {
                performUpdate()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        } else {
            Button("Check Now") {
                checkForUpdates()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(settings.updateCheckInProgress)
        }
    }

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

// MARK: - Helpers

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .tracking(1.0)
            .foregroundColor(.secondary)
    }
}

private struct SettingRow<Content: View>: View {
    let icon: String
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(width: 16)

            Text(label)
                .font(.system(size: 11))

            Spacer()

            content()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

private struct CompactToggle: View {
    let icon: String
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(width: 16)

            Text(label)
                .font(.system(size: 11))

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

#Preview {
    SettingsView()
}

#Preview("Dark") {
    SettingsView()
        .preferredColorScheme(.dark)
}
