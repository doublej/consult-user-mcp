import Foundation

struct QuestionOption: Codable {
    let label: String
    let description: String?
}

struct QuestionItem: Codable {
    let id: String
    let question: String
    let options: [QuestionOption]
    let multiSelect: Bool
}

struct QuestionsRequest: Codable {
    let questions: [QuestionItem]
    let mode: String  // "wizard" | "accordion" | "questionnaire"
    let position: String
}

struct QuestionsResponse: Codable {
    let dialogType: String
    let answers: [String: StringOrStrings]
    let cancelled: Bool
    let dismissed: Bool
    let completedCount: Int
}
