import Foundation

struct ChangelogFile: Decodable {
    let releases: [ChangelogRelease]
}

struct ChangelogRelease: Decodable, Identifiable {
    let version: String
    let platform: String
    let date: String
    let highlight: String?
    let changes: [ChangelogEntry]

    var id: String { "\(platform)-\(version)" }
}

struct ChangelogEntry: Decodable, Identifiable {
    let text: String
    let type: ChangeType
    let scope: String?

    var id: String { text }
}

enum ChangeType: String, Decodable {
    case added, changed, fixed, removed

    var label: String {
        switch self {
        case .added: "New"
        case .changed: "Updated"
        case .fixed: "Fixed"
        case .removed: "Removed"
        }
    }
}
