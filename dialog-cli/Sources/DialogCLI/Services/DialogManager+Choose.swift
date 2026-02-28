import AppKit
import SwiftUI

extension DialogManager {
    private func makeChoiceResponse(
        answer: StringOrStrings? = nil,
        cancelled: Bool = false,
        dismissed: Bool = false,
        description: String? = nil,
        descriptions: [String?]? = nil,
        comment: String? = nil,
        snoozed: Bool? = nil,
        snoozeMinutes: Int? = nil,
        remainingSeconds: Int? = nil,
        feedbackText: String? = nil,
        askDifferently: String? = nil,
        instruction: String? = nil
    ) -> ChoiceResponse {
        ChoiceResponse(
            dialogType: "choose",
            answer: answer,
            cancelled: cancelled,
            dismissed: dismissed,
            description: description,
            descriptions: descriptions,
            comment: comment,
            snoozed: snoozed,
            snoozeMinutes: snoozeMinutes,
            remainingSeconds: remainingSeconds,
            feedbackText: feedbackText,
            askDifferently: askDifferently,
            instruction: instruction
        )
    }

    func choose(_ request: ChooseRequest) -> ChoiceResponse {
        let snoozeCheck = UserSettings.isSnoozeActive()
        if snoozeCheck.active, let remaining = snoozeCheck.remainingSeconds {
            SnoozedRequestsManager.append(clientName: getClientName(), dialogType: "choose", summary: request.body)
            return makeChoiceResponse(cancelled: false, snoozed: true, remainingSeconds: remaining, instruction: snoozeActiveInstruction(remaining: remaining))
        }

        // Validate descriptions length matches choices
        let normalizedDescriptions: [String]? = request.descriptions.map { descs in
            if descs.count == request.choices.count {
                return descs
            }
            // Truncate or pad to match choices length
            return (0..<request.choices.count).map { descs[safe: $0] ?? "" }
        }

        NSApp.setActivationPolicy(.accessory)

        var result: ChoiceResponse?

        let swiftUIDialog = SwiftUIChooseDialog(
            title: request.title ?? buildTitle(),
            body: request.body,
            choices: request.choices,
            descriptions: normalizedDescriptions,
            allowMultiple: request.allowMultiple,
            allowOther: request.allowOther,
            defaultSelection: request.defaultSelection,
            onComplete: { selectedIndices, otherText in
                if selectedIndices.isEmpty && otherText == nil {
                    result = self.makeChoiceResponse(cancelled: true)
                } else if request.allowMultiple {
                    var selected = selectedIndices.sorted().map { request.choices[$0] }
                    var descs: [String?] = selectedIndices.sorted().map { request.descriptions?[safe: $0] }
                    if let other = otherText, !other.isEmpty {
                        selected.append(other)
                        descs.append(nil)
                    }
                    result = self.makeChoiceResponse(answer: .multiple(selected), descriptions: descs)
                } else if let other = otherText, !other.isEmpty {
                    result = self.makeChoiceResponse(answer: .single(other))
                } else if let idx = selectedIndices.first {
                    result = self.makeChoiceResponse(answer: .single(request.choices[idx]), description: request.descriptions?[safe: idx])
                }
                NSApp.stopModal()
            },
            onCancel: {
                result = self.makeChoiceResponse(cancelled: true)
                NSApp.stopModal()
            },
            onSnooze: { minutes in
                UserSettings.setSnooze(minutes: minutes)
                result = self.makeChoiceResponse(snoozed: true, snoozeMinutes: minutes, remainingSeconds: minutes * 60, instruction: self.snoozeInstruction(minutes: minutes))
                NSApp.stopModal()
            },
            onFeedback: { feedback, selectedIndices, otherText in
                let answer: StringOrStrings?
                let desc: String?
                let descs: [String?]?
                if selectedIndices.isEmpty && otherText == nil {
                    answer = nil
                    desc = nil
                    descs = nil
                } else if request.allowMultiple {
                    var selected = selectedIndices.sorted().map { request.choices[$0] }
                    var selectedDescs: [String?] = selectedIndices.sorted().map { request.descriptions?[safe: $0] }
                    if let other = otherText, !other.isEmpty {
                        selected.append(other)
                        selectedDescs.append(nil)
                    }
                    answer = .multiple(selected)
                    desc = nil
                    descs = selectedDescs
                } else if let other = otherText, !other.isEmpty {
                    answer = .single(other)
                    desc = nil
                    descs = nil
                } else if let idx = selectedIndices.first {
                    answer = .single(request.choices[idx])
                    desc = request.descriptions?[safe: idx]
                    descs = nil
                } else {
                    answer = nil
                    desc = nil
                    descs = nil
                }
                result = self.makeChoiceResponse(answer: answer, description: desc, descriptions: descs, feedbackText: feedback)
                NSApp.stopModal()
            },
            onAskDifferently: { type in
                result = self.makeChoiceResponse(askDifferently: type)
                NSApp.stopModal()
            }
        )

        let position = effectivePosition(request.position)
        let (window, _, _) = createAutoSizedWindow(content: swiftUIDialog, position: position)

        positionWindow(window, position: position)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        playShowSound()

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .dialogContentSizeChanged, object: nil)
        }

        NSApp.runModal(for: window)
        FocusManager.shared.reset()
        window.close()

        let response = result ?? makeChoiceResponse(cancelled: true, dismissed: true)

        // Record to history (skip if snoozed)
        if response.snoozed != true {
            let answerString: String?
            switch response.answer {
            case .single(let s): answerString = s
            case .multiple(let arr): answerString = arr.joined(separator: ", ")
            case nil: answerString = nil
            }
            let entry = HistoryEntry(
                id: UUID(),
                timestamp: Date(),
                clientName: getClientName(),
                dialogType: "choose",
                questionSummary: request.body,
                answer: answerString,
                cancelled: response.cancelled,
                snoozed: false
            )
            HistoryManager.append(entry: entry)
        }

        return response
    }
}
