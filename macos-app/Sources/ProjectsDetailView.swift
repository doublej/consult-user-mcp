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
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                SettingsPageHeader(
                    icon: "folder.fill",
                    title: "Projects",
                    description: "Manage discovered project directories"
                )

                if !projectManager.projects.isEmpty {
                    Button(action: { projectManager.removeAll() }) {
                        Label("Clear All", systemImage: "trash")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered)
                }
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
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color(.controlBackgroundColor) : Color(.controlBackgroundColor).opacity(0.7))
        )
        .onHover { isHovered = $0 }
    }

    private var actionButtons: some View {
        HStack(spacing: 6) {
            if isEditing {
                Button(action: saveEdit) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(action: cancelEdit) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Button(action: startEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Rename")

                Button(action: openInFinder) {
                    Image(systemName: "folder")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Open in Finder")

                Button(action: openInTerminal) {
                    Image(systemName: "terminal")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Open in Terminal")

                Button(action: remove) {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Remove")
            }
        }
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
