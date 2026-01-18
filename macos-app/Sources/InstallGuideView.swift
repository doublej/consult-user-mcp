import SwiftUI
import AppKit

// MARK: - Brand Logos (preserved)

struct ClaudeLogo: View {
    var size: CGFloat = 20
    var showTerminalBadge: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.22)
                    .fill(Color(red: 0.84, green: 0.46, blue: 0.33))
                ClaudeStarShape()
                    .fill(Color(red: 0.99, green: 0.95, blue: 0.93))
                    .frame(width: size * 0.65, height: size * 0.65)
            }
            .frame(width: size, height: size)

            if showTerminalBadge {
                Image(systemName: "terminal.fill")
                    .font(.system(size: size * 0.32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(2)
                    .background(Circle().fill(Color.black.opacity(0.8)))
                    .offset(x: 4, y: 4)
            }
        }
    }
}

struct ClaudeStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.38
        let points = 8

        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = (CGFloat(i) / CGFloat(points * 2)) * 2 * .pi - .pi / 2
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct OpenAILogo: View {
    var size: CGFloat = 20

    var body: some View {
        OpenAIKnotShape()
            .fill(Color.primary)
            .frame(width: size, height: size)
    }
}

struct OpenAIKnotShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * 0.9
        let innerRadius = radius * 0.45
        let strokeWidth = radius * 0.18

        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 2
            let nextAngle = angle + .pi / 3

            let outerX = center.x + cos(angle) * radius
            let outerY = center.y + sin(angle) * radius

            let midAngle = angle + .pi / 6
            let innerX = center.x + cos(midAngle) * innerRadius
            let innerY = center.y + sin(midAngle) * innerRadius

            let nextOuterX = center.x + cos(nextAngle) * radius
            let nextOuterY = center.y + sin(nextAngle) * radius

            var petal = Path()
            petal.move(to: CGPoint(x: outerX, y: outerY))
            petal.addQuadCurve(
                to: CGPoint(x: innerX, y: innerY),
                control: CGPoint(
                    x: center.x + cos(angle + .pi/12) * (radius * 0.75),
                    y: center.y + sin(angle + .pi/12) * (radius * 0.75)
                )
            )
            petal.addQuadCurve(
                to: CGPoint(x: nextOuterX, y: nextOuterY),
                control: CGPoint(
                    x: center.x + cos(nextAngle - .pi/12) * (radius * 0.75),
                    y: center.y + sin(nextAngle - .pi/12) * (radius * 0.75)
                )
            )

            path.addPath(petal.strokedPath(StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)))
        }

        return path
    }
}

// MARK: - Install Guide View

struct InstallGuideView: View {
    @State private var selectedTarget: InstallTarget = .claudeCode
    @State private var copyFeedback: String?
    @Binding var showInstallGuide: Bool

    private var serverPath: String {
        let bundlePath = Bundle.main.bundlePath
        return "\(bundlePath)/Contents/Resources/mcp-server/dist/index.js"
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 16) {
                    targetSelector
                    installSteps
                    Spacer(minLength: 16)
                }
                .padding(16)
            }
        }
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(.windowBackgroundColor))
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
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            Image(systemName: "chevron.left")
                .font(.system(size: 12, weight: .semibold))
                .opacity(0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Target Selector

    private var targetSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INSTALL FOR")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.0)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                ForEach(InstallTarget.allCases) { target in
                    targetButton(target)
                }
            }
        }
    }

    private func targetButton(_ target: InstallTarget) -> some View {
        Button(action: { selectedTarget = target }) {
            VStack(spacing: 4) {
                targetLogo(for: target)
                Text(target.displayName)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedTarget == target ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(selectedTarget == target ? Color.accentColor : Color(.separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .foregroundColor(selectedTarget == target ? .accentColor : .secondary)
    }

    @ViewBuilder
    private func targetLogo(for target: InstallTarget) -> some View {
        switch target {
        case .claudeDesktop:
            ClaudeLogo(size: 20)
        case .claudeCode:
            ClaudeLogo(size: 20, showTerminalBadge: true)
        case .codex:
            OpenAILogo(size: 20)
        }
    }

    // MARK: - Install Steps

    private var installSteps: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepCard(number: 1, title: "Open config file") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedTarget.configPath)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Button(action: openConfigFile) {
                        Label("Reveal in Finder", systemImage: "folder")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            stepCard(number: 2, title: "Add MCP configuration") {
                VStack(alignment: .leading, spacing: 6) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(configSnippet)
                            .font(.system(size: 9, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(4)

                    HStack {
                        Button(action: copyConfig) {
                            Label(copyFeedback ?? "Copy", systemImage: copyFeedback != nil ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Spacer()

                        Button(action: autoInstall) {
                            Label("Auto Install", systemImage: "wand.and.stars")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }

            stepCard(number: 3, title: "Restart \(selectedTarget.displayName)") {
                Text("Restart the application to load the MCP server.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func stepCard<Content: View>(number: Int, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("\(number)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(Color.accentColor))

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }

            content()
                .padding(.leading, 22)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.controlBackgroundColor))
        )
    }

    // MARK: - Config Snippet

    private var configSnippet: String {
        switch selectedTarget.configFormat {
        case .json:
            return """
"consult-user-mcp": {
  "command": "node",
  "args": ["\(serverPath)"]
}
"""
        case .toml:
            return """
[mcp_servers.consult-user-mcp]
command = "node"
args = ["\(serverPath)"]
"""
        }
    }

    // MARK: - Actions

    private func openConfigFile() {
        let path = selectedTarget.expandedPath
        let url = URL(fileURLWithPath: path)
        let dir = url.deletingLastPathComponent()

        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

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
        let path = selectedTarget.expandedPath
        let fm = FileManager.default

        let dir = (path as NSString).deletingLastPathComponent
        try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)

        switch selectedTarget.configFormat {
        case .json:
            autoInstallJSON(path: path)
        case .toml:
            autoInstallTOML(path: path)
        }
    }

    private func autoInstallJSON(path: String) {
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

        if let data = try? JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: URL(fileURLWithPath: path))
            showInstallSuccess()
        }
    }

    private func autoInstallTOML(path: String) {
        let fm = FileManager.default
        var content = ""

        if let data = fm.contents(atPath: path),
           let existingContent = String(data: data, encoding: .utf8) {
            content = existingContent
        }

        if content.contains("[mcp_servers.consult-user-mcp]") {
            if let range = content.range(of: #"\[mcp_servers\.consult-user-mcp\][^\[]*"#, options: .regularExpression) {
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
