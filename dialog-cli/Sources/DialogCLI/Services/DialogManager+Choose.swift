import AppKit
import SwiftUI

extension DialogManager {
    func choose(_ request: ChooseRequest) -> ChoiceResponse {
        let snoozeCheck = UserSettings.isSnoozeActive()
        if snoozeCheck.active, let remaining = snoozeCheck.remainingSeconds {
            return ChoiceResponse(dialogType: "choose", answer: nil, cancelled: false, dismissed: false, description: nil, descriptions: nil, comment: nil, snoozed: true, snoozeMinutes: nil, remainingSeconds: remaining, feedbackText: nil, instruction: "Snooze active. Wait \(remaining) seconds before re-asking.")
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
                result = ChoiceResponse(dialogType: "choose", answer: nil, cancelled: false, dismissed: false, description: nil, descriptions: nil, comment: nil, snoozed: true, snoozeMinutes: minutes, remainingSeconds: minutes * 60, feedbackText: nil, instruction: "Set a timer for \(minutes) minute\(minutes == 1 ? "" : "s") and re-ask this question when it fires.")
                NSApp.stopModal()
            },
            onFeedback: { feedback in
                result = ChoiceResponse(dialogType: "choose", answer: nil, cancelled: false, dismissed: false, description: nil, descriptions: nil, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: feedback, instruction: nil)
                NSApp.stopModal()
            }
        )

        let (window, _, _) = createAutoSizedWindow(content: swiftUIDialog)

        positionWindow(window, position: effectivePosition(request.position))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .dialogContentSizeChanged, object: nil)
        }

        NSApp.runModal(for: window)
        window.close()

        return result ?? ChoiceResponse(dialogType: "choose", answer: nil, cancelled: true, dismissed: true, description: nil, descriptions: nil, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
    }
}
