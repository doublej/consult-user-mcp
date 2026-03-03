import SwiftUI

struct ChangelogView: View {
    let currentVersion: String
    let targetVersion: String
    let expandSections: Bool
    let showUpdateButton: Bool
    let onUpdate: () -> Void
    let onDismiss: () -> Void

    @State private var releases: [ChangelogRelease] = []
    @State private var expandedSections: Set<String> = []
    @State private var isLoading = true
    @State private var loadFailed = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .background(Color(.windowBackgroundColor))
        .task { loadChangelog() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 48, height: 48)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("What's New")
                    .font(.system(size: 18, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(20)
    }

    private var subtitle: String {
        showUpdateButton
            ? "v\(currentVersion) \u{2192} v\(targetVersion)"
            : "v\(targetVersion)"
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if isLoading {
            loadingView
        } else if loadFailed || releases.isEmpty {
            emptyView
        } else {
            releaseList
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack {
            Spacer()
            Text("Could not load changelog")
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var releaseList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(releases) { release in
                    releaseSection(release)
                }

                changelogLink
            }
            .padding(20)
        }
    }

    private var changelogLink: some View {
        HStack {
            Spacer()
            Link("View full changelog", destination: AppURLs.changelog)
                .font(.system(size: 12))
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Release Section

    private func releaseSection(_ release: ChangelogRelease) -> some View {
        DisclosureGroup(isExpanded: isExpandedBinding(for: release)) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(release.changes) { entry in
                    changeRow(entry)
                }
            }
            .padding(.top, 4)
        } label: {
            releaseSectionHeader(release)
        }
    }

    private func releaseSectionHeader(_ release: ChangelogRelease) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("v\(release.version)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                Spacer()
                Text(release.date)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            if let highlight = release.highlight {
                Text(highlight)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func changeRow(_ entry: ChangelogEntry) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            TypeBadge(type: entry.type)
            Text(entry.text)
                .font(.system(size: 12))
                .foregroundColor(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func isExpandedBinding(for release: ChangelogRelease) -> Binding<Bool> {
        Binding(
            get: { expandedSections.contains(release.id) },
            set: { expanded in
                if expanded {
                    expandedSections.insert(release.id)
                } else {
                    expandedSections.remove(release.id)
                }
            }
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button(showUpdateButton ? "Later" : "Close") { onDismiss() }
                .keyboardShortcut(.cancelAction)

            Spacer()

            if showUpdateButton {
                Button("Update Now") { onUpdate() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
    }

    // MARK: - Load

    private func loadChangelog() {
        ChangelogFetcher.shared.fetch(
            currentVersion: currentVersion,
            targetVersion: targetVersion
        ) { result in
            releases = result
            loadFailed = result.isEmpty
            isLoading = false

            if expandSections {
                expandedSections = Set(result.map(\.id))
            }
        }
    }
}

// MARK: - Type Badge

private struct TypeBadge: View {
    let type: ChangeType

    var body: some View {
        Text(type.label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color))
    }

    private var color: Color {
        switch type {
        case .added: .green
        case .changed: .blue
        case .fixed: .pink
        case .removed: .purple
        }
    }
}
