import AppKit
import SwiftUI

extension DialogManager {
    func confirm(_ request: ConfirmRequest) -> ConfirmResponse {
        let snoozeCheck = UserSettings.isSnoozeActive()
        if snoozeCheck.active, let remaining = snoozeCheck.remainingSeconds {
            return ConfirmResponse(dialogType: "confirm", confirmed: false, cancelled: false, dismissed: false, answer: nil, comment: nil, snoozed: true, snoozeMinutes: nil, remainingSeconds: remaining, feedbackText: nil, instruction: "Snooze active. Wait \(remaining) seconds before re-asking.")
        }

        NSApp.setActivationPolicy(.accessory)

        var result: ConfirmResponse?

        let swiftUIDialog = SwiftUIConfirmDialog(
            title: request.title,
            bodyText: request.body,
            confirmLabel: request.confirmLabel,
            cancelLabel: request.cancelLabel,
            onConfirm: {
                result = ConfirmResponse(dialogType: "confirm", confirmed: true, cancelled: false, dismissed: false, answer: request.confirmLabel, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
                NSApp.stopModal()
            },
            onCancel: {
                result = ConfirmResponse(dialogType: "confirm", confirmed: false, cancelled: false, dismissed: false, answer: request.cancelLabel, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
                NSApp.stopModal()
            },
            onSnooze: { minutes in
                UserSettings.setSnooze(minutes: minutes)
                result = ConfirmResponse(dialogType: "confirm", confirmed: false, cancelled: false, dismissed: false, answer: nil, comment: nil, snoozed: true, snoozeMinutes: minutes, remainingSeconds: minutes * 60, feedbackText: nil, instruction: "Set a timer for \(minutes) minute\(minutes == 1 ? "" : "s") and re-ask this question when it fires.")
                NSApp.stopModal()
            },
            onFeedback: { feedback in
                result = ConfirmResponse(dialogType: "confirm", confirmed: false, cancelled: false, dismissed: false, answer: nil, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: feedback, instruction: nil)
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

        return result ?? ConfirmResponse(dialogType: "confirm", confirmed: false, cancelled: true, dismissed: true, answer: nil, comment: nil, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, instruction: nil)
    }
}
