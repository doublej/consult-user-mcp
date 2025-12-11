import Foundation

// MARK: - Settings Reader

struct UserSettings {
    var position: String = "left"
    var speechRate: Int = 200

    static func load() -> UserSettings {
        var settings = UserSettings()

        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return settings
        }

        let settingsURL = appSupport.appendingPathComponent("SpeakMCP/settings.json")
        guard let data = fm.contents(atPath: settingsURL.path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return settings
        }

        if let position = json["position"] as? String {
            settings.position = position
        }
        if let rate = json["speechRate"] as? Int {
            settings.speechRate = rate
        } else if let rate = json["speechRate"] as? Double {
            settings.speechRate = Int(rate)
        }

        return settings
    }
}
