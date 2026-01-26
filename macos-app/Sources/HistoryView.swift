import SwiftUI

struct HistoryView: View {
    @ObservedObject private var historyManager = HistoryManager.shared
    @State private var showClearConfirmation = false
    @State private var selectedEntry: HistoryEntry?
    @Binding var isPresented: Bool

    private let maxHeight: CGFloat = (NSScreen.main?.visibleFrame.height ?? 600) - 100

    var body: some View {
        VStack(spacing: 0) {
            if let entry = selectedEntry {
                HistoryDetailView(entry: entry, onBack: { selectedEntry = nil })
            } else {
                listView
            }
        }
        .frame(width: 300)
        .frame(minHeight: 200, maxHeight: maxHeight)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
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

            if historyManager.entries.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(groupedEntries.keys.sorted().reversed(), id: \.self) { group in
                            if let entries = groupedEntries[group] {
                                Section {
                                    ForEach(entries.reversed()) { entry in
                                        Button { selectedEntry = entry } label: {
                                            HistoryEntryRow(entry: entry)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                } header: {
                                    Text(group)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .padding(.top, 8)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }

            footer
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Button(action: { isPresented = false }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color(.controlBackgroundColor)))
            }
            .buttonStyle(.plain)
            .help("Back")

            Text("Dialog History")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            if !historyManager.entries.isEmpty {
                Button(action: { showClearConfirmation = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear History")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("\(historyManager.entries.count) entries")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(Color(.tertiaryLabelColor))

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("No History")
                .font(.system(size: 13, weight: .medium))
            Text("Dialog interactions will appear here")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    // MARK: - Grouping

    private var groupedEntries: [String: [HistoryEntry]] {
        Dictionary(grouping: historyManager.entries) { entry in
            dateGroup(for: entry.timestamp)
        }
    }

    private func dateGroup(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return "Older"
        }
    }
}

// MARK: - History Detail View

private struct HistoryDetailView: View {
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
            header
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    typeAndStatus
                    questionSection
                    if entry.answer != nil || entry.cancelled {
                        answerSection
                    }
                    metadataSection
                }
                .padding(16)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color(.controlBackgroundColor)))
            }
            .buttonStyle(.plain)
            .help("Back to History")

            Text("Details")
                .font(.system(size: 13, weight: .semibold))

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            Text(value)
                .font(.system(size: 11))
                .foregroundColor(.primary)
                .textSelection(.enabled)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

// MARK: - History Entry Row

private struct HistoryEntryRow: View {
    let entry: HistoryEntry
    @State private var isHovered = false

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
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.clientName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(timeFormatter.string(from: entry.timestamp))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(.tertiaryLabelColor))

                    Spacer()

                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                }

                Text(entry.questionSummary)
                    .font(.system(size: 11))
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

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabelColor))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(.selectedControlColor).opacity(0.3) : Color(.controlBackgroundColor))
        )
        .contentShape(Rectangle())
        .onHover { hovering in isHovered = hovering }
    }
}

#Preview {
    HistoryView(isPresented: .constant(true))
}
