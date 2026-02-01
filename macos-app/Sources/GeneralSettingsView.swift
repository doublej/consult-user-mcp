import SwiftUI
import AppKit

struct GeneralSettingsView: View {
    @ObservedObject private var settings = DialogSettings.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsPageHeader(
                    icon: "gearshape.fill",
                    title: "General",
                    description: "Configure dialog appearance and behavior"
                )

                if settings.snoozeRemaining > 0 {
                    SnoozeBannerView()
                }

                PositionSettingsSection()
                AppearanceSettingsSection()
                BehaviorSettingsSection()

                Spacer()
            }
            .padding(24)
        }
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - Snooze Banner

struct SnoozeBannerView: View {
    @ObservedObject private var settings = DialogSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)

                Text(settings.snoozeDisplayTime)
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)

                Spacer()

                Button("End Snooze") {
                    settings.clearSnooze()
                }
                .buttonStyle(.bordered)
            }

            ProgressView(value: settings.snoozeProgress)
                .progressViewStyle(.linear)
                .tint(.orange)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Position Section

private struct PositionSettingsSection: View {
    @ObservedObject private var settings = DialogSettings.shared

    var body: some View {
        SettingsSectionContainer(title: "Position") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose where dialogs appear on screen")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                PositionPicker(selection: $settings.position)
                    .onChange(of: settings.position) { _, _ in
                        settings.saveToFile()
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 12)
            }
        }
    }
}

// MARK: - Appearance Section

private struct AppearanceSettingsSection: View {
    @ObservedObject private var settings = DialogSettings.shared

    var body: some View {
        SettingsSectionContainer(title: "Appearance") {
            VStack(spacing: 0) {
                SettingsRowWithControl(
                    icon: "bell",
                    title: "Sound",
                    subtitle: "Play when dialog appears"
                ) {
                    HStack(spacing: 8) {
                        if settings.soundOnShow != .none {
                            Button(action: { settings.soundOnShow.play() }) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color(.controlBackgroundColor)))
                            .help("Preview sound")
                        }

                        Picker("", selection: $settings.soundOnShow) {
                            ForEach(SoundEffect.allCases, id: \.self) { sound in
                                Text(sound.label).tag(sound)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 90)
                    }
                }

                Divider().padding(.leading, 40)

                SettingsToggleRow(
                    icon: "sparkles",
                    title: "Animations",
                    subtitle: "Smooth transitions",
                    isOn: $settings.animationsEnabled
                )

                Divider().padding(.leading, 40)

                SettingsToggleRow(
                    icon: "pin",
                    title: "Always on Top",
                    subtitle: "Keep dialogs above other windows",
                    isOn: $settings.alwaysOnTop
                )
            }
            .padding(.vertical, 4)
        }
        .onChange(of: settings.soundOnShow) { _, _ in settings.saveToFile() }
        .onChange(of: settings.animationsEnabled) { _, _ in settings.saveToFile() }
        .onChange(of: settings.alwaysOnTop) { _, _ in settings.saveToFile() }
    }
}

// MARK: - Behavior Section

private struct BehaviorSettingsSection: View {
    @ObservedObject private var settings = DialogSettings.shared

    private var cooldownMs: Int {
        Int(settings.buttonCooldownDuration * 1000)
    }

    var body: some View {
        SettingsSectionContainer(title: "Behavior") {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    icon: "timer",
                    title: "Button activation delay",
                    subtitle: "Prevent accidental clicks",
                    isOn: $settings.buttonCooldownEnabled
                )

                if settings.buttonCooldownEnabled {
                    Divider().padding(.leading, 40)

                    HStack(spacing: 14) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(width: 24)

                        Slider(
                            value: $settings.buttonCooldownDuration,
                            in: 0.1...3.0,
                            step: 0.1
                        )

                        Text("\(cooldownMs) ms")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 55, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .padding(.vertical, 4)
        }
        .onChange(of: settings.buttonCooldownEnabled) { _, _ in settings.saveToFile() }
        .onChange(of: settings.buttonCooldownDuration) { _, _ in settings.saveToFile() }
    }
}

// MARK: - Page Header

struct SettingsPageHeader<Trailing: View>: View {
    let icon: String
    let title: String
    let description: String
    let trailing: Trailing

    init(
        icon: String,
        title: String,
        description: String,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            trailing
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Helpers

struct SettingsSectionContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .medium))
                .tracking(1.0)
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.controlBackgroundColor))
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
    }
}

struct SettingsRowWithControl<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder let control: () -> Content

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            control()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GeneralSettingsView()
        .frame(width: 480, height: 500)
}
