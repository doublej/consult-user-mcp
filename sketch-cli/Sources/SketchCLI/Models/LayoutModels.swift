import Foundation

struct GridBlock: Codable, Identifiable, Equatable {
    let id: String
    var label: String
    var x: Int
    var y: Int
    var w: Int
    var h: Int
    var color: String?
    var content: String?
    var role: String?
    var flowDirection: String?
    var importance: String?
    var elevation: Int?

    init(id: String = UUID().uuidString, label: String, x: Int, y: Int, w: Int, h: Int, color: String? = nil, content: String? = nil, role: String? = nil, flowDirection: String? = nil, importance: String? = nil, elevation: Int? = nil) {
        self.id = id
        self.label = label
        self.x = x
        self.y = y
        self.w = w
        self.h = h
        self.color = color
        self.content = content
        self.role = role
        self.flowDirection = flowDirection
        self.importance = importance
        self.elevation = elevation
    }
}

struct GridLayout: Codable, Equatable {
    var columns: Int
    var rows: Int
    var blocks: [GridBlock]
    var frame: String?
}

struct DensityTemplate: Codable {
    let name: String
    let width: Int
    let height: Int
    let density: String
    let description: String
    let maxBlocks: Int

    static let builtIn: [DensityTemplate] = [
        DensityTemplate(
            name: "compact",
            width: 6, height: 4,
            density: "low",
            description: "Simple layouts with 2-4 blocks",
            maxBlocks: 4
        ),
        DensityTemplate(
            name: "standard",
            width: 12, height: 8,
            density: "medium",
            description: "General purpose layout (default)",
            maxBlocks: 12
        ),
        DensityTemplate(
            name: "spacious",
            width: 16, height: 10,
            density: "high",
            description: "Complex dashboards with many sections",
            maxBlocks: 20
        ),
        DensityTemplate(
            name: "detailed",
            width: 20, height: 16,
            density: "very high",
            description: "High-fidelity wireframes",
            maxBlocks: 30
        ),
        DensityTemplate(
            name: "mobile",
            width: 4, height: 12,
            density: "medium",
            description: "Tall narrow mobile layouts",
            maxBlocks: 8
        ),
    ]
}
