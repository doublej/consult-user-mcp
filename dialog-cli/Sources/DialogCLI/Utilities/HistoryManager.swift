import Foundation

// MARK: - History Manager

struct HistoryManager {
    private static let maxEntries = 500

    private static var historyURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ConsultUserMCP/history.json")
    }

    // MARK: - Load

    static func load() -> HistoryFile {
        guard let url = historyURL,
              let data = FileManager.default.contents(atPath: url.path) else {
            return HistoryFile(entries: [])
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let file = try? decoder.decode(HistoryFile.self, from: data) else {
            return HistoryFile(entries: [])
        }

        return file
    }

    // MARK: - Append

    static func append(entry: HistoryEntry) {
        guard let url = historyURL else { return }
        let fm = FileManager.default

        var file = load()
        file.entries.append(entry)
        file.entries = prune(file.entries)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(file)
            try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
        } catch {
            fputs("Failed to save history: \(error.localizedDescription)\n", stderr)
        }
    }

    // MARK: - Prune

    private static func prune(_ entries: [HistoryEntry]) -> [HistoryEntry] {
        guard entries.count > maxEntries else { return entries }
        return Array(entries.suffix(maxEntries))
    }
}
