import SwiftUI
import AppKit

// MARK: - Design System
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}

struct SettingsView: View {
    @StateObject private var settings = DialogSettings.shared
    @State private var previewPulse = false
    @State private var showInstallGuide = false

    var body: some View {
        Group {
            if showInstallGuide {
                InstallGuideView(showInstallGuide: $showInstallGuide)
            } else {
                mainSettingsView
            }
        }
        .frame(width: 300, height: 540)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var mainSettingsView: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    installCard
                    positionSection
                    appearanceSection
                    speechSection
                }
                .padding(Spacing.md)
            }

            footer
        }
        .onChange(of: settings.position) { _, _ in
            triggerPreviewPulse()
            settings.saveToFile()
        }
        .onChange(of: settings.size) { _, _ in settings.saveToFile() }
        .onChange(of: settings.soundOnShow) { _, _ in settings.saveToFile() }
        .onChange(of: settings.soundOnDismiss) { _, _ in settings.saveToFile() }
        .onChange(of: settings.animationsEnabled) { _, _ in settings.saveToFile() }
        .onChange(of: settings.alwaysOnTop) { _, _ in settings.saveToFile() }
        .onChange(of: settings.showCommentField) { _, _ in settings.saveToFile() }
        .onChange(of: settings.speechRate) { _, _ in settings.saveToFile() }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Consult User MCP")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            Button(action: { NSApp.terminate(nil) }) {
                Image(systemName: "power")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color(nsColor: .controlBackgroundColor)))
            }
            .buttonStyle(.plain)
            .help("Quit")
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Install Card
    private var installCard: some View {
        Button(action: { showInstallGuide = true }) {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.green.opacity(0.2), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 32, height: 32)

                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.linearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }

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
                    .foregroundColor(Color(nsColor: .tertiaryLabelColor))
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Position Section
    private var positionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Position")

            VStack(spacing: Spacing.sm) {
                // Mini preview
                positionPreview

                // Position buttons
                HStack(spacing: Spacing.xs) {
                    ForEach(DialogPosition.allCases, id: \.self) { position in
                        positionButton(position)
                    }
                }
            }
            .padding(Spacing.sm)
            .background(sectionBackground)
        }
    }

    private var positionPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .textBackgroundColor))
                .frame(height: 50)

            // Menu bar indicator
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(nsColor: .separatorColor).opacity(0.5))
                    .frame(height: 6)
                Spacer()
            }

            // Dialog indicator
            GeometryReader { geo in
                let dialogWidth: CGFloat = 40
                let xPos: CGFloat = {
                    switch settings.position {
                    case .left: return 6
                    case .center: return (geo.size.width - dialogWidth) / 2
                    case .right: return geo.size.width - dialogWidth - 6
                    }
                }()

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.accentColor)
                    .frame(width: dialogWidth, height: 24)
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                    .position(x: xPos + dialogWidth / 2, y: 22)
                    .scaleEffect(previewPulse ? 1.08 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: previewPulse)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: settings.position)
            }
        }
    }

    private func positionButton(_ position: DialogPosition) -> some View {
        Button(action: { settings.position = position }) {
            VStack(spacing: 3) {
                Image(systemName: position.icon)
                    .font(.system(size: 12))
                Text(position.label)
                    .font(.system(size: 8, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(settings.position == position
                          ? Color.accentColor.opacity(0.12)
                          : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(settings.position == position
                                  ? Color.accentColor.opacity(0.5)
                                  : Color(nsColor: .separatorColor).opacity(0.5),
                                  lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .foregroundColor(settings.position == position ? .accentColor : .secondary)
    }

    // MARK: - Appearance Section
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Appearance")

            VStack(spacing: 0) {
                // Size
                settingRow(icon: "aspectratio", label: "Size") {
                    Picker("", selection: $settings.size) {
                        ForEach(DialogSize.allCases, id: \.self) { size in
                            Text(size.shortLabel).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 130)
                }

                Divider().padding(.leading, 28)

                // Animations
                compactToggle(icon: "sparkles", label: "Animations", isOn: $settings.animationsEnabled)

                Divider().padding(.leading, 28)

                // Always on top
                compactToggle(icon: "pin", label: "Always on Top", isOn: $settings.alwaysOnTop)

                Divider().padding(.leading, 28)

                // Sound on show
                settingRow(icon: "bell", label: "Sound") {
                    Picker("", selection: $settings.soundOnShow) {
                        ForEach(SoundEffect.allCases, id: \.self) { sound in
                            Text(sound.label).tag(sound)
                        }
                    }
                    .frame(width: 80)
                }
            }
            .padding(.vertical, Spacing.xs)
            .background(sectionBackground)
        }
    }

    // MARK: - Speech Section
    private var speechSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader("Speech")

            VStack(spacing: Spacing.sm) {
                // Rate slider
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Image(systemName: "hare")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(width: 16)

                        Text("Rate")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(Int(settings.speechRate))")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 32, alignment: .trailing)
                    }

                    Slider(value: $settings.speechRate, in: 100...400, step: 25)
                        .controlSize(.small)
                }

                // Test button
                HStack {
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 16)

                    Text("Test")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Spacer()

                    Button(action: testSpeech) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 8))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
            .padding(Spacing.sm)
            .background(sectionBackground)
        }
    }

    // MARK: - Footer
    private var footer: some View {
        HStack {
            Text("v1.0")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))

            Spacer()

            Button(action: openGitHub) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    // MARK: - Helpers
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(Color(nsColor: .tertiaryLabelColor))
            .tracking(0.5)
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(nsColor: .controlBackgroundColor))
    }

    private func settingRow<Content: View>(icon: String, label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(width: 16)

            Text(label)
                .font(.system(size: 11))

            Spacer()

            content()
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
    }

    private func compactToggle(icon: String, label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(width: 16)

            Text(label)
                .font(.system(size: 11))

            Spacer()

            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
    }

    private func triggerPreviewPulse() {
        previewPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            previewPulse = false
        }
    }

    private func testSpeech() {
        let synth = NSSpeechSynthesizer()
        synth.rate = Float(settings.speechRate)
        synth.startSpeaking("Hello! Testing speech.")
    }

    private func openGitHub() {
        if let url = URL(string: "https://github.com") {
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview {
    SettingsView()
}

#Preview("Dark") {
    SettingsView()
        .preferredColorScheme(.dark)
}
