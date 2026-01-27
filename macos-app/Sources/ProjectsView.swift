import SwiftUI
import AppKit

struct ProjectsView: View {
    @ObservedObject private var projectManager = ProjectManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .frame(width: 400, height: 450)
        .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text("Discovered Projects")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            if !projectManager.projects.isEmpty {
                Button(action: clearAll) {
                    Text("Clear All")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.controlBackgroundColor).opacity(0.5))
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
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No Projects Yet")
                .font(.system(size: 14, weight: .medium))

            Text("Projects are discovered automatically\nwhen dialogs are shown from a project directory.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var projectList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(projectManager.projects) { project in
                    ProjectRow(project: project)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Actions

    private func clearAll() {
        projectManager.removeAll()
    }
}

// MARK: - Project Row

private struct ProjectRow: View {
    let project: Project

    @State private var isEditing = false
    @State private var editedName = ""
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                folderIcon
                nameAndPath
                Spacer()
                actionButtons
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(.controlBackgroundColor) : Color(.controlBackgroundColor).opacity(0.6))
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var folderIcon: some View {
        Image(systemName: "folder.fill")
            .font(.system(size: 20))
            .foregroundColor(.accentColor)
    }

    @ViewBuilder
    private var nameAndPath: some View {
        VStack(alignment: .leading, spacing: 2) {
            if isEditing {
                TextField("Project name", text: $editedName, onCommit: saveEdit)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .onAppear { editedName = project.displayName }
            } else {
                Text(project.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
            }

            Text(project.path)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 4) {
            if isEditing {
                IconButton(icon: "checkmark", action: saveEdit)
                IconButton(icon: "xmark", action: cancelEdit)
            } else {
                IconButton(icon: "pencil", action: startEdit)
                    .help("Rename")
                IconButton(icon: "folder", action: openInFinder)
                    .help("Open in Finder")
                IconButton(icon: "terminal", action: openInTerminal)
                    .help("Open in Terminal")
                IconButton(icon: "trash", isDestructive: true, action: remove)
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

// MARK: - Icon Button

private struct IconButton: View {
    let icon: String
    var isDestructive: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(buttonColor)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(isHovered ? Color(.controlBackgroundColor) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var buttonColor: Color {
        if isDestructive && isHovered {
            return .red
        }
        return isHovered ? .primary : .secondary
    }
}

#Preview {
    ProjectsView()
}
