import SwiftUI
import AppKit

// MARK: - Install Detail View (for NavigationSplitView)

struct InstallDetailView: View {
    @State private var step: InstallWizardStep = .targetSelection
    @State private var answers = InstallAnswers()
    @State private var installResult: InstallResult?

    private var serverPath: String {
        let bundlePath = Bundle.main.bundlePath
        return "\(bundlePath)/Contents/Resources/mcp-server/dist/index.js"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            progressStepsView
            content

            if installResult == nil {
                Divider()
                footerBar
            }
        }
        .background(Color(.windowBackgroundColor))
    }

    private var footerBar: some View {
        HStack {
            if step != .targetSelection {
                Button("Back") { goBack() }
                    .buttonStyle(.bordered)
            }

            Spacer()

            Button(step == .confirmation ? "Install" : "Next") { goNext() }
                .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    // MARK: - Header

    private var header: some View {
        SettingsPageHeader(
            icon: "puzzlepiece.extension.fill",
            title: "Install",
            description: "Set up MCP integration with your AI tools"
        ) {
            if installResult?.isFullySuccessful == true {
                Button("Start Over") {
                    resetWizard()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    // MARK: - Progress Steps

    private var progressStepsView: some View {
        ProgressStepsView(
            steps: InstallWizardStep.allCases,
            currentStep: step
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch step {
                case .targetSelection:
                    targetSelectionContent
                case .basePromptChoice:
                    basePromptContent
                case .confirmation:
                    confirmationContent
                }
            }
            .padding(24)
        }
    }

    // MARK: - Target Selection

    private var targetSelectionContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose Installation Target")
                    .font(.system(size: 14, weight: .medium))

                Text("Select where you want to install the Consult User MCP server.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(InstallTarget.allCases) { target in
                    targetCard(target)
                }
            }

        }
    }

    private func targetCard(_ target: InstallTarget) -> some View {
        Button(action: { answers.target = target }) {
            HStack(spacing: 18) {
                targetLogo(for: target)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(target.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)

                    Text(target.description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 16)

                Image(systemName: answers.target == target ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(answers.target == target ? .accentColor : Color(.separatorColor))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(answers.target == target ? Color.accentColor.opacity(0.08) : Color(.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(answers.target == target ? Color.accentColor : Color(.separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func targetLogo(for target: InstallTarget) -> some View {
        switch target {
        case .claudeDesktop:
            ClaudeLogo(size: 32)
        case .claudeCode:
            ClaudeLogo(size: 32, showTerminalBadge: true)
        case .codex:
            OpenAILogo(size: 32)
        }
    }

    // MARK: - Base Prompt

    private var basePromptContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Usage Hints")
                    .font(.system(size: 14, weight: .medium))

                Text("Add instructions to \(fileName) to help Claude use the MCP tools correctly.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            basePromptToggle
            if answers.includeBasePrompt && fileExists {
                existingFileOptions
            }

        }
    }

    private var fileName: String {
        answers.target.claudeMdPath?.components(separatedBy: "/").last ?? "CLAUDE.md"
    }

    private var fileExists: Bool {
        ClaudeMdInstaller.detectExisting(for: answers.target)
    }

    private var installedInfo: BasePromptInfo? {
        ClaudeMdInstaller.detectInstalledInfo(for: answers.target)
    }

    private var isUpdateAvailable: Bool {
        ClaudeMdInstaller.isUpdateAvailable(for: answers.target)
    }

    private var basePromptToggle: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $answers.includeBasePrompt) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Include usage hints")
                        .font(.system(size: 13, weight: .medium))
                    Text("Teaches Claude when to use dialog tools instead of text questions")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)

            if fileExists {
                fileStatusBadge
                    .padding(.leading, 36)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.controlBackgroundColor))
        )
    }

    @ViewBuilder
    private var fileStatusBadge: some View {
        if let info = installedInfo, isUpdateAvailable {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Update available")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.orange)
                    Text("v\(info.version) → v\(ClaudeMdInstaller.bundledVersion)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        } else if installedInfo != nil {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Usage hints installed (v\(ClaudeMdInstaller.bundledVersion))")
                    .font(.system(size: 11))
                    .foregroundColor(.green)
            }
        } else {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.orange)
                Text("\(fileName) already exists")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
            }
        }
    }

    private var existingFileOptions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isUpdateAvailable ? "UPDATE OPTIONS" : "EXISTING FILE")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.0)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                if isUpdateAvailable {
                    modeOption(.update, icon: "arrow.up.circle", title: "Update hints", description: "Replace with latest version")
                    modeOption(.skip, icon: "xmark.circle", title: "Keep existing", description: "Don't update usage hints")
                } else if installedInfo != nil {
                    modeOption(.skip, icon: "checkmark.circle", title: "Already installed", description: "Usage hints are up to date")
                } else {
                    modeOption(.appendSection, icon: "text.append", title: "Append section", description: "Add hints to existing file")
                    modeOption(.skip, icon: "xmark.circle", title: "Skip", description: "Don't add usage hints")
                }
            }
        }
    }

    private func modeOption(_ mode: BasePromptInstallMode, icon: String, title: String, description: String) -> some View {
        Button(action: { answers.basePromptMode = mode }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(answers.basePromptMode == mode ? .accentColor : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: answers.basePromptMode == mode ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(answers.basePromptMode == mode ? .accentColor : Color(.separatorColor))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(answers.basePromptMode == mode ? Color.accentColor.opacity(0.08) : Color(.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(answers.basePromptMode == mode ? Color.accentColor.opacity(0.3) : Color(.separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Confirmation

    private var confirmationContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let result = installResult {
                resultView(result)
            } else {
                summaryView
            }
        }
    }

    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ready to Install")
                    .font(.system(size: 14, weight: .medium))

                Text("The following changes will be made to your system.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                summaryItem(icon: "doc.text", title: "MCP Configuration", detail: answers.target.configPath)

                if answers.target.supportsBasePrompt && answers.includeBasePrompt && answers.basePromptMode != .skip {
                    summaryItem(icon: "text.bubble", title: "Usage Hints", detail: answers.target.claudeMdPath ?? "")
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.controlBackgroundColor))
            )

        }
    }

    private func summaryItem(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(detail)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func resultView(_ result: InstallResult) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            if result.isFullySuccessful {
                successBanner
            } else {
                partialSuccessBanner
            }

            VStack(alignment: .leading, spacing: 12) {
                resultItem(success: result.mcpConfigSuccess, title: "MCP Configuration", detail: result.mcpConfigSuccess ? "Installed" : "Failed")

                if answers.target.supportsBasePrompt && answers.includeBasePrompt && answers.basePromptMode != .skip {
                    resultItem(success: result.basePromptSuccess, title: "Usage Hints", detail: result.basePromptSuccess ? "Installed" : (result.basePromptError ?? "Failed"))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.controlBackgroundColor))
            )

            nextStepsSection
        }
    }

    private var successBanner: some View {
        HStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 6) {
                Text("Installation Complete")
                    .font(.system(size: 16, weight: .semibold))
                Text("Restart \(answers.target.displayName) to activate the MCP server.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.green.opacity(0.1))
        )
    }

    private var partialSuccessBanner: some View {
        HStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 6) {
                Text("Partial Installation")
                    .font(.system(size: 16, weight: .semibold))
                Text("Some items could not be installed. Check details below.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.1))
        )
    }

    private func resultItem(success: Bool, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(success ? .green : .red)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nextStepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NEXT STEPS")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.0)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
                    .frame(width: 28)

                Text("Restart \(answers.target.displayName) to load the MCP server")
                    .font(.system(size: 13))
                    .foregroundColor(.primary)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
            )
        }
    }

    // MARK: - Navigation

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch step {
            case .targetSelection:
                break
            case .basePromptChoice:
                step = .targetSelection
            case .confirmation:
                if answers.target.supportsBasePrompt {
                    step = .basePromptChoice
                } else {
                    step = .targetSelection
                }
            }
        }
    }

    private func goNext() {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch step {
            case .targetSelection:
                if answers.target.supportsBasePrompt {
                    prepareBasePromptDefaults()
                    step = .basePromptChoice
                } else {
                    step = .confirmation
                }
            case .basePromptChoice:
                step = .confirmation
            case .confirmation:
                performInstall()
            }
        }
    }

    private func prepareBasePromptDefaults() {
        if ClaudeMdInstaller.detectExisting(for: answers.target) {
            if ClaudeMdInstaller.isUpdateAvailable(for: answers.target) {
                answers.basePromptMode = .update
            } else if ClaudeMdInstaller.detectInstalledInfo(for: answers.target) != nil {
                answers.basePromptMode = .skip
            } else {
                answers.basePromptMode = .appendSection
            }
        } else {
            answers.basePromptMode = .createNew
        }
    }

    private func resetWizard() {
        withAnimation(.easeInOut(duration: 0.2)) {
            step = .targetSelection
            answers = InstallAnswers()
            installResult = nil
        }
    }

    // MARK: - Install

    private func performInstall() {
        let target = answers.target
        let path = target.expandedPath
        let fm = FileManager.default

        let dir = (path as NSString).deletingLastPathComponent
        try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)

        var mcpSuccess = false
        switch target.configFormat {
        case .json:
            mcpSuccess = installJSON(path: path)
        case .toml:
            mcpSuccess = installTOML(path: path)
        }

        var promptSuccess = true
        var promptError: String?
        if answers.includeBasePrompt && answers.basePromptMode != .skip {
            do {
                try ClaudeMdInstaller.install(for: target, mode: answers.basePromptMode)
            } catch {
                promptSuccess = false
                promptError = error.localizedDescription
            }
        }

        installResult = InstallResult(
            mcpConfigSuccess: mcpSuccess,
            basePromptSuccess: promptSuccess,
            basePromptError: promptError
        )
    }

    private func installJSON(path: String) -> Bool {
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
            return (try? data.write(to: URL(fileURLWithPath: path))) != nil
        }
        return false
    }

    private func installTOML(path: String) -> Bool {
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

#Preview {
    InstallDetailView()
        .frame(width: 480, height: 600)
}
