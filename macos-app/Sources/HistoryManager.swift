import SwiftUI
import Combine

final class HistoryManager: ObservableObject {
    static let shared = HistoryManager()

    let historyURL: URL
    private var pollTimer: Timer?
    private var lastModified: Date?

    @Published private(set) var entries: [HistoryEntry] = []

    // MARK: - Init

    private init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let folder = appSupport.appendingPathComponent("ConsultUserMCP")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        historyURL = folder.appendingPathComponent("history.json")

        lastModified = fileModificationDate()
        loadFromFile()
        startPolling()
    }

    // MARK: - Load

    private func loadFromFile() {
        guard let data = try? Data(contentsOf: historyURL) else {
            entries = []
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let file = try? decoder.decode(HistoryFile.self, from: data) else {
            entries = []
            return
        }

        entries = file.entries
    }

    // MARK: - Clear

    func clearHistory() {
        entries = []
        let file = HistoryFile(entries: [])

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(file) else { return }
        try? data.write(to: historyURL, options: .atomic)
        lastModified = fileModificationDate()
    }

    // MARK: - File Polling

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    private func checkForChanges() {
        let currentMod = fileModificationDate()
        guard currentMod != lastModified else { return }
        lastModified = currentMod
        loadFromFile()
    }

    private func fileModificationDate() -> Date? {
        try? FileManager.default.attributesOfItem(atPath: historyURL.path)[.modificationDate] as? Date
    }
}
