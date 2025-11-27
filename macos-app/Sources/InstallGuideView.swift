import SwiftUI
import AppKit

enum InstallTarget: String, CaseIterable {
    case claudeDesktop = "Claude Desktop"
    case claudeCode = "Claude Code"
    case codex = "Codex CLI"

    var icon: String {
        switch self {
        case .claudeDesktop: return "message.fill"
        case .claudeCode: return "terminal.fill"
        case .codex: return "chevron.left.forwardslash.chevron.right"
        }
    }

    var configPath: String {
        switch self {
        case .claudeDesktop:
            return "~/Library/Application Support/Claude/claude_desktop_config.json"
        case .claudeCode:
            return "~/.claude.json"
        case .codex:
            return "~/.codex/config.toml"
        }
    }

    var configFormat: ConfigFormat {
        switch self {
        case .claudeDesktop, .claudeCode:
            return .json
        case .codex:
            return .toml
        }
    }

    var description: String {
        switch self {
        case .claudeDesktop:
            return "Anthropic's desktop app"
        case .claudeCode:
            return "CLI coding assistant"
        case .codex:
            return "OpenAI's CLI tool"
        }
    }
}

enum ConfigFormat {
    case json
    case toml
}

struct InstallGuideView: View {
    @State private var selectedTarget: InstallTarget = .claudeCode
    @State private var installStep: Int = 0
    @State private var copyFeedback: String? = nil
    @Binding var showInstallGuide: Bool

    private let serverPath: String

