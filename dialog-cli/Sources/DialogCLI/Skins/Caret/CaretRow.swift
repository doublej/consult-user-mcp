import AppKit
import SwiftUI

/// One option (§3.10).
///
/// Chosen and focused ride separate channels and neither borrows the other's:
/// **chosen** is the row's own leading hairline going amber, with the ordinal,
/// and **focused** is the caret standing out on the surface's rail, a rail's
/// width further out. All four combinations are therefore legible at once, which
/// §3.10 requires and §10.26 says a style must define rather than inherit.
///
/// The mark for chosen is a hairline on the row's leading edge, at the same
/// weight as the rail it sits on. Every row carries one, so choosing changes its
/// colour and nothing else — nothing appears, nothing thickens, nothing moves.
/// An enclosure that closes around the row reads as a box drawn round the
/// option and competes with the frame the whole surface is already drawn in; a
/// line that was already there does not.
///
/// The set of hairlines also does the work of showing that the options are a
/// set, and that each one is takeable on its own, in both selection modes at
/// once — so how many may be chosen is left to `CaretSetHeader` to say in
/// words, which is where §10.12 wanted it anyway.
struct CaretRow<Trailing: View>: View {
    let ordinal: Int
    let label: String
    let description: String?
    let chosen: Bool
    let onActivate: () -> Void
    var onFocus: (Bool) -> Void = { _ in }
    var register: ((NSView) -> Void)? = nil
    @ViewBuilder var trailingContent: () -> Trailing

    @State private var focused = false
    @State private var hovered = false
    @State private var pressed = false
    @Environment(\.caretPalette) private var palette
    @Environment(\.layoutDirection) private var direction

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
        .overlay(alignment: .leading) { stem }
        .contentShape(Rectangle())
        // The whole row is the target; the hairline is not a second one.
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

    /// The hairline every row carries. Filled rather than stroked, so none of it
    /// can be lost to the clip of the region it sits at the edge of — a stroke
    /// centred on the shape's own edge leaves half its width outside it.
    private var stem: some View {
        Capsule()
            .fill(chosen ? palette.caret : palette.rail)
            .frame(width: CaretStyle.hair)
            .padding(.vertical, CaretStyle.u(4))
            .allowsHitTesting(false)
    }
}

extension CaretRow where Trailing == EmptyView {
    init(ordinal: Int, label: String, description: String?, chosen: Bool,
         onActivate: @escaping () -> Void, onFocus: @escaping (Bool) -> Void = { _ in },
         register: ((NSView) -> Void)? = nil) {
        self.init(ordinal: ordinal, label: label, description: description, chosen: chosen,
                  onActivate: onActivate, onFocus: onFocus, register: register,
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
