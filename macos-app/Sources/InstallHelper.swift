import Foundation

// MARK: - Install Helper

enum InstallHelper {

    static func performInstall(for answers: InstallAnswers, with serverPath: String) -> InstallResult {
        let target = answers.target
        let path = target.expandedPath
        let fm = FileManager.default

        let dir = (path as NSString).deletingLastPathComponent
        try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)

        let mcpSuccess: Bool
        switch target.configFormat {
        case .json:
            mcpSuccess = installJSON(target: target, mcpServer: serverPath)
        case .toml:
            mcpSuccess = installTOML(target: target, mcpServer: serverPath)
        }

        var promptSuccess = true
        var promptError: String?
        if answers.target.supportsBasePrompt && answers.includeBasePrompt && answers.basePromptMode != .skip {
            do {
                try ClaudeMdInstaller.install(for: target, mode: answers.basePromptMode)
            } catch {
                promptSuccess = false
                promptError = error.localizedDescription
            }
        }

        return InstallResult(
            mcpConfigSuccess: mcpSuccess,
            basePromptSuccess: promptSuccess,
            basePromptError: promptError
        )
    }

    static func installJSON(target: InstallTarget, mcpServer serverPath: String) -> Bool {
        let path = target.expandedPath
        let fm = FileManager.default
        var config: [String: Any] = [:]

        if let data = fm.contents(atPath: path),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            config = json
        }

        var mcpServers = config["mcpServers"] as? [String: Any] ?? [:]
        mcpServers["consult-user-mcp"] = [
            "command": "node",
            "args": [serverPath]
        ]
        config["mcpServers"] = mcpServers

        guard let data = try? JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys]) else {
            return false
        }
        return (try? data.write(to: URL(fileURLWithPath: path))) != nil
    }

    static func installTOML(target: InstallTarget, mcpServer serverPath: String) -> Bool {
        let path = target.expandedPath
        let fm = FileManager.default
        var content = ""

        if let data = fm.contents(atPath: path),
           let existingContent = String(data: data, encoding: .utf8) {
            content = existingContent
        }

        if content.contains("[mcp_servers.consult-user-mcp]") {
            if let range = content.range(
                of: #"\[mcp_servers\.consult-user-mcp\][^\[]*"#,
                options: .regularExpression
            ) {
                let newSection = """
                [mcp_servers.consult-user-mcp]
                command = "node"
                args = ["\(serverPath)"]

                """
                content.replaceSubrange(range, with: newSection)
            }
        } else {
            let newSection = """

            [mcp_servers.consult-user-mcp]
            command = "node"
            args = ["\(serverPath)"]
            """
            content += newSection
        }

        return (try? content.write(toFile: path, atomically: true, encoding: .utf8)) != nil
    }
}
