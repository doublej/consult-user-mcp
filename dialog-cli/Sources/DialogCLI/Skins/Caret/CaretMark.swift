import AppKit
import SwiftUI

/// One arm of the mark: how far it reaches from its stem, and — for the two
/// lower ones, which are the ways out — what state it is carrying.
struct CaretArmStyle {
    var length: CGFloat
    var tone: Color? = nil
    var thick: Bool = false
}

/// The mark at surface scale, minus its lower corners.
///
/// Two bracket stems run the height of the surface, one at each edge, each
/// returning inward at the top. The stems stop at the start of the lower
/// fillets, because those corners belong to the actions and are drawn by
/// `CaretCornerShape` in whatever colour the action is currently in — so the
/// line is continuous and is only ever drawn once.
struct CaretFrameShape: Shape {
    var topLeading: CGFloat
    var topTrailing: CGFloat
    var inset: CGFloat

    func path(in rect: CGRect) -> Path {
        let r = CaretStyle.fillet
        let top = rect.minY + inset
        let bottom = rect.maxY - inset
        let left = rect.minX + inset
        let right = rect.maxX - inset

        var path = Path()

        path.move(to: CGPoint(x: left + max(topLeading, r), y: top))
        path.addLine(to: CGPoint(x: left + r, y: top))
        path.addQuadCurve(to: CGPoint(x: left, y: top + r), control: CGPoint(x: left, y: top))
        path.addLine(to: CGPoint(x: left, y: bottom - r))

        path.move(to: CGPoint(x: right - max(topTrailing, r), y: top))
        path.addLine(to: CGPoint(x: right - r, y: top))
        path.addQuadCurve(to: CGPoint(x: right, y: top + r), control: CGPoint(x: right, y: top))
        path.addLine(to: CGPoint(x: right, y: bottom - r))

        return path
    }
}

/// One lower corner: the fillet that finishes the stem, then the arm that runs
/// inward under the action it bounds. It starts exactly where the stem stops.
struct CaretCornerShape: Shape {
    var length: CGFloat
    var trailing: Bool
    var inset: CGFloat

    func path(in rect: CGRect) -> Path {
        let r = CaretStyle.fillet
        let bottom = rect.maxY - inset
        let x = trailing ? rect.maxX - inset : rect.minX + inset
        let sign: CGFloat = trailing ? -1 : 1

        var path = Path()
        path.move(to: CGPoint(x: x, y: bottom - r))
        path.addQuadCurve(to: CGPoint(x: x + sign * r, y: bottom), control: CGPoint(x: x, y: bottom))
        path.addLine(to: CGPoint(x: x + sign * max(length, r), y: bottom))
        return path
    }
}

/// The frame plus the one thing that moves.
///
/// The caret is the focus indicator (§10.26 requires a style to define one
/// explicitly) and, while the surface is still inert, the remaining-time
/// indication for the opening cooldown (§4.6): it starts as a full-height bar
/// and retracts towards its resting position as the block expires.
struct CaretRails: View {
    let topLeading: CGFloat
    let topTrailing: CGFloat
    let bottomLeading: CaretArmStyle
    let bottomTrailing: CaretArmStyle
    let focusRect: CGRect?
    /// 1 when the surface is live; below 1 while the cooldown runs, or while
    /// a transient surface's lifetime is running out.
    let cooldown: Double
    var progressTone: Color? = nil
    var dimmed: Bool = false
    @Environment(\.caretPalette) private var palette

    private var inset: CGFloat { CaretStyle.caretRail / 2 }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                CaretFrameShape(topLeading: topLeading, topTrailing: topTrailing, inset: inset)
                    .stroke(palette.rail, style: StrokeStyle(lineWidth: CaretStyle.hair, lineCap: .round))
                    .opacity(dimmed ? 0.4 : 1)

                corner(bottomLeading, trailing: false)
                corner(bottomTrailing, trailing: true)

