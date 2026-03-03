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
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(releases) { release in
                    releaseSection(release)
                }

                changelogLink
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private var changelogLink: some View {
        HStack {
            Spacer()
            Link("View full changelog", destination: AppURLs.changelog)
                .font(.system(size: 12))
            Spacer()
        }
        .padding(.top, 12)
    }

    // MARK: - Release Section

    private func releaseSection(_ release: ChangelogRelease) -> some View {
        let isExpanded = expandedSections.contains(release.id)

        return VStack(alignment: .leading, spacing: 0) {
            sectionHeader(release, isExpanded: isExpanded)
                .contentShape(Rectangle())
                .onTapGesture { toggleSection(release.id) }

            if isExpanded {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(release.changes) { entry in
                        changeRow(entry)
                    }
                }
                .padding(.top, 6)
                .padding(.bottom, 4)
            }
        }
        .padding(.vertical, 8)
    }

    private func sectionHeader(_ release: ChangelogRelease, isExpanded: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))

            Text("v\(release.version)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))

            if let highlight = release.highlight {
                Text("\u{2014}")
                    .foregroundStyle(.tertiary)
                Text(highlight)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(release.date)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
    }

    private func changeRow(_ entry: ChangelogEntry) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            TypeBadge(type: entry.type)
                .frame(width: 56, alignment: .leading)
            Text(entry.text)
                .font(.system(size: 12))
                .foregroundColor(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 16)
    }

    private func toggleSection(_ id: String) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if expandedSections.contains(id) {
                expandedSections.remove(id)
            } else {
                expandedSections.insert(id)
            }
        }
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
