import Foundation

enum ContentInference {
    private static let mapping: [(keywords: [String], content: String)] = [
        (["image", "photo", "hero", "banner", "thumbnail", "logo"], "image"),
        (["video", "player"], "video"),
        (["avatar", "profile pic"], "avatar"),
        (["button", "cta", "action"], "button"),
        (["input", "search", "field"], "input"),
        (["list", "feed", "items"], "list"),
        (["chart", "graph", "stats", "analytics"], "chart"),
        (["map", "location"], "map"),
        (["nav", "menu", "tabs", "breadcrumb"], "nav"),
        (["form", "signup", "login", "register", "contact"], "form"),
    ]

    static func infer(from label: String) -> String? {
        let lower = label.lowercased()
        for (keywords, content) in mapping {
            if keywords.contains(where: { lower.contains($0) }) {
                return content
            }
        }
        return nil
    }

    static func resolve(explicit: String?, label: String) -> String? {
        explicit ?? infer(from: label)
    }

    static func inferImportance(explicit: String?, role: String?) -> String {
        if let explicit { return explicit }
        switch role {
        case "canvas": return "primary"
        case "header", "sidebar": return "secondary"
        case "toolbar", "panel", "footer": return "tertiary"
        default: return "secondary"
        }
    }
}
