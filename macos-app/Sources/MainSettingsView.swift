import SwiftUI
import AppKit

struct MainSettingsView: View {
    @State private var selectedSection: SettingsSection = .general
    @StateObject private var settings = DialogSettings.shared

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedSection)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 680, minHeight: 500)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedSection {
        case .general:
            GeneralSettingsView()
        case .projects:
            ProjectsDetailView()
        case .history:
            HistoryDetailView()
        case .updates:
            UpdatesSettingsView()
        case .install:
            InstallDetailView()
        }
    }
}

// MARK: - Preview

#Preview {
    MainSettingsView()
}
