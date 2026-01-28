import SwiftUI
import AppKit

// MARK: - Brand Logos

struct ClaudeLogo: View {
    var size: CGFloat = 20
    var showTerminalBadge: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            logoImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22))

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

    private var logoImage: Image {
        if let url = Bundle.main.url(forResource: "claude-logo", withExtension: "png"),
           let nsImage = NSImage(contentsOf: url) {
            return Image(nsImage: nsImage)
        }
        return Image(systemName: "sparkle")
    }
}

struct OpenAILogo: View {
    var size: CGFloat = 20

    var body: some View {
        logoImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }

    private var logoImage: Image {
        if let url = Bundle.main.url(forResource: "openai-logo", withExtension: "png"),
           let nsImage = NSImage(contentsOf: url) {
            return Image(nsImage: nsImage)
        }
        return Image(systemName: "brain")
    }
}

// MARK: - Wizard Steps

enum InstallWizardStep: Int, WizardStep, CaseIterable {
    case targetSelection
    case basePromptChoice
    case confirmation

    var title: String {
        switch self {
        case .targetSelection: return "Target"
        case .basePromptChoice: return "Prompts"
        case .confirmation: return "Install"
        }
    }
}

// MARK: - Install Answers

struct InstallAnswers {
    var target: InstallTarget = .claudeCode
    var includeBasePrompt: Bool = true
    var basePromptMode: BasePromptInstallMode = .createNew
}

// MARK: - Install Guide View

struct InstallGuideView: View {
    @State private var step: InstallWizardStep = .targetSelection
    @State private var answers = InstallAnswers()
    @State private var installResult: InstallResult?
    @Binding var showInstallGuide: Bool

    private var serverPath: String {
        let bundlePath = Bundle.main.bundlePath
        return "\(bundlePath)/Contents/Resources/mcp-server/dist/index.js"
    }

    var body: some View {
        WizardContainer(
            title: "Installation Guide",
            currentStep: step,
            onBack: goBack,
            onClose: { showInstallGuide = false }
        ) {
            switch step {
            case .targetSelection:
                TargetSelectionStep(answers: $answers, onNext: goToNextStep)
            case .basePromptChoice:
                BasePromptStep(answers: $answers, onBack: goBack, onNext: goToNextStep)
            case .confirmation:
                ConfirmationStep(
                    answers: answers,
                    serverPath: serverPath,
                    installResult: $installResult,
                    onBack: goBack,
                    onInstall: performInstall
                )
            }
        }
    }

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch step {
            case .targetSelection:
                showInstallGuide = false
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

    private func goToNextStep() {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch step {
            case .targetSelection:
                if answers.target.supportsBasePrompt {
                    // Set default mode based on existing file state
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
                    step = .basePromptChoice
                } else {
                    step = .confirmation
                }
            case .basePromptChoice:
                step = .confirmation
            case .confirmation:
                break
            }
        }
    }

    private func performInstall() {
        let target = answers.target
        let path = target.expandedPath
        let fm = FileManager.default

        let dir = (path as NSString).deletingLastPathComponent
        try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)

        // Install MCP config
        var mcpSuccess = false
        switch target.configFormat {
        case .json:
            mcpSuccess = installJSON(path: path)
        case .toml:
            mcpSuccess = installTOML(path: path)
        }

        // Install base prompt if applicable
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

// MARK: - Install Result

struct InstallResult {
    let mcpConfigSuccess: Bool
    let basePromptSuccess: Bool
    let basePromptError: String?

    var isFullySuccessful: Bool {
        mcpConfigSuccess && basePromptSuccess
    }
}

// MARK: - Target Selection Step

private struct TargetSelectionStep: View {
    @Binding var answers: InstallAnswers
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose where to install the MCP server.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                ForEach(InstallTarget.allCases) { target in
                    targetCard(target)
                }
            }

            WizardNavigationButtons(
                showBack: false,
                nextLabel: "Next",
                nextEnabled: true,
                onBack: {},
                onNext: onNext
            )
        }
    }

    private func targetCard(_ target: InstallTarget) -> some View {
        WizardOptionCard(
            value: target,
            title: target.displayName,
            subtitle: target.description,
            icon: AnyView(targetLogo(for: target)),
            selection: $answers.target
        )
    }

    @ViewBuilder
    private func targetLogo(for target: InstallTarget) -> some View {
        switch target {
        case .claudeDesktop:
            ClaudeLogo(size: 24)
        case .claudeCode:
            ClaudeLogo(size: 24, showTerminalBadge: true)
        case .codex:
            OpenAILogo(size: 24)
        }
    }
}

// MARK: - Base Prompt Step

private struct BasePromptStep: View {
    @Binding var answers: InstallAnswers
    let onBack: () -> Void
    let onNext: () -> Void

    private var fileExists: Bool {
        ClaudeMdInstaller.detectExisting(for: answers.target)
    }

    private var installedInfo: BasePromptInfo? {
        ClaudeMdInstaller.detectInstalledInfo(for: answers.target)
    }

    private var isUpdateAvailable: Bool {
        ClaudeMdInstaller.isUpdateAvailable(for: answers.target)
    }

