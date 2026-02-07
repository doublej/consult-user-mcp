import Foundation
import AppKit

// MARK: - Settings Reader

struct UserSettings {
    var position: String = "left"
    var soundOnShow: String = "subtle"
    var playSoundForQuestions: Bool = true
    var playSoundForNotifications: Bool = false
    var muteSoundsWhileSnoozed: Bool = true
    var animationsEnabled: Bool = true
    var alwaysOnTop: Bool = true
    var snoozeUntil: Date?
    var buttonCooldownEnabled: Bool = true
    var buttonCooldownDuration: Double = 2.0

    enum SoundContext {
        case question
        case notification
    }

    func playSound() {
        let soundName: String?
        switch soundOnShow {
        case "subtle": soundName = "Tink"
        case "pop": soundName = "Pop"
        case "chime": soundName = "Glass"
        default: soundName = nil
        }
        guard let name = soundName else { return }
        NSSound(named: NSSound.Name(name))?.play()
    }

    func shouldPlaySound(for context: SoundContext) -> Bool {
        if muteSoundsWhileSnoozed, isSnoozedNow {
            return false
        }

        switch context {
        case .question:
            return playSoundForQuestions
        case .notification:
            return playSoundForNotifications
        }
    }

    private var isSnoozedNow: Bool {
        guard let snoozeUntil else { return false }
        return snoozeUntil > Date()
    }

    private static var settingsURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("ConsultUserMCP/settings.json")
    }

    static func load() -> UserSettings {
        var settings = UserSettings()

        guard let url = settingsURL,
              let data = FileManager.default.contents(atPath: url.path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return settings
        }

        if let position = json["position"] as? String {
            settings.position = position
        }
        if let sound = json["soundOnShow"] as? String {
            settings.soundOnShow = sound
        }
        if let animations = json["animationsEnabled"] as? Bool {
            settings.animationsEnabled = animations
        }
        if let onTop = json["alwaysOnTop"] as? Bool {
            settings.alwaysOnTop = onTop
        }
        if let playQuestions = json["playSoundForQuestions"] as? Bool {
            settings.playSoundForQuestions = playQuestions
        }
        if let playNotifications = json["playSoundForNotifications"] as? Bool {
            settings.playSoundForNotifications = playNotifications
        }
        if let muteWhileSnoozed = json["muteSoundsWhileSnoozed"] as? Bool {
            settings.muteSoundsWhileSnoozed = muteWhileSnoozed
        }
        if let snoozeStr = json["snoozeUntil"] as? String {
            let formatter = ISO8601DateFormatter()
            settings.snoozeUntil = formatter.date(from: snoozeStr)
        }
        if let cooldownEnabled = json["buttonCooldownEnabled"] as? Bool {
            settings.buttonCooldownEnabled = cooldownEnabled
        }
        if let cooldownDuration = json["buttonCooldownDuration"] as? Double {
            settings.buttonCooldownDuration = cooldownDuration
        }

        return settings
    }

    // MARK: - Snooze Management

    static func setSnooze(minutes: Int) {
        guard let url = settingsURL else { return }
        let fm = FileManager.default

        var json: [String: Any] = [:]
        if let data = fm.contents(atPath: url.path),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = existing
        }

        let formatter = ISO8601DateFormatter()
        let expiry = Date().addingTimeInterval(TimeInterval(minutes * 60))
        json["snoozeUntil"] = formatter.string(from: expiry)

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url)
        } catch {
            fputs("Failed to save settings: \(error.localizedDescription)\n", stderr)
        }
    }

    static func clearSnooze() {
        guard let url = settingsURL else { return }
        let fm = FileManager.default

        guard let data = fm.contents(atPath: url.path),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        json.removeValue(forKey: "snoozeUntil")

        do {
            let newData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            try newData.write(to: url)
        } catch {
            fputs("Failed to clear snooze: \(error.localizedDescription)\n", stderr)
        }
    }

    static func isSnoozeActive() -> (active: Bool, remainingSeconds: Int?) {
        let settings = load()
        guard let snoozeUntil = settings.snoozeUntil else {
            return (false, nil)
        }

        let remaining = snoozeUntil.timeIntervalSinceNow
        if remaining > 0 {
            return (true, Int(remaining))
        } else {
            // Snooze expired, clean it up
            clearSnooze()
            return (false, nil)
        }
    }
}
