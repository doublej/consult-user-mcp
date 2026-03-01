import AppKit
import SwiftUI

final class OptionCycleState: ObservableObject {
    @Published var promotedBlockId: String?

    private var overlappingIds: [String] = []
    private var eventMonitor: Any?
    private var optionWasDown = false

    func update(point: CGPoint, blocks: [GridBlock], cellW: CGFloat, cellH: CGFloat) {
        overlappingIds = blocks.filter { b in
            CGRect(x: CGFloat(b.x) * cellW, y: CGFloat(b.y) * cellH,
                   width: CGFloat(b.w) * cellW, height: CGFloat(b.h) * cellH).contains(point)
        }.map(\.id)
        if let promoted = promotedBlockId, !overlappingIds.contains(promoted) {
            promotedBlockId = nil
        }
    }

    func clearHover() {
        overlappingIds = []
        promotedBlockId = nil
    }

    func startMonitoring() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlags(event)
            return event
        }
    }

    func stopMonitoring() {
        guard let monitor = eventMonitor else { return }
        NSEvent.removeMonitor(monitor)
        eventMonitor = nil
    }

    private func handleFlags(_ event: NSEvent) {
        let optionDown = event.modifierFlags.contains(.option)
        defer { optionWasDown = optionDown }
        guard optionDown && !optionWasDown, overlappingIds.count > 1 else { return }

        let idx = promotedBlockId.flatMap { overlappingIds.firstIndex(of: $0) }
        let next = (idx ?? -1) + 1
        promotedBlockId = overlappingIds[next % overlappingIds.count]
    }

    deinit { stopMonitoring() }
}

struct GridCanvasView: View {
    @Binding var layout: GridLayout
    var interactive: Bool = true
    var blockNumbers: [String: String] = [:]
    var onAddBlock: ((Int, Int) -> Void)?

    @StateObject private var cycleState = OptionCycleState()
    var nestingMap: [String: String]? = nil

    var body: some View {
        GeometryReader { geo in
            let cellW = geo.size.width / CGFloat(layout.columns)
            let cellH = geo.size.height / CGFloat(layout.rows)
            let resolvedNesting = nestingMap ?? DescriptionRenderer.detectNesting(layout.blocks)

            ZStack(alignment: .topLeading) {
                gridBackground(cellW: cellW, cellH: cellH, size: geo.size)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                ForEach(sortedBlocks(resolvedNesting)) { block in
                    let blockBinding = binding(for: block)
                    let isNested = resolvedNesting[block.id] != nil
                    BlockView(
                        block: blockBinding,
                        cellWidth: cellW,
                        cellHeight: cellH,
                        gridColumns: layout.columns,
                        gridRows: layout.rows,
                        interactive: interactive,
                        isNested: isNested,
                        hoverOverride: cycleState.promotedBlockId.map { $0 == block.id },
                        displayNumber: blockNumbers[block.id] ?? "",
                        onDelete: { deleteBlock(id: block.id) },
                        onRename: { newLabel in renameBlock(id: block.id, label: newLabel) },
                        onDuplicate: { duplicateBlock(id: block.id) }
                    )
                    .offset(
                        x: CGFloat(block.x) * cellW + (isNested ? 3 : 1),
                        y: CGFloat(block.y) * cellH + (isNested ? 3 : 1)
                    )
                }
            }
            .coordinateSpace(name: "canvas")
            .onContinuousHover { phase in
                guard interactive else { return }
                switch phase {
                case .active(let location):
                    cycleState.update(point: location, blocks: layout.blocks, cellW: cellW, cellH: cellH)
                case .ended:
                    cycleState.clearHover()
                }
            }
            .onAppear { if interactive { cycleState.startMonitoring() } }
            .onDisappear { cycleState.stopMonitoring() }
        }
    }

    /// Sort blocks: parents first, nested children after their parents
    private func sortedBlocks(_ nestingMap: [String: String]) -> [GridBlock] {
        let parents = layout.blocks.filter { nestingMap[$0.id] == nil }
        let children = layout.blocks.filter { nestingMap[$0.id] != nil }
        return parents + children
    }

    private func gridBackground(cellW: CGFloat, cellH: CGFloat, size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let lineColor = Color(Theme.gridLines)
            for col in 0 ... layout.columns {
                let x = CGFloat(col) * cellW
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: canvasSize.height))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
            }
            for row in 0 ... layout.rows {
                let y = CGFloat(row) * cellH
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: canvasSize.width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
            guard interactive else { return }
            let col = Int(location.x / cellW)
            let row = Int(location.y / cellH)
            guard col >= 0, col < layout.columns, row >= 0, row < layout.rows else { return }
            let occupied = layout.blocks.contains { b in
                col >= b.x && col < b.x + b.w && row >= b.y && row < b.y + b.h
            }
            if !occupied {
                onAddBlock?(col, row)
            }
        }
    }

    private func binding(for block: GridBlock) -> Binding<GridBlock> {
        Binding(
            get: { layout.blocks.first(where: { $0.id == block.id }) ?? block },
            set: { newValue in
                if let idx = layout.blocks.firstIndex(where: { $0.id == block.id }) {
                    layout.blocks[idx] = newValue
                }
            }
        )
    }

    private func deleteBlock(id: String) {
        layout.blocks.removeAll { $0.id == id }
    }

    private func renameBlock(id: String, label: String) {
        if let idx = layout.blocks.firstIndex(where: { $0.id == id }) {
            layout.blocks[idx].label = label
        }
    }

    private func duplicateBlock(id: String) {
        guard let original = layout.blocks.first(where: { $0.id == id }) else { return }

        // Offset the duplicate slightly (1 cell right, 1 cell down)
        let duplicate = GridBlock(
            label: "\(original.label) Copy",
            x: min(original.x + 1, layout.columns - original.w),
            y: min(original.y + 1, layout.rows - original.h),
            w: original.w,
            h: original.h,
            color: original.color
        )

        layout.blocks.append(duplicate)
    }
}
