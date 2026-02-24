import AppKit
import SwiftUI

extension DialogManager {
    private func makeQuestionsResponse(
        answers: [String: StringOrStrings] = [:],
        cancelled: Bool = false,
        dismissed: Bool = false,
        completedCount: Int = 0,
        snoozed: Bool? = nil,
        snoozeMinutes: Int? = nil,
        remainingSeconds: Int? = nil,
        feedbackText: String? = nil,
        askDifferently: String? = nil,
        instruction: String? = nil
    ) -> QuestionsResponse {
        QuestionsResponse(
            dialogType: "questions",
            answers: answers,
            cancelled: cancelled,
            dismissed: dismissed,
            completedCount: completedCount,
            snoozed: snoozed,
            snoozeMinutes: snoozeMinutes,
            remainingSeconds: remainingSeconds,
            feedbackText: feedbackText,
            askDifferently: askDifferently,
            instruction: instruction
        )
    }

    func questions(_ request: QuestionsRequest) -> QuestionsResponse {
        let snoozeCheck = UserSettings.isSnoozeActive()
        if snoozeCheck.active, let remaining = snoozeCheck.remainingSeconds {
            let summary = request.questions.first?.question ?? "Multiple questions"
            SnoozedRequestsManager.append(clientName: getClientName(), dialogType: "questions", summary: summary)
            return makeQuestionsResponse(snoozed: true, remainingSeconds: remaining, instruction: snoozeActiveInstruction(remaining: remaining))
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

            return makeQuestionsResponse(answers: responseAnswers, cancelled: cancelled, dismissed: dismissed, completedCount: completedCount)
        }

        let onComplete: ([String: QuestionAnswer]) -> Void = { answers in
            result = buildResponse(answers: answers, cancelled: false, dismissed: false)
            NSApp.stopModal()
        }

        let onCancel: () -> Void = {
            result = self.makeQuestionsResponse(cancelled: true)
            NSApp.stopModal()
        }

        let onSnooze: (Int) -> Void = { minutes in
            UserSettings.setSnooze(minutes: minutes)
            result = self.makeQuestionsResponse(snoozed: true, snoozeMinutes: minutes, remainingSeconds: minutes * 60, instruction: self.snoozeInstruction(minutes: minutes))
            NSApp.stopModal()
        }

        let onFeedback: (String, [String: QuestionAnswer]) -> Void = { feedback, currentAnswers in
            let response = buildResponse(answers: currentAnswers, cancelled: false, dismissed: false)
            result = self.makeQuestionsResponse(answers: response.answers, completedCount: response.completedCount, feedbackText: feedback)
            NSApp.stopModal()
        }

        let onAskDifferently: (String) -> Void = { type in
            result = self.makeQuestionsResponse(askDifferently: type)
            NSApp.stopModal()
        }

        let dialogTitle = request.title ?? buildTitle()
        let dialogBody = request.body

        let dialogContent: AnyView
        switch request.mode {
        case "wizard":
            dialogContent = AnyView(SwiftUIWizardDialog(
                title: dialogTitle,
                bodyText: dialogBody,
                questions: request.questions,
                onComplete: onComplete,
                onCancel: onCancel,
                onSnooze: onSnooze,
                onFeedback: onFeedback,
                onAskDifferently: onAskDifferently
            ))
        default:
            dialogContent = AnyView(SwiftUIAccordionDialog(
                title: dialogTitle,
                bodyText: dialogBody,
                questions: request.questions,
                onComplete: onComplete,
                onCancel: onCancel,
                onSnooze: onSnooze,
                onFeedback: onFeedback,
                onAskDifferently: onAskDifferently
            ))
        }

        // Compute initial height from content to avoid fittingSize + ScrollView issues
        let chromeHeight: CGFloat = 340  // header + progress + toolbar + buttons + padding
        let maxStepHeight = request.questions.map { question -> CGFloat in
            let questionTextHeight: CGFloat = 30
            let hasDescriptions = question.options.contains { $0.description != nil }
            let optionHeight: CGFloat = hasDescriptions ? 68 : 48
            let optionsHeight = CGFloat(question.options.count) * optionHeight
                + CGFloat(max(0, question.options.count - 1)) * 8
            let padding: CGFloat = 20  // top + bottom
            return questionTextHeight + optionsHeight + padding
        }.max() ?? 200
        let estimatedHeight = chromeHeight + maxStepHeight

        let (window, _, _) = createAutoSizedWindow(content: dialogContent, minWidth: 460, minHeight: estimatedHeight)

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

        let response = result ?? makeQuestionsResponse(cancelled: true, dismissed: true)

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
