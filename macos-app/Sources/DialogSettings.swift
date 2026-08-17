import SwiftUI
import Combine

final class DialogSettings: ObservableObject {
    static let shared = DialogSettings()

    private let settingsURL: URL
    private var snoozeTimer: Timer?
    private var pollTimer: Timer?
    private var lastModified: Date?

    // MARK: - Persisted Settings

    @AppStorage("dialogPosition") var position: DialogPosition = .left
    @AppStorage("dialogSize") var size: DialogSize = .regular
    /// Not a setting. Dialogs are Caret, and the Appearance section no longer
    /// offers a choice — one interface is the one that gets designed, measured
    /// and screenshotted, and the layout audit is calibrated against this one
    /// only. `DIALOG_SKIN` still reaches the others for development.
    let skin: DialogSkin = .caret
    @AppStorage("soundOnShow") var soundOnShow: SoundEffect = .subtle
    @AppStorage("animationsEnabled") var animationsEnabled: Bool = true
    @AppStorage("alwaysOnTop") var alwaysOnTop: Bool = true
    @AppStorage("showCommentField") var showCommentField: Bool = true
    @AppStorage("buttonCooldownEnabled") var buttonCooldownEnabled: Bool = true
    @AppStorage("buttonCooldownDuration") var buttonCooldownDuration: Double = 2.0
    @AppStorage("playSoundForQuestions") var playSoundForQuestions: Bool = true
    @AppStorage("playSoundForNotifications") var playSoundForNotifications: Bool = false
    @AppStorage("muteSoundsWhileSnoozed") var muteSoundsWhileSnoozed: Bool = true
    @AppStorage("humanizeResponses") var humanizeResponses: Bool = true
    @AppStorage("reviewBeforeSend") var reviewBeforeSend: Bool = false
    @AppStorage("afkMode") var afkMode: Bool = false
    @AppStorage("autoAfkOnSleep") var autoAfkOnSleep: Bool = false
    @AppStorage("autoAfkOnIdle") var autoAfkOnIdle: Bool = false
    @AppStorage("autoAfkIdleMinutes") var autoAfkIdleMinutes: Double = 5
    /// True when AFK was turned on by a trigger (sleep/idle). Used to avoid auto-clearing a manual toggle.
    @AppStorage("afkAutoEnabled") var afkAutoEnabled: Bool = false

    // MARK: - Update Settings (persisted via AppStorage)

    @AppStorage("autoCheckForUpdatesEnabled") var autoCheckForUpdatesEnabled: Bool = true
    @AppStorage("updateCheckCadence") var updateCheckCadence: UpdateCheckCadence = .weekly
    @AppStorage("updateReminderInterval") var updateReminderInterval: UpdateReminderInterval = .threeDays
    @AppStorage("includePrereleaseUpdates") var includePrereleaseUpdates: Bool = false
    @AppStorage("lastUpdateCheckTime") private var lastUpdateCheckTime: Double = 0
    @AppStorage("latestKnownVersion") var latestKnownVersion: String = ""
    @AppStorage("updateReminderUntilTime") private var updateReminderUntilTime: Double = 0
    @AppStorage("ignoredUpdateVersion") private var ignoredUpdateVersion: String = ""

    // MARK: - Runtime State

    @Published private(set) var snoozeRemaining: Int = 0
    private var snoozeTotalSeconds: Int = 0

    @Published var updateCheckInProgress: Bool = false
    @Published var updateAvailable: UpdateManager.Release? = nil
    @Published var updateDownloadProgress: Double? = nil  // nil = not downloading, 0-1 = progress
    @Published var updateStatus: String? = nil  // Status message during update
    @Published var pendingSettingsSection: SettingsSection? = nil

    // MARK: - Update Computed Properties

    var lastUpdateCheck: Date? {
        lastUpdateCheckTime > 0 ? Date(timeIntervalSince1970: lastUpdateCheckTime) : nil
    }

    func recordUpdateCheck(latestVersion: String?) {
        lastUpdateCheckTime = Date().timeIntervalSince1970
        if let version = latestVersion {
            latestKnownVersion = version
        }
        saveToFile()
    }

    var shouldAutoCheckForUpdates: Bool {
        guard autoCheckForUpdatesEnabled else { return false }
        guard let minimumInterval = updateCheckCadence.minimumInterval else { return false }
        guard let lastCheck = lastUpdateCheck else { return true }
        return Date().timeIntervalSince(lastCheck) >= minimumInterval
    }

    var updateReminderUntil: Date? {
        guard updateReminderUntilTime > 0 else { return nil }
        return Date(timeIntervalSince1970: updateReminderUntilTime)
    }

    func remindAboutUpdate(after seconds: TimeInterval) {
        updateReminderUntilTime = Date().addingTimeInterval(seconds).timeIntervalSince1970
        saveToFile()
    }

    func remindAboutUpdate(hours: Int) {
        remindAboutUpdate(after: TimeInterval(hours) * 3600)
    }

    func ignoreUpdate(version: String) {
        ignoredUpdateVersion = version
        updateReminderUntilTime = 0
        saveToFile()
    }

    func clearUpdateReminderState() {
        updateReminderUntilTime = 0
        ignoredUpdateVersion = ""
        saveToFile()
    }

    func shouldPromptForUpdate(version: String) -> Bool {
        if ignoredUpdateVersion == version {
            return false
        }
        if let reminderUntil = updateReminderUntil, reminderUntil > Date() {
            return false
        }
        if updateReminderUntil != nil && (updateReminderUntil ?? .distantPast) <= Date() {
            updateReminderUntilTime = 0
            saveToFile()
        }
        return true
    }

