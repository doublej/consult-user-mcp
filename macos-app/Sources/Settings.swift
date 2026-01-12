import Foundation
import SwiftUI

enum DialogPosition: String, CaseIterable, Codable {
    case left = "left"
    case center = "center"
    case right = "right"

    var label: String {
        switch self {
        case .left: return "Left"
        case .center: return "Center"
        case .right: return "Right"
        }
    }

    var icon: String {
        switch self {
        case .left: return "rectangle.lefthalf.inset.filled"
        case .center: return "rectangle.center.inset.filled"
        case .right: return "rectangle.righthalf.inset.filled"
        }
    }
}

enum DialogSize: String, CaseIterable, Codable {
    case compact = "compact"
    case regular = "regular"
    case large = "large"

    var label: String {
        switch self {
        case .compact: return "Compact"
        case .regular: return "Regular"
        case .large: return "Large"
        }
    }

    var shortLabel: String {
        switch self {
        case .compact: return "S"
        case .regular: return "M"
        case .large: return "L"
        }
    }

    var scale: CGFloat {
        switch self {
        case .compact: return 0.85
        case .regular: return 1.0
        case .large: return 1.2
        }
    }
}

enum SoundEffect: String, CaseIterable, Codable {
    case none = "none"
    case subtle = "subtle"
    case pop = "pop"
    case chime = "chime"

    var label: String {
        switch self {
        case .none: return "None"
        case .subtle: return "Subtle"
        case .pop: return "Pop"
        case .chime: return "Chime"
        }
    }

    var systemSound: String? {
        switch self {
        case .none: return nil
        case .subtle: return "Tink"
        case .pop: return "Pop"
        case .chime: return "Glass"
        }
    }
}

class DialogSettings: ObservableObject {
    static let shared = DialogSettings()

    @AppStorage("dialogPosition") var position: DialogPosition = .left
    @AppStorage("dialogSize") var size: DialogSize = .regular
    @AppStorage("soundOnShow") var soundOnShow: SoundEffect = .subtle
    @AppStorage("soundOnDismiss") var soundOnDismiss: SoundEffect = .none
    @AppStorage("animationsEnabled") var animationsEnabled: Bool = true
    @AppStorage("alwaysOnTop") var alwaysOnTop: Bool = true
    @AppStorage("showCommentField") var showCommentField: Bool = true

    // Snooze state
    @Published var snoozeRemaining: Int = 0
    private var snoozeTimer: Timer?

    private init() {
        startSnoozeMonitoring()
    }

    deinit {
        snoozeTimer?.invalidate()
    }

    // MARK: - Snooze Monitoring

    func startSnoozeMonitoring() {
        snoozeTimer?.invalidate()
        snoozeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSnoozeState()
        }
        updateSnoozeState()
    }

    private func updateSnoozeState() {
        let url = settingsFileURL()
        guard let data = FileManager.default.contents(atPath: url.path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let snoozeStr = json["snoozeUntil"] as? String else {
            snoozeRemaining = 0
            return
        }

        let formatter = ISO8601DateFormatter()
        guard let snoozeUntil = formatter.date(from: snoozeStr) else {
            snoozeRemaining = 0
            return
        }

        let remaining = snoozeUntil.timeIntervalSinceNow
        if remaining > 0 {
            snoozeRemaining = Int(remaining)
        } else {
            snoozeRemaining = 0
            clearSnooze()
        }
    }

    func clearSnooze() {
        let url = settingsFileURL()
        guard let data = FileManager.default.contents(atPath: url.path),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        json.removeValue(forKey: "snoozeUntil")
        snoozeRemaining = 0

        if let newData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            try? newData.write(to: url)
        }
    }

    func saveToFile() {
        let settings: [String: Any] = [
            "position": position.rawValue,
            "size": size.rawValue,
            "soundOnShow": soundOnShow.rawValue,
            "soundOnDismiss": soundOnDismiss.rawValue,
            "animationsEnabled": animationsEnabled,
            "alwaysOnTop": alwaysOnTop,
            "showCommentField": showCommentField
        ]

        let url = settingsFileURL()
        if let data = try? JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted) {
            try? data.write(to: url)
        }
    }

    private func settingsFileURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ConsultUserMCP")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("settings.json")
    }
}
