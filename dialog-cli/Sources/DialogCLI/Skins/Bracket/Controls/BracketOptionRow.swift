import AppKit
import SwiftUI

/// The selection indicator. Its **form** — not its colour — is what tells the
/// person whether they may choose more than one (§3.13): a disc for single
/// select, a square for multi. The state change is immediate; there is no
/// draw-in.
struct BracketIndicator: View {
    var isSelected: Bool
    var isMultiSelect: Bool

    private let side: CGFloat = 14

    private var edge: Color { isSelected ? BracketStyle.amber : BracketStyle.line }
    private var core: Color { isSelected ? BracketStyle.amber : Color.clear }

    var body: some View {
        ZStack {
            if isMultiSelect {
                RoundedRectangle(cornerRadius: 3.5, style: .continuous).fill(core)
                RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                    .strokeBorder(edge, lineWidth: 1.5)
                if isSelected {
                    Path { path in
                        path.move(to: CGPoint(x: 3.5, y: 7.2))
                        path.addLine(to: CGPoint(x: 6, y: 9.8))
                        path.addLine(to: CGPoint(x: 10.5, y: 4.4))
                    }
                    .stroke(
                        BracketStyle.ground,
                        style: StrokeStyle(lineWidth: 1.9, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: side, height: side)
                }
            } else {
                Circle().fill(core)
                Circle().strokeBorder(edge, lineWidth: 1.5)
                if isSelected {
                    Circle()
                        .fill(BracketStyle.ground)
                        .frame(width: 5, height: 5)
                }
            }
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }
}

/// One selectable option (§3.13).
///
/// Four channels, deliberately not overlapping:
/// - **selection** — the indicator fills, the row fill lifts from the ground to
///   the warm graphite, and the border warms;
/// - **focus** — the amber caret in the leading lane, and nothing else;
/// - **hover** — the row fill only;
/// - **pressed** — the row fill only, darker.
///
/// So focused-and-unselected, selected-and-unfocused, both and neither are all
/// four legible at once.
struct BracketOptionRow<Accessory: View>: View {
    var ordinal: Int
    var label: String
    var detail: String?
    var isSelected: Bool
    var isMultiSelect: Bool
    var onTap: () -> Void
    @ViewBuilder var accessory: () -> Accessory

    @State private var isFocused = false
    @State private var isHovering = false
    @State private var isPressed = false

    private var fill: Color {
        if isPressed { return BracketStyle.card }
        if isSelected { return BracketStyle.chosen }
        if isHovering { return BracketStyle.hover }
        return Color.clear
    }

    private var stroke: Color {
        isSelected ? BracketStyle.amber.opacity(0.45) : BracketStyle.line
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            FocusCaret(height: 18, visible: isFocused)
                .padding(.top, 2)
                .padding(.trailing, 9)

            Text(String(format: "%02d", ordinal))
                .font(BracketStyle.monoFont(BracketStyle.Size.label, .medium))
                .foregroundColor(BracketStyle.inkMuted.opacity(isSelected ? 0.9 : 0.6))
                .padding(.top, 3)
                .padding(.trailing, 10)

            BracketIndicator(isSelected: isSelected, isMultiSelect: isMultiSelect)
                .padding(.top, 2)
                .padding(.trailing, 10)

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(BracketStyle.sansFont(BracketStyle.Size.option, isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? BracketStyle.ink : BracketStyle.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(BracketStyle.sansFont(BracketStyle.Size.context, .regular))
                        .foregroundColor(BracketStyle.sand.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                accessory()
            }
        }
        .padding(.leading, 11)
        .padding(.trailing, 13)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: BracketStyle.Radius.card, style: .continuous)
                .fill(fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: BracketStyle.Radius.card, style: .continuous)
                .strokeBorder(stroke, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { value in
                    isPressed = false
                    // The whole row is the target, never the indicator alone.
                    if value.translation.width.magnitude < 6,
                       value.translation.height.magnitude < 6 {
                        onTap()
                    }
                }
        )
        .bracketFocusable(
            isButton: false,
            onFocusChange: { isFocused = $0 },
            onSpace: onTap
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(detail.map { "\(label). \($0)" } ?? label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

extension BracketOptionRow where Accessory == EmptyView {
    init(
        ordinal: Int,
        label: String,
        detail: String?,
        isSelected: Bool,
        isMultiSelect: Bool,
        onTap: @escaping () -> Void
    ) {
        self.init(
            ordinal: ordinal,
            label: label,
            detail: detail,
            isSelected: isSelected,
            isMultiSelect: isMultiSelect,
            onTap: onTap,
            accessory: { EmptyView() }
        )
    }
}
