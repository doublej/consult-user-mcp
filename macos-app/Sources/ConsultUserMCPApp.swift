import SwiftUI

@main
struct ConsultUserMCPApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // AppDelegate owns the status item and every window; this scene only exists because
        // `App` needs one. It used to be `Settings { EmptyView() }`, which macOS showed as a
        // blank window at launch and on ⌘,. A never-inserted menu bar extra has no window.
        MenuBarExtra("Consult User MCP", isInserted: .constant(false)) {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") { SettingsWindowController.shared.showWindow() }
                    .keyboardShortcut(",")
            }
        }
    }
}
