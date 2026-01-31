import Foundation

// MARK: - History Manager

struct HistoryManager {
    private static let maxEntriesPerDay = 200

    private static var historyDir: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ConsultUserMCP/history")
    }

    private static var todayFileURL: URL? {
        let dateString = Self.dayString(from: Date())
        return historyDir?.appendingPathComponent("\(dateString).json")
    }

    // MARK: - Append

    static func append(entry: HistoryEntry) {
        guard let dir = historyDir, let url = todayFileURL else { return }
        let fm = FileManager.default

        var entries = loadDay(url: url)
        entries.append(entry)
        entries = prune(entries)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try encoder.encode(entries)
            try data.write(to: url, options: .atomic)
        } catch {
            fputs("Failed to save history: \(error.localizedDescription)\n", stderr)
        }
    }

    // MARK: - Load single day

    private static func loadDay(url: URL) -> [HistoryEntry] {
        guard let data = FileManager.default.contents(atPath: url.path) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return (try? decoder.decode([HistoryEntry].self, from: data)) ?? []
    }

    // MARK: - Prune

    private static func prune(_ entries: [HistoryEntry]) -> [HistoryEntry] {
        guard entries.count > maxEntriesPerDay else { return entries }
        return Array(entries.suffix(maxEntriesPerDay))
    }

    // MARK: - Date formatting

    static func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}
