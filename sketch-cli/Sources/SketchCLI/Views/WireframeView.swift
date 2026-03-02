import SwiftUI

struct WireframeView: View {
    let contentType: String
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            wireframe(for: contentType, width: w, height: h)
                .opacity(0.3)
        }
        .padding(6)
    }

    @ViewBuilder
    private func wireframe(for type: String, width: CGFloat, height: CGFloat) -> some View {
        switch type {
        case "text": textWireframe(width: width, height: height)
        case "image": imageWireframe(width: width, height: height)
        case "video": videoWireframe(width: width, height: height)
        case "avatar": avatarWireframe(width: width, height: height)
        case "button": buttonWireframe(width: width, height: height)
        case "input": inputWireframe(width: width, height: height)
        case "list": listWireframe(width: width, height: height)
        case "chart": chartWireframe(width: width, height: height)
        case "map": mapWireframe(width: width, height: height)
        case "nav": navWireframe(width: width, height: height)
        case "form": formWireframe(width: width, height: height)
        default: EmptyView()
        }
    }

    private func textWireframe(width: CGFloat, height: CGFloat) -> some View {
        let barH = max(3, height * 0.12)
        let gap = max(2, height * 0.08)
        let count = min(4, max(2, Int(height / (barH + gap))))
        return VStack(alignment: .leading, spacing: gap) {
            ForEach(0..<count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: i == count - 1 ? width * 0.6 : width, height: barH)
            }
        }
    }

    private func imageWireframe(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Diagonal cross
            Path { p in
                p.move(to: .zero)
                p.addLine(to: CGPoint(x: width, y: height))
                p.move(to: CGPoint(x: width, y: 0))
                p.addLine(to: CGPoint(x: 0, y: height))
            }
            .stroke(color, lineWidth: 1)
            Image(systemName: "photo")
                .font(.system(size: min(width, height) * 0.25))
                .foregroundColor(color)
        }
    }

    private func videoWireframe(width: CGFloat, height: CGFloat) -> some View {
        let size = min(width, height) * 0.4
        return Path { p in
            let cx = width / 2
            let cy = height / 2
            p.move(to: CGPoint(x: cx - size * 0.4, y: cy - size * 0.5))
            p.addLine(to: CGPoint(x: cx + size * 0.5, y: cy))
            p.addLine(to: CGPoint(x: cx - size * 0.4, y: cy + size * 0.5))
            p.closeSubpath()
        }
        .fill(color)
    }

    private func avatarWireframe(width: CGFloat, height: CGFloat) -> some View {
        let size = min(width, height) * 0.5
        return ZStack {
            Circle()
                .stroke(color, lineWidth: 1.5)
                .frame(width: size, height: size)
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.45))
                .foregroundColor(color)
        }
    }

    private func buttonWireframe(width: CGFloat, height: CGFloat) -> some View {
        let pillW = min(width * 0.7, 100.0)
        let pillH = min(height * 0.4, 24.0)
        return RoundedRectangle(cornerRadius: pillH / 2)
            .stroke(color, lineWidth: 1.5)
            .frame(width: pillW, height: pillH)
    }

    private func inputWireframe(width: CGFloat, height: CGFloat) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 0) {
                Rectangle().fill(color).frame(width: 1.5, height: 14)
                Rectangle().fill(color).frame(height: 1.5)
            }
            .frame(height: 14)
        }
    }

    private func listWireframe(width: CGFloat, height: CGFloat) -> some View {
        let rowH = max(3, height * 0.1)
        let gap = max(2, height * 0.06)
        let count = min(5, max(2, Int(height / (rowH + gap))))
        return VStack(alignment: .leading, spacing: gap) {
            ForEach(0..<count, id: \.self) { _ in
                HStack(spacing: 6) {
                    Circle().fill(color).frame(width: rowH, height: rowH)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(height: rowH)
                }
            }
        }
    }

    private func chartWireframe(width: CGFloat, height: CGFloat) -> some View {
        let barCount = min(5, max(3, Int(width / 16)))
        let barW = max(4, (width - CGFloat(barCount - 1) * 4) / CGFloat(barCount))
        let heights: [CGFloat] = [0.6, 0.9, 0.4, 0.75, 0.5]
        return HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: barW, height: height * heights[i % heights.count])
            }
        }
    }

    private func mapWireframe(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Crosshair
            Path { p in
                p.move(to: CGPoint(x: width / 2, y: 0))
                p.addLine(to: CGPoint(x: width / 2, y: height))
                p.move(to: CGPoint(x: 0, y: height / 2))
                p.addLine(to: CGPoint(x: width, y: height / 2))
            }
            .stroke(color, lineWidth: 0.75)
            Image(systemName: "mappin")
                .font(.system(size: min(width, height) * 0.25))
                .foregroundColor(color)
        }
    }

    private func navWireframe(width: CGFloat, height: CGFloat) -> some View {
        let count = min(4, max(2, Int(width / 30)))
        let gap: CGFloat = 4
        let pillW = (width - CGFloat(count - 1) * gap) / CGFloat(count)
        let pillH = min(height * 0.4, 18.0)
        return HStack(spacing: gap) {
            ForEach(0..<count, id: \.self) { _ in
                RoundedRectangle(cornerRadius: pillH / 2)
                    .fill(color)
                    .frame(width: pillW, height: pillH)
            }
        }
    }

    private func formWireframe(width: CGFloat, height: CGFloat) -> some View {
        let fieldH = max(3, height * 0.1)
        let gap = max(2, height * 0.06)
        let count = min(3, max(1, Int((height * 0.7) / (fieldH + gap))))
        let btnH = min(height * 0.15, 18.0)
        return VStack(spacing: gap) {
            ForEach(0..<count, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 3)
                    .stroke(color, lineWidth: 1)
                    .frame(height: fieldH)
            }
            Spacer()
            RoundedRectangle(cornerRadius: btnH / 2)
                .fill(color)
                .frame(width: width * 0.5, height: btnH)
        }
    }
}
