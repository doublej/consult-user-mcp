import AppKit
import Foundation

// MARK: - GitHub Issue Reporter

struct GitHubReporter {
    private static let repo = "doublej/consult-user-mcp"

    static func openIssue(description: String, screenshotData: Data?, copyToClipboard: Bool) {
        let command = DialogManager.shared.currentCommand
        let callJSON = DialogManager.shared.currentCallJSON
        let body = buildBody(description: description, command: command, callJSON: callJSON,
                             copyToClipboard: copyToClipboard)

        if copyToClipboard, let data = screenshotData, let image = NSImage(data: data) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([image])
        }

        let title = String(description.prefix(72))
        var components = URLComponents(string: "https://github.com/\(repo)/issues/new")!
        components.queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "body", value: body),
            URLQueryItem(name: "labels", value: "bug"),
        ]
        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }

    private static func buildBody(description: String, command: String?, callJSON: String?,
                                   copyToClipboard: Bool) -> String {
        var parts: [String] = []

        parts.append("## Description\n\(description)")

        if let command, let json = callJSON {
            let prettyJSON = prettyPrint(json) ?? json
            parts.append("## MCP Call\n**Command:** `\(command)`\n```json\n\(prettyJSON)\n```")
        }

        let env = buildEnvSection()
        parts.append("## Environment\n\(env)")

        if copyToClipboard {
            parts.append("## Screenshot\n*Screenshot copied to clipboard — paste it here with ⌘V*")
        }

        parts.append("---\n*Reported via Consult User MCP*")

        return parts.joined(separator: "\n\n")
    }

    private static func buildEnvSection() -> String {
        var lines: [String] = []
        if let path = DialogManager.shared.getProjectPath() {
            lines.append("- Project: `\(path)`")
        }
        lines.append("- Client: `\(DialogManager.shared.getClientName())`")
        return lines.joined(separator: "\n")
    }

    private static func prettyPrint(_ jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted)
        else { return nil }
        return String(data: pretty, encoding: .utf8)
    }
}
