import SwiftUI

struct AnnotationOverlayView: View {
    let annotations: [Annotation]
    let cellW: CGFloat
    let cellH: CGFloat
    var blocks: [GridBlock] = []
    var activeDragBlockId: String? = nil
    var activeDragOffset: CGSize = .zero

    private let markerSize: CGFloat = 20

    private func ownerBlock(for annotation: Annotation) -> GridBlock? {
        blocks.first { b in
            annotation.x >= b.x && annotation.x < b.x + b.w &&
            annotation.y >= b.y && annotation.y < b.y + b.h
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(annotations.enumerated()), id: \.offset) { index, annotation in
                let owner = ownerBlock(for: annotation)
                let isLinked = activeDragBlockId != nil && owner?.id == activeDragBlockId
                let dragOff = isLinked ? activeDragOffset : CGSize.zero

                let cx = CGFloat(annotation.x) * cellW + cellW / 2 + dragOff.width
                let cy = CGFloat(annotation.y) * cellH + cellH / 2 + dragOff.height
                let markerX = CGFloat(annotation.x) * cellW - markerSize / 2 + dragOff.width
                let markerY = CGFloat(annotation.y) * cellH - markerSize / 2 + dragOff.height

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
