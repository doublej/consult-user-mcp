import SwiftUI
import AppKit

struct UninstallSettingsView: View {
    @State private var keepData = false
    @State private var showConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsPageHeader(
                    icon: "trash.fill",
                    title: "Uninstall",
                    description: "Remove Consult User MCP from this computer"
                )

                removalListSection
                keepDataSection
                uninstallButton
                cliHintSection

                Spacer()
            }
            .padding(24)
        }
        .background(Color(.windowBackgroundColor))
        .alert("Uninstall Consult User MCP?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Uninstall", role: .destructive) {
                UninstallManager.run(keepData: keepData)
            }
        } message: {
            Text("This will remove the app and all MCP configurations. This cannot be undone.")
        }
    }

    // MARK: - Removal List

    private var removalListSection: some View {
        SettingsSectionContainer(title: "What will be removed") {
            VStack(spacing: 0) {
                ForEach(Array(removalItems.enumerated()), id: \.element.id) { index, item in
                    removalRow(item: item)

                    if index < removalItems.count - 1 {
                        Divider().padding(.leading, 40)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var removalItems: [UninstallManager.RemovalItem] {
        UninstallManager.removalTargets(keepData: keepData)
    }

    private func removalRow(item: UninstallManager.RemovalItem) -> some View {
        HStack(spacing: 14) {
            Image(systemName: item.icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 13))
                Text(item.detail)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Keep Data Toggle

    private var keepDataSection: some View {
        SettingsSectionContainer(title: "Options") {
            SettingsToggleRow(
                icon: "externaldrive",
                title: "Keep settings and dialog history",
                subtitle: "Preserves ~/Library/Application Support/ConsultUserMCP",
                isOn: $keepData
            )
            .padding(.vertical, 4)
        }
    }

    // MARK: - Uninstall Button

    private var uninstallButton: some View {
        Button(action: { showConfirmation = true }) {
            HStack {
                Image(systemName: "trash")
                Text("Uninstall Consult User MCP")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - CLI Hint

    private var cliHintSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Text("You can also run uninstall.sh from the repository.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.controlBackgroundColor))
        )
    }
}

#Preview {
    UninstallSettingsView()
        .frame(width: 480, height: 600)
}
