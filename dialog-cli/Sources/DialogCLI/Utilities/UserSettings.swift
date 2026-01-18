import Foundation

// MARK: - Settings Reader

struct UserSettings {
    var position: String = "left"
    var snoozeUntil: Date?

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
        if let snoozeStr = json["snoozeUntil"] as? String {
            let formatter = ISO8601DateFormatter()
            settings.snoozeUntil = formatter.date(from: snoozeStr)
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
