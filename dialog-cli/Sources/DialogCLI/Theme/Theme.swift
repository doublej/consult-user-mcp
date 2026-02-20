import AppKit
import SwiftUI

// MARK: - Theme Protocol

protocol ThemeProtocol {
    var name: String { get }

    // Window
    var windowBackground: NSColor { get }

    // Cards
    var cardBackground: NSColor { get }
    var cardHover: NSColor { get }
    var cardSelected: NSColor { get }

    // Text
    var textPrimary: NSColor { get }
    var textSecondary: NSColor { get }
    var textMuted: NSColor { get }

    // Accents
    var accentBlue: NSColor { get }
    var accentBlueDark: NSColor { get }
    var accentGreen: NSColor { get }
    var accentRed: NSColor { get }

    // Input
    var border: NSColor { get }
    var inputBackground: NSColor { get }

    // Radii
    var cornerRadius: CGFloat { get }
    var buttonRadius: CGFloat { get }
    var cardRadius: CGFloat { get }
}

// MARK: - Theme Manager

final class ThemeManager {
    static let shared = ThemeManager()

    private(set) var current: ThemeProtocol = MidnightTheme()

    private init() {}

    func setTheme(_ theme: ThemeProtocol) {
        current = theme
    }

    func setTheme(named name: String) {
        switch name.lowercased() {
        case "midnight", "dark":
            current = MidnightTheme()
        case "sunset", "warm":
            current = SunsetTheme()
        default:
            current = MidnightTheme()
        }
    }
}

// MARK: - Sunset Theme (Warm Orange)

struct SunsetTheme: ThemeProtocol {
    let name = "sunset"

    let windowBackground = NSColor(red: 0.12, green: 0.08, blue: 0.06, alpha: 0.98)
    let cardBackground = NSColor(red: 0.18, green: 0.12, blue: 0.10, alpha: 1.0)
    let cardHover = NSColor(red: 0.24, green: 0.16, blue: 0.12, alpha: 1.0)
    let cardSelected = NSColor(red: 0.30, green: 0.20, blue: 0.14, alpha: 1.0)

    let textPrimary = NSColor(red: 1.0, green: 0.96, blue: 0.92, alpha: 1.0)
    let textSecondary = NSColor(red: 0.85, green: 0.75, blue: 0.65, alpha: 1.0)
    let textMuted = NSColor(red: 0.62, green: 0.52, blue: 0.44, alpha: 1.0)

    let accentBlue = NSColor(red: 1.0, green: 0.55, blue: 0.25, alpha: 1.0)  // Orange as primary
    let accentBlueDark = NSColor(red: 0.90, green: 0.45, blue: 0.15, alpha: 1.0)
    let accentGreen = NSColor(red: 0.95, green: 0.75, blue: 0.30, alpha: 1.0)  // Gold
    let accentRed = NSColor(red: 0.95, green: 0.35, blue: 0.30, alpha: 1.0)

    let border = NSColor(red: 0.40, green: 0.30, blue: 0.25, alpha: 1.0)
    let inputBackground = NSColor(red: 0.14, green: 0.10, blue: 0.08, alpha: 1.0)

    let cornerRadius: CGFloat = 16
    let buttonRadius: CGFloat = 12
    let cardRadius: CGFloat = 10
}

// MARK: - Midnight Theme (Default)

struct MidnightTheme: ThemeProtocol {
    let name = "midnight"

    let windowBackground = NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 0.98)
    let cardBackground = NSColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
    let cardHover = NSColor(red: 0.18, green: 0.18, blue: 0.22, alpha: 1.0)
    let cardSelected = NSColor(red: 0.22, green: 0.22, blue: 0.28, alpha: 1.0)

    let textPrimary = NSColor.white
    let textSecondary = NSColor(white: 0.75, alpha: 1.0)
    let textMuted = NSColor(white: 0.5, alpha: 1.0)

    let accentBlue = NSColor(red: 0.35, green: 0.55, blue: 1.0, alpha: 1.0)
    let accentBlueDark = NSColor(red: 0.25, green: 0.45, blue: 0.90, alpha: 1.0)
    let accentGreen = NSColor(red: 0.30, green: 0.85, blue: 0.55, alpha: 1.0)
    let accentRed = NSColor(red: 0.95, green: 0.35, blue: 0.40, alpha: 1.0)

    let border = NSColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)
    let inputBackground = NSColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1.0)

    let cornerRadius: CGFloat = 16
    let buttonRadius: CGFloat = 12
    let cardRadius: CGFloat = 10
}

// MARK: - Static Theme Accessor (Backward Compatibility)

struct Theme {
    private static var current: ThemeProtocol { ThemeManager.shared.current }

    // NSColor accessors
    static var windowBackground: NSColor { current.windowBackground }
    static var cardBackground: NSColor { current.cardBackground }
    static var cardHover: NSColor { current.cardHover }
    static var cardSelected: NSColor { current.cardSelected }
    static var textPrimary: NSColor { current.textPrimary }
    static var textSecondary: NSColor { current.textSecondary }
    static var textMuted: NSColor { current.textMuted }
    static var accentBlue: NSColor { current.accentBlue }
    static var accentBlueDark: NSColor { current.accentBlueDark }
    static var accentGreen: NSColor { current.accentGreen }
    static var accentRed: NSColor { current.accentRed }
    static var border: NSColor { current.border }
    static var inputBackground: NSColor { current.inputBackground }

    static var cornerRadius: CGFloat { current.cornerRadius }
    static var buttonRadius: CGFloat { current.buttonRadius }
    static var cardRadius: CGFloat { current.cardRadius }

    // SwiftUI Color accessors
    enum Colors {
        private static var current: ThemeProtocol { ThemeManager.shared.current }

        static var windowBackground: Color { Color(current.windowBackground) }
        static var cardBackground: Color { Color(current.cardBackground) }
        static var cardHover: Color { Color(current.cardHover) }
        static var cardSelected: Color { Color(current.cardSelected) }
        static var textPrimary: Color { Color(current.textPrimary) }
        static var textSecondary: Color { Color(current.textSecondary) }
        static var textMuted: Color { Color(current.textMuted) }
        static var accentBlue: Color { Color(current.accentBlue) }
        static var accentBlueLight: Color { Color(current.accentBlue).opacity(0.8) }
        static var accentBlueDark: Color { Color(current.accentBlueDark) }
        static var accentGreen: Color { Color(current.accentGreen) }
        static var accentRed: Color { Color(current.accentRed) }
        static var border: Color { Color(current.border) }
        static var inputBackground: Color { Color(current.inputBackground) }
    }
}
