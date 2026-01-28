import Foundation
import SwiftUI

// MARK: - Install Mode

enum BasePromptInstallMode: String, CaseIterable, Identifiable {
    case createNew
    case appendSection
    case update
    case skip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .createNew: return "Create new file"
        case .appendSection: return "Append to existing"
        case .update: return "Update to latest"
        case .skip: return "Skip"
        }
    }

    var description: String {
        switch self {
        case .createNew: return "Create CLAUDE.md with usage hints"
        case .appendSection: return "Add hints to existing file"
        case .update: return "Replace with latest version"
        case .skip: return "Don't modify instructions file"
        }
    }
}

// MARK: - Base Prompt Info

struct BasePromptInfo: Equatable {
    let version: String
    let content: String
}

// MARK: - CLAUDE.md Installer

enum ClaudeMdInstaller {
    private static let tagName = "consult-user-mcp-baseprompt"

    enum InstallError: Error, LocalizedError {
        case noPathConfigured
        case fileWriteFailed(String)
        case resourceNotFound

        var errorDescription: String? {
            switch self {
            case .noPathConfigured:
                return "This target doesn't support base prompt installation"
            case .fileWriteFailed(let path):
                return "Failed to write to \(path)"
            case .resourceNotFound:
                return "Base prompt resource not found in bundle"
            }
        }
    }

    static var bundledVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static func detectExisting(for target: InstallTarget) -> Bool {
        guard let path = target.claudeMdExpandedPath else { return false }
        return FileManager.default.fileExists(atPath: path)
    }

    static func basePromptContent() -> String? {
        guard let url = Bundle.main.url(forResource: "base-prompt", withExtension: "md"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        return content
    }

    static func wrappedBasePromptContent() -> String? {
        guard let content = basePromptContent() else { return nil }
        return """
            <\(tagName) version="\(bundledVersion)">
            \(content.trimmingCharacters(in: .whitespacesAndNewlines))
            </\(tagName)>
            """
    }

    static func detectInstalledInfo(for target: InstallTarget) -> BasePromptInfo? {
        guard let path = target.claudeMdExpandedPath,
              let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        // Try to find versioned XML tags first
        let versionPattern = #"<\#(tagName) version="([^"]+)">"#
        if content.range(of: versionPattern, options: .regularExpression) != nil,
           let match = try? NSRegularExpression(pattern: versionPattern).firstMatch(
               in: content,
               range: NSRange(content.startIndex..., in: content)
           ),
           let versionNSRange = Range(match.range(at: 1), in: content) {

            let version = String(content[versionNSRange])

            // Extract content between tags
            let contentPattern = #"<\#(tagName) version="[^"]+">(.+?)</\#(tagName)>"#
            if let contentMatch = try? NSRegularExpression(
                pattern: contentPattern,
                options: .dotMatchesLineSeparators
            ).firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
               let contentNSRange = Range(contentMatch.range(at: 1), in: content) {
                return BasePromptInfo(
                    version: version,
                    content: String(content[contentNSRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
        }

        // Fallback: check for legacy unversioned content (header-based detection)
        if content.contains("# Consult User MCP") {
            return BasePromptInfo(version: "0.0.0", content: "")
        }

        return nil
    }

    static func isUpdateAvailable(for target: InstallTarget) -> Bool {
        guard let installed = detectInstalledInfo(for: target) else { return false }
        return compareVersions(installed.version, bundledVersion) == .orderedAscending
    }

    private static func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(parts1.count, parts2.count) {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0
            if p1 < p2 { return .orderedAscending }
            if p1 > p2 { return .orderedDescending }
        }
        return .orderedSame
    }

    static func install(for target: InstallTarget, mode: BasePromptInstallMode) throws {
        guard mode != .skip else { return }

        guard let path = target.claudeMdExpandedPath else {
            throw InstallError.noPathConfigured
        }

        guard let wrappedPrompt = wrappedBasePromptContent() else {
            throw InstallError.resourceNotFound
        }

        let fm = FileManager.default
        let dir = (path as NSString).deletingLastPathComponent

        // Ensure directory exists
        try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)

        let finalContent: String

        switch mode {
        case .createNew:
            finalContent = wrappedPrompt

        case .appendSection:
            var existingContent = ""
            if let data = fm.contents(atPath: path),
               let content = String(data: data, encoding: .utf8) {
                existingContent = content
            }

            // Check if already contains the section (versioned or legacy)
            if existingContent.contains("<\(tagName)") || existingContent.contains("# Consult User MCP") {
                return // Already installed, skip
            }

            // Append with separator
            if existingContent.isEmpty {
                finalContent = wrappedPrompt
            } else {
                finalContent = existingContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    + "\n\n"
                    + wrappedPrompt
            }

        case .update:
            var existingContent = ""
            if let data = fm.contents(atPath: path),
               let content = String(data: data, encoding: .utf8) {
                existingContent = content
            }

            // Replace existing versioned section
            let tagPattern = #"<\#(tagName) version="[^"]+">\s*[\s\S]*?\s*</\#(tagName)>"#
            if let range = existingContent.range(of: tagPattern, options: .regularExpression) {
                existingContent.replaceSubrange(range, with: wrappedPrompt)
                finalContent = existingContent
            } else {
                // Fallback: try to replace legacy section (# Consult User MCP to end or next section)
                let legacyPattern = #"# Consult User MCP[\s\S]*?(?=\n#[^#]|\z)"#
                if let range = existingContent.range(of: legacyPattern, options: .regularExpression) {
                    existingContent.replaceSubrange(range, with: wrappedPrompt)
                    finalContent = existingContent
                } else {
                    // No existing section found, append
                    finalContent = existingContent.trimmingCharacters(in: .whitespacesAndNewlines)
                        + "\n\n"
                        + wrappedPrompt
                }
            }

        case .skip:
            return
        }

        do {
            try finalContent.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            throw InstallError.fileWriteFailed(path)
        }
    }
}
