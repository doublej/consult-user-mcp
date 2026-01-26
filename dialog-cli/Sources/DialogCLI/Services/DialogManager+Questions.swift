import AppKit
import SwiftUI

extension DialogManager {
    func questions(_ request: QuestionsRequest) -> QuestionsResponse {
        let snoozeCheck = UserSettings.isSnoozeActive()
        if snoozeCheck.active, let remaining = snoozeCheck.remainingSeconds {
            return QuestionsResponse(dialogType: "questions", answers: [:], cancelled: false, dismissed: false, completedCount: 0, snoozed: true, snoozeMinutes: nil, remainingSeconds: remaining, feedbackText: nil, instruction: snoozeActiveInstruction(remaining: remaining))
        }

        NSApp.setActivationPolicy(.accessory)

        var result: QuestionsResponse?

        func buildResponse(answers: [String: QuestionAnswer], cancelled: Bool, dismissed: Bool) -> QuestionsResponse {
            var responseAnswers: [String: StringOrStrings] = [:]
            var completedCount = 0

            for question in request.questions {
                if let answer = answers[question.id], !answer.isEmpty {
                    completedCount += 1
                    switch answer {
                    case .choices(let indices):
                        let labels = indices.sorted().map { question.options[$0].label }
                        if question.multiSelect {
                            responseAnswers[question.id] = .multiple(labels)
                        } else if let first = labels.first {
                            responseAnswers[question.id] = .single(first)
                        }
                    case .text(let str):
                        responseAnswers[question.id] = .single(str)
                    }
                }
            }

            return QuestionsResponse(dialogType: "questions", answers: responseAnswers, cancelled: cancelled, dismissed: dismissed, completedCount: completedCount, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
        }

        let onComplete: ([String: QuestionAnswer]) -> Void = { answers in
            result = buildResponse(answers: answers, cancelled: false, dismissed: false)
            NSApp.stopModal()
        }

        let onCancel: () -> Void = {
            result = QuestionsResponse(dialogType: "questions", answers: [:], cancelled: true, dismissed: false, completedCount: 0, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
            NSApp.stopModal()
        }

        let onSnooze: (Int) -> Void = { minutes in
            UserSettings.setSnooze(minutes: minutes)
            result = QuestionsResponse(dialogType: "questions", answers: [:], cancelled: false, dismissed: false, completedCount: 0, snoozed: true, snoozeMinutes: minutes, remainingSeconds: minutes * 60, feedbackText: nil, instruction: self.snoozeInstruction(minutes: minutes))
            NSApp.stopModal()
        }

        let onFeedback: (String) -> Void = { feedback in
            result = QuestionsResponse(dialogType: "questions", answers: [:], cancelled: false, dismissed: false, completedCount: 0, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: feedback, instruction: nil)
            NSApp.stopModal()
        }

        let dialogContent: AnyView
        switch request.mode {
        case "wizard":
            dialogContent = AnyView(SwiftUIWizardDialog(
                questions: request.questions,
                onComplete: onComplete,
                onCancel: onCancel,
                onSnooze: onSnooze,
                onFeedback: onFeedback
            ))
        default:
            dialogContent = AnyView(SwiftUIAccordionDialog(
                questions: request.questions,
                onComplete: onComplete,
                onCancel: onCancel,
                onSnooze: onSnooze,
                onFeedback: onFeedback
            ))
        }

        let (window, _, _) = createAutoSizedWindow(content: dialogContent, minWidth: 460)

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        playShowSound()

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .dialogContentSizeChanged, object: nil)
        }

        NSApp.runModal(for: window)
        FocusManager.shared.reset()
        window.close()

        let response = result ?? QuestionsResponse(dialogType: "questions", answers: [:], cancelled: true, dismissed: true, completedCount: 0, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)

        // Record to history (skip if snoozed)
        if response.snoozed != true {
            let questionSummary = request.questions.first?.question ?? "Multiple questions"
            let answerStrings = response.answers.map { key, value -> String in
                switch value {
                case .single(let s): return "\(key): \(s)"
                case .multiple(let arr): return "\(key): \(arr.joined(separator: ", "))"
                }
            }
            let entry = HistoryEntry(
                id: UUID(),
                timestamp: Date(),
                clientName: getClientName(),
                dialogType: "questions",
                questionSummary: questionSummary,
                answer: answerStrings.isEmpty ? nil : answerStrings.joined(separator: "; "),
                cancelled: response.cancelled,
                snoozed: false
            )
            HistoryManager.append(entry: entry)
        }

        return response
    }
}
