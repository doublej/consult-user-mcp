import Foundation

extension QuestionAnswer {
    static func isAnswered(
        answer: QuestionAnswer?,
        otherSelected: Bool,
        otherText: String
    ) -> Bool {
        if let answer = answer, !answer.isEmpty { return true }
        return otherSelected && !otherText.isEmpty
    }
}
