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
        svg += roleZones(colored.blocks, cellW: cellW, cellH: cellH)

        for block in colored.blocks {
            svg += blockRect(block, cellW: cellW, cellH: cellH)
        }

        svg += "\n</svg>"
        return svg
    }

    private static func roleZones(_ blocks: [GridBlock], cellW: Double, cellH: Double) -> String {
        var svg = ""
        for block in blocks {
            guard let fill = roleZoneFill(block.role) else { continue }
            let rx = format(Double(block.x) * cellW)
            let ry = format(Double(block.y) * cellH)
            let rw = format(Double(block.w) * cellW)
            let rh = format(Double(block.h) * cellH)
            svg += "\n<rect x=\"\(rx)\" y=\"\(ry)\" width=\"\(rw)\" height=\"\(rh)\" fill=\"\(fill)\"/>"
        }
        return svg
    }

    private static func roleZoneFill(_ role: String?) -> String? {
        switch role {
        case "header", "footer": return "rgba(160,140,120,0.05)"
        case "sidebar", "toolbar": return "rgba(120,140,170,0.05)"
        case "canvas", "panel": return "rgba(128,128,128,0.03)"
        default: return nil
        }
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
        let bx = Double(block.x) * cellW + 1
        let by = Double(block.y) * cellH + 1
        let bw = Double(block.w) * cellW - 2
        let bh = Double(block.h) * cellH - 2
        let imp = ContentInference.inferImportance(explicit: block.importance, role: block.role)
        let fillAlpha: Double = imp == "primary" ? 0.35 : imp == "tertiary" ? 0.12 : 0.25
        let strokeW: Double = imp == "primary" ? 2.5 : imp == "tertiary" ? 0.5 : 1.5
        let dashAttr = imp == "tertiary" ? " stroke-dasharray=\"4 3\"" : ""
        let fill = hexToRGBA(hex, alpha: fillAlpha)
        let wireframeFill = hexToRGBA(hex, alpha: 0.3)

        var svg = """

        <rect x="\(format(bx))" y="\(format(by))" width="\(format(bw))" height="\(format(bh))" rx="4" fill="\(fill)" stroke="\(hex)" stroke-width="\(format(strokeW))"\(dashAttr)/>
        <text x="\(format(bx + 7))" y="\(format(by + 17))" fill="white" font-family="system-ui, sans-serif" font-size="12">\(escapeXML(block.label))</text>
        """

        if let ct = ContentInference.resolve(explicit: block.content, label: block.label) {
            svg += wireframeSvg(type: ct, x: bx + 8, y: by + 24, w: bw - 16, h: bh - 32, fill: wireframeFill)
        }

        if let dir = block.flowDirection {
            let arrow = dir == "row" ? "\u{2192}" : "\u{2193}"
            let ax = bx + 32
            let ay = by + 15
            svg += "\n<text x=\"\(format(ax))\" y=\"\(format(ay))\" fill=\"\(hex)\" opacity=\"0.7\" font-family=\"system-ui\" font-size=\"12\">\(arrow)</text>"
        }

        return svg
    }

    private static func wireframeSvg(type: String, x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        guard w > 4, h > 4 else { return "" }
        switch type {
        case "text": return textSvg(x: x, y: y, w: w, h: h, fill: fill)
        case "image": return imageSvg(x: x, y: y, w: w, h: h, fill: fill)
        case "video": return videoSvg(x: x, y: y, w: w, h: h, fill: fill)
        case "avatar": return avatarSvg(x: x, y: y, w: w, h: h, fill: fill)
        case "button": return buttonSvg(x: x, y: y, w: w, h: h, fill: fill)
        case "input": return inputSvg(x: x, y: y, w: w, h: h, fill: fill)
        case "list": return listSvg(x: x, y: y, w: w, h: h, fill: fill)
        case "chart": return chartSvg(x: x, y: y, w: w, h: h, fill: fill)
        case "map": return mapSvg(x: x, y: y, w: w, h: h, fill: fill)
        case "nav": return navSvg(x: x, y: y, w: w, h: h, fill: fill)
        case "form": return formSvg(x: x, y: y, w: w, h: h, fill: fill)
        default: return ""
        }
    }

    private static func textSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let barH = max(3.0, h * 0.12)
        let gap = max(2.0, h * 0.08)
        let count = min(4, max(2, Int(h / (barH + gap))))
        var s = ""
        for i in 0..<count {
            let barW = i == count - 1 ? w * 0.6 : w
            let by = y + Double(i) * (barH + gap)
            s += "\n<rect x=\"\(format(x))\" y=\"\(format(by))\" width=\"\(format(barW))\" height=\"\(format(barH))\" rx=\"2\" fill=\"\(fill)\"/>"
        }
        return s
    }

    private static func imageSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let cx = format(x + w / 2)
        let cy = format(y + h / 2)
        return """
        \n<line x1="\(format(x))" y1="\(format(y))" x2="\(format(x + w))" y2="\(format(y + h))" stroke="\(fill)" stroke-width="1"/>
        <line x1="\(format(x + w))" y1="\(format(y))" x2="\(format(x))" y2="\(format(y + h))" stroke="\(fill)" stroke-width="1"/>
        <text x="\(cx)" y="\(cy)" fill="\(fill)" font-family="system-ui" font-size="11" text-anchor="middle" dominant-baseline="central">IMG</text>
        """
    }

    private static func videoSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let cx = x + w / 2
        let cy = y + h / 2
        let s = min(w, h) * 0.35
        let points = "\(format(cx - s * 0.4)),\(format(cy - s * 0.5)) \(format(cx + s * 0.5)),\(format(cy)) \(format(cx - s * 0.4)),\(format(cy + s * 0.5))"
        return "\n<polygon points=\"\(points)\" fill=\"\(fill)\"/>"
    }

    private static func avatarSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let r = min(w, h) * 0.25
        let cx = format(x + w / 2)
        let cy = format(y + h / 2)
        return """
        \n<circle cx="\(cx)" cy="\(cy)" r="\(format(r))" fill="none" stroke="\(fill)" stroke-width="1.5"/>
        <text x="\(cx)" y="\(cy)" fill="\(fill)" font-family="system-ui" font-size="10" text-anchor="middle" dominant-baseline="central">USR</text>
        """
    }

    private static func buttonSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let pw = min(w * 0.7, 80.0)
        let ph = min(h * 0.4, 20.0)
        let bx = x + (w - pw) / 2
        let by = y + (h - ph) / 2
        return "\n<rect x=\"\(format(bx))\" y=\"\(format(by))\" width=\"\(format(pw))\" height=\"\(format(ph))\" rx=\"\(format(ph / 2))\" fill=\"none\" stroke=\"\(fill)\" stroke-width=\"1.5\"/>"
    }

    private static func inputSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let ly = y + h - 4
        return """
        \n<line x1="\(format(x))" y1="\(format(ly))" x2="\(format(x + w))" y2="\(format(ly))" stroke="\(fill)" stroke-width="1.5"/>
        <rect x="\(format(x + 2))" y="\(format(ly - 10))" width="1.5" height="10" fill="\(fill)"/>
        """
    }

    private static func listSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let rowH = max(3.0, h * 0.1)
        let gap = max(2.0, h * 0.06)
        let count = min(5, max(2, Int(h / (rowH + gap))))
        var s = ""
        for i in 0..<count {
            let ry = y + Double(i) * (rowH + gap)
            s += "\n<circle cx=\"\(format(x + rowH / 2))\" cy=\"\(format(ry + rowH / 2))\" r=\"\(format(rowH / 2))\" fill=\"\(fill)\"/>"
            s += "\n<rect x=\"\(format(x + rowH + 4))\" y=\"\(format(ry))\" width=\"\(format(w - rowH - 4))\" height=\"\(format(rowH))\" rx=\"2\" fill=\"\(fill)\"/>"
        }
        return s
    }

    private static func chartSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let count = min(5, max(3, Int(w / 16)))
        let gap = 4.0
        let barW = (w - Double(count - 1) * gap) / Double(count)
        let heights: [Double] = [0.6, 0.9, 0.4, 0.75, 0.5]
        var s = ""
        for i in 0..<count {
            let bh = h * heights[i % heights.count]
            let bx = x + Double(i) * (barW + gap)
            let by = y + h - bh
            s += "\n<rect x=\"\(format(bx))\" y=\"\(format(by))\" width=\"\(format(barW))\" height=\"\(format(bh))\" rx=\"2\" fill=\"\(fill)\"/>"
        }
        return s
    }

    private static func mapSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let cx = format(x + w / 2)
        let cy = format(y + h / 2)
        return """
        \n<line x1="\(cx)" y1="\(format(y))" x2="\(cx)" y2="\(format(y + h))" stroke="\(fill)" stroke-width="0.75"/>
        <line x1="\(format(x))" y1="\(cy)" x2="\(format(x + w))" y2="\(cy)" stroke="\(fill)" stroke-width="0.75"/>
        <text x="\(cx)" y="\(cy)" fill="\(fill)" font-family="system-ui" font-size="11" text-anchor="middle" dominant-baseline="central">MAP</text>
        """
    }

    private static func navSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let count = min(4, max(2, Int(w / 30)))
        let gap = 4.0
        let pillW = (w - Double(count - 1) * gap) / Double(count)
        let pillH = min(h * 0.4, 16.0)
        let py = y + (h - pillH) / 2
        var s = ""
        for i in 0..<count {
            let px = x + Double(i) * (pillW + gap)
            s += "\n<rect x=\"\(format(px))\" y=\"\(format(py))\" width=\"\(format(pillW))\" height=\"\(format(pillH))\" rx=\"\(format(pillH / 2))\" fill=\"\(fill)\"/>"
        }
        return s
    }

    private static func formSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let fieldH = max(3.0, h * 0.1)
        let gap = max(2.0, h * 0.06)
        let count = min(3, max(1, Int((h * 0.7) / (fieldH + gap))))
        let btnH = min(h * 0.15, 16.0)
        var s = ""
        for i in 0..<count {
            let fy = y + Double(i) * (fieldH + gap)
            s += "\n<rect x=\"\(format(x))\" y=\"\(format(fy))\" width=\"\(format(w))\" height=\"\(format(fieldH))\" rx=\"3\" fill=\"none\" stroke=\"\(fill)\" stroke-width=\"1\"/>"
        }
        let bx = x + (w - w * 0.5) / 2
        let by = y + h - btnH
        s += "\n<rect x=\"\(format(bx))\" y=\"\(format(by))\" width=\"\(format(w * 0.5))\" height=\"\(format(btnH))\" rx=\"\(format(btnH / 2))\" fill=\"\(fill)\"/>"
        return s
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
