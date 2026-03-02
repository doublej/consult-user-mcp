import AppKit
import Foundation

enum GitHubReporter {
    private static let repo = "doublej/consult-user-mcp"

    static func openIssue() {
        var components = URLComponents(string: "https://github.com/\(repo)/issues/new")!
        components.queryItems = [
            URLQueryItem(name: "title", value: "Layout editor: "),
            URLQueryItem(name: "body", value: "## Description\n\n\n## Environment\n- Component: sketch-cli (layout editor)"),
            URLQueryItem(name: "labels", value: "bug"),
        ]
        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }
}
