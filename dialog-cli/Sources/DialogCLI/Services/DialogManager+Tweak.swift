import AppKit
import SwiftUI

extension DialogManager {
    func tweak(_ request: TweakRequest) -> TweakResponse {
        let snoozeCheck = UserSettings.isSnoozeActive()
        if snoozeCheck.active, let remaining = snoozeCheck.remainingSeconds {
            SnoozedRequestsManager.append(clientName: getClientName(), dialogType: "tweak", summary: request.body)
            return TweakResponse(dialogType: "tweak", answers: [:], action: nil, cancelled: false, dismissed: false, snoozed: true, snoozeMinutes: nil, remainingSeconds: remaining, feedbackText: nil, askDifferently: nil, instruction: snoozeActiveInstruction(remaining: remaining), replayAnimations: nil)
        }

        NSApp.setActivationPolicy(.accessory)

        var result: TweakResponse?

        let fileRewriter = FileRewriter(parameters: request.parameters, projectPath: getProjectPath())

        let onSaveToFile: ([String: Double], Bool) -> Void = { answers, replay in
            result = TweakResponse(dialogType: "tweak", answers: answers, action: "file", cancelled: false, dismissed: false, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, askDifferently: nil, instruction: nil, replayAnimations: replay)
            NSApp.stopModal()
        }

        let onTellAgent: ([String: Double], Bool) -> Void = { answers, replay in
            _ = fileRewriter.resetAll()
            result = TweakResponse(dialogType: "tweak", answers: answers, action: "agent", cancelled: false, dismissed: false, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, askDifferently: nil, instruction: nil, replayAnimations: replay)
            NSApp.stopModal()
        }

        let onCancel: () -> Void = {
            result = TweakResponse(dialogType: "tweak", answers: [:], action: nil, cancelled: true, dismissed: false, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, askDifferently: nil, instruction: nil, replayAnimations: nil)
            NSApp.stopModal()
        }

        let onSnooze: (Int) -> Void = { minutes in
            UserSettings.setSnooze(minutes: minutes)
            result = TweakResponse(dialogType: "tweak", answers: [:], action: nil, cancelled: false, dismissed: false, snoozed: true, snoozeMinutes: minutes, remainingSeconds: minutes * 60, feedbackText: nil, askDifferently: nil, instruction: self.snoozeInstruction(minutes: minutes), replayAnimations: nil)
            NSApp.stopModal()
        }

        let onFeedback: (String, [String: Double]) -> Void = { feedback, currentAnswers in
            result = TweakResponse(dialogType: "tweak", answers: currentAnswers, action: nil, cancelled: false, dismissed: false, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: feedback, askDifferently: nil, instruction: nil, replayAnimations: nil)
            NSApp.stopModal()
        }

        let onAskDifferently: (String) -> Void = { type in
            result = TweakResponse(dialogType: "tweak", answers: [:], action: nil, cancelled: false, dismissed: false, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, askDifferently: type, instruction: nil, replayAnimations: nil)
            NSApp.stopModal()
        }

        let dialogContent = SwiftUITweakDialog(
            bodyText: request.body,
            parameters: request.parameters,
            fileRewriter: fileRewriter,
            onSaveToFile: onSaveToFile,
            onTellAgent: onTellAgent,
            onCancel: onCancel,
            onSnooze: onSnooze,
            onFeedback: onFeedback,
            onAskDifferently: onAskDifferently
        )

        let position = effectivePosition(request.position)
        let (window, _, _) = createAutoSizedWindow(content: dialogContent, minWidth: 460, position: position)

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

        let response = result ?? TweakResponse(dialogType: "tweak", answers: [:], action: nil, cancelled: true, dismissed: true, snoozed: nil, snoozeMinutes: nil, remainingSeconds: nil, feedbackText: nil, askDifferently: nil, instruction: nil, replayAnimations: nil)

        // Record to history (skip if snoozed)
        if response.snoozed != true {
            let answerSummary = response.answers.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            let entry = HistoryEntry(
                id: UUID(),
                timestamp: Date(),
                clientName: getClientName(),
                dialogType: "tweak",
                questionSummary: request.body,
                answer: answerSummary.isEmpty ? nil : answerSummary,
                cancelled: response.cancelled,
                snoozed: false
            )
            HistoryManager.append(entry: entry)
        }

        return response
    }
}