    init(showInstallGuide: Binding<Bool>) {
        self._showInstallGuide = showInstallGuide
        // Compute server path relative to app bundle
        if let bundlePath = Bundle.main.bundlePath as String? {
            let appDir = (bundlePath as NSString).deletingLastPathComponent
            self.serverPath = "\(appDir)/mcp-server/dist/index.js"
        } else {
            self.serverPath = "/path/to/speak/mcp-server/dist/index.js"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            ScrollView {
                VStack(spacing: 20) {
                    // Target selector
                    targetSelector

                    // Installation steps
                    installSteps

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .frame(width: 300, height: 540)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { showInstallGuide = false }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)

            Spacer()

            Text("Installation Guide")
                .font(.system(size: 15, weight: .semibold))

            Spacer()

            // Spacer for symmetry
            Image(systemName: "chevron.left")
                .font(.system(size: 12, weight: .semibold))
                .opacity(0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Target Selector

    private var targetSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INSTALL FOR")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                ForEach(InstallTarget.allCases, id: \.self) { target in
                    Button(action: { selectedTarget = target }) {
                        VStack(spacing: 4) {
                            Image(systemName: target.icon)
                                .font(.system(size: 16))
                            Text(target.rawValue)
                                .font(.system(size: 9, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedTarget == target
                                      ? Color.accentColor.opacity(0.15)
                                      : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(selectedTarget == target
                                              ? Color.accentColor
                                              : Color(nsColor: .separatorColor),
                                              lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(selectedTarget == target ? .accentColor : .secondary)
                }
            }
        }
    }

    // MARK: - Install Steps

    private var installSteps: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Step 1: Config location
            stepCard(number: 1, title: "Open config file") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Config location:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    HStack {
                        Text(selectedTarget.configPath)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        Button(action: openConfigFile) {
                            Image(systemName: "folder")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(4)
                }
            }

            // Step 2: Add config
            stepCard(number: 2, title: "Add MCP configuration") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedTarget.configFormat == .json ? "Add this to your mcpServers:" : "Add this to your config.toml:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(configSnippet)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(4)

                    HStack {
                        Button(action: copyConfig) {
                            Label(copyFeedback ?? "Copy", systemImage: copyFeedback != nil ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Spacer()

                        Button(action: autoInstall) {
                            Label("Auto Install", systemImage: "wand.and.stars")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }

            // Step 3: Restart
            stepCard(number: 3, title: "Restart \(selectedTarget.rawValue)") {
                Text("Restart the application to load the MCP server.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func stepCard<Content: View>(number: Int, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("\(number)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(Color.accentColor))

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }

            content()
                .padding(.leading, 26)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    // MARK: - Config Snippet

    private var configSnippet: String {
        let actualPath = resolveServerPath()
        switch selectedTarget.configFormat {
        case .json:
            return """
"speak": {
  "command": "node",
  "args": ["\(actualPath)"]
}
"""
        case .toml:
            return """
[mcp_servers.speak]
command = "node"
args = ["\(actualPath)"]
"""
        }
    }

    private func resolveServerPath() -> String {
        // Try to find the actual mcp-server path
        let fm = FileManager.default

        // Check relative to app bundle
        if let bundlePath = Bundle.main.bundlePath as String? {
            let appDir = (bundlePath as NSString).deletingLastPathComponent
            let serverPath = "\(appDir)/mcp-server/dist/index.js"
            if fm.fileExists(atPath: serverPath) {
                return serverPath
            }
        }

        // Check common development paths
        let devPath = "/Users/jurrejan/Documents/development/mcp/speak/mcp-server/dist/index.js"
        if fm.fileExists(atPath: devPath) {
            return devPath
        }

        return "/path/to/speak/mcp-server/dist/index.js"
    }

    // MARK: - Actions

    private func openConfigFile() {
        let path = (selectedTarget.configPath as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: path)
        let dir = url.deletingLastPathComponent()

        // Create directory if needed
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: path) {
            let initialContent: String
            switch selectedTarget.configFormat {
            case .json:
                initialContent = "{\n  \"mcpServers\": {}\n}"
            case .toml:
                initialContent = "# Codex configuration\n"
            }
            try? initialContent.write(toFile: path, atomically: true, encoding: .utf8)
        }

        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: dir.path)
    }

    private func copyConfig() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(configSnippet, forType: .string)

        copyFeedback = "Copied!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copyFeedback = nil
        }
    }

    private func autoInstall() {
        let path = (selectedTarget.configPath as NSString).expandingTildeInPath
        let fm = FileManager.default

        // Create directory if needed
        let dir = (path as NSString).deletingLastPathComponent
        try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)

        let serverPath = resolveServerPath()

        switch selectedTarget.configFormat {
        case .json:
            autoInstallJSON(path: path, serverPath: serverPath)
        case .toml:
            autoInstallTOML(path: path, serverPath: serverPath)
        }
    }

    private func autoInstallJSON(path: String, serverPath: String) {
        let fm = FileManager.default
        var config: [String: Any] = [:]

        // Read existing config
        if let data = fm.contents(atPath: path),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            config = json
        }

        // Ensure mcpServers exists
        var mcpServers = config["mcpServers"] as? [String: Any] ?? [:]

        // Add speak server
        mcpServers["speak"] = [
            "command": "node",
            "args": [serverPath]
        ]

        config["mcpServers"] = mcpServers

        // Write back
        if let data = try? JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: URL(fileURLWithPath: path))
            showInstallSuccess()
        }
    }

    private func autoInstallTOML(path: String, serverPath: String) {
        let fm = FileManager.default
        var content = ""

        // Read existing config
        if let data = fm.contents(atPath: path),
           let existingContent = String(data: data, encoding: .utf8) {
            content = existingContent
        }

        // Check if speak server already exists
        if content.contains("[mcp_servers.speak]") {
            // Update existing entry - replace the section
            if let range = content.range(of: #"\[mcp_servers\.speak\][^\[]*"#, options: .regularExpression) {
                let newSection = """
[mcp_servers.speak]
command = "node"
args = ["\(serverPath)"]

"""
                content.replaceSubrange(range, with: newSection)
            }
        } else {
            // Add new entry
            let newSection = """

[mcp_servers.speak]
command = "node"
args = ["\(serverPath)"]
"""
            content += newSection
        }

        // Write back
        try? content.write(toFile: path, atomically: true, encoding: .utf8)
        showInstallSuccess()
    }

    private func showInstallSuccess() {
        copyFeedback = "Installed!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copyFeedback = nil
        }
    }
}

#Preview {
    InstallGuideView(showInstallGuide: .constant(true))
}
