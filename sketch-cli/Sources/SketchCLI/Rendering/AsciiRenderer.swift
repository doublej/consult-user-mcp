import Foundation

enum AsciiRenderer {
    static func render(_ layout: GridLayout) -> String {
        let cols = layout.columns
        let rows = layout.rows

        // Build a grid of characters: each cell gets an abbreviation
        var grid = Array(repeating: Array(repeating: ".", count: cols), count: rows)

        // Assign short labels (first letter or first unique chars)
        let abbreviations = buildAbbreviations(layout.blocks)

        // Sort largest blocks first so smaller blocks render on top
        let sortedBlocks = layout.blocks.sorted { ($0.w * $0.h) > ($1.w * $1.h) }

        for block in sortedBlocks {
            let abbr = abbreviations[block.id] ?? "?"
            for row in block.y ..< min(block.y + block.h, rows) {
                for col in block.x ..< min(block.x + block.w, cols) {
                    grid[row][col] = abbr
                }
            }
        }

        let cellWidth = 5
        let separator = "+" + String(repeating: String(repeating: "-", count: cellWidth) + "+", count: cols)

        var lines: [String] = []
        for row in 0 ..< rows {
            lines.append(separator)
            var cellLine = "|"
            for col in 0 ..< cols {
                let content = grid[row][col]
                let padded = " " + content + String(repeating: " ", count: cellWidth - content.count - 2) + " "
                // Check if right neighbor is same block
                let rightSame = col + 1 < cols && grid[row][col] == grid[row][col + 1]
                cellLine += padded + (rightSame ? " " : "|")
            }
            lines.append(cellLine)
        }
        lines.append(separator)

        // Legend
        let legend = abbreviations.compactMap { (id, abbr) -> String? in
            guard let block = layout.blocks.first(where: { $0.id == id }) else { return nil }
            return "\(abbr)=\(block.label)"
        }.sorted().joined(separator: "  ")

        if !legend.isEmpty {
            lines.append(legend)
        }

        return lines.joined(separator: "\n")
    }

    private static func buildAbbreviations(_ blocks: [GridBlock]) -> [String: String] {
        var result: [String: String] = [:]
        var used: Set<String> = ["."]

        for block in blocks {
            let firstChar = String(block.label.prefix(1)).uppercased()
            if !used.contains(firstChar) {
                result[block.id] = firstChar
                used.insert(firstChar)
            } else {
                // Try first two chars
                let twoChar = String(block.label.prefix(2)).uppercased()
                if !used.contains(twoChar) {
                    result[block.id] = twoChar
                    used.insert(twoChar)
                } else {
                    // Fallback: label initial + index
                    var i = 2
                    while used.contains(firstChar + "\(i)") { i += 1 }
                    let key = firstChar + "\(i)"
                    result[block.id] = key
                    used.insert(key)
                }
            }
        }
        return result
    }
}
