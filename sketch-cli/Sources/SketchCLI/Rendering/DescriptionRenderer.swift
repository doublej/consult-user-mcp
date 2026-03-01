import Foundation

enum DescriptionRenderer {
    static func render(_ layout: GridLayout, detail: String = "full") -> String {
        var lines: [String] = []
        lines.append("Layout: \(layout.columns) columns \u{00D7} \(layout.rows) rows")

        if layout.blocks.isEmpty {
            lines.append("No blocks defined.")
            return lines.joined(separator: "\n")
        }

        let nesting = detectNesting(layout.blocks)

        for block in layout.blocks {
            let colStart = block.x + 1
            let colEnd = block.x + block.w
            let rowStart = block.y + 1
            let rowEnd = block.y + block.h

            let indent = nesting[block.id] != nil ? "  " : ""
            var desc = indent + "- \"\(block.label)\""

            if detail == "brief" {
                desc += " at (\(block.x),\(block.y)) size \(block.w)\u{00D7}\(block.h)"
            } else {
                desc += " " + spatialDescription(block, in: layout)
                desc += " (cols \(colStart)\u{2013}\(colEnd), rows \(rowStart)\u{2013}\(rowEnd))"
            }

            if let parentId = nesting[block.id],
               let parent = layout.blocks.first(where: { $0.id == parentId }) {
                desc += " [nested inside \"\(parent.label)\"]"
            }

            lines.append(desc)
        }

        return lines.joined(separator: "\n")
    }

    /// Returns a map of childId -> parentId for blocks fully contained in another block
    static func detectNesting(_ blocks: [GridBlock]) -> [String: String] {
        var nesting: [String: String] = [:]

        for child in blocks {
            var bestParent: GridBlock?
            var bestArea = Int.max

            for candidate in blocks where candidate.id != child.id {
                if contains(candidate, child) {
                    let area = candidate.w * candidate.h
                    if area < bestArea {
                        bestArea = area
                        bestParent = candidate
                    }
                }
            }

            if let parent = bestParent {
                nesting[child.id] = parent.id
            }
        }

        return nesting
    }

    private static func contains(_ outer: GridBlock, _ inner: GridBlock) -> Bool {
        inner.x >= outer.x &&
        inner.y >= outer.y &&
        inner.x + inner.w <= outer.x + outer.w &&
        inner.y + inner.h <= outer.y + outer.h
    }

    private static func spatialDescription(_ block: GridBlock, in layout: GridLayout) -> String {
        let isFullWidth = block.x == 0 && block.w == layout.columns
        let isTop = block.y == 0
        let isBottom = block.y + block.h == layout.rows
        let isLeft = block.x == 0
        let isRight = block.x + block.w == layout.columns

        if isFullWidth && isTop { return "spans full width at top" }
        if isFullWidth && isBottom { return "spans full width at bottom" }
        if isFullWidth { return "spans full width" }

        var parts: [String] = []
        if isLeft { parts.append("on the left") }
        if isRight { parts.append("on the right") }
        if isTop { parts.append("at the top") }
        if isBottom { parts.append("at the bottom") }

        if parts.isEmpty {
            parts.append("in the center area")
        }

        return parts.joined(separator: ", ")
    }
}
