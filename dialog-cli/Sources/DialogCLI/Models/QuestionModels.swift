import Foundation

struct QuestionOption: Codable {
    let label: String
    let description: String?
}

enum QuestionType: String, Codable {
    case choice
    case text
}

struct QuestionItem: Codable {
    let id: String
    let question: String
    let type: QuestionType
    let options: [QuestionOption]
    let multiSelect: Bool
    let placeholder: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        question = try container.decode(String.self, forKey: .question)
        type = try container.decodeIfPresent(QuestionType.self, forKey: .type) ?? .choice
        options = try container.decodeIfPresent([QuestionOption].self, forKey: .options) ?? []
        multiSelect = try container.decodeIfPresent(Bool.self, forKey: .multiSelect) ?? false
        placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
    }
}

// Answer can be either choice indices or text
enum QuestionAnswer {
    case choices(Set<Int>)
    case text(String)

    var isEmpty: Bool {
        switch self {
        case .choices(let set): return set.isEmpty
        case .text(let str): return str.isEmpty
        }
    }
}

struct QuestionsRequest: Codable {
    let questions: [QuestionItem]
    let mode: String  // "wizard" | "accordion"
    let position: DialogPosition
}

struct QuestionsResponse: Codable {
    let dialogType: String
    let answers: [String: StringOrStrings]
    let cancelled: Bool
    let dismissed: Bool
    let completedCount: Int
    let snoozed: Bool?
    let snoozeMinutes: Int?
    let remainingSeconds: Int?
    let feedbackText: String?
    let instruction: String?
}
