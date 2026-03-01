import AppKit

enum ThemeMode: String {
    case dark
    case light
}

enum Theme {
    static var current: ThemeMode = .dark

    static var windowBackground: NSColor {
        current == .dark
            ? NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
            : NSColor.white
    }

    static var cardBackground: NSColor {
        current == .dark
            ? NSColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
            : NSColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
    }

    static var cardHover: NSColor {
        current == .dark
            ? NSColor(red: 0.18, green: 0.18, blue: 0.22, alpha: 1.0)
            : NSColor(red: 0.90, green: 0.90, blue: 0.94, alpha: 1.0)
    }

    static var cardSelected: NSColor {
        current == .dark
            ? NSColor(red: 0.22, green: 0.22, blue: 0.28, alpha: 1.0)
            : NSColor(red: 0.85, green: 0.85, blue: 0.90, alpha: 1.0)
    }

    static var textPrimary: NSColor {
        current == .dark
            ? NSColor.white
            : NSColor.black
    }

    static var textSecondary: NSColor {
        current == .dark
            ? NSColor(white: 0.75, alpha: 1.0)
            : NSColor(white: 0.30, alpha: 1.0)
    }

    static var textMuted: NSColor {
        current == .dark
            ? NSColor(white: 0.4, alpha: 1.0)
            : NSColor(white: 0.55, alpha: 1.0)
    }

    static var accentBlue: NSColor {
        current == .dark
            ? NSColor(red: 0.35, green: 0.55, blue: 1.0, alpha: 1.0)
            : NSColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
    }

    static var accentBlueDark: NSColor {
        current == .dark
            ? NSColor(red: 0.25, green: 0.45, blue: 0.90, alpha: 1.0)
            : NSColor(red: 0.0, green: 0.40, blue: 0.85, alpha: 1.0)
    }

    static var border: NSColor {
        current == .dark
            ? NSColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)
            : NSColor(red: 0.80, green: 0.80, blue: 0.82, alpha: 1.0)
    }

    static var gridLines: NSColor {
        current == .dark
            ? NSColor.gray.withAlphaComponent(0.15)
            : NSColor.gray.withAlphaComponent(0.20)
    }
}
