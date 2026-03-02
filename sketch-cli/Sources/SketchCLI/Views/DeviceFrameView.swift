import SwiftUI

struct DeviceFrameView<Content: View>: View {
    let frame: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        switch frame {
        case "browser": browserFrame
        case "phone": phoneFrame
        case "tablet": tabletFrame
        default: content()
        }
    }

    private var browserFrame: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack(spacing: 6) {
                Circle().fill(Color.red.opacity(0.7)).frame(width: 10, height: 10)
                Circle().fill(Color.yellow.opacity(0.7)).frame(width: 10, height: 10)
                Circle().fill(Color.green.opacity(0.7)).frame(width: 10, height: 10)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.15))
                    .frame(height: 20)
                    .overlay(
                        Text("https://")
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.45))
                    )
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(white: 0.12))

            content()
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(white: 0.25), lineWidth: 1)
        )
    }

    private var phoneFrame: some View {
        VStack(spacing: 0) {
            // Status bar
            HStack {
                Text("9:41")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(white: 0.5))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(white: 0.08))

            content()
        }
        .padding(6)
        .background(Color(white: 0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color(white: 0.3), lineWidth: 2)
        )
    }

    private var tabletFrame: some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(8)
        .background(Color(white: 0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(white: 0.25), lineWidth: 1.5)
        )
    }
}
