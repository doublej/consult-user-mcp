import AppKit

/// Palette for the Bracket skin.
///
/// The locked brand system is: graphite ground, one saturated colour (alert
/// amber) and a sand tone that carries everything the *agent* said. The
/// `ThemeProtocol` slot names are legacy and carry no design intent here —
/// `accentBlue` is the amber, `accentGreen` is the sand.
struct BracketTheme: ThemeProtocol {
    let name = "bracket"

    // Ground — N3 graphite.
    let windowBackground = NSColor(hex: 0x232326)
    let cardBackground = NSColor(hex: 0x2D2D31)
    let cardHover = NSColor(hex: 0x35353A)
    /// Amber at 12% over the card: a warm graphite that reads as "chosen"
    /// without being the accent itself.
    let cardSelected = NSColor(hex: 0x463B30)

    let textPrimary = NSColor(hex: 0xF2F2F4)
    let textSecondary = NSColor(hex: 0xC3C3C8)
    let textMuted = NSColor(hex: 0x98989F)

    /// P4 alert amber, oklch(0.78 0.16 68). The only saturated colour.
    let accentBlue = NSColor(hex: 0xF9A129)
    /// Pressed / on-light amber, oklch(0.66 0.15 68).
    let accentBlueDark = NSColor(hex: 0xCD7D00)
    /// A4 sand — agent context, never selection.
    let accentGreen = NSColor(hex: 0xD6BC96)
    let accentRed = NSColor(hex: 0xF2595A)

    let border = NSColor(hex: 0x3A3A40)
    /// A well, recessed below the window ground rather than raised above it.
    let inputBackground = NSColor(hex: 0x1C1C1F)

    let cornerRadius: CGFloat = 14
    let buttonRadius: CGFloat = 7
    let cardRadius: CGFloat = 8
}

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