                if cooldown < 1 {
                    let full = geo.size.height - inset * 2
                    Capsule()
                        .fill(progressTone ?? palette.caret)
                        .opacity(0.5)
                        .frame(width: CaretStyle.caretWidth, height: max(0, full * (1 - cooldown)))
                        .position(x: inset, y: geo.size.height / 2)
                } else if let rect = focusRect {
                    // 3 units of cursor against 5 of stem, 18 of 30 tall.
                    Capsule()
                        .fill(palette.caret)
                        .frame(width: CaretStyle.caretWidth, height: max(CaretStyle.u(12), rect.height * 0.6))
                        .position(x: inset, y: rect.midY)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func corner(_ arm: CaretArmStyle, trailing: Bool) -> some View {
        CaretCornerShape(length: arm.length, trailing: trailing, inset: inset)
            .stroke(
                arm.tone ?? palette.rail,
                style: StrokeStyle(lineWidth: arm.thick ? CaretStyle.caretWidth : CaretStyle.hair, lineCap: .round)
            )
            .opacity(dimmed ? 0.4 : 1)
    }
}

// MARK: - The arms that are actions

enum CaretActionRole {
    case commit
    case decline
    case destructive
}

/// One way out. Its label only — the line beneath it is the surface's own
/// lower corner, drawn by `CaretRails`, because there is no button row here:
/// the frame's two lower arms *are* the ways out, one at each corner, so
/// decline sits before commit in reading order without any special pleading.
struct CaretAction: View {
    let label: String
    let role: CaretActionRole
    let key: String?
    /// Whether the key actually does this right now (§3.8).
    var keyAvailable: Bool = true
    var enabled: Bool = true
    /// §4.6: while the opening cooldown runs the ways out are still in the
    /// focus ring but nothing they promise will happen yet, so they render in
    /// a damped state rather than an unavailable one.
    var damped: Bool = false
    var trailing: Bool = false
    /// Only the report flow uses this: its second step has no content
    /// element, so the commit action is where Return has to land.
    var autofocus: Bool = false
    /// Points the focus target is extended upward by, so two controls sharing
    /// a row still sort into reading order. Invisible.
    var focusLift: CGFloat = 0
    var onFocus: (Bool) -> Void = { _ in }
    let action: () -> Void

    @State private var focused = false
    @State private var pressed = false
    @State private var hovered = false
    @Environment(\.caretPalette) private var palette

    static func width(label: String, key: String?) -> CGFloat {
        var w = CaretStyle.width(Self.clip(label), font: CaretStyle.action, tracking: CaretStyle.displayTracking)
        if let key {
            w += CaretStyle.width(key, font: CaretStyle.monoKey, tracking: 0.06) + CaretStyle.u(10) + CaretStyle.u(8)
        }
        return ceil(w)
    }

    /// §3.9: a label that does not fit is truncated. The action never grows
    /// and the surface is never widened to hold one.
    static func clip(_ label: String) -> String {
        let limit = 28
        guard label.count > limit else { return label }
        return String(label.prefix(limit - 1)) + "…"
    }

    /// How far the arm beneath this action has to reach to bound it.
    static func armLength(label: String, key: String?) -> CGFloat {
        CaretStyle.u(9) + width(label: label, key: key) + CaretStyle.u(10)
    }

    var body: some View {
        HStack(spacing: CaretStyle.u(8)) {
            if trailing, let key { CaretKeycap(glyph: key, available: enabled && keyAvailable, strong: role == .commit) }
            Text(Self.clip(label))
                .font(Font(CaretStyle.action))
                .kerning(CaretStyle.action.pointSize * CaretStyle.displayTracking)
                .foregroundStyle(labelColour)
                .lineLimit(1)
            if !trailing, let key { CaretKeycap(glyph: key, available: enabled && keyAvailable, strong: role == .commit) }
        }
        .frame(width: Self.width(label: label, key: key),
               height: CaretStyle.u(20),
               alignment: trailing ? .trailing : .leading)
        .padding(trailing ? .trailing : .leading, CaretStyle.u(9))
        .contentShape(Rectangle())
        .overlay(
            CaretTarget(
                isContent: false,
                isEnabled: enabled,
                takesReturn: true,
                onActivate: action,
                onFocusChange: { focused = $0; onFocus($0) },
                onPressChange: { pressed = $0 },
                onHoverChange: { hovered = $0 },
                register: autofocus ? { view in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                        view.window?.makeFirstResponder(view)
                    }
                } : nil
            )
            .padding(.top, -focusLift)
        )
        .caretStop(focused)
        .accessibilityLabel(Text(label))
    }

    private var labelColour: Color {
        guard enabled else { return palette.inkMuted.opacity(0.55) }
        if damped { return palette.inkMuted }
        if pressed { return palette.caret }
        switch role {
        case .commit: return palette.ink
        case .decline: return hovered || focused ? palette.ink : palette.inkSecond
        case .destructive: return palette.danger
        }
    }

    /// The four variants of §3.9 live on the arm: an available commit arm is
    /// amber, a decline arm is a live rail, destructive is danger, and
    /// unavailable falls back to a dead rail — which is also how the commit
    /// arm drops its promise that Return will work.
    static func armTone(role: CaretActionRole, enabled: Bool, damped: Bool, focused: Bool, palette: CaretPalette) -> Color {
        guard enabled, !damped else { return palette.rail }
        switch role {
        case .commit: return palette.caret
        case .decline: return focused ? palette.railLive : palette.rail
        case .destructive: return palette.danger
        }
    }
}
