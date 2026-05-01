import SwiftUI

@MainActor
final class QuestionFormState: ObservableObject {
    @Published var answers: [String: QuestionAnswer] = [:]
    @Published var textInputs: [String: String] = [:]
    @Published var otherSelections: [String: Bool] = [:]
    @Published var otherTexts: [String: String] = [:]

    func answer(for question: QuestionItem) -> QuestionAnswer {
        answers[question.id] ?? .empty(for: question)
    }

    func bindingForAnswer(_ question: QuestionItem) -> Binding<QuestionAnswer> {
        Binding(
            get: { self.answer(for: question) },
            set: { self.answers[question.id] = $0 }
        )
    }

    func bindingForText(_ id: String) -> Binding<String> {
        Binding(
            get: { self.textInputs[id] ?? "" },
            set: { self.textInputs[id] = $0 }
        )
    }

    func bindingForOtherSelected(_ id: String) -> Binding<Bool> {
        Binding(
            get: { self.otherSelections[id] ?? false },
            set: { self.otherSelections[id] = $0 }
        )
    }

    func bindingForOtherText(_ id: String) -> Binding<String> {
        Binding(
            get: { self.otherTexts[id] ?? "" },
            set: { self.otherTexts[id] = $0 }
        )
    }

    func isAnswered(_ questionId: String) -> Bool {
        QuestionAnswer.isAnswered(
            answer: answers[questionId],
            otherSelected: otherSelections[questionId] ?? false,
            otherText: otherTexts[questionId] ?? ""
        )
    }
}
