import AppKit
import SwiftUI

// MARK: - Modern Theme

struct Theme {
    static let windowBackground = NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 0.98)
    static let cardBackground = NSColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
    static let cardHover = NSColor(red: 0.18, green: 0.18, blue: 0.22, alpha: 1.0)
    static let cardSelected = NSColor(red: 0.22, green: 0.22, blue: 0.28, alpha: 1.0)

    static let textPrimary = NSColor.white
    static let textSecondary = NSColor(white: 0.75, alpha: 1.0)
    static let textMuted = NSColor(white: 0.4, alpha: 1.0)

    static let accentBlue = NSColor(red: 0.35, green: 0.55, blue: 1.0, alpha: 1.0)
    static let accentGreen = NSColor(red: 0.30, green: 0.85, blue: 0.55, alpha: 1.0)
    static let accentRed = NSColor(red: 0.95, green: 0.35, blue: 0.40, alpha: 1.0)

    static let border = NSColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)
    static let inputBackground = NSColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1.0)

    static let cornerRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 12
    static let cardRadius: CGFloat = 10

    // SwiftUI Colors
    enum Colors {
        static let windowBackground = Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.98)
        static let cardBackground = Color(red: 0.14, green: 0.14, blue: 0.16)
        static let cardHover = Color(red: 0.18, green: 0.18, blue: 0.22)
        static let cardSelected = Color(red: 0.22, green: 0.22, blue: 0.28)
        static let textPrimary = Color.white
        static let textSecondary = Color(white: 0.75)
        static let textMuted = Color(white: 0.4)
        static let accentBlue = Color(red: 0.35, green: 0.55, blue: 1.0)
        static let accentBlueLight = Color(red: 0.45, green: 0.65, blue: 1.0)
        static let accentBlueDark = Color(red: 0.25, green: 0.45, blue: 0.90)
        static let accentGreen = Color(red: 0.30, green: 0.85, blue: 0.55)
        static let accentRed = Color(red: 0.95, green: 0.35, blue: 0.40)
        static let border = Color(white: 0.35)
        static let inputBackground = Color(red: 0.16, green: 0.16, blue: 0.18)
    }
}
