import SwiftUI
import Combine

final class DialogSettings: ObservableObject {
    static let shared = DialogSettings()

    private let settingsURL: URL
    private var snoozeTimer: Timer?

    // MARK: - Persisted Settings

    @AppStorage("dialogPosition") var position: DialogPosition = .left
    @AppStorage("dialogSize") var size: DialogSize = .regular
    @AppStorage("soundOnShow") var soundOnShow: SoundEffect = .subtle
    @AppStorage("animationsEnabled") var animationsEnabled: Bool = true
    @AppStorage("alwaysOnTop") var alwaysOnTop: Bool = true
    @AppStorage("showCommentField") var showCommentField: Bool = true

    // MARK: - Runtime State

    @Published private(set) var snoozeRemaining: Int = 0
    private var snoozeTotalSeconds: Int = 0

    // MARK: - Init

    private init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let folder = appSupport.appendingPathComponent("ConsultUserMCP")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        settingsURL = folder.appendingPathComponent("settings.json")

        loadFromFile()
        startSnoozeMonitoring()
    }

    // MARK: - File Persistence

    private struct SettingsFile: Codable {
        var position: DialogPosition
        var size: DialogSize
        var soundOnShow: SoundEffect
        var animationsEnabled: Bool
        var alwaysOnTop: Bool
        var showCommentField: Bool
        var snoozeUntil: Date?
    }

    func saveToFile() {
        let settings = SettingsFile(
            position: position,
            size: size,
            soundOnShow: soundOnShow,
            soundOnDismiss: soundOnDismiss,
            animationsEnabled: animationsEnabled,
            alwaysOnTop: alwaysOnTop,
            showCommentField: showCommentField,
            snoozeUntil: snoozeUntilDate
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(settings) else { return }
        try? data.write(to: settingsURL, options: .atomic)
    }

    private func loadFromFile() {
        guard let data = try? Data(contentsOf: settingsURL) else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let settings = try? decoder.decode(SettingsFile.self, from: data) else { return }

        position = settings.position
        size = settings.size
        soundOnShow = settings.soundOnShow
        soundOnDismiss = settings.soundOnDismiss
        animationsEnabled = settings.animationsEnabled
        alwaysOnTop = settings.alwaysOnTop
        showCommentField = settings.showCommentField
        snoozeUntilDate = settings.snoozeUntil
    }

    // MARK: - Snooze

    private var snoozeUntilDate: Date? {
        didSet { updateSnoozeRemaining() }
    }

    var isSnoozed: Bool {
        guard let until = snoozeUntilDate else { return false }
        return until > Date()
    }

    func snooze(minutes: Int) {
        snoozeTotalSeconds = minutes * 60
        snoozeUntilDate = Date().addingTimeInterval(TimeInterval(snoozeTotalSeconds))
        saveToFile()
    }

    func clearSnooze() {
        snoozeUntilDate = nil
        snoozeRemaining = 0
        snoozeTotalSeconds = 0
        saveToFile()
    }

    private func startSnoozeMonitoring() {
        snoozeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pollSnoozeFile()
            self?.updateSnoozeRemaining()
        }
        updateSnoozeRemaining()
    }

    private func pollSnoozeFile() {
        guard let data = try? Data(contentsOf: settingsURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        // If snoozeUntil is missing or invalid, clear snooze state
        guard let snoozeString = json["snoozeUntil"] as? String else {
            if snoozeUntilDate != nil {
                snoozeUntilDate = nil
                snoozeTotalSeconds = 0
            }
            return
        }

        let formatter = ISO8601DateFormatter()
        snoozeUntilDate = formatter.date(from: snoozeString)
    }

    private func updateSnoozeRemaining() {
        guard let until = snoozeUntilDate else {
            snoozeRemaining = 0
            return
        }

        let remaining = Int(until.timeIntervalSinceNow)
        snoozeRemaining = max(0, remaining)

        // Initialize total from remaining if loaded from file
        if snoozeTotalSeconds == 0 && snoozeRemaining > 0 {
            snoozeTotalSeconds = snoozeRemaining
        }

        if remaining <= 0 {
            snoozeUntilDate = nil
            snoozeTotalSeconds = 0
            saveToFile()
        }
    }

    var snoozeDisplayTime: String {
        let minutes = snoozeRemaining / 60
        let seconds = snoozeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var snoozeProgress: Double {
        guard snoozeRemaining > 0, snoozeTotalSeconds > 0 else { return 0 }
        return Double(snoozeRemaining) / Double(snoozeTotalSeconds)
    }
}
