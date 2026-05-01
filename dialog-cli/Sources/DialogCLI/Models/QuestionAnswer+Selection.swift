import Foundation

extension QuestionAnswer {
    static func toggling(
        choice index: Int,
        in answer: QuestionAnswer,
        otherSelected: Bool,
        multiSelect: Bool
    ) -> (answer: QuestionAnswer, otherSelected: Bool) {
        var indices: Set<Int> = {
            if case .choices(let s) = answer { return s }
            return []
        }()
        indices.toggle(index, multiSelect: multiSelect)
        return (.choices(indices), multiSelect ? otherSelected : false)
    }

    static func togglingOther(
        in answer: QuestionAnswer,
        otherSelected: Bool,
        multiSelect: Bool
    ) -> (answer: QuestionAnswer, otherSelected: Bool) {
        if multiSelect {
            return (answer, !otherSelected)
        }
        return (.choices([]), true)
    }
}
