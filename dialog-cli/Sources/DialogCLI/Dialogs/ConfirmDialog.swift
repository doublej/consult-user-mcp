import AppKit
import SwiftUI

// MARK: - SwiftUI Confirm Dialog

struct SwiftUIConfirmDialog: View {
    let title: String
    let message: String
    let confirmLabel: String
    let cancelLabel: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let onSnooze: (Int) -> Void
    let onFeedback: (String) -> Void

    @State private var expandedTool: DialogToolbar.ToolbarTool?

    var body: some View {
        DialogContainer(keyHandler: { keyCode, _ in
            if keyCode == 36 { // Enter/Return - confirm
                onConfirm()
                return true
            }
            return false
        }) {
            VStack(spacing: 0) {
                DialogHeader(icon: "questionmark", title: title, subtitle: message)
                    .padding(.bottom, 12)

                DialogToolbar(
                    expandedTool: $expandedTool,
                    onSnooze: onSnooze,
                    onFeedback: onFeedback
                )

                DialogFooter(
                    hints: [
                        KeyboardHint(key: "⏎", label: "confirm"),
                        KeyboardHint(key: "Esc", label: "cancel")
                    ],
                    buttons: [
                        .init(cancelLabel, action: onCancel),
                        .init(confirmLabel, isPrimary: true, showReturnHint: true, action: onConfirm)
                    ]
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("\(title). \(message)"))
        }
    }
}
