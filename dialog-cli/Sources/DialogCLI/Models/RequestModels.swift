import Foundation

struct ConfirmRequest: Codable {
    let message: String
    let title: String
    let confirmLabel: String
    let cancelLabel: String
    let position: String
}

struct ChooseRequest: Codable {
    let prompt: String
    let choices: [String]
    let descriptions: [String]?
    let allowMultiple: Bool
    let defaultSelection: String?
    let position: String
}

struct TextInputRequest: Codable {
    let prompt: String
    let title: String
    let defaultValue: String
    let hidden: Bool
    let position: String
}

struct NotifyRequest: Codable {
    let message: String
    let title: String
    let subtitle: String?
    let sound: Bool
}

struct SpeakRequest: Codable {
    let text: String
    let voice: String?
    let rate: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        rate = try container.decode(Int.self, forKey: .rate)
        if container.contains(.voice) {
            voice = try? container.decode(String.self, forKey: .voice)
        } else {
            voice = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case text, voice, rate
    }
}
