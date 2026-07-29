import AppKit
import SwiftUI

/// The mark at surface scale.
///
/// Two bracket stems run the full height of the surface, one at each edge,
/// each returning inward at the top and the bottom — the `[` and `]` of the
/// brand mark, drawn as the window's own structure rather than as an icon.
/// Every arm is exactly as long as the label it bounds, so the frame is a
/// pure function of what the surface is carrying.
struct CaretFrameShape: Shape {
    /// Arm lengths measured from the stem, in order: top-leading,
    /// top-trailing, bottom-leading, bottom-trailing.
    var arms: (CGFloat, CGFloat, CGFloat, CGFloat)
    var stemInset: CGFloat
    var verticalInset: CGFloat

    func path(in rect: CGRect) -> Path {
        let r = CaretStyle.fillet
        let top = rect.minY + verticalInset
        let bottom = rect.maxY - verticalInset
        let left = rect.minX + stemInset
        let right = rect.maxX - stemInset

        var path = Path()

        // Opening bracket.
        path.move(to: CGPoint(x: left + max(arms.0, r), y: top))
        path.addLine(to: CGPoint(x: left + r, y: top))
        path.addQuadCurve(to: CGPoint(x: left, y: top + r), control: CGPoint(x: left, y: top))
        path.addLine(to: CGPoint(x: left, y: bottom - r))
        path.addQuadCurve(to: CGPoint(x: left + r, y: bottom), control: CGPoint(x: left, y: bottom))
        path.addLine(to: CGPoint(x: left + max(arms.2, r), y: bottom))

        // Closing bracket.
        path.move(to: CGPoint(x: right - max(arms.1, r), y: top))
        path.addLine(to: CGPoint(x: right - r, y: top))
        path.addQuadCurve(to: CGPoint(x: right, y: top + r), control: CGPoint(x: right, y: top))
        path.addLine(to: CGPoint(x: right, y: bottom - r))
        path.addQuadCurve(to: CGPoint(x: right - r, y: bottom), control: CGPoint(x: right, y: bottom))
        path.addLine(to: CGPoint(x: right - max(arms.3, r), y: bottom))

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
    let arms: (CGFloat, CGFloat, CGFloat, CGFloat)
    let focusRect: CGRect?
    /// 1 when the surface is live; below 1 while the cooldown runs.
    let cooldown: Double
    var dimmed: Bool = false
    @Environment(\.caretPalette) private var palette

    private var stemInset: CGFloat { CaretStyle.caretRail / 2 }
    private var vInset: CGFloat { CaretStyle.u(6) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                CaretFrameShape(arms: arms, stemInset: stemInset, verticalInset: vInset)
                    .stroke(palette.rail, style: StrokeStyle(lineWidth: CaretStyle.hair, lineCap: .round))
                    .opacity(dimmed ? 0.4 : 1)

                if cooldown < 1 {
                    let full = geo.size.height - vInset * 2
                    let length = full * (1 - cooldown)
                    Capsule()
                        .fill(palette.caret)
                        .opacity(0.5)
                        .frame(width: CaretStyle.caretWidth, height: max(0, length))
                        .position(x: stemInset, y: geo.size.height / 2)
                } else if let rect = focusRect {
                    // 3 units of cursor against 5 of stem, 18 of 30 tall.
                    let height = max(CaretStyle.u(12), rect.height * 0.6)
                    Capsule()
                        .fill(palette.caret)
                        .frame(width: CaretStyle.caretWidth, height: height)
                        .position(x: stemInset, y: rect.midY)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - The arms that are actions

enum CaretActionRole {
    case commit
    case decline
    case destructive
}

/// One way out, drawn on the arm that bounds it.
///
/// There is no button row: the surface's two lower arms are the ways out, one
/// at each corner, so decline sits before commit in reading order and Tab
/// reaches them in the order §3.9 requires without any special pleading.
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

    /// The arm this action is drawn on: label above, arm beneath, the arm
    /// running back to the stem it belongs to.
    var body: some View {
        let text = Self.clip(label)
        VStack(alignment: trailing ? .trailing : .leading, spacing: CaretStyle.u(6)) {
            HStack(spacing: CaretStyle.u(8)) {
                if trailing, let key { CaretKeycap(glyph: key, available: enabled && keyAvailable, strong: role == .commit) }
                Text(text)
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
                    onFocusChange: { focused = $0 },
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

            Rectangle()
                .fill(armColour)
                .frame(width: Self.width(label: label, key: key) + CaretStyle.u(9),
                       height: focused ? CaretStyle.caretWidth : CaretStyle.hair)
        }
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

    /// The four variants of §3.9 live here: an available commit arm is amber,
    /// a decline arm is a live rail, destructive is danger, and unavailable
    /// falls back to a dead rail — which is also how the commit arm drops its
    /// promise that Return will work.
    private var armColour: Color {
        guard enabled, !damped else { return palette.rail }
        if pressed { return palette.caret }
        switch role {
        case .commit: return palette.caret
        case .decline: return hovered || focused ? palette.railLive : palette.rail
        case .destructive: return palette.danger
        }
    }
}
