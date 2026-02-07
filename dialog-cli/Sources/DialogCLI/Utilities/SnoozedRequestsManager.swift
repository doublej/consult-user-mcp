import Foundation

struct SnoozedRequestsManager {
    private static let maxEntries = 50

    private static var fileURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ConsultUserMCP/snoozed-requests.json")
    }

    static func append(clientName: String, dialogType: String, summary: String) {
        guard let url = fileURL else { return }
        let fm = FileManager.default

        var entries = load()
        let entry = SnoozedRequest(
            id: UUID(),
            timestamp: Date(),
            clientName: clientName,
            dialogType: dialogType,
            summary: String(summary.prefix(200))
        )
        entries.append(entry)
        if entries.count > maxEntries {
            entries = Array(entries.suffix(maxEntries))
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try encoder.encode(entries)
            try data.write(to: url, options: .atomic)
        } catch {
            fputs("Failed to save snoozed request: \(error.localizedDescription)\n", stderr)
        }
    }

    static func load() -> [SnoozedRequest] {
        guard let url = fileURL,
              let data = FileManager.default.contents(atPath: url.path) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([SnoozedRequest].self, from: data)) ?? []
    }

    static func count() -> Int {
        load().count
    }
}
