import Foundation
import SwiftUI

// MARK: - Install Mode

enum BasePromptInstallMode: String, CaseIterable, Identifiable {
    case createNew
    case appendSection
    case skip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .createNew: return "Create new file"
        case .appendSection: return "Append to existing"
        case .skip: return "Skip"
        }
    }

    var description: String {
        switch self {
        case .createNew: return "Create CLAUDE.md with usage hints"
        case .appendSection: return "Add hints to existing file"
        case .skip: return "Don't modify instructions file"
        }
    }
}

// MARK: - CLAUDE.md Installer

enum ClaudeMdInstaller {
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

    static func install(for target: InstallTarget, mode: BasePromptInstallMode) throws {
        guard mode != .skip else { return }

        guard let path = target.claudeMdExpandedPath else {
            throw InstallError.noPathConfigured
        }

        guard let basePrompt = basePromptContent() else {
            throw InstallError.resourceNotFound
        }

        let fm = FileManager.default
        let dir = (path as NSString).deletingLastPathComponent

        // Ensure directory exists
        try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)

        let finalContent: String

        switch mode {
        case .createNew:
            finalContent = basePrompt

        case .appendSection:
            var existingContent = ""
            if let data = fm.contents(atPath: path),
               let content = String(data: data, encoding: .utf8) {
                existingContent = content
            }

            // Check if already contains the section
            if existingContent.contains("# Consult User MCP") {
                return // Already installed, skip
            }

            // Append with separator
            if existingContent.isEmpty {
                finalContent = basePrompt
            } else {
                finalContent = existingContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    + "\n\n"
                    + basePrompt
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
