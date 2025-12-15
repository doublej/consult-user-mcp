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
    @AppStorage("speechRate") var speechRate: Double = 200
    @AppStorage("speechVoice") var speechVoice: String = ""

    private init() {}

    func saveToFile() {
        let settings: [String: Any] = [
            "position": position.rawValue,
            "size": size.rawValue,
            "soundOnShow": soundOnShow.rawValue,
            "soundOnDismiss": soundOnDismiss.rawValue,
            "animationsEnabled": animationsEnabled,
            "alwaysOnTop": alwaysOnTop,
            "showCommentField": showCommentField,
            "speechRate": speechRate,
            "speechVoice": speechVoice
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
