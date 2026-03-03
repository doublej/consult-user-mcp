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
    @Binding var stashedBlocks: [GridBlock]
    var interactive: Bool = true
    var blockNumbers: [String: String] = [:]
    var onAddBlock: ((Int, Int) -> Void)?
    var onDragHintChanged: ((Bool, Bool, Bool) -> Void)?

    @StateObject private var cycleState = OptionCycleState()
    @State private var activeDragBlockId: String?
    @State private var activeDragOffset: CGSize = .zero
    var isDragging: Bool { activeDragBlockId != nil }
    var nestingMap: [String: String]? = nil

    var body: some View {
        GeometryReader { geo in
            let cellSize = min(geo.size.width / CGFloat(layout.columns), geo.size.height / CGFloat(layout.rows))
            let cellW = cellSize
            let cellH = cellSize
            let resolvedNesting = nestingMap ?? DescriptionRenderer.detectNesting(layout.blocks)

            ZStack(alignment: .topLeading) {
                gridBackground(cellW: cellW, cellH: cellH, size: geo.size)

                ForEach(sortedBlocks(resolvedNesting)) { block in
                    let blockBinding = binding(for: block)
                    let isNested = resolvedNesting[block.id] != nil
                    let isChildOfDragged = activeDragBlockId.map { resolvedNesting[block.id] == $0 } ?? false
                    let childOffset = isChildOfDragged ? activeDragOffset : .zero

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
                        onDuplicate: { duplicateBlock(id: block.id) },
                        onDragUpdate: { offset in
                            activeDragBlockId = offset != nil ? block.id : nil
                            activeDragOffset = offset ?? .zero
                            if let offset = offset {
                                let colDelta = Int(round(offset.width / cellW))
                                let rowDelta = Int(round(offset.height / cellH))
                                let isOverBottom = block.y + rowDelta >= layout.rows
                                let isOverSidebar = block.x + colDelta < 0
                                onDragHintChanged?(true, isOverBottom, isOverSidebar)
                            } else {
                                onDragHintChanged?(false, false, false)
                            }
                        },
                        onDragEnd: { colDelta, rowDelta in
                            moveBlock(id: block.id, colDelta: colDelta, rowDelta: rowDelta,
                                      nesting: resolvedNesting)
                        }
                    )
                    .offset(
                        x: CGFloat(block.x) * cellW + (isNested ? 3 : 1) + childOffset.width,
                        y: CGFloat(block.y) * cellH + (isNested ? 3 : 1) + childOffset.height
                    )
                }

                AlignmentGuidesView(
                    blocks: layout.blocks,
                    activeBlockId: activeDragBlockId ?? cycleState.promotedBlockId,
                    cellW: cellW, cellH: cellH,
                    gridColumns: layout.columns, gridRows: layout.rows
                )

                if let annotations = layout.annotations, !annotations.isEmpty {
                    AnnotationOverlayView(
                        annotations: annotations, cellW: cellW, cellH: cellH,
                        blocks: layout.blocks,
                        activeDragBlockId: activeDragBlockId,
                        activeDragOffset: activeDragOffset
                    )
                }
            }
            .frame(width: cellW * CGFloat(layout.columns), height: cellH * CGFloat(layout.rows))
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
            .onChange(of: layout.blocks) {
                let activeIds = Set(layout.blocks.map(\.id))
                stashedBlocks.removeAll { activeIds.contains($0.id) }
            }
            .onAppear { if interactive { cycleState.startMonitoring() } }
            .onDisappear { cycleState.stopMonitoring() }
            .frame(width: geo.size.width, height: geo.size.height)
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
            // White fill
            context.fill(Path(CGRect(origin: .zero, size: canvasSize)), with: .color(.white))
            // Light blue grid lines
            let lineColor = Color(red: 0.78, green: 0.88, blue: 0.98)
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
            // Role zone tints
            for block in layout.blocks {
                guard let tint = roleTint(block.role) else { continue }
                let rect = CGRect(
                    x: CGFloat(block.x) * cellW,
                    y: CGFloat(block.y) * cellH,
                    width: CGFloat(block.w) * cellW,
                    height: CGFloat(block.h) * cellH
                )
                context.fill(Path(rect), with: .color(tint))
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

    private func roleTint(_ role: String?) -> Color? {
        guard let role, let blockRole = BlockRole(rawValue: role) else { return nil }
        let t = RoleZoneTint.from(blockRole)
        return Color(red: t.r / 255, green: t.g / 255, blue: t.b / 255).opacity(t.a)
    }

    private func moveBlock(id: String, colDelta: Int, rowDelta: Int, nesting: [String: String]) {
        guard let block = layout.blocks.first(where: { $0.id == id }) else { return }
        let childIds = Set(nesting.filter { $0.value == id }.map(\.key))

        // Stash: unclamped target exceeds grid bottom or left edge
        if block.y + rowDelta >= layout.rows || block.x + colDelta < 0 {
            let removed = layout.blocks.filter { $0.id == id || childIds.contains($0.id) }
            stashedBlocks.append(contentsOf: removed)
            layout.blocks.removeAll { $0.id == id || childIds.contains($0.id) }
            return
        }

        // Move the block
        let newX = max(0, min(layout.columns - block.w, block.x + colDelta))
        let newY = max(0, min(layout.rows - block.h, block.y + rowDelta))
        let actualDx = newX - block.x
        let actualDy = newY - block.y

        // Move annotations within the block's bounds
        if actualDx != 0 || actualDy != 0, var annotations = layout.annotations {
            for i in annotations.indices {
                let ann = annotations[i]
                if ann.x >= block.x && ann.x < block.x + block.w &&
                   ann.y >= block.y && ann.y < block.y + block.h {
                    annotations[i] = Annotation(x: ann.x + actualDx, y: ann.y + actualDy, text: ann.text)
                }
            }
            layout.annotations = annotations
        }

        if let idx = layout.blocks.firstIndex(where: { $0.id == id }) {
            layout.blocks[idx].x = newX
            layout.blocks[idx].y = newY
        }

        // Move children by the same delta
        for childId in childIds {
            guard let idx = layout.blocks.firstIndex(where: { $0.id == childId }) else { continue }
            let child = layout.blocks[idx]
            layout.blocks[idx].x = max(0, min(layout.columns - child.w, child.x + colDelta))
            layout.blocks[idx].y = max(0, min(layout.rows - child.h, child.y + rowDelta))
        }
    }

}
