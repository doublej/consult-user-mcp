import SwiftUI
import Combine

final class HistoryManager: ObservableObject {
    static let shared = HistoryManager()

    private let historyURL: URL
    private var fileMonitor: DispatchSourceFileSystemObject?

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

        loadFromFile()
        startFileMonitoring()
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
    }

    // MARK: - File Monitoring

    private func startFileMonitoring() {
        let fd = open(historyURL.path, O_EVTONLY | O_CREAT, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { return }

        fileMonitor = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .extend],
            queue: .main
        )

        fileMonitor?.setEventHandler { [weak self] in
            self?.loadFromFile()
        }

        fileMonitor?.setCancelHandler {
            close(fd)
        }

        fileMonitor?.resume()
    }
}
