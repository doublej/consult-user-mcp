import SwiftUI

struct HistoryView: View {
    @ObservedObject private var historyManager = HistoryManager.shared
    @State private var showClearConfirmation = false
    @Binding var isPresented: Bool

    private let maxHeight: CGFloat = (NSScreen.main?.visibleFrame.height ?? 600) - 100

    var body: some View {
        VStack(spacing: 0) {
            header

            if historyManager.entries.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(groupedEntries.keys.sorted().reversed(), id: \.self) { group in
                            if let entries = groupedEntries[group] {
                                Section {
                                    ForEach(entries.reversed()) { entry in
                                        HistoryEntryRow(entry: entry)
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
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxHeight: maxHeight)
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

// MARK: - History Entry Row

private struct HistoryEntryRow: View {
    let entry: HistoryEntry

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
        if entry.cancelled {
            return .orange
        }
        return .green
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
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
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.controlBackgroundColor))
        )
    }
}

#Preview {
    HistoryView(isPresented: .constant(true))
}
