import SwiftUI

struct PositionPicker: View {
    @Binding var selection: DialogPosition

    var body: some View {
        HStack(spacing: 12) {
            ForEach(DialogPosition.allCases, id: \.self) { position in
                PositionButton(
                    position: position,
                    isSelected: selection == position
                ) {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selection = position
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PositionButton: View {
    let position: DialogPosition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ScreenIcon(position: position, isSelected: isSelected)
                    .frame(height: 44)

                Text(position.label)
                    .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ScreenIcon: View {
    let position: DialogPosition
    let isSelected: Bool

    var body: some View {
        GeometryReader { geo in
            let aspectRatio: CGFloat = 16 / 9
            let iconWidth = min(geo.size.width * 0.8, geo.size.height * aspectRatio)
            let iconHeight = iconWidth / aspectRatio

            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isSelected ? Color.accentColor : Color(.separatorColor), lineWidth: isSelected ? 1.5 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(.controlBackgroundColor))
                    )
                    .frame(width: iconWidth, height: iconHeight)

                dialogIndicator(in: CGSize(width: iconWidth, height: iconHeight))
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func dialogIndicator(in size: CGSize) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isSelected ? Color.accentColor : Color(.tertiaryLabelColor))
            .frame(width: 5, height: size.height * 0.55)
            .offset(x: indicatorXOffset(in: size))
    }

    private func indicatorXOffset(in size: CGSize) -> CGFloat {
        let inset: CGFloat = 8
        switch position {
        case .left:
            return -(size.width / 2 - inset - 2.5)
        case .center:
            return 0
        case .right:
            return size.width / 2 - inset - 2.5
        }
    }
}

#Preview {
    PositionPicker(selection: .constant(.left))
        .padding()
}
