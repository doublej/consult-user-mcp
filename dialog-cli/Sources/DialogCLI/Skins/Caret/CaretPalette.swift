import AppKit
import SwiftUI

/// Every colour the Caret layer draws with.
///
/// This is the only file in the layer that names a colour value. Everything
/// else reads a role off the active palette, so a second palette is a second
/// value of this struct and nothing else changes (spec §7.4).
///
/// Values come from the locked brand system: graphite ground, alert amber as
/// the single saturated colour, sand for agent context. The two amber values
/// are `oklch(0.78 0.16 68)` and `oklch(0.66 0.15 68)` converted to sRGB.
struct CaretPalette {
    let id: String
    /// Drives nothing visual by itself — it tells the report overlay and the
    /// note pane which direction to tint towards.
    let isLight: Bool

    /// The ground the whole surface sits on.
    let window: Color
    /// Raised ground: the annotation pane, the postpone tray, a pressed target.
    let channel: Color
    /// The bracket rails and arms at rest.
    let rail: Color
    /// A rail that is carrying something — a hovered target, an open tool.
    let railLive: Color

    let ink: Color
    let inkSecond: Color
    let inkMuted: Color
    /// Sand. Everything the agent says, so it never competes with the caret.
    let context: Color

    /// The caret. The only saturated colour on the surface.
    let caret: Color
    /// The single-colour cut of the mark — the caret at 45%, used where amber
    /// would read as an alarm (spec §5.6) or as unavailable.
    let caretQuiet: Color
    /// Type set on an amber field.
    let onCaret: Color
    let danger: Color

    /// Wash laid over the surface while the report flow owns it.
    let veil: Color

    static let dark = CaretPalette(
        id: "dark",
        isLight: false,
        window: Color(caretHex: 0x232326),
        channel: Color(caretHex: 0x2D2D31),
        rail: Color(caretHex: 0x4A4A52),
        railLive: Color(caretHex: 0x71717D),
        ink: Color(caretHex: 0xF2F2F4),
        inkSecond: Color(caretHex: 0xC3C3C8),
        inkMuted: Color(caretHex: 0x98989F),
        context: Color(caretHex: 0xD6BC96),
        caret: Color(caretHex: 0xF9A129),
        caretQuiet: Color(caretHex: 0xF2F2F4, opacity: 0.45),
        onCaret: Color(caretHex: 0x232326),
        danger: Color(caretHex: 0xF2595A),
        veil: Color(caretHex: 0x0E0E10, opacity: 0.82)
    )

    static let light = CaretPalette(
        id: "light",
        isLight: true,
        window: Color(caretHex: 0xEFEDE8),
        channel: Color(caretHex: 0xFAFAF8),
        rail: Color(caretHex: 0xD5D1C8),
        railLive: Color(caretHex: 0xA8A296),
        ink: Color(caretHex: 0x1B1B1F),
        inkSecond: Color(caretHex: 0x57544E),
        inkMuted: Color(caretHex: 0x6E6A62),
        context: Color(caretHex: 0x7A5C2E),
        caret: Color(caretHex: 0xCD7D00),
        caretQuiet: Color(caretHex: 0x1B1B1F, opacity: 0.45),
        onCaret: Color(caretHex: 0xFFF6E7),
        danger: Color(caretHex: 0xB53230),
        veil: Color(caretHex: 0xEFEDE8, opacity: 0.86)
    )

    /// `DIALOG_THEME` is the product's colour-scheme input (spec §6.2).
    /// Anything unrecognised falls back to the default, which is dark.
    static func resolve() -> CaretPalette {
        let requested = ProcessInfo.processInfo.environment["DIALOG_THEME"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
        switch requested {
        case "light", "paper", "day": return .light
        default: return .dark
        }
    }
}

// MARK: - Theme bridge

/// `preferredTheme` is how a palette reaches anything the layer did not draw.
/// The Caret layer draws everything except the `tweak` surface, which it hands
/// to the default style on purpose (spec §7.3) — this is what stops that one
/// surface from arriving unstyled.
struct CaretTheme: ThemeProtocol {
    let palette: CaretPalette

    var name: String { "caret-\(palette.id)" }

    var windowBackground: NSColor { NSColor(palette.window) }
    var cardBackground: NSColor { NSColor(palette.channel) }
    var cardHover: NSColor { NSColor(palette.railLive) }
    var cardSelected: NSColor { NSColor(palette.caret).withAlphaComponent(0.18) }

    var textPrimary: NSColor { NSColor(palette.ink) }
    var textSecondary: NSColor { NSColor(palette.inkSecond) }
    var textMuted: NSColor { NSColor(palette.inkMuted) }

    var accentBlue: NSColor { NSColor(palette.caret) }
    var accentBlueDark: NSColor { NSColor(palette.caret).blended(withFraction: 0.2, of: .black) ?? NSColor(palette.caret) }
    var accentGreen: NSColor { NSColor(palette.context) }
    var accentRed: NSColor { NSColor(palette.danger) }

    var border: NSColor { NSColor(palette.rail) }
    var inputBackground: NSColor { NSColor(palette.channel) }

    var cornerRadius: CGFloat { 12 }
    var buttonRadius: CGFloat { 3 }
    var cardRadius: CGFloat { 3 }
}

// MARK: - Hex

private extension Color {
    init(caretHex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((caretHex >> 16) & 0xFF) / 255,
            green: Double((caretHex >> 8) & 0xFF) / 255,
            blue: Double(caretHex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
