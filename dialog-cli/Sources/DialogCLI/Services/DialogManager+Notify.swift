import AppKit
import SwiftUI

extension DialogManager {
    func notify(_ request: NotifyRequest) -> NotifyResponse {
        NSApp.setActivationPolicy(.accessory)

        let spec = NotifySpec(title: request.title, body: request.body)

        let position = DialogPosition(rawValue: getSettings().position) ?? .right

        let (window, _, _) = createSkinnedWindow(.notify, position: position) { skin in
            skin.notifyView(spec)
        }
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
