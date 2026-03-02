import Foundation

struct BlockInput: Codable {
    let label: String
    let x: Int
    let y: Int
    let w: Int
    let h: Int
    let color: String?
    let content: String?
    let role: String?
    let flowDirection: String?
    let importance: String?
    let elevation: Int?
}

struct ProposeLayoutRequest: Codable {
    let width: Int?
    let height: Int?
    let template: String?
    let title: String?
    let description: String?
    let blocks: [BlockInput]?
    let structure: LayoutNode?
    let theme: String?
    let frame: String?

    func resolvedLayout() -> GridLayout {
        var cols = width ?? 12
        var rows = height ?? 8
        let resolvedFrame = frame ?? (template == "mobile" ? "phone" : nil)

        if let templateName = template,
           let tmpl = DensityTemplate.builtIn.first(where: { $0.name == templateName }) {
            cols = tmpl.width
            rows = tmpl.height
        }

        cols = max(3, min(20, cols))
        rows = max(3, min(20, rows))

        if let structure {
            let gridBlocks = LayoutCompiler.compile(structure, columns: cols, rows: rows)
            return GridLayout(columns: cols, rows: rows, blocks: gridBlocks, frame: resolvedFrame)
        }

        let inputBlocks = blocks ?? []
        let gridBlocks = inputBlocks.map { input in
            GridBlock(
                label: input.label,
                x: input.x, y: input.y,
                w: input.w, h: input.h,
                color: input.color,
                content: input.content,
                role: input.role,
                flowDirection: input.flowDirection,
                importance: input.importance,
                elevation: input.elevation
            )
        }

        return GridLayout(columns: cols, rows: rows, blocks: gridBlocks, frame: resolvedFrame)
    }
}

struct DescribeRequest: Codable {
    let columns: Int
    let rows: Int
    let blocks: [BlockInput]?
    let structure: LayoutNode?
    let detail: String?

    func resolvedBlocks() -> [GridBlock] {
        if let structure {
            return LayoutCompiler.compile(structure, columns: columns, rows: rows)
        }
        return (blocks ?? []).map {
            GridBlock(label: $0.label, x: $0.x, y: $0.y, w: $0.w, h: $0.h, color: $0.color, content: $0.content, role: $0.role, flowDirection: $0.flowDirection, importance: $0.importance, elevation: $0.elevation)
        }
    }
}
