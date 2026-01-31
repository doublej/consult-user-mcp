import SwiftUI

// MARK: - History Detail View (for NavigationSplitView)

struct HistoryDetailView: View {
    @ObservedObject private var historyManager = HistoryManager.shared
    @State private var showClearConfirmation = false
    @State private var selectedEntry: HistoryEntry?
    @State private var searchText: String = ""
    @State private var collapsedSections: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            if let entry = selectedEntry {
                HistoryEntryDetailView(entry: entry, onBack: { selectedEntry = nil })
            } else {
                listView
            }
        }
        .background(Color(.windowBackgroundColor))
        .alert("Clear History", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                historyManager.clearHistory()
            }
        } message: {
            Text("This will permanently delete all dialog history. This cannot be undone.")
        }
    }

    private var listView: some View {
        VStack(spacing: 0) {
            header

            if !historyManager.entries.isEmpty {
                searchField
            }

            if historyManager.entries.isEmpty {
                emptyState
            } else if filteredEntries.isEmpty {
                noResultsState
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(sortedGroupKeys, id: \.self) { dateKey in
                            if let entries = groupedEntries[dateKey] {
                                sectionView(dateKey: dateKey, entries: entries)
                            }
                        }
                    }
                    .padding(24)
                }
            }

            footer
        }
        .onAppear { initCollapsedSections() }
    }

    private func sectionView(dateKey: String, entries: [HistoryEntry]) -> some View {
        let isCollapsed = !isSearching && collapsedSections.contains(dateKey)
        return VStack(alignment: .leading, spacing: 8) {
            sectionHeaderButton(dateKey: dateKey, count: entries.count)

            if !isCollapsed {
                VStack(spacing: 6) {
                    ForEach(Array(entries.reversed().enumerated()), id: \.element.id) { index, entry in
                        Button { selectedEntry = entry } label: {
                            HistoryEntryRow(entry: entry, isAlternate: index % 2 == 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func sectionHeaderButton(dateKey: String, count: Int) -> some View {
        let isCollapsed = !isSearching && collapsedSections.contains(dateKey)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if collapsedSections.contains(dateKey) {
                    collapsedSections.remove(dateKey)
                } else {
                    collapsedSections.insert(dateKey)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 12)

                Text(sectionHeader(for: dateKey))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                if isCollapsed {
                    Text("(\(count))")
                        .font(.system(size: 10))
                        .foregroundColor(Color(.tertiaryLabelColor))
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search

    private var isSearching: Bool { !searchText.isEmpty }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            TextField("Search history…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
            if isSearching {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(.controlBackgroundColor)))
        .padding(.horizontal, 24)
        .padding(.bottom, 4)
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("No matching entries")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func initCollapsedSections() {
        let todayKey = Self.dayFormatter.string(from: Date())
        collapsedSections = Set(sortedGroupKeys.filter { $0 != todayKey })
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            SettingsPageHeader(
                icon: "clock.arrow.circlepath",
                title: "History",
                description: "View past dialog interactions"
            )

            if !historyManager.entries.isEmpty {
                Button(action: { showClearConfirmation = true }) {
                    Label("Clear All", systemImage: "trash")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 8)
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Group {
                if isSearching {
                    Text("\(filteredEntries.count) of \(historyManager.entries.count) entries")
                } else {
                    Text("\(historyManager.entries.count) entries")
                }
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(Color(.tertiaryLabelColor))

            Spacer()

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([historyManager.historyDir])
            } label: {
                Image(systemName: "folder")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabelColor))
            }
            .buttonStyle(.plain)
            .help("Reveal data file in Finder")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color(.controlBackgroundColor).opacity(0.4))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 52))
                .foregroundColor(.secondary)
            VStack(spacing: 8) {
                Text("No History")
                    .font(.system(size: 17, weight: .medium))
                Text("Dialog interactions will appear here")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Filtering & Grouping

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        return f
    }()

    private var filteredEntries: [HistoryEntry] {
        guard isSearching else { return historyManager.entries }
        let query = searchText.lowercased()
        return historyManager.entries.filter { entry in
            entry.questionSummary.localizedCaseInsensitiveContains(query)
                || (entry.answer?.localizedCaseInsensitiveContains(query) ?? false)
                || entry.clientName.localizedCaseInsensitiveContains(query)
        }
    }

    private var groupedEntries: [String: [HistoryEntry]] {
        Dictionary(grouping: filteredEntries) { entry in
            Self.dayFormatter.string(from: entry.timestamp)
        }
    }

    private var sortedGroupKeys: [String] {
        groupedEntries.keys.sorted().reversed()
    }

    private func sectionHeader(for dateKey: String) -> String {
        guard let date = Self.dayFormatter.date(from: dateKey) else { return dateKey }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }

        let display = DateFormatter()
        display.dateFormat = "EEEE, MMM d"
        display.timeZone = .current
        return display.string(from: date)
    }
}

// MARK: - History Entry Detail View

private struct HistoryEntryDetailView: View {
    let entry: HistoryEntry
    let onBack: () -> Void

    private var icon: String {
        switch entry.dialogType {
        case "confirm": return "checkmark.circle"
        case "choose": return "list.bullet"
        case "textInput": return "text.cursor"
        case "questions": return "questionmark.circle"
        case "notify": return "bell"
        default: return "bubble.left"
        }
    }

    private var dialogTypeName: String {
        switch entry.dialogType {
        case "confirm": return "Confirmation"
        case "choose": return "Multiple Choice"
        case "textInput": return "Text Input"
        case "questions": return "Questions"
        case "notify": return "Notification"
        default: return entry.dialogType.capitalized
        }
    }

    private var statusText: String {
        if entry.cancelled { return "Cancelled" }
        if entry.snoozed { return "Snoozed" }
        return "Completed"
    }

    private var statusColor: Color {
        if entry.cancelled { return .orange }
        if entry.snoozed { return .yellow }
        return .green
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(spacing: 0) {
            entryHeader
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    typeAndStatus
                    questionSection
                    if entry.answer != nil || entry.cancelled {
                        answerSection
                    }
                    metadataSection
                }
                .padding(24)
            }
        }
        .background(Color(.windowBackgroundColor))
    }

    private var entryHeader: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Label("Back", systemImage: "chevron.left")
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)

            Spacer()

            Text("Entry Details")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()

            // Balance spacer
            Button("Back") {}
                .buttonStyle(.bordered)
                .opacity(0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.windowBackgroundColor))
    }

    private var typeAndStatus: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(dialogTypeName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                Text(statusText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(statusColor)
            }
        }
    }

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Question")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            Text(entry.questionSummary)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.controlBackgroundColor))
                )
        }
    }

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Answer")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            if let answer = entry.answer {
                Text(answer)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.controlBackgroundColor))
                    )
            } else if entry.cancelled {
                Text("User cancelled the dialog")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                    .italic()
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange.opacity(0.1))
                    )
            }
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                metadataRow(label: "Client", value: entry.clientName)
                Divider().padding(.leading, 8)
                metadataRow(label: "Time", value: dateFormatter.string(from: entry.timestamp))
                Divider().padding(.leading, 8)
                metadataRow(label: "Type", value: dialogTypeName)
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.controlBackgroundColor))
            )
        }
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .textSelection(.enabled)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - History Entry Row

