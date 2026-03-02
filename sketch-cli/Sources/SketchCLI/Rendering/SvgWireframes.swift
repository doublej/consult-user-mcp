import Foundation

/// SVG wireframe shape generators for content types.
/// Extracted from SvgRenderer to keep file sizes manageable.
enum SvgWireframes {
    static func render(type: String, x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
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
            s += "\n<rect x=\"\(fmt(x))\" y=\"\(fmt(by))\" width=\"\(fmt(barW))\" height=\"\(fmt(barH))\" rx=\"2\" fill=\"\(fill)\"/>"
        }
        return s
    }

    private static func imageSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let cx = fmt(x + w / 2)
        let cy = fmt(y + h / 2)
        return """
        \n<line x1="\(fmt(x))" y1="\(fmt(y))" x2="\(fmt(x + w))" y2="\(fmt(y + h))" stroke="\(fill)" stroke-width="1"/>
        <line x1="\(fmt(x + w))" y1="\(fmt(y))" x2="\(fmt(x))" y2="\(fmt(y + h))" stroke="\(fill)" stroke-width="1"/>
        <text x="\(cx)" y="\(cy)" fill="\(fill)" font-family="system-ui" font-size="11" text-anchor="middle" dominant-baseline="central">IMG</text>
        """
    }

    private static func videoSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let cx = x + w / 2
        let cy = y + h / 2
        let s = min(w, h) * 0.35
        let points = "\(fmt(cx - s * 0.4)),\(fmt(cy - s * 0.5)) \(fmt(cx + s * 0.5)),\(fmt(cy)) \(fmt(cx - s * 0.4)),\(fmt(cy + s * 0.5))"
        return "\n<polygon points=\"\(points)\" fill=\"\(fill)\"/>"
    }

    private static func avatarSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let r = min(w, h) * 0.25
        let cx = fmt(x + w / 2)
        let cy = fmt(y + h / 2)
        return """
        \n<circle cx="\(cx)" cy="\(cy)" r="\(fmt(r))" fill="none" stroke="\(fill)" stroke-width="1.5"/>
        <text x="\(cx)" y="\(cy)" fill="\(fill)" font-family="system-ui" font-size="10" text-anchor="middle" dominant-baseline="central">USR</text>
        """
    }

    private static func buttonSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let pw = min(w * 0.7, 80.0)
        let ph = min(h * 0.4, 20.0)
        let bx = x + (w - pw) / 2
        let by = y + (h - ph) / 2
        return "\n<rect x=\"\(fmt(bx))\" y=\"\(fmt(by))\" width=\"\(fmt(pw))\" height=\"\(fmt(ph))\" rx=\"\(fmt(ph / 2))\" fill=\"none\" stroke=\"\(fill)\" stroke-width=\"1.5\"/>"
    }

    private static func inputSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let ly = y + h - 4
        return """
        \n<line x1="\(fmt(x))" y1="\(fmt(ly))" x2="\(fmt(x + w))" y2="\(fmt(ly))" stroke="\(fill)" stroke-width="1.5"/>
        <rect x="\(fmt(x + 2))" y="\(fmt(ly - 10))" width="1.5" height="10" fill="\(fill)"/>
        """
    }

    private static func listSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let rowH = max(3.0, h * 0.1)
        let gap = max(2.0, h * 0.06)
        let count = min(5, max(2, Int(h / (rowH + gap))))
        var s = ""
        for i in 0..<count {
            let ry = y + Double(i) * (rowH + gap)
            s += "\n<circle cx=\"\(fmt(x + rowH / 2))\" cy=\"\(fmt(ry + rowH / 2))\" r=\"\(fmt(rowH / 2))\" fill=\"\(fill)\"/>"
            s += "\n<rect x=\"\(fmt(x + rowH + 4))\" y=\"\(fmt(ry))\" width=\"\(fmt(w - rowH - 4))\" height=\"\(fmt(rowH))\" rx=\"2\" fill=\"\(fill)\"/>"
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
            s += "\n<rect x=\"\(fmt(bx))\" y=\"\(fmt(by))\" width=\"\(fmt(barW))\" height=\"\(fmt(bh))\" rx=\"2\" fill=\"\(fill)\"/>"
        }
        return s
    }

    private static func mapSvg(x: Double, y: Double, w: Double, h: Double, fill: String) -> String {
        let cx = fmt(x + w / 2)
        let cy = fmt(y + h / 2)
        return """
        \n<line x1="\(cx)" y1="\(fmt(y))" x2="\(cx)" y2="\(fmt(y + h))" stroke="\(fill)" stroke-width="0.75"/>
        <line x1="\(fmt(x))" y1="\(cy)" x2="\(fmt(x + w))" y2="\(cy)" stroke="\(fill)" stroke-width="0.75"/>
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
            s += "\n<rect x=\"\(fmt(px))\" y=\"\(fmt(py))\" width=\"\(fmt(pillW))\" height=\"\(fmt(pillH))\" rx=\"\(fmt(pillH / 2))\" fill=\"\(fill)\"/>"
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
            s += "\n<rect x=\"\(fmt(x))\" y=\"\(fmt(fy))\" width=\"\(fmt(w))\" height=\"\(fmt(fieldH))\" rx=\"3\" fill=\"none\" stroke=\"\(fill)\" stroke-width=\"1\"/>"
        }
        let bx = x + (w - w * 0.5) / 2
        let by = y + h - btnH
        s += "\n<rect x=\"\(fmt(bx))\" y=\"\(fmt(by))\" width=\"\(fmt(w * 0.5))\" height=\"\(fmt(btnH))\" rx=\"\(fmt(btnH / 2))\" fill=\"\(fill)\"/>"
        return s
    }

    private static func fmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
