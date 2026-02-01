import SwiftUI

struct SidebarView: View {
    @Binding var selection: SettingsSection
    @ObservedObject private var historyManager = HistoryManager.shared
    @ObservedObject private var projectManager = ProjectManager.shared
    @ObservedObject private var settings = DialogSettings.shared

    var body: some View {
        List(selection: $selection) {
            ForEach(SettingsSection.allCases) { section in
                sidebarRow(section)
                    .tag(section)
            }
        }
        .listStyle(.sidebar)
    }

    private func sidebarRow(_ section: SettingsSection) -> some View {
        HStack(spacing: 8) {
            Image(systemName: section.icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor(for: section))
                .frame(width: 20)

            Text(section.title)
                .font(.system(size: 13))

            Spacer()

            badge(for: section)
        }
        .padding(.vertical, 4)
    }

    private func iconColor(for section: SettingsSection) -> Color {
        switch section {
        case .updates where settings.updateAvailable != nil:
            return .orange
        default:
            return .secondary
        }
    }

    @ViewBuilder
    private func badge(for section: SettingsSection) -> some View {
        switch section {
        case .projects where !projectManager.projects.isEmpty:
            countBadge(projectManager.projects.count)

        case .history where !historyManager.entries.isEmpty:
            countBadge(historyManager.entries.count)

        case .updates where settings.updateAvailable != nil:
            Circle()
                .fill(Color.orange)
                .frame(width: 8, height: 8)
                .frame(minWidth: 28)

        default:
            EmptyView()
        }
    }

    private func countBadge(_ count: Int) -> some View {
        Text("\(count)")
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .frame(minWidth: 28)
            .background(Capsule().fill(Color(.controlBackgroundColor)))
    }
}

#Preview {
    SidebarView(selection: .constant(.general))
        .frame(width: 200)
}