private struct HistoryEntryRow: View {
    let entry: HistoryEntry
    let isAlternate: Bool
    @State private var isHovered = false

    init(entry: HistoryEntry, isAlternate: Bool = false) {
        self.entry = entry
        self.isAlternate = isAlternate
    }

    private var icon: String {
        switch entry.dialogType {
        case "confirm": return "checkmark.circle"
        case "choose": return "list.bullet"
        case "textInput": return "text.cursor"
        case "questions": return "questionmark.circle"
        case "notify": return "bell"
        default: return "bubble.left"
        }
    }

    private var statusColor: Color {
        if entry.cancelled { return .orange }
        return .green
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon column
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 28)

            // Client & time column
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.clientName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(timeFormatter.string(from: entry.timestamp))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(.tertiaryLabelColor))
            }
            .frame(width: 80, alignment: .leading)

            // Question column
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.questionSummary)
                    .font(.system(size: 12))
                    .lineLimit(2)
                    .foregroundColor(.primary)

                if let answer = entry.answer {
                    Text(answer)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else if entry.cancelled {
                    Text("Cancelled")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }
            }

            Spacer(minLength: 12)

            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabelColor))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(.selectedControlColor).opacity(0.3) : (isAlternate ? Color(.controlBackgroundColor).opacity(0.5) : Color(.controlBackgroundColor)))
        )
        .contentShape(Rectangle())
        .onHover { hovering in isHovered = hovering }
    }
}

#Preview {
    HistoryDetailView()
        .frame(width: 480, height: 500)
}
