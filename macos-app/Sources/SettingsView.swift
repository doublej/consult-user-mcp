import SwiftUI
import AppKit

struct SettingsView: View {
    @StateObject private var settings = DialogSettings.shared
    @State private var selectedTarget: InstallTarget = .claudeCode
    @State private var showInstallGuide = false

    private let maxHeight: CGFloat = (NSScreen.main?.visibleFrame.height ?? 600) - 100

    var body: some View {
        Group {
            if showInstallGuide {
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
            Text("v1.0")
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
