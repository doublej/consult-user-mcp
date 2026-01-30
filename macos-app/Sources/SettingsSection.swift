import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case projects
    case history
    case updates
    case install

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .projects: return "Projects"
        case .history: return "History"
        case .updates: return "Updates"
        case .install: return "Install"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .projects: return "folder.badge.gearshape"
        case .history: return "clock.arrow.circlepath"
        case .updates: return "arrow.triangle.2.circlepath"
        case .install: return "plus.circle"
        }
    }

    var subtitle: String {
        switch self {
        case .general: return "Position, appearance, behavior"
        case .projects: return "Discovered project contexts"
        case .history: return "Dialog interactions"
        case .updates: return "Version and updates"
        case .install: return "MCP integration wizard"
        }
    }
}
