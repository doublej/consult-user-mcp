import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case projects
    case history
    case updates
    case install
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .projects: return "Projects"
        case .history: return "History"
        case .updates: return "Updates"
        case .install: return "Install"
        case .about: return "About"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .projects: return "folder.badge.gearshape"
        case .history: return "clock.arrow.circlepath"
        case .updates: return "arrow.triangle.2.circlepath"
        case .install: return "plus.circle"
        case .about: return "info.circle"
        }
    }

    var subtitle: String {
        switch self {
        case .general: return "Position, appearance, behavior"
        case .projects: return "Discovered project contexts"
        case .history: return "Dialog interactions"
        case .updates: return "Update checks and installs"
        case .install: return "MCP integration wizard"
        case .about: return "Version, feedback, credits"
        }
    }
}