    func remindAboutUpdateUsingPreference() {
        remindAboutUpdate(after: updateReminderInterval.seconds)
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

        lastModified = settingsModificationDate()
        loadFromFile()
        // Rewrite once on launch. Otherwise an install upgrading from a version
        // that still had the skin toggle keeps `"skin": "classic"` in the file
        // until the user happens to change some other setting, and dialogs go
        // on rendering the skin the app no longer offers.
        saveToFile()
        startPolling()

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
        var playSoundForQuestions: Bool?
        var playSoundForNotifications: Bool?
        var muteSoundsWhileSnoozed: Bool?
        var autoCheckForUpdatesEnabled: Bool?
        var updateCheckCadence: UpdateCheckCadence?
        var updateReminderInterval: UpdateReminderInterval?
        var includePrereleaseUpdates: Bool?
        var lastUpdateCheckTime: Double?
        var latestKnownVersion: String?
        var buttonCooldownEnabled: Bool?
        var buttonCooldownDuration: Double?
        var humanizeResponses: Bool?
        var reviewBeforeSend: Bool?
        var afkMode: Bool?
        var autoAfkOnSleep: Bool?
        var autoAfkOnIdle: Bool?
        var autoAfkIdleMinutes: Double?
        var afkAutoEnabled: Bool?
        /// A plain string rather than `DialogSkin`, on purpose. The CLI carries
        /// more skins than the toggle offers and `DIALOG_SKIN` can put any of
        /// them in this file; decoding into the enum would fail on one it does
        /// not know and take every other setting in the file down with it.
        var skin: String?
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
            playSoundForQuestions: playSoundForQuestions,
            playSoundForNotifications: playSoundForNotifications,
            muteSoundsWhileSnoozed: muteSoundsWhileSnoozed,
            autoCheckForUpdatesEnabled: autoCheckForUpdatesEnabled,
            updateCheckCadence: updateCheckCadence,
            updateReminderInterval: updateReminderInterval,
            includePrereleaseUpdates: includePrereleaseUpdates,
            lastUpdateCheckTime: lastUpdateCheckTime > 0 ? lastUpdateCheckTime : nil,
            latestKnownVersion: latestKnownVersion.isEmpty ? nil : latestKnownVersion,
            buttonCooldownEnabled: buttonCooldownEnabled,
            buttonCooldownDuration: buttonCooldownDuration,
            humanizeResponses: humanizeResponses,
            reviewBeforeSend: reviewBeforeSend,
            afkMode: afkMode,
            autoAfkOnSleep: autoAfkOnSleep,
            autoAfkOnIdle: autoAfkOnIdle,
            autoAfkIdleMinutes: autoAfkIdleMinutes,
            afkAutoEnabled: afkAutoEnabled,
            skin: skin.rawValue
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(settings) else { return }
        try? data.write(to: settingsURL, options: .atomic)
        lastModified = settingsModificationDate()
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
        if let soundForQuestions = settings.playSoundForQuestions {
            playSoundForQuestions = soundForQuestions
        }
        if let soundForNotifications = settings.playSoundForNotifications {
            playSoundForNotifications = soundForNotifications
        }
        if let muteOnSnooze = settings.muteSoundsWhileSnoozed {
            muteSoundsWhileSnoozed = muteOnSnooze
        }
        if let autoCheck = settings.autoCheckForUpdatesEnabled {
            autoCheckForUpdatesEnabled = autoCheck
        }
        if let cadence = settings.updateCheckCadence {
            updateCheckCadence = cadence
        }
        if let reminderInterval = settings.updateReminderInterval {
            updateReminderInterval = reminderInterval
        }
        if let includePrerelease = settings.includePrereleaseUpdates {
            includePrereleaseUpdates = includePrerelease
        }
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
        if let humanize = settings.humanizeResponses {
            humanizeResponses = humanize
        }
        if let review = settings.reviewBeforeSend {
            reviewBeforeSend = review
        }
        if let afk = settings.afkMode {
            afkMode = afk
        }
        if let onSleep = settings.autoAfkOnSleep {
            autoAfkOnSleep = onSleep
        }
        if let onIdle = settings.autoAfkOnIdle {
            autoAfkOnIdle = onIdle
        }
        if let idleMin = settings.autoAfkIdleMinutes {
            autoAfkIdleMinutes = idleMin
        }
        if let auto = settings.afkAutoEnabled {
            afkAutoEnabled = auto
        }
        // `skin` is deliberately not read back. It is a constant now, and the
        // next save overwrites whatever an older version left in the file —
        // which is how everyone still on Classic arrives at Caret.
    }

    // MARK: - AFK Mode

    /// User-initiated toggle. Clears the auto-enabled flag so the manual choice stays sticky.
    func toggleAfkMode() {
        afkMode.toggle()
        afkAutoEnabled = false
        saveToFile()
    }

    /// Trigger-initiated change. Tags the AFK state so later triggers know whether to clear it.
    func setAfkFromTrigger(_ enabled: Bool) {
        if enabled {
            guard !afkMode else { return }
            afkMode = true
            afkAutoEnabled = true
        } else {
            guard afkMode && afkAutoEnabled else { return }
            afkMode = false
            afkAutoEnabled = false
        }
        saveToFile()
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
        NotificationCenter.default.post(name: .snoozeDidEnd, object: nil)
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
            NotificationCenter.default.post(name: .snoozeDidEnd, object: nil)
        }
    }

    // MARK: - File Polling (for external changes)

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    private func checkForChanges() {
        let currentMod = settingsModificationDate()
        guard currentMod != lastModified else { return }
        lastModified = currentMod
        handleExternalFileChange()
    }

    private func settingsModificationDate() -> Date? {
        try? FileManager.default.attributesOfItem(atPath: settingsURL.path)[.modificationDate] as? Date
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
