import Foundation

enum SvgRenderer {
    private static let width = 800
    private static let height = 600
    private static let background = "#1a1a1e"
    private static let gridColor = "rgba(128,128,128,0.15)"

    static func render(_ layout: GridLayout) -> String? {
        var colored = layout
        colored.blocks = ColorPalette.assignColors(to: colored.blocks)

        let cellW = Double(width) / Double(layout.columns)
        let cellH = Double(height) / Double(layout.rows)

        var svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(width) \(height)" width="\(width)" height="\(height)">
        <rect width="\(width)" height="\(height)" fill="\(background)"/>
        """

        svg += gridLines(columns: layout.columns, rows: layout.rows, cellW: cellW, cellH: cellH)

        for block in colored.blocks {
            svg += blockRect(block, cellW: cellW, cellH: cellH)
        }

        svg += "\n</svg>"
        return svg
    }

    private static func gridLines(columns: Int, rows: Int, cellW: Double, cellH: Double) -> String {
        var lines = ""
        for col in 0...columns {
            let x = format(Double(col) * cellW)
            lines += "\n<line x1=\"\(x)\" y1=\"0\" x2=\"\(x)\" y2=\"\(height)\" stroke=\"\(gridColor)\" stroke-width=\"0.5\"/>"
        }
        for row in 0...rows {
            let y = format(Double(row) * cellH)
            lines += "\n<line x1=\"0\" y1=\"\(y)\" x2=\"\(width)\" y2=\"\(y)\" stroke=\"\(gridColor)\" stroke-width=\"0.5\"/>"
        }
        return lines
    }

    private static func blockRect(_ block: GridBlock, cellW: Double, cellH: Double) -> String {
        let hex = block.color ?? "#3B82F6"
        let x = format(Double(block.x) * cellW + 1)
        let y = format(Double(block.y) * cellH + 1)
        let w = format(Double(block.w) * cellW - 2)
        let h = format(Double(block.h) * cellH - 2)
        let fill = hexToRGBA(hex, alpha: 0.25)

        return """

        <rect x="\(x)" y="\(y)" width="\(w)" height="\(h)" rx="4" fill="\(fill)" stroke="\(hex)" stroke-width="1.5"/>
        <text x="\(format(Double(block.x) * cellW + 8))" y="\(format(Double(block.y) * cellH + 18))" fill="white" font-family="system-ui, sans-serif" font-size="12">\(escapeXML(block.label))</text>
        """
    }

    private static func hexToRGBA(_ hex: String, alpha: Double) -> String {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let rgb = UInt64(cleaned, radix: 16) else {
            return "rgba(59,130,246,\(alpha))"
        }
        let r = (rgb >> 16) & 0xFF
        let g = (rgb >> 8) & 0xFF
        let b = rgb & 0xFF
        return "rgba(\(r),\(g),\(b),\(alpha))"
    }

    private static func escapeXML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
