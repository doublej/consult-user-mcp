import AppKit
import SwiftUI

/// An action control. Four variants (§3.11), all distinguishable by **fill
/// weight**: primary is the only filled amber shape in the interface, secondary
/// is an outline, destructive is a filled danger shape, disabled loses its
/// outline entirely and drops the Return glyph.
///
/// The width is measured from the label with `NSFont` and set explicitly, so
/// the surface measures identically on both passes of the sizing law (§2.2).
struct BracketButton: View {
    enum Variant { case primary, secondary, destructive }

    var title: String
    var variant: Variant = .secondary
    var isEnabled: Bool = true
    /// §3.11 — the primary indicates Return **only while enabled**.
    var showsReturn: Bool = false
    /// 0…1; below 1 the control is damped and drains a remaining-time bar.
    var readiness: CGFloat = 1
    /// The snooze durations, which sit inline in the tool strip.
    var compact: Bool = false
    var action: () -> Void

    @State private var isFocused = false
    @State private var isHovering = false
    @State private var isPressed = false

    private static let returnGap: CGFloat = 9
    private static let caretLane = BracketStyle.Caret.width + 9

    private var height: CGFloat { compact ? 26 : 32 }
    private var sideInset: CGFloat { compact ? 10 : 14 }
    private var labelFont: NSFont {
        compact
            ? BracketStyle.mono(BracketStyle.Size.context, .medium)
            : BracketStyle.sans(BracketStyle.Size.action, .semibold)
    }

    private var returnGlyphShown: Bool { showsReturn && isEnabled }

    private var width: CGFloat {
        let label = (title as NSString).size(withAttributes: [.font: labelFont]).width
        let hint = returnGlyphShown
            ? Self.returnGap + ("⏎" as NSString).size(
                withAttributes: [.font: BracketStyle.mono(11, .medium)]
            ).width
            : 0
        return ceil(sideInset * 2 + Self.caretLane + label + hint)
    }

    private var fill: Color {
        guard isEnabled else { return BracketStyle.card }
        switch variant {
        case .primary: return isPressed ? BracketStyle.amberDeep : BracketStyle.amber
        case .destructive: return isPressed ? BracketStyle.danger.opacity(0.8) : BracketStyle.danger
        case .secondary: return isHovering ? BracketStyle.hover : Color.clear
        }
    }

    private var stroke: Color {
        guard isEnabled else { return .clear }
        switch variant {
        case .primary, .destructive: return .clear
        case .secondary: return BracketStyle.line
        }
    }

    private var labelColor: Color {
        guard isEnabled else { return BracketStyle.inkMuted.opacity(0.55) }
        switch variant {
        case .primary: return BracketStyle.ground
        case .destructive: return BracketStyle.ink
        case .secondary: return BracketStyle.inkSecondary
        }
    }

    /// On a filled variant the caret flips to the ground colour so the focus
    /// channel stays the same shape in the same place, always legible.
    private var caretColor: Color {
        switch variant {
        case .primary, .destructive: return BracketStyle.ground
        case .secondary: return BracketStyle.amber
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: BracketStyle.Caret.width / 2, style: .continuous)
                .fill(caretColor)
                .frame(width: BracketStyle.Caret.width, height: compact ? 12 : 15)
                .opacity(isFocused ? 1 : 0)
                .padding(.trailing, 9)

            Text(title)
                .font(Font(labelFont as CTFont))
                .foregroundColor(labelColor)
                .lineLimit(1)
                .truncationMode(.tail)

            if returnGlyphShown {
                Text("⏎")
                    .font(BracketStyle.monoFont(11, .medium))
                    .foregroundColor(labelColor.opacity(0.75))
                    .padding(.leading, Self.returnGap)
            }
        }
        .padding(.horizontal, sideInset)
        .frame(width: width, height: height)
        .background(
            RoundedRectangle(cornerRadius: BracketStyle.Radius.button, style: .continuous)
                .fill(fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: BracketStyle.Radius.button, style: .continuous)
                .strokeBorder(stroke, lineWidth: 1)
        )
        .overlay(alignment: .bottomLeading) { readinessBar }
        .clipShape(RoundedRectangle(cornerRadius: BracketStyle.Radius.button, style: .continuous))
        .opacity(readiness < 1 ? 0.42 : 1)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .gesture(pressGesture)
        .bracketFocusable(
            isButton: true,
            isFocusable: isEnabled,
            onFocusChange: { isFocused = $0 },
            onSpace: { fire() }
        )
        .accessibilityElement()
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }

    /// The §4.6 remaining-time indication: a hairline that drains along the
    /// bottom edge of every action control while input is being swallowed.
    @ViewBuilder private var readinessBar: some View {
        if readiness < 1 {
            GeometryReader { geo in
                Rectangle()
                    .fill(variant == .secondary ? BracketStyle.amber : BracketStyle.ground)
                    .frame(width: geo.size.width * (1 - readiness), height: 2)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .allowsHitTesting(false)
        }
    }

    /// §3.11 — activation requires press *and* release on the same control;
    /// dragging off cancels it. A zero-distance drag also stops the press from
    /// reaching the window's own drag handling (§2.5).
    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isPressed = isEnabled && contains(value.location)
            }
            .onEnded { value in
                let inside = contains(value.location)
                isPressed = false
                if inside { fire() }
            }
    }

    private func contains(_ point: CGPoint) -> Bool {
        point.x >= 0 && point.x <= width && point.y >= 0 && point.y <= height
    }

    private func fire() {
        guard isEnabled, readiness >= 1 else { return }
        action()
    }
}
