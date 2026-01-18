import SwiftUI

struct PositionPicker: View {
    @Binding var selection: DialogPosition

    private let iconSize = CGSize(width: 40, height: 28)
    private let spacing: CGFloat = 8

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(DialogPosition.allCases, id: \.self) { position in
                PositionButton(
                    position: position,
                    isSelected: selection == position,
                    size: iconSize
                ) {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selection = position
                    }
                }
            }
        }
    }
}

private struct PositionButton: View {
    let position: DialogPosition
    let isSelected: Bool
    let size: CGSize
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ScreenIcon(position: position, isSelected: isSelected)
                    .frame(width: size.width, height: size.height)

                Text(position.label)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ScreenIcon: View {
    let position: DialogPosition
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected ? Color.accentColor : Color(.separatorColor), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(.controlBackgroundColor))
                )

            dialogIndicator
        }
    }

    @ViewBuilder
    private var dialogIndicator: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 2)
                .fill(isSelected ? Color.accentColor : Color(.secondaryLabelColor))
                .frame(width: 4, height: geo.size.height * 0.6)
                .position(indicatorPosition(in: geo.size))
        }
    }

    private func indicatorPosition(in size: CGSize) -> CGPoint {
        let y = size.height / 2
        switch position {
        case .left:
            return CGPoint(x: 6, y: y)
        case .center:
            return CGPoint(x: size.width / 2, y: y)
        case .right:
            return CGPoint(x: size.width - 6, y: y)
        }
    }
}

#Preview {
    PositionPicker(selection: .constant(.left))
        .padding()
}
