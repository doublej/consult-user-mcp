import Foundation

struct LayoutResponse: Codable {
    let status: String
    let layout: GridLayout?
    let ascii: String?
    let image: String?
    let summary: String?
    let changes: [String]?
}

struct TemplatesResponse: Codable {
    let templates: [DensityTemplate]
}

struct DescribeResponse: Codable {
    let summary: String
    let ascii: String
}
