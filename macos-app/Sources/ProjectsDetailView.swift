import SwiftUI
import AppKit

struct ProjectsDetailView: View {
    @ObservedObject private var projectManager = ProjectManager.shared

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        SettingsPageHeader(
            icon: "folder.fill",
            title: "Projects",
            description: "Manage discovered project directories"
        ) {
            if !projectManager.projects.isEmpty {
                Button(action: { projectManager.removeAll() }) {
                    Label("Clear All", systemImage: "trash")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    // MARK: - Content

    private var content: some View {
        Group {
            if projectManager.projects.isEmpty {
                emptyState
            } else {
                projectList
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 52))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("No Projects Yet")
                    .font(.system(size: 17, weight: .medium))

                Text("Projects are discovered automatically when dialogs\nare shown from a project directory.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var projectList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(projectManager.projects) { project in
                    ProjectDetailRow(project: project)
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Project Detail Row

private struct ProjectDetailRow: View {
    let project: Project

    @State private var isEditing = false
    @State private var editedName = ""
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            // Left section: icon and info
            HStack(spacing: 16) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.accentColor)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 4) {
                    if isEditing {
                        TextField("Project name", text: $editedName, onCommit: saveEdit)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .medium))
                            .onAppear { editedName = project.displayName }
                    } else {
                        Text(project.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                    }

                    Text(project.path)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: 20)

            // Right section: actions
            actionButtons
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color(.controlBackgroundColor) : Color(.controlBackgroundColor).opacity(0.7))
        )
        .onHover { isHovered = $0 }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            if isEditing {
                actionButton("checkmark", action: saveEdit)
                actionButton("xmark", action: cancelEdit)
            } else {
                actionButton("pencil", action: startEdit, help: "Rename")
                actionButton("folder", action: openInFinder, help: "Open in Finder")
                actionButton("terminal", action: openInTerminal, help: "Open in Terminal")
                actionButton("trash", action: remove, help: "Remove", color: .red)
            }
        }
    }

    private func actionButton(
        _ icon: String,
        action: @escaping () -> Void,
        help: String? = nil,
        color: Color? = nil
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .help(help ?? "")
    }

    // MARK: - Actions

    private func startEdit() {
        editedName = project.displayName
        isEditing = true
    }

    private func saveEdit() {
        ProjectManager.shared.rename(path: project.path, to: editedName)
        isEditing = false
    }

    private func cancelEdit() {
        isEditing = false
    }

    private func openInFinder() {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: project.path)
    }

    private func openInTerminal() {
        let script = """
        tell application "Terminal"
            activate
            do script "cd '\(project.path.replacingOccurrences(of: "'", with: "'\\''"))'"
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    private func remove() {
        ProjectManager.shared.remove(path: project.path)
    }
}

#Preview {
    ProjectsDetailView()
        .frame(width: 480, height: 500)
}
