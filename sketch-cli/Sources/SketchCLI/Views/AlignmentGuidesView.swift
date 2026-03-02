import SwiftUI

struct AlignmentGuidesView: View {
    let blocks: [GridBlock]
    let activeBlockId: String?
    let cellW: CGFloat
    let cellH: CGFloat
    let gridColumns: Int
    let gridRows: Int

    var body: some View {
        Canvas { context, size in
            guard let activeId = activeBlockId,
                  let active = blocks.first(where: { $0.id == activeId }) else { return }

            let guideColor = Color.cyan.opacity(0.4)
            let activeEdges = blockEdges(active)

            for block in blocks where block.id != activeId {
                let edges = blockEdges(block)
                // Shared vertical edges (x-coordinates)
                for ax in activeEdges.xs {
                    guard edges.xs.contains(ax) else { continue }
                    let x = CGFloat(ax) * cellW
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: .color(guideColor), lineWidth: 0.5)
                }
                // Shared horizontal edges (y-coordinates)
                for ay in activeEdges.ys {
                    guard edges.ys.contains(ay) else { continue }
                    let y = CGFloat(ay) * cellH
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(guideColor), lineWidth: 0.5)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func blockEdges(_ b: GridBlock) -> (xs: Set<Int>, ys: Set<Int>) {
        (xs: [b.x, b.x + b.w], ys: [b.y, b.y + b.h])
    }
}
