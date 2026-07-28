import AppKit
import SwiftUI

/// Token set for the Alt skin. Applied automatically by `SkinRegistry` when
/// the skin activates, which is what restyles the shared AppKit widgets
/// (`FocusableButton`, `FocusableTextField`, `FocusableChoiceCard`) that read
/// the global `Theme`.
struct AltTheme: ThemeProtocol {
    let name = "alt"

    let windowBackground = NSColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 0.99)
    let cardBackground = NSColor(red: 0.11, green: 0.11, blue: 0.14, alpha: 1.0)
    let cardHover = NSColor(red: 0.15, green: 0.15, blue: 0.19, alpha: 1.0)
    let cardSelected = NSColor(red: 0.20, green: 0.17, blue: 0.28, alpha: 1.0)

    let textPrimary = NSColor(white: 0.96, alpha: 1.0)
    let textSecondary = NSColor(white: 0.70, alpha: 1.0)
    let textMuted = NSColor(white: 0.44, alpha: 1.0)

    let accentBlue = NSColor(red: 0.60, green: 0.45, blue: 1.0, alpha: 1.0)
    let accentBlueDark = NSColor(red: 0.48, green: 0.34, blue: 0.88, alpha: 1.0)
    let accentGreen = NSColor(red: 0.35, green: 0.82, blue: 0.62, alpha: 1.0)
    let accentRed = NSColor(red: 0.96, green: 0.42, blue: 0.44, alpha: 1.0)

    let border = NSColor(white: 0.24, alpha: 1.0)
    let inputBackground = NSColor(red: 0.09, green: 0.09, blue: 0.12, alpha: 1.0)

    // Sharper geometry than Classic — part of what makes the skin readable
    // as a different UI at a glance.
    let cornerRadius: CGFloat = 10
    let buttonRadius: CGFloat = 6
    let cardRadius: CGFloat = 4
}

// MARK: - Alt Layout Constants

/// Spacing/typography the Alt skin owns outright. Kept separate from
/// `ThemeProtocol` because those tokens are shared with the AppKit widgets,
/// while these describe only Alt's own SwiftUI layout.
enum AltMetrics {
    static let railWidth: CGFloat = 3
    static let contentPadding: CGFloat = 22
    static let sectionSpacing: CGFloat = 14
    static let contentIdealWidth: CGFloat = 400
    static let paneWidth: CGFloat = 380

    static let kickerSize: CGFloat = 10
    static let titleSize: CGFloat = 17
    static let bodySize: CGFloat = 13
}
