import AppKit
import SwiftUI

extension DialogManager {
    func preview(_ request: PreviewRequest) -> PreviewResponse {
        NSApp.setActivationPolicy(.accessory)

        let spec = PreviewSpec(body: request.body)

        let position = DialogPosition(rawValue: getSettings().position) ?? .right

        let (window, _, _) = createSkinnedWindow(.preview, position: position) { skin in
            skin.previewView(spec)
        }
        positionWindow(window, position: position)
        window.level = .floating
        window.orderFrontRegardless()

        let autoCloseDelay: TimeInterval = 4.0
        DispatchQueue.main.asyncAfter(deadline: .now() + autoCloseDelay) {
            NSApp.stopModal()
        }

        NSApp.runModal(for: window)
        window.close()

        return PreviewResponse(dialogType: "preview", success: true)
    }
}
