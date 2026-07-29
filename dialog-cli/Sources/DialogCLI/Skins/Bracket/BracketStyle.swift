import AppKit
import SwiftUI

/// Type, rhythm and the two signature atoms (the mark, the focus caret).
///
/// **Face substitution.** The locked direction names Manrope + DM Mono. A skin
/// may not add SPM resources, so neither face can ship. The *system* is kept —
/// a round geometric sans against a narrow mono, one weight step between roles,
/// tight negative tracking at display size — and the faces are substituted with
/// SF Pro Rounded and SF Mono, both of which macOS ships.
enum BracketStyle {

    // MARK: - Faces

    static func sans(_ size: CGFloat, _ weight: NSFont.Weight = .medium) -> NSFont {
        let base = NSFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded),
              let rounded = NSFont(descriptor: descriptor, size: size) else { return base }
        return rounded
    }

    static func mono(_ size: CGFloat, _ weight: NSFont.Weight = .medium) -> NSFont {
        NSFont.monospacedSystemFont(ofSize: size, weight: weight)
    }

    static func sansFont(_ size: CGFloat, _ weight: NSFont.Weight = .medium) -> Font {
        Font(sans(size, weight) as CTFont)
    }

    static func monoFont(_ size: CGFloat, _ weight: NSFont.Weight = .medium) -> Font {
        Font(mono(size, weight) as CTFont)
    }

    // MARK: - Scale (T1 native compact)

    enum Size {
        /// Mono, uppercase, tracked — the surface-kind label and every keycap.
        static let label: CGFloat = 9.5
        /// The question, presented as a statement.
        static let statement: CGFloat = 16
        /// The question, presented as prose, and the surface title.
        static let body: CGFloat = 12.5
        /// Option labels.
        static let option: CGFloat = 12.5
        /// Option descriptions and other agent context.
        static let context: CGFloat = 11
        /// Action-control labels.
        static let action: CGFloat = 12.5
    }

    // MARK: - Rhythm

    enum Space {
        static let gutter: CGFloat = 18
        static let block: CGFloat = 14
        static let tight: CGFloat = 8
        static let hair: CGFloat = 4
    }

    /// The mark's cursor is 3 units wide and 18 tall on a 40-unit grid. Every
    /// focus caret in the interface is that same bar.
    enum Caret {
        static let width: CGFloat = 3
        static let ratio: CGFloat = 3.0 / 18.0
        static let gutter: CGFloat = 12
    }

    /// Mirrors `BracketTheme`, so the skin's own drawing never has to go
    /// through the theme to find out how round its own corners are.
    enum Radius {
        static let window: CGFloat = 14
        static let button: CGFloat = 7
        static let card: CGFloat = 8
        static let chip: CGFloat = 6
    }

    static let labelTracking: CGFloat = 1.35

    // MARK: - Palette shortcuts

    static var amber: Color { Theme.Colors.accentBlue }
    static var amberDeep: Color { Theme.Colors.accentBlueDark }
    static var sand: Color { Theme.Colors.accentGreen }
    static var danger: Color { Theme.Colors.accentRed }
    static var ground: Color { Theme.Colors.windowBackground }
    static var card: Color { Theme.Colors.cardBackground }
    static var hover: Color { Theme.Colors.cardHover }
    static var chosen: Color { Theme.Colors.cardSelected }
    static var line: Color { Theme.Colors.border }
    static var well: Color { Theme.Colors.inputBackground }
    static var ink: Color { Theme.Colors.textPrimary }
    static var inkSecondary: Color { Theme.Colors.textSecondary }
    static var inkMuted: Color { Theme.Colors.textMuted }

    static var amberNS: NSColor { NSColor(hex: 0xF9A129) }
    static var groundNS: NSColor { NSColor(hex: 0x232326) }

    // MARK: - The presentation switch (§3.3)

    /// A body with no line break is a statement; one containing a line break is
    /// prose. Two channels answer it here: scale/weight **and** colour — a
    /// statement is the question itself and sits in primary ink at headline
    /// size; prose is the agent explaining itself and sits in sand at body size.
    static func isStatement(_ body: String) -> Bool {
        !body.contains("\n")
    }
}

// MARK: - The mark

/// The bracket mark, drawn from the locked 40-unit construction: 5-unit stroke,
/// 1.5-unit fillets, arms 11 wide, and the 3×18 amber cursor centred between
/// them. Nothing else in the interface draws this shape.
struct BracketMark: View {
    var height: CGFloat
    var strokeColor: Color
    var cursorColor: Color

    /// Exported viewBox is `3 4 34 32`.
    private var scale: CGFloat { height / 32 }
    private var width: CGFloat { 34 * scale }

    var body: some View {
        Canvas { context, _ in
            func bar(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
                let rect = CGRect(
                    x: (x - 3) * scale, y: (y - 4) * scale,
                    width: w * scale, height: h * scale
                )
                context.fill(
                    Path(roundedRect: rect, cornerRadius: 1.5 * scale),
                    with: .color(color)
                )
            }
            bar(4, 5, 5, 30, strokeColor)
            bar(4, 5, 11, 5, strokeColor)
            bar(4, 30, 11, 5, strokeColor)
            bar(31, 5, 5, 30, strokeColor)
            bar(25, 5, 11, 5, strokeColor)
            bar(25, 30, 11, 5, strokeColor)
            bar(18.5, 11, 3, 18, cursorColor)
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - The focus caret

/// The single channel that means *focus*, everywhere in the skin: the mark's
/// own cursor, parked at the leading edge of whatever will react to Space or
/// Return. It answers §10.26 explicitly. It never carries selection, never
/// carries state, and no other element is this shape or this colour-and-shape
/// combination.
struct FocusCaret: View {
    var height: CGFloat
    var visible: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: BracketStyle.Caret.width / 2, style: .continuous)
            .fill(BracketStyle.amber)
            .frame(width: BracketStyle.Caret.width, height: height)
            .opacity(visible ? 1 : 0)
            .accessibilityHidden(true)
    }
}
