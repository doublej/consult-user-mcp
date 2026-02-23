import Foundation
import AppKit

enum UninstallManager {
    private static let tagName = "consult-user-mcp-baseprompt"

    struct RemovalItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    static func removalTargets(keepData: Bool) -> [RemovalItem] {
        var items: [RemovalItem] = []

        for target in InstallTarget.allCases {
            if isMCPConfigured(for: target) {
                items.append(RemovalItem(
                    icon: "doc.text",
                    title: "MCP config: \(target.displayName)",
                    detail: target.configPath
                ))
            }
            if target.supportsBasePrompt, isBasePromptInstalled(for: target) {
                items.append(RemovalItem(
                    icon: "text.bubble",
                    title: "Base prompt: \(target.displayName)",
                    detail: target.claudeMdPath ?? ""
                ))
            }
        }

        items.append(RemovalItem(
            icon: "app",
            title: "Application bundle",
            detail: "/Applications/Consult User MCP.app"
        ))

        if !keepData {
            items.append(RemovalItem(
                icon: "folder",
                title: "Settings and history",
                detail: "~/Library/Application Support/ConsultUserMCP"
            ))
            items.append(RemovalItem(
                icon: "doc.badge.gearshape",
                title: "Projects file",
                detail: "~/.config/consult-user-mcp/projects.json"
            ))
        }

        return items
    }

    static func run(keepData: Bool) {
        for target in InstallTarget.allCases {
            removeMCPConfig(for: target)
            if target.supportsBasePrompt {
                removeBasePrompt(for: target)
            }
        }

        if !keepData {
            removeAppData()
        }

        moveAppToTrash()
        terminateApp()
    }

    // MARK: - Detection

    private static func isMCPConfigured(for target: InstallTarget) -> Bool {
        let path = target.expandedPath
        guard FileManager.default.fileExists(atPath: path),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return false
        }

        switch target.configFormat {
        case .json:
            return content.contains("consult-user-mcp")
        case .toml:
            return content.contains("[mcp_servers.consult-user-mcp]")
        }
    }

    private static func isBasePromptInstalled(for target: InstallTarget) -> Bool {
        guard let path = target.claudeMdExpandedPath,
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return false
        }
        return content.contains("<\(tagName)") || content.contains("# Consult User MCP")
    }

    // MARK: - Removal

    private static func removeMCPConfig(for target: InstallTarget) {
        let path = target.expandedPath
        guard FileManager.default.fileExists(atPath: path),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return
        }

        switch target.configFormat {
        case .json:
            removeJSONEntry(path: path, content: content)
        case .toml:
            removeTOMLSection(path: path, content: content)
        }
    }

    private static func removeJSONEntry(path: String, content: String) {
        guard let data = content.data(using: .utf8),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var mcpServers = json["mcpServers"] as? [String: Any],
              mcpServers["consult-user-mcp"] != nil else {
            return
        }

        mcpServers.removeValue(forKey: "consult-user-mcp")

        if mcpServers.isEmpty {
            json.removeValue(forKey: "mcpServers")
        } else {
            json["mcpServers"] = mcpServers
        }

        if let updatedData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) {
            try? updatedData.write(to: URL(fileURLWithPath: path))
        }
    }

    private static func removeTOMLSection(path: String, content: String) {
        var updated = content.replacingOccurrences(
            of: #"(?ms)^\s*\[mcp_servers\.consult-user-mcp\][\s\S]*?(?=^\s*\[|\z)"#,
            with: "",
            options: .regularExpression
        )

        if updated == content { return }

        updated = updated.replacingOccurrences(
            of: #"(\r?\n){3,}"#,
            with: "\n\n",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        if !updated.isEmpty {
            updated += "\n"
        }

        try? updated.write(toFile: path, atomically: true, encoding: .utf8)
    }

    private static func removeBasePrompt(for target: InstallTarget) {
        guard let path = target.claudeMdExpandedPath,
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return
        }

        let tagPattern = "\\s*<\(tagName) version=\"[^\"]+\">[\\s\\S]*?</\(tagName)>\\s*"
        var updated = content.replacingOccurrences(
            of: tagPattern,
            with: "\n\n",
            options: .regularExpression
        )

        updated = updated.replacingOccurrences(
            of: #"(?ms)^\s*# Consult User MCP[\s\S]*?(?=^#[^#]|\z)"#,
            with: "",
            options: .regularExpression
        )

        if updated == content { return }

        updated = updated.replacingOccurrences(
            of: #"(\r?\n){3,}"#,
            with: "\n\n",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        if updated.isEmpty {
            try? FileManager.default.removeItem(atPath: path)
        } else {
            try? (updated + "\n").write(toFile: path, atomically: true, encoding: .utf8)
        }
    }

    private static func removeAppData() {
        let fm = FileManager.default

        let appSupportPath = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("ConsultUserMCP").path
        if let path = appSupportPath, fm.fileExists(atPath: path) {
            try? fm.removeItem(atPath: path)
        }

        let projectsPath = ("~/.config/consult-user-mcp/projects.json" as NSString).expandingTildeInPath
        if fm.fileExists(atPath: projectsPath) {
            try? fm.removeItem(atPath: projectsPath)
        }

        let configDir = ("~/.config/consult-user-mcp" as NSString).expandingTildeInPath
        if fm.fileExists(atPath: configDir),
           (try? fm.contentsOfDirectory(atPath: configDir))?.isEmpty == true {
            try? fm.removeItem(atPath: configDir)
        }
    }

    private static func moveAppToTrash() {
        let appPath = "/Applications/Consult User MCP.app"
        let url = URL(fileURLWithPath: appPath)
        guard FileManager.default.fileExists(atPath: appPath) else { return }

        var resultingURL: NSURL?
        try? FileManager.default.trashItem(at: url, resultingItemURL: &resultingURL)
    }

    private static func terminateApp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.terminate(nil)
        }
    }
}
