import SwiftUI
import AppKit

struct AboutSettingsView: View {
    private let issuesURL = URL(string: "https://github.com/doublej/consult-user-mcp/issues")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsPageHeader(
                    icon: "info.circle.fill",
                    title: "About",
                    description: "Version information and project feedback"
                )

                tipsSection
                currentVersionSection
                feedbackSection

                Spacer()
            }
            .padding(24)
        }
        .background(Color(.windowBackgroundColor))
    }

    private var tipsSection: some View {
        let tips: [(icon: String, text: String)] = [
            ("hammer", "Option-click (\u{2325}) the menu bar icon to test all dialog types"),
            ("cursorarrow.click.2", "Right-click the menu bar icon for quick access to Settings and Updates"),
            ("keyboard", "Use arrow keys, Enter, and Escape to navigate dialogs without a mouse"),
            ("clock.arrow.circlepath", "Every dialog interaction is recorded \u{2014} search and copy answers from the History tab"),
            ("moon.zzz", "When snoozed, the menu bar icon turns orange \u{2014} all dialogs pause until it expires"),
        ]

        return SettingsSectionContainer(title: "Tips") {
            VStack(spacing: 0) {
                ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                    if index > 0 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Image(systemName: tip.icon)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 16, alignment: .leading)
                        Text(tip.text)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
        }
    }

    private var currentVersionSection: some View {
        SettingsSectionContainer(title: "Current Version") {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    appIcon

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Consult User MCP")
                            .font(.system(size: 15, weight: .semibold))
                        Text("v\(VersionInfo.app)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 0)
                }
                .padding(16)

                Divider()
                    .padding(.horizontal, 16)

                versionGrid
                    .padding(16)
            }
        }
    }

    private var feedbackSection: some View {
        SettingsSectionContainer(title: "Feedback") {
            VStack(alignment: .leading, spacing: 14) {
                Text("This project has gotten to this point purely driven by my personal needs. I'd love to get your feedback on what features or changes could make it work better for you.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Link(destination: issuesURL) {
                    Label("Open GitHub Issues", systemImage: "arrow.up.right.square")
                        .font(.system(size: 13, weight: .medium))
                }

                Divider()

                Text("Made by JJ")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
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
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var versionGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            versionGridRow("MCP Server", VersionInfo.mcp)
            versionGridRow("Dialog CLI", VersionInfo.cli)
            versionGridRow("Base Prompt", VersionInfo.baseprompt)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func versionGridRow(_ label: String, _ version: String) -> some View {
        GridRow {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            Text("v\(version)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    AboutSettingsView()
        .frame(width: 480, height: 500)
}