    private var fileName: String {
        answers.target.claudeMdPath?.components(separatedBy: "/").last ?? "CLAUDE.md"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            promptExplanation

            Toggle(isOn: $answers.includeBasePrompt) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Include usage hints")
                        .font(.system(size: 12, weight: .medium))
                    Text("Helps Claude use the MCP tools correctly")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
            )

            if answers.includeBasePrompt && fileExists {
                existingFileOptions
            }

            WizardNavigationButtons(
                showBack: true,
                nextLabel: "Next",
                nextEnabled: true,
                onBack: onBack,
                onNext: onNext
            )
        }
    }

    private var promptExplanation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add usage hints to \(fileName)?")
                .font(.system(size: 12, weight: .medium))

            Text("This teaches Claude when to use the dialog tools instead of asking questions in text.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            if fileExists {
                if let info = installedInfo, isUpdateAvailable {
                    updateAvailableBanner(installedVersion: info.version)
                } else if installedInfo != nil {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Usage hints installed (v\(ClaudeMdInstaller.bundledVersion))")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                    .padding(.top, 4)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.orange)
                        Text("\(fileName) already exists")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private func updateAvailableBanner(installedVersion: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up.circle.fill")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text("Update available")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.orange)
                Text("v\(installedVersion) → v\(ClaudeMdInstaller.bundledVersion)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 4)
    }

    private var existingFileOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isUpdateAvailable ? "UPDATE OPTIONS" : "EXISTING FILE")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.0)
                .foregroundColor(.secondary)

            VStack(spacing: 6) {
                if isUpdateAvailable {
                    modeOption(.update, icon: "arrow.up.circle")
                    modeOption(.skip, icon: "xmark.circle", title: "Keep existing", description: "Don't update usage hints")
                } else if installedInfo != nil {
                    modeOption(.skip, icon: "checkmark.circle", title: "Already installed", description: "Usage hints are up to date")
                } else {
                    modeOption(.appendSection, icon: "text.append")
                    modeOption(.skip, icon: "xmark.circle")
                }
            }
        }
    }

    private func modeOption(
        _ mode: BasePromptInstallMode,
        icon: String,
        title: String? = nil,
        description: String? = nil
    ) -> some View {
        Button(action: { answers.basePromptMode = mode }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(answers.basePromptMode == mode ? .accentColor : .secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title ?? mode.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                    Text(description ?? mode.description)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: answers.basePromptMode == mode ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundColor(answers.basePromptMode == mode ? .accentColor : Color(.separatorColor))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(answers.basePromptMode == mode ? Color.accentColor.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        answers.basePromptMode == mode ? Color.accentColor.opacity(0.3) : Color(.separatorColor),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Confirmation Step

private struct ConfirmationStep: View {
    let answers: InstallAnswers
    let serverPath: String
    @Binding var installResult: InstallResult?
    let onBack: () -> Void
    let onInstall: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let result = installResult {
                resultView(result)
            } else {
                summaryView
            }
        }
    }

    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ready to install")
                .font(.system(size: 12, weight: .medium))

            VStack(alignment: .leading, spacing: 10) {
                summaryItem(
                    icon: "doc.text",
                    title: "MCP configuration",
                    detail: answers.target.configPath
                )

                if answers.target.supportsBasePrompt && answers.includeBasePrompt && answers.basePromptMode != .skip {
                    summaryItem(
                        icon: "text.bubble",
                        title: "Usage hints",
                        detail: answers.target.claudeMdPath ?? ""
                    )
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
            )

            WizardNavigationButtons(
                showBack: true,
                nextLabel: "Install",
                nextEnabled: true,
                onBack: onBack,
                onNext: onInstall
            )
        }
    }

    private func summaryItem(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                Text(detail)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private func resultView(_ result: InstallResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if result.isFullySuccessful {
                successBanner
            } else {
                partialSuccessBanner(result)
            }

            VStack(alignment: .leading, spacing: 10) {
                resultItem(
                    success: result.mcpConfigSuccess,
                    title: "MCP configuration",
                    detail: result.mcpConfigSuccess ? "Installed" : "Failed"
                )

                if answers.target.supportsBasePrompt && answers.includeBasePrompt && answers.basePromptMode != .skip {
                    resultItem(
                        success: result.basePromptSuccess,
                        title: "Usage hints",
                        detail: result.basePromptSuccess ? "Installed" : (result.basePromptError ?? "Failed")
                    )
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
            )

            restartInstructions
        }
    }

    private var successBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("Installation complete")
                    .font(.system(size: 13, weight: .semibold))
                Text("Restart \(answers.target.displayName) to activate")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
        )
    }

    private func partialSuccessBanner(_ result: InstallResult) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Partial installation")
                    .font(.system(size: 13, weight: .semibold))
                Text("Some items could not be installed")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }

    private func resultItem(success: Bool, title: String, detail: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(success ? .green : .red)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                Text(detail)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private var restartInstructions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NEXT STEPS")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.0)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                Text("Restart \(answers.target.displayName) to load the MCP server")
                    .font(.system(size: 11))
                    .foregroundColor(.primary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.controlBackgroundColor))
            )
        }
    }
}

#Preview {
    InstallGuideView(showInstallGuide: .constant(true))
}
