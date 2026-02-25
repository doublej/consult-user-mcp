import AppKit
import SwiftUI

extension DialogManager {
    func notify(_ request: NotifyRequest) -> NotifyResponse {
        NSApp.setActivationPolicy(.accessory)

        let pane = SwiftUINotifyPane(
            title: request.title,
            bodyText: request.body
        )

        let position = DialogPosition(rawValue: getSettings().position) ?? .right

        let (window, _, _) = createAutoSizedWindow(
            content: pane,
            minWidth: 360,
            minHeight: 120,
            maxHeightRatio: 0.45,
            position: position
        )
        positionWindow(window, position: position)
        window.level = .floating
        window.orderFrontRegardless()

        if request.sound {
            playShowSound(for: .notification)
        }

        let autoCloseDelay: TimeInterval = 4.0
        DispatchQueue.main.asyncAfter(deadline: .now() + autoCloseDelay) {
            NSApp.stopModal()
        }

        NSApp.runModal(for: window)
        window.close()

        let entry = HistoryEntry(
            id: UUID(),
            timestamp: Date(),
            clientName: getClientName(),
            dialogType: "notify",
            questionSummary: request.title,
            answer: request.body,
            cancelled: false,
            snoozed: false
        )
        HistoryManager.append(entry: entry)

        return NotifyResponse(dialogType: "notify", success: true)
    }
}
