import Foundation

struct Rect {
    var x: Int
    var y: Int
    var w: Int
    var h: Int
}

enum LayoutCompiler {
    static func compile(_ node: LayoutNode, columns: Int, rows: Int) -> [GridBlock] {
        var blocks: [GridBlock] = []
        compile(node, bounds: Rect(x: 0, y: 0, w: columns, h: rows), into: &blocks)
        return blocks
    }

    private static func compile(_ node: LayoutNode, bounds: Rect, into blocks: inout [GridBlock]) {
        guard bounds.w > 0, bounds.h > 0 else { return }

        if node.emitsBlock {
            blocks.append(GridBlock(
                label: node.displayLabel,
                x: bounds.x, y: bounds.y,
                w: bounds.w, h: bounds.h,
                color: node.color,
                role: node.role,
                flowDirection: node.layout?.direction
            ))
        }

        guard let children = node.children, !children.isEmpty else { return }

        let direction = node.layout?.resolvedDirection ?? .column
        let gap = node.layout?.gap ?? 0
        let childRects = distribute(children, direction: direction, gap: gap, bounds: bounds)

        for (child, rect) in zip(children, childRects) {
            compile(child, bounds: rect, into: &blocks)
        }
    }

    private static func distribute(
        _ children: [LayoutNode],
        direction: LayoutNodeLayout.Direction,
        gap: Int,
        bounds: Rect
    ) -> [Rect] {
        let totalGap = max(0, gap * (children.count - 1))
        let available = (direction == .row ? bounds.w : bounds.h) - totalGap
        guard available > 0 else { return children.map { _ in Rect(x: bounds.x, y: bounds.y, w: 0, h: 0) } }

        // Resolve fixed sizes
        var sizes = children.map { child -> Int? in
            let dim = direction == .row ? child.constraints?.width : child.constraints?.height
            guard let dim else { return nil }
            switch dim {
            case .fixed(let n): return n
            case .hug: return 1
            case .fill: return nil
            }
        }

        let fixedTotal = sizes.compactMap { $0 }.reduce(0, +)
        let fillCount = sizes.filter { $0 == nil }.count
        let remaining = max(0, available - fixedTotal)

        if fillCount > 0 {
            let totalPriority = children.enumerated()
                .filter { sizes[$0.offset] == nil }
                .map { $0.element.priority ?? 1 }
                .reduce(0, +)

            var distributed = 0
            var fillIndex = 0
            let fillIndices = sizes.enumerated().filter { $0.element == nil }.map(\.offset)

            for (i, idx) in fillIndices.enumerated() {
                let priority = children[idx].priority ?? 1
                let isLast = i == fillIndices.count - 1
                let share = isLast
                    ? remaining - distributed
                    : (totalPriority > 0 ? remaining * priority / totalPriority : remaining / fillCount)
                sizes[idx] = max(1, share)
                distributed += sizes[idx]!
                fillIndex += 1
            }
        }

        // Clamp if overflows
        let total = sizes.compactMap { $0 }.reduce(0, +)
        if total > available {
            let scale = Double(available) / Double(total)
            for i in sizes.indices {
                sizes[i] = max(1, Int(Double(sizes[i]!) * scale))
            }
        }

        // Build rects
        var rects: [Rect] = []
        var offset = direction == .row ? bounds.x : bounds.y

        for (i, size) in sizes.enumerated() {
            let s = size ?? 1
            let rect: Rect
            if direction == .row {
                rect = Rect(x: offset, y: bounds.y, w: s, h: bounds.h)
            } else {
                rect = Rect(x: bounds.x, y: offset, w: bounds.w, h: s)
            }
            rects.append(rect)
            offset += s + (i < sizes.count - 1 ? gap : 0)
        }

        return rects
    }
}
