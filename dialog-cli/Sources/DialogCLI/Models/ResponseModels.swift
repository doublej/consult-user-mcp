import Foundation

enum StringOrStrings: Codable {
    case single(String)
    case multiple([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let arr = try? container.decode([String].self) {
            self = .multiple(arr)
        } else if let str = try? container.decode(String.self) {
            self = .single(str)
        } else {
            throw DecodingError.typeMismatch(StringOrStrings.self, .init(codingPath: decoder.codingPath, debugDescription: "Expected String or [String]"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let str): try container.encode(str)
        case .multiple(let arr): try container.encode(arr)
        }
    }
}

struct ConfirmResponse: Codable {
    let dialogType: String
    let confirmed: Bool
    let cancelled: Bool
    let dismissed: Bool
    let answer: String?
    let comment: String?
    let snoozed: Bool?
    let snoozeMinutes: Int?
    let feedbackText: String?
    let instruction: String?
}

struct ChoiceResponse: Codable {
    let dialogType: String
    let answer: StringOrStrings?
    let cancelled: Bool
    let dismissed: Bool
    let description: String?
    let descriptions: [String?]?
    let comment: String?
    let snoozed: Bool?
    let snoozeMinutes: Int?
    let feedbackText: String?
    let instruction: String?
}

struct TextInputResponse: Codable {
    let dialogType: String
    let answer: String?
    let cancelled: Bool
    let dismissed: Bool
    let comment: String?
    let snoozed: Bool?
    let snoozeMinutes: Int?
    let feedbackText: String?
    let instruction: String?
}

struct NotifyResponse: Codable {
    let dialogType: String
    let success: Bool
}

struct SpeakResponse: Codable {
    let dialogType: String
    let success: Bool
}
