import AppKit
import SwiftUI

extension DialogManager {
    func textInput(_ request: TextInputRequest) -> TextInputResponse {
        let snoozeCheck = UserSettings.isSnoozeActive()
        if snoozeCheck.active, let remaining = snoozeCheck.remainingSeconds {
            SnoozedRequestsManager.append(clientName: getClientName(), dialogType: "textInput", summary: request.body)
            return TextInputResponse(dialogType: "textInput", answer: nil, cancelled: false, dismissed: false, comment: nil, snoozed: true, snoozeMinutes: nil, remainingSeconds: remaining, feedbackText: nil, askDifferently: nil, instruction: snoozeActiveInstruction(remaining: remaining))
        }

        NSApp.setActivationPolicy(.accessory)

        var result: TextInputResponse?

        let swiftUIDialog = SwiftUITextInputDialog(
            title: request.title,
            bodyText: request.body,
            isHidden: request.hidden,
            defaultValue: request.defaultValue,
            onSubmit: { text in
                result = TextInputResponse(dialogType: "textInput", answer: text, cancelled: false, dismissed: false, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, askDifferently: nil, instruction: nil)
                NSApp.stopModal()
            },
            onCancel: {
                result = TextInputResponse(dialogType: "textInput", answer: nil, cancelled: true, dismissed: false, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, askDifferently: nil, instruction: nil)
                NSApp.stopModal()
            },
            onSnooze: { minutes in
                UserSettings.setSnooze(minutes: minutes)
                result = TextInputResponse(dialogType: "textInput", answer: nil, cancelled: false, dismissed: false, comment: nil, snoozed: true, snoozeMinutes: minutes, remainingSeconds: minutes * 60, feedbackText: nil, askDifferently: nil, instruction: self.snoozeInstruction(minutes: minutes))
                NSApp.stopModal()
            },
            onFeedback: { feedback in
                result = TextInputResponse(dialogType: "textInput", answer: nil, cancelled: false, dismissed: false, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: feedback, askDifferently: nil, instruction: nil)
                NSApp.stopModal()
            },
            onAskDifferently: { type in
                result = TextInputResponse(dialogType: "textInput", answer: nil, cancelled: false, dismissed: false, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, askDifferently: type, instruction: nil)
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

        let response = result ?? TextInputResponse(dialogType: "textInput", answer: nil, cancelled: true, dismissed: true, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, askDifferently: nil, instruction: nil)

        // Record to history (skip if snoozed)
        if response.snoozed != true {
            let entry = HistoryEntry(
                id: UUID(),
                timestamp: Date(),
                clientName: getClientName(),
                dialogType: "textInput",
                questionSummary: request.body,
                answer: response.answer,
                cancelled: response.cancelled,
                snoozed: false
            )
            HistoryManager.append(entry: entry)
        }

        return response
    }
}
