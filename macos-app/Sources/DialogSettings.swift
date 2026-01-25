import SwiftUI
import Combine

final class DialogSettings: ObservableObject {
    static let shared = DialogSettings()

    private let settingsURL: URL
    private var snoozeTimer: Timer?
    private var fileMonitor: DispatchSourceFileSystemObject?

    // MARK: - Persisted Settings

    @AppStorage("dialogPosition") var position: DialogPosition = .left
    @AppStorage("dialogSize") var size: DialogSize = .regular
    @AppStorage("soundOnShow") var soundOnShow: SoundEffect = .subtle
    @AppStorage("animationsEnabled") var animationsEnabled: Bool = true
    @AppStorage("alwaysOnTop") var alwaysOnTop: Bool = true
    @AppStorage("showCommentField") var showCommentField: Bool = true
    @AppStorage("buttonCooldownEnabled") var buttonCooldownEnabled: Bool = true
    @AppStorage("buttonCooldownDuration") var buttonCooldownDuration: Double = 2.0

    // MARK: - Update Settings (persisted via AppStorage)

    @AppStorage("lastUpdateCheckTime") private var lastUpdateCheckTime: Double = 0
    @AppStorage("latestKnownVersion") var latestKnownVersion: String = ""

    // MARK: - Runtime State

    @Published private(set) var snoozeRemaining: Int = 0
    private var snoozeTotalSeconds: Int = 0

    @Published var updateCheckInProgress: Bool = false
    @Published var updateAvailable: UpdateManager.Release? = nil
    @Published var updateDownloadProgress: Double? = nil  // nil = not downloading, 0-1 = progress
    @Published var updateStatus: String? = nil  // Status message during update

    // MARK: - Update Computed Properties

    var lastUpdateCheck: Date? {
        lastUpdateCheckTime > 0 ? Date(timeIntervalSince1970: lastUpdateCheckTime) : nil
    }

    func recordUpdateCheck(latestVersion: String?) {
        lastUpdateCheckTime = Date().timeIntervalSince1970
        if let version = latestVersion {
            latestKnownVersion = version
        }
    }

    var shouldAutoCheckForUpdates: Bool {
        guard let lastCheck = lastUpdateCheck else { return true }
        return Date().timeIntervalSince(lastCheck) > 4 * 60 * 60 // 4 hours
    }

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
        startFileMonitoring()

        // Start countdown timer if snooze is already active from file
        if isSnoozed {
            startCountdownTimer()
        }
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
        var lastUpdateCheckTime: Double?
        var latestKnownVersion: String?
        var buttonCooldownEnabled: Bool?
        var buttonCooldownDuration: Double?
    }

    func saveToFile() {
        let settings = SettingsFile(
            position: position,
            size: size,
            soundOnShow: soundOnShow,
            animationsEnabled: animationsEnabled,
            alwaysOnTop: alwaysOnTop,
            showCommentField: showCommentField,
            snoozeUntil: snoozeUntilDate,
            lastUpdateCheckTime: lastUpdateCheckTime > 0 ? lastUpdateCheckTime : nil,
            latestKnownVersion: latestKnownVersion.isEmpty ? nil : latestKnownVersion,
            buttonCooldownEnabled: buttonCooldownEnabled,
            buttonCooldownDuration: buttonCooldownDuration
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
        animationsEnabled = settings.animationsEnabled
        alwaysOnTop = settings.alwaysOnTop
        showCommentField = settings.showCommentField
        snoozeUntilDate = settings.snoozeUntil
        if let checkTime = settings.lastUpdateCheckTime {
            lastUpdateCheckTime = checkTime
        }
        if let version = settings.latestKnownVersion {
            latestKnownVersion = version
        }
        if let cooldownEnabled = settings.buttonCooldownEnabled {
            buttonCooldownEnabled = cooldownEnabled
        }
        if let cooldownDuration = settings.buttonCooldownDuration {
            buttonCooldownDuration = cooldownDuration
        }
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
        startCountdownTimer()
    }

    func clearSnooze() {
        stopCountdownTimer()
        snoozeUntilDate = nil
        snoozeRemaining = 0
        snoozeTotalSeconds = 0
        saveToFile()
    }

    // MARK: - Countdown Timer (on-demand)

    private func startCountdownTimer() {
        stopCountdownTimer()
        snoozeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSnoozeRemaining()
        }
        updateSnoozeRemaining()
    }

    private func stopCountdownTimer() {
        snoozeTimer?.invalidate()
        snoozeTimer = nil
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
            stopCountdownTimer()
            snoozeUntilDate = nil
            snoozeTotalSeconds = 0
            saveToFile()
        }
    }

    // MARK: - File Monitoring (for external changes)

    private func startFileMonitoring() {
        let fd = open(settingsURL.path, O_EVTONLY)
        guard fd >= 0 else { return }

        fileMonitor = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename],
            queue: .main
        )

        fileMonitor?.setEventHandler { [weak self] in
            self?.handleExternalFileChange()
        }

        fileMonitor?.setCancelHandler {
            close(fd)
        }

        fileMonitor?.resume()
    }

    private func handleExternalFileChange() {
        loadSnoozeFromFile()

        // Start countdown if snooze became active from external change
        if isSnoozed && snoozeTimer == nil {
            startCountdownTimer()
        }
    }

    private func loadSnoozeFromFile() {
        guard let data = try? Data(contentsOf: settingsURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        // If snoozeUntil is missing or invalid, clear snooze state
        guard let snoozeString = json["snoozeUntil"] as? String else {
            if snoozeUntilDate != nil {
                stopCountdownTimer()
                snoozeUntilDate = nil
                snoozeTotalSeconds = 0
            }
            return
        }

        let formatter = ISO8601DateFormatter()
        snoozeUntilDate = formatter.date(from: snoozeString)
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
