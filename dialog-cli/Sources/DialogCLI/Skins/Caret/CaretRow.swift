import AppKit
import SwiftUI

/// The enclosure that marks a chosen option: the brand mark again, at row
/// scale. Choosing something puts it in brackets.
struct CaretRowBracket: Shape {
    var trailing: Bool
    /// A closed bracket has both arms. An open one is the bare stem — what a
    /// multi-select row shows before anything is chosen, so the person can see
    /// that each row is takeable on its own.
    var closed: Bool

    func path(in rect: CGRect) -> Path {
        let r = CaretStyle.u(2.5)
        let arm = CaretStyle.u(6)
        let x = trailing ? rect.maxX : rect.minX
        let sign: CGFloat = trailing ? -1 : 1
        var path = Path()

        if closed { path.move(to: CGPoint(x: x + sign * arm, y: rect.minY)) }
        path.move(to: CGPoint(x: x + sign * (closed ? arm : 0), y: rect.minY))
        if closed {
            path.addLine(to: CGPoint(x: x + sign * r, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: x, y: rect.minY + r), control: CGPoint(x: x, y: rect.minY))
        } else {
            path.move(to: CGPoint(x: x, y: rect.minY + r))
        }
        path.addLine(to: CGPoint(x: x, y: rect.maxY - r))
        if closed {
            path.addQuadCurve(to: CGPoint(x: x + sign * r, y: rect.maxY), control: CGPoint(x: x, y: rect.maxY))
            path.addLine(to: CGPoint(x: x + sign * arm, y: rect.maxY))
        }
        return path
    }
}

/// One option (§3.10).
///
/// Chosen and focused ride separate channels and neither borrows the other's:
/// **chosen** is the enclosure — brackets close around the row — and **focused**
/// is the caret standing beside it out on the surface's own rail. All four
/// combinations are therefore legible at once, which §3.10 requires and §10.26
/// says a style must define rather than inherit.
///
/// The indicator's *form* also differs between the two modes: a single-select
/// row is bare until it is chosen, a multi-select row carries an open bracket
/// from the first frame. That is the difference the person reads before they
/// touch anything.
struct CaretRow<Trailing: View>: View {
    let ordinal: Int
    let label: String
    let description: String?
    let chosen: Bool
    let multi: Bool
    let onActivate: () -> Void
    var onFocus: (Bool) -> Void = { _ in }
    var register: ((NSView) -> Void)? = nil
    @ViewBuilder var trailingContent: () -> Trailing

    @State private var focused = false
    @State private var hovered = false
    @State private var pressed = false
    @Environment(\.caretPalette) private var palette

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: CaretStyle.u(12)) {
            Text(String(format: "%02d", ordinal))
                .font(Font(CaretStyle.mono))
                .foregroundStyle(chosen ? palette.caret : palette.inkMuted)
                .frame(width: CaretStyle.width("00", font: CaretStyle.mono), alignment: .trailing)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: CaretStyle.u(3)) {
                // Long labels wrap. They never truncate, so an uneven set is
                // expected and correct.
                Text(label)
                    .font(Font(CaretStyle.action))
                    .kerning(CaretStyle.action.pointSize * CaretStyle.displayTracking)
                    .foregroundStyle(chosen || focused || hovered ? palette.ink : palette.inkSecond)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let description, !description.isEmpty {
                    // The caller's own words about the option, so they take the
                    // colour every other thing the agent says takes.
                    Text(description)
                        .font(Font(CaretStyle.label))
                        .foregroundStyle(palette.context)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                trailingContent()
            }
        }
        .padding(.vertical, CaretStyle.u(9))
        .padding(.horizontal, CaretStyle.u(14))
        // Rows do not shrink to fit short labels.
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CaretStyle.u(3), style: .continuous)
                .fill(pressed ? palette.railLive.opacity(0.35) : (hovered ? palette.channel : Color.clear))
        )
        .overlay(alignment: .leading) { bracket(trailing: false) }
        .overlay(alignment: .trailing) { bracket(trailing: true) }
        .contentShape(Rectangle())
        // The whole row is the target; the enclosure is not a second one.
        .overlay(
            CaretTarget(
                isContent: true,
                onActivate: onActivate,
                onFocusChange: { focused = $0; onFocus($0) },
                onPressChange: { pressed = $0 },
                onHoverChange: { hovered = $0 },
                register: register
            )
        )
        .caretStop(focused)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text(chosen ? "chosen" : "not chosen"))
    }

    @ViewBuilder
    private func bracket(trailing: Bool) -> some View {
        let visible = chosen || (multi && !trailing)
        CaretRowBracket(trailing: trailing, closed: chosen)
            .stroke(chosen ? palette.caret : palette.rail,
                    style: StrokeStyle(lineWidth: chosen ? CaretStyle.caretWidth : CaretStyle.hair, lineCap: .round))
            .frame(width: CaretStyle.u(7))
            .opacity(visible ? 1 : 0)
            .padding(.vertical, CaretStyle.u(4))
            .allowsHitTesting(false)
    }
}

extension CaretRow where Trailing == EmptyView {
    init(ordinal: Int, label: String, description: String?, chosen: Bool, multi: Bool,
         onActivate: @escaping () -> Void, onFocus: @escaping (Bool) -> Void = { _ in },
         register: ((NSView) -> Void)? = nil) {
        self.init(ordinal: ordinal, label: label, description: description, chosen: chosen,
                  multi: multi, onActivate: onActivate, onFocus: onFocus, register: register,
                  trailingContent: { EmptyView() })
    }
}

// MARK: - Count and helper

/// What is chosen, and how many may be (§7.5, and the count §10.12 asks for).
/// It sits at the head of the set rather than in a corner, because it is a
/// fact about the set.
struct CaretSetHeader: View {
    let multi: Bool
    let count: Int
    @Environment(\.caretPalette) private var palette

    var body: some View {
        Text(text)
            .font(Font(CaretStyle.monoTiny))
            .kerning(CaretStyle.monoTiny.pointSize * CaretStyle.railTracking)
            .foregroundStyle(count > 0 ? palette.caret : palette.inkMuted)
    }

    private var text: String {
        if count > 0 { return "\(count) SELECTED" }
        return multi ? "SELECT ANY" : "SELECT ONE"
    }
}

/// §10.14: an unavailable commit never explains itself anywhere in the
/// product. This is the explanation, and it appears only after the person has
/// touched the region — a freshly opened surface is not pre-scolded.
struct CaretHelper: View {
    let text: String
    @Environment(\.caretPalette) private var palette

    var body: some View {
        HStack(spacing: CaretStyle.u(7)) {
            Rectangle()
                .fill(palette.caret)
                .frame(width: CaretStyle.caretWidth, height: CaretStyle.u(11))
                .clipShape(Capsule())
            Text(text)
                .font(Font(CaretStyle.label))
                .foregroundStyle(palette.inkSecond)
        }
    }
}
