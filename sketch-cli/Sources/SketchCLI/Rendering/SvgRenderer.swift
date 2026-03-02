import Foundation

enum SvgRenderer {
    private static let width = 800
    private static let height = 600
    private static let background = "#1a1a1e"
    private static let gridColor = "rgba(128,128,128,0.15)"

    static func render(_ layout: GridLayout) -> String? {
        var colored = layout
        colored.blocks = ColorPalette.assignColors(to: colored.blocks)

        let chrome = frameChrome(layout.frame)
        let totalW = width + chrome.padL + chrome.padR
        let totalH = height + chrome.padT + chrome.padB
        let cellW = Double(width) / Double(layout.columns)
        let cellH = Double(height) / Double(layout.rows)

        var svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(totalW) \(totalH)" width="\(totalW)" height="\(totalH)">
        <defs>
        <filter id="elev1"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity="0.1"/></filter>
        <filter id="elev2"><feDropShadow dx="0" dy="3" stdDeviation="6" flood-opacity="0.15"/></filter>
        <filter id="elev3"><feDropShadow dx="0" dy="6" stdDeviation="12" flood-opacity="0.2"/></filter>
        </defs>
        <rect width="\(totalW)" height="\(totalH)" fill="\(background)"/>
        """

        svg += chrome.svg
        svg += "\n<g transform=\"translate(\(chrome.padL),\(chrome.padT))\">"
        svg += gridLines(columns: layout.columns, rows: layout.rows, cellW: cellW, cellH: cellH)
        svg += roleZones(colored.blocks, cellW: cellW, cellH: cellH)

        for block in colored.blocks {
            svg += blockRect(block, cellW: cellW, cellH: cellH)
        }

        if let annotations = layout.annotations {
            svg += annotationSvg(annotations, cellW: cellW, cellH: cellH)
        }

        svg += "\n</g>"

        // Legend below grid
        if let annotations = layout.annotations, !annotations.isEmpty {
            let legendY = totalH + 8
            for (i, ann) in annotations.enumerated() {
                let ly = legendY + i * 18
                svg += "\n<circle cx=\"\(chrome.padL + 8)\" cy=\"\(ly + 6)\" r=\"7\" fill=\"#f59e0b\"/>"
                svg += "\n<text x=\"\(chrome.padL + 8)\" y=\"\(ly + 10)\" fill=\"white\" font-family=\"system-ui\" font-size=\"9\" font-weight=\"bold\" text-anchor=\"middle\">\(i + 1)</text>"
                svg += "\n<text x=\"\(chrome.padL + 22)\" y=\"\(ly + 10)\" fill=\"rgba(255,255,255,0.7)\" font-family=\"system-ui\" font-size=\"11\">\(escapeXML(ann.text))</text>"
            }
        }

        svg += "\n</svg>"
        return svg
    }

    private struct FrameChrome {
        let padL: Int; let padR: Int; let padT: Int; let padB: Int
        let svg: String
    }

    private static func frameChrome(_ frame: String?) -> FrameChrome {
        guard let frame else { return FrameChrome(padL: 0, padR: 0, padT: 0, padB: 0, svg: "") }
        switch frame {
        case "browser":
            let barH = 32
            let svg = """
            \n<rect x="0" y="0" width="\(width)" height="\(barH)" rx="8" fill="#1e1e1e"/>
            <circle cx="14" cy="16" r="5" fill="#ff5f57" opacity="0.7"/>
            <circle cx="30" cy="16" r="5" fill="#febc2e" opacity="0.7"/>
            <circle cx="46" cy="16" r="5" fill="#28c840" opacity="0.7"/>
            <rect x="80" y="8" width="\(width - 160)" height="16" rx="4" fill="#151515"/>
            <text x="\(width / 2)" y="20" fill="rgba(255,255,255,0.35)" font-family="system-ui" font-size="10" text-anchor="middle">https://</text>
            """
            return FrameChrome(padL: 0, padR: 0, padT: barH, padB: 0, svg: svg)
        case "phone":
            let pad = 12, topBar = 20
            let totalPadT = pad + topBar
            let svg = """
            \n<rect x="0" y="0" width="\(width + pad * 2)" height="\(height + totalPadT + pad)" rx="20" fill="#0d0d0d" stroke="rgba(255,255,255,0.3)" stroke-width="2"/>
            <text x="\(pad + 12)" y="\(pad + 14)" fill="rgba(255,255,255,0.5)" font-family="system-ui" font-size="10" font-weight="600">9:41</text>
            """
            return FrameChrome(padL: pad, padR: pad, padT: totalPadT, padB: pad, svg: svg)
        case "tablet":
            let pad = 16
            let svg = """
            \n<rect x="0" y="0" width="\(width + pad * 2)" height="\(height + pad * 2)" rx="14" fill="#0d0d0d" stroke="rgba(255,255,255,0.25)" stroke-width="1.5"/>
            """
            return FrameChrome(padL: pad, padR: pad, padT: pad, padB: pad, svg: svg)
        default:
            return FrameChrome(padL: 0, padR: 0, padT: 0, padB: 0, svg: "")
        }
    }

    private static func annotationSvg(_ annotations: [Annotation], cellW: Double, cellH: Double) -> String {
        var svg = ""
        for (i, ann) in annotations.enumerated() {
            let cx = Double(ann.x) * cellW + cellW / 2
            let cy = Double(ann.y) * cellH + cellH / 2
            let mx = Double(ann.x) * cellW - 10
            let my = Double(ann.y) * cellH - 10
            // Leader line
            svg += "\n<line x1=\"\(format(mx + 10))\" y1=\"\(format(my + 10))\" x2=\"\(format(cx))\" y2=\"\(format(cy))\" stroke=\"#f59e0b\" opacity=\"0.4\" stroke-width=\"1\"/>"
            // Circle marker
            svg += "\n<circle cx=\"\(format(mx + 10))\" cy=\"\(format(my + 10))\" r=\"10\" fill=\"#f59e0b\"/>"
            svg += "\n<text x=\"\(format(mx + 10))\" y=\"\(format(my + 14))\" fill=\"white\" font-family=\"system-ui\" font-size=\"11\" font-weight=\"bold\" text-anchor=\"middle\">\(i + 1)</text>"
        }
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
        let elev = ContentInference.inferElevation(explicit: block.elevation, label: block.label)
        let filterAttr = elev > 0 ? " filter=\"url(#elev\(elev))\"" : ""
        let fill = hexToRGBA(hex, alpha: fillAlpha)
        let wireframeFill = hexToRGBA(hex, alpha: 0.3)

        var svg = """

        <rect x="\(format(bx))" y="\(format(by))" width="\(format(bw))" height="\(format(bh))" rx="4" fill="\(fill)" stroke="\(hex)" stroke-width="\(format(strokeW))"\(dashAttr)\(filterAttr)/>
        <text x="\(format(bx + 7))" y="\(format(by + 17))" fill="white" font-family="system-ui, sans-serif" font-size="12">\(escapeXML(block.label))</text>
        """

        if let ct = ContentInference.resolve(explicit: block.content, label: block.label) {
            svg += SvgWireframes.render(type: ct, x: bx + 8, y: by + 24, w: bw - 16, h: bh - 32, fill: wireframeFill)
        }

        if let dir = block.flowDirection {
            let arrow = dir == "row" ? "\u{2192}" : "\u{2193}"
            let ax = bx + 32
            let ay = by + 15
            svg += "\n<text x=\"\(format(ax))\" y=\"\(format(ay))\" fill=\"\(hex)\" opacity=\"0.7\" font-family=\"system-ui\" font-size=\"12\">\(arrow)</text>"
        }

        return svg
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
