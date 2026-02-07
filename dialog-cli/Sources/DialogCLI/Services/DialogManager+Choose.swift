import AppKit
import SwiftUI

extension DialogManager {
    func choose(_ request: ChooseRequest) -> ChoiceResponse {
        let snoozeCheck = UserSettings.isSnoozeActive()
        if snoozeCheck.active, let remaining = snoozeCheck.remainingSeconds {
            SnoozedRequestsManager.append(clientName: getClientName(), dialogType: "choose", summary: request.body)
            return ChoiceResponse(dialogType: "choose", answer: nil, cancelled: false, dismissed: false, description: nil, descriptions: nil, comment: nil, snoozed: true, snoozeMinutes: nil, remainingSeconds: remaining, feedbackText: nil, instruction: snoozeActiveInstruction(remaining: remaining))
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
            body: request.body,
            choices: request.choices,
            descriptions: normalizedDescriptions,
            allowMultiple: request.allowMultiple,
            defaultSelection: request.defaultSelection,
            onComplete: { selectedIndices in
                if selectedIndices.isEmpty {
                    result = ChoiceResponse(dialogType: "choose", answer: nil, cancelled: true, dismissed: false, description: nil, descriptions: nil, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
                } else if request.allowMultiple {
                    let selected = selectedIndices.sorted().map { request.choices[$0] }
                    let descs = selectedIndices.sorted().map { request.descriptions?[safe: $0] }
                    result = ChoiceResponse(dialogType: "choose", answer: .multiple(selected), cancelled: false, dismissed: false, description: nil, descriptions: descs, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
                } else if let idx = selectedIndices.first {
                    result = ChoiceResponse(dialogType: "choose", answer: .single(request.choices[idx]), cancelled: false, dismissed: false, description: request.descriptions?[safe: idx], descriptions: nil, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
                }
                NSApp.stopModal()
            },
            onCancel: {
                result = ChoiceResponse(dialogType: "choose", answer: nil, cancelled: true, dismissed: false, description: nil, descriptions: nil, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
                NSApp.stopModal()
            },
            onSnooze: { minutes in
                UserSettings.setSnooze(minutes: minutes)
                result = ChoiceResponse(dialogType: "choose", answer: nil, cancelled: false, dismissed: false, description: nil, descriptions: nil, comment: nil, snoozed: true, snoozeMinutes: minutes, remainingSeconds: minutes * 60, feedbackText: nil, instruction: self.snoozeInstruction(minutes: minutes))
                NSApp.stopModal()
            },
            onFeedback: { feedback, selectedIndices in
                // Build answer from current selections
                let answer: StringOrStrings?
                let desc: String?
                let descs: [String?]?
                if selectedIndices.isEmpty {
                    answer = nil
                    desc = nil
                    descs = nil
                } else if request.allowMultiple {
                    let selected = selectedIndices.sorted().map { request.choices[$0] }
                    let selectedDescs = selectedIndices.sorted().map { request.descriptions?[safe: $0] }
                    answer = .multiple(selected)
                    desc = nil
                    descs = selectedDescs
                } else if let idx = selectedIndices.first {
                    answer = .single(request.choices[idx])
                    desc = request.descriptions?[safe: idx]
                    descs = nil
                } else {
                    answer = nil
                    desc = nil
                    descs = nil
                }
                result = ChoiceResponse(dialogType: "choose", answer: answer, cancelled: false, dismissed: false, description: desc, descriptions: descs, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: feedback, instruction: nil)
                NSApp.stopModal()
            }
        )

        let (window, _, _) = createAutoSizedWindow(content: swiftUIDialog)

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

        let response = result ?? ChoiceResponse(dialogType: "choose", answer: nil, cancelled: true, dismissed: true, description: nil, descriptions: nil, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)

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
