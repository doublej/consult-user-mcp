import SwiftUI
import Combine

final class HistoryManager: ObservableObject {
    static let shared = HistoryManager()

    let historyDir: URL
    private let legacyFileURL: URL
    private var pollTimer: Timer?
    private var lastDirModified: Date?
    private var lastTodayFileModified: Date?
    private let maxDaysToLoad = 30

    @Published private(set) var entries: [HistoryEntry] = []

    // MARK: - Init

    private init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let folder = appSupport.appendingPathComponent("ConsultUserMCP")
        historyDir = folder.appendingPathComponent("history")
        legacyFileURL = folder.appendingPathComponent("history.json")

        try? FileManager.default.createDirectory(at: historyDir, withIntermediateDirectories: true)
        migrateLegacyFile()
        loadAllDays()
        startPolling()
    }

    // MARK: - Migration

    private func migrateLegacyFile() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: legacyFileURL.path),
              let data = try? Data(contentsOf: legacyFileURL) else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let legacy = try? decoder.decode(LegacyHistoryFile.self, from: data) else { return }

        let grouped = Dictionary(grouping: legacy.entries) { dayString(from: $0.timestamp) }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        for (day, dayEntries) in grouped {
            let dayURL = historyDir.appendingPathComponent("\(day).json")
            guard let encoded = try? encoder.encode(dayEntries) else { continue }
            try? encoded.write(to: dayURL, options: .atomic)
        }

        try? fm.removeItem(at: legacyFileURL)
    }

    // MARK: - Load

    private func loadAllDays() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: historyDir, includingPropertiesForKeys: nil) else {
            entries = []
            return
        }

        let cutoff = Calendar.current.date(byAdding: .day, value: -maxDaysToLoad, to: Date())!
        let cutoffString = dayString(from: cutoff)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var all: [HistoryEntry] = []
        for file in files where file.pathExtension == "json" {
            let name = file.deletingPathExtension().lastPathComponent
            guard name >= cutoffString else { continue }
            guard let data = try? Data(contentsOf: file),
                  let dayEntries = try? decoder.decode([HistoryEntry].self, from: data) else { continue }
            all.append(contentsOf: dayEntries)
        }

        entries = all.sorted { $0.timestamp < $1.timestamp }
        lastDirModified = dirModificationDate()
        lastTodayFileModified = todayFileModificationDate()
    }

    // MARK: - Clear

    func clearHistory() {
        entries = []
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: historyDir, includingPropertiesForKeys: nil) else { return }
        for file in files where file.pathExtension == "json" {
            try? fm.removeItem(at: file)
        }
        lastDirModified = dirModificationDate()
        lastTodayFileModified = nil
    }

    // MARK: - File Polling

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    private func checkForChanges() {
        let currentDirMod = dirModificationDate()
        let currentTodayMod = todayFileModificationDate()

        let dirChanged = currentDirMod != lastDirModified
        let todayChanged = currentTodayMod != lastTodayFileModified

        guard dirChanged || todayChanged else { return }
        loadAllDays()
    }

    private func dirModificationDate() -> Date? {
        try? FileManager.default.attributesOfItem(atPath: historyDir.path)[.modificationDate] as? Date
    }

    private func todayFileModificationDate() -> Date? {
        let todayURL = historyDir.appendingPathComponent("\(dayString(from: Date())).json")
        return try? FileManager.default.attributesOfItem(atPath: todayURL.path)[.modificationDate] as? Date
    }

    // MARK: - Date formatting

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        return f
    }()

    private func dayString(from date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }
}
