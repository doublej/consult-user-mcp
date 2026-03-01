import Foundation

struct LayoutNodeConstraints: Codable {
    let width: DimensionValue?
    let height: DimensionValue?
}

struct LayoutNodeLayout: Codable {
    let direction: String?
    let gap: Int?

    var resolvedDirection: Direction {
        direction == "row" ? .row : .column
    }

    enum Direction {
        case row, column
    }
}

enum DimensionValue: Codable {
    case fixed(Int)
    case hug
    case fill

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            self = .fixed(intVal)
        } else if let strVal = try? container.decode(String.self) {
            switch strVal {
            case "hug": self = .hug
            case "fill": self = .fill
            default: self = .fill
            }
        } else {
            self = .fill
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .fixed(let n): try container.encode(n)
        case .hug: try container.encode("hug")
        case .fill: try container.encode("fill")
        }
    }
}

struct LayoutNode: Codable {
    let id: String
    let role: String?
    let label: String?
    let children: [LayoutNode]?
    let constraints: LayoutNodeConstraints?
    let layout: LayoutNodeLayout?
    let priority: Int?
    let color: String?

    var displayLabel: String { label ?? id }
    var isLeaf: Bool { children == nil || children!.isEmpty }
    var emitsBlock: Bool { isLeaf || role != nil }
}
