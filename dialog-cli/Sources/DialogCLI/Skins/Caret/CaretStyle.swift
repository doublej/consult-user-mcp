import AppKit
import SwiftUI

/// Type and measure for the Caret layer.
///
/// The brand system names Manrope and DM Mono. Neither ships with macOS and
/// this target may not carry font resources, so both faces are substituted and
/// only the *system* survives: one geometric sans across four sizes with a
/// single weight step, one mono for every key, path and number, and Manrope's
/// negative tracking at display sizes.
///
///   Manrope  → the host UI sans (`NSFont.systemFont`)
///   DM Mono  → the host UI mono (`NSFont.monospacedSystemFont`)
///
/// Every dimension in the layer is a multiple of `unit`, which is derived from
/// the host's own text size. A surface built at one text size and rendered at
/// another therefore floors, caps and reflows against the same grid (§7.4).
enum CaretStyle {

    /// 1.0 at the stock 13pt UI text size.
    static let unit: CGFloat = max(0.75, min(1.6, NSFont.systemFontSize / 13.0))

    /// Read once. Motion is a person-level preference.
    static let animates: Bool = UserSettings.load().animationsEnabled

    /// The curve the window's own resize runs on. Anything this layer animates
    /// alongside a resize has to match it or the two read as two events.
    static let resizeDuration: Double = 0.2
    /// How long after the content changes the window's own resize actually
    /// starts. The size observer measures first and animates a turn later;
    /// measured at roughly this, and the compensation has to wait it out
    /// rather than easing through it.
    static let resizeLag: Double = 0.06

    static func u(_ value: CGFloat) -> CGFloat { value * unit }

    // MARK: - Faces
    //
    // T1 "native compact": 14 question / 12 body / 10 label / 9.5 mono keycap.
    // The statement size sits one step above the question because §3.3 makes a
    // one-line body a headline.

    static var statement: NSFont { .systemFont(ofSize: u(17.5), weight: .semibold) }
    static var question: NSFont { .systemFont(ofSize: u(14), weight: .semibold) }
    static var body: NSFont { .systemFont(ofSize: u(12), weight: .medium) }
    static var bodyEmphasis: NSFont { .systemFont(ofSize: u(12), weight: .bold) }
    static var label: NSFont { .systemFont(ofSize: u(10.5), weight: .medium) }
    static var action: NSFont { .systemFont(ofSize: u(12.5), weight: .semibold) }

    static var mono: NSFont { .monospacedSystemFont(ofSize: u(9.5), weight: .regular) }
    static var monoKey: NSFont { .monospacedSystemFont(ofSize: u(9.5), weight: .medium) }
    static var monoTiny: NSFont { .monospacedSystemFont(ofSize: u(8.5), weight: .medium) }
    static var monoCode: NSFont { .monospacedSystemFont(ofSize: u(11), weight: .regular) }

    /// Manrope sets its wordmark at -.045em and its questions at -.01em.
    static let displayTracking: CGFloat = -0.02
    static let railTracking: CGFloat = 0.14

    // MARK: - The mark at surface scale
    //
    // 40-unit construction grid: bracket stem 5 wide, arms 11 long, 30 tall
    // out of 40. Scaled here to a window: the stems become the two gutters,
    // the arms become the four corner returns.

    /// The leading gutter. Carries the caret and nothing else.
    static var caretRail: CGFloat { u(20) }
    /// The trailing gutter. Carries the tools and nothing else.
    static var toolRail: CGFloat { u(30) }
    /// Stem and arm weight.
    static var hair: CGFloat { max(1, u(1.5)) }
    /// A rail segment that is carrying focus thickens to the caret's own width.
    static var caretWidth: CGFloat { max(2, u(3)) }
    /// Arm length as a fraction of the surface width — 11/40 of the mark.
    static let armFraction: CGFloat = 0.275
    /// Fillet radius. The mark sits one `caretRail/2` inside the window on
    /// every edge, so a concentric nest wants exactly that much less radius
    /// than the window's own.
    static var fillet: CGFloat { windowRadius - caretRail / 2 }

    static var gutter: CGFloat { u(16) }
    static var lineGap: CGFloat { u(9) }
    static var blockGap: CGFloat { u(16) }
    static var rowHeight: CGFloat { u(34) }
    static var paneWidth: CGFloat { u(252) }
    static var windowRadius: CGFloat { u(14) }

    /// The measure the agent's words are set to. Bounded so a passage never
    /// runs the full width of a wide surface.
    static var proseMeasure: CGFloat { u(420) }

    /// How tall the one scrolling region may grow before it starts scrolling
    /// (§2.3). Everything outside it — the arms, the tools, the ways out —
    /// stays put.
    static var channelCap: CGFloat {
        let screen = NSScreen.main?.visibleFrame.height ?? 900
        return max(u(180), screen * 0.85 - u(190))
    }

    // MARK: - Measurement
    //
    // §2.2 is measured once. Any control whose width is not a pure function of
    // its own content makes the two `fittingSize` passes disagree, so every
    // action, keycap and rail label is measured here and framed explicitly.

    static func width(_ text: String, font: NSFont, tracking: CGFloat = 0) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        var attrs: [NSAttributedString.Key: Any] = [.font: font]
        if tracking != 0 { attrs[.kern] = font.pointSize * tracking }
        return ceil(NSAttributedString(string: text, attributes: attrs).size().width)
    }

    static func height(_ font: NSFont) -> CGFloat {
        ceil(font.ascender - font.descender + font.leading)
    }
}

// MARK: - Keycap

/// A key, drawn beside the thing it operates rather than collected into a
/// legend. §3.8 requires that what the person is told tracks live
/// availability, so a keycap has an unavailable state and renders it.
struct CaretKeycap: View {
    let glyph: String
    var available: Bool = true
    var strong: Bool = false
    @Environment(\.caretPalette) private var palette

    var body: some View {
        Text(glyph)
            .font(Font(CaretStyle.monoKey))
            .kerning(CaretStyle.monoKey.pointSize * 0.06)
            .foregroundStyle(colour)
            .frame(width: CaretStyle.width(glyph, font: CaretStyle.monoKey, tracking: 0.06) + CaretStyle.u(10),
                   height: CaretStyle.u(15))
            .background(
                RoundedRectangle(cornerRadius: CaretStyle.u(3), style: .continuous)
                    .strokeBorder(border, lineWidth: 1)
            )
            .opacity(available ? 1 : 0.4)
            .accessibilityHidden(true)
    }

    private var colour: Color {
        guard available else { return palette.inkMuted }
        return strong ? palette.caret : palette.inkSecond
    }

    private var border: Color {
        guard available else { return palette.rail }
        return strong ? palette.caret.opacity(0.55) : palette.rail
    }
}

// MARK: - Palette in the environment

private struct CaretPaletteKey: EnvironmentKey {
    static let defaultValue = CaretPalette.dark
}

extension EnvironmentValues {
    var caretPalette: CaretPalette {
        get { self[CaretPaletteKey.self] }
        set { self[CaretPaletteKey.self] = newValue }
    }
}
