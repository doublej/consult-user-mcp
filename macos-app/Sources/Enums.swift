import SwiftUI
import AppKit

// MARK: - Dialog Position

enum DialogPosition: String, CaseIterable, Codable {
    case left
    case center
    case right

    var icon: String {
        switch self {
        case .left: return "rectangle.lefthalf.inset.filled"
        case .center: return "rectangle.center.inset.filled"
        case .right: return "rectangle.righthalf.inset.filled"
        }
    }

    var label: String {
        rawValue.capitalized
    }
}

// MARK: - Dialog Size

enum DialogSize: String, CaseIterable, Codable {
    case compact
    case regular
    case large

    var scale: CGFloat {
        switch self {
        case .compact: return 0.85
        case .regular: return 1.0
        case .large: return 1.2
        }
    }

    var label: String {
        rawValue.capitalized
    }

    var shortLabel: String {
        switch self {
        case .compact: return "S"
        case .regular: return "M"
        case .large: return "L"
        }
    }
}

// MARK: - Sound Effect

enum SoundEffect: String, CaseIterable, Codable {
    case none
    case subtle
    case pop
    case chime

    var systemSound: String? {
        switch self {
        case .none: return nil
        case .subtle: return "Tink"
        case .pop: return "Pop"
        case .chime: return "Glass"
        }
    }

    var label: String {
        switch self {
        case .none: return "Off"
        case .subtle: return "Tink"
        case .pop: return "Pop"
        case .chime: return "Glass"
        }
    }

    var icon: String {
        switch self {
        case .none: return "speaker.slash"
        case .subtle: return "speaker.wave.1"
        case .pop: return "speaker.wave.2"
        case .chime: return "speaker.wave.3"
        }
    }

    func play() {
        guard let soundName = systemSound else { return }
        NSSound(named: NSSound.Name(soundName))?.play()
    }
}

// MARK: - Update Cadence

enum UpdateCheckCadence: String, CaseIterable, Codable {
    case daily
    case weekly
    case manual

    var label: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .manual: return "Manual only"
        }
    }

    var minimumInterval: TimeInterval? {
        switch self {
        case .daily: return 24 * 60 * 60
        case .weekly: return 7 * 24 * 60 * 60
        case .manual: return nil
        }
    }
}

enum UpdateReminderInterval: String, CaseIterable, Codable {
    case oneDay
    case threeDays
    case sevenDays

    var label: String {
        switch self {
        case .oneDay: return "1 day"
        case .threeDays: return "3 days"
        case .sevenDays: return "7 days"
        }
    }

    var seconds: TimeInterval {
        switch self {
        case .oneDay: return 24 * 60 * 60
        case .threeDays: return 3 * 24 * 60 * 60
        case .sevenDays: return 7 * 24 * 60 * 60
        }
    }
}

// MARK: - Install Target

enum InstallTarget: String, CaseIterable, Identifiable {
    case claudeDesktop
    case claudeCode
    case codex

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeDesktop: return "Claude"
        case .claudeCode: return "Claude Code"
        case .codex: return "Codex"
        }
    }

    var description: String {
        switch self {
        case .claudeDesktop: return "Anthropic's desktop app"
        case .claudeCode: return "CLI coding assistant"
        case .codex: return "OpenAI's CLI tool"
        }
    }

    var configPath: String {
        switch self {
        case .claudeDesktop:
            return "~/Library/Application Support/Claude/claude_desktop_config.json"
        case .claudeCode:
            return "~/.claude.json"
        case .codex:
            return "~/.codex/config.toml"
        }
    }

    var expandedPath: String {
        (configPath as NSString).expandingTildeInPath
    }

    var configFormat: ConfigFormat {
        switch self {
        case .claudeDesktop, .claudeCode: return .json
        case .codex: return .toml
        }
    }

    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: expandedPath)
    }

    var claudeMdPath: String? {
        switch self {
        case .claudeDesktop: return nil
        case .claudeCode: return "~/.claude/CLAUDE.md"
        case .codex: return "~/.codex/AGENTS.md"
        }
    }

    var claudeMdExpandedPath: String? {
        claudeMdPath.map { ($0 as NSString).expandingTildeInPath }
    }

    var supportsBasePrompt: Bool {
        claudeMdPath != nil
    }
}

enum ConfigFormat {
    case json
    case toml
}
