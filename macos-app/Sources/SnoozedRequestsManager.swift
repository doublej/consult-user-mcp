import SwiftUI

final class SnoozedRequestsManager: ObservableObject {
    static let shared = SnoozedRequestsManager()

    private let fileURL: URL
    private var pollTimer: Timer?
    private var lastModified: Date?

    @Published private(set) var requests: [SnoozedRequest] = []

    var count: Int { requests.count }

    private init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        fileURL = appSupport.appendingPathComponent("ConsultUserMCP/snoozed-requests.json")
        loadFromFile()
        startPolling()
    }

    func clear() {
        requests = []
        try? FileManager.default.removeItem(at: fileURL)
        lastModified = nil
    }

    private func loadFromFile() {
        guard let data = try? Data(contentsOf: fileURL) else {
            if !requests.isEmpty { requests = [] }
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        requests = (try? decoder.decode([SnoozedRequest].self, from: data)) ?? []
        lastModified = fileModificationDate()
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    private func checkForChanges() {
        let currentMod = fileModificationDate()
        guard currentMod != lastModified else { return }
        loadFromFile()
    }

    private func fileModificationDate() -> Date? {
        try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date
    }
}
