import SwiftUI

struct AnnotationOverlayView: View {
    let annotations: [Annotation]
    let cellW: CGFloat
    let cellH: CGFloat

    private let markerSize: CGFloat = 20

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(annotations.enumerated()), id: \.offset) { index, annotation in
                let cx = CGFloat(annotation.x) * cellW + cellW / 2
                let cy = CGFloat(annotation.y) * cellH + cellH / 2
                let markerX = CGFloat(annotation.x) * cellW - markerSize / 2
                let markerY = CGFloat(annotation.y) * cellH - markerSize / 2

                // Leader line from marker to cell centre
                Path { p in
                    p.move(to: CGPoint(x: markerX + markerSize / 2, y: markerY + markerSize / 2))
                    p.addLine(to: CGPoint(x: cx, y: cy))
                }
                .stroke(Color.orange.opacity(0.4), lineWidth: 1)

                // Numbered circle
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: markerSize, height: markerSize)
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: markerX, y: markerY)
            }
        }
        .allowsHitTesting(false)
    }
}
