import AppKit
import SwiftUI

// MARK: - SwiftUI Confirm Dialog

struct SwiftUIConfirmDialog: View {
    let title: String
    let bodyText: String
    let confirmLabel: String
    let cancelLabel: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let onSnooze: (Int) -> Void
    let onFeedback: (String) -> Void
    let onAskDifferently: (String) -> Void

    var body: some View {
        DialogContainer(
            keyHandler: { keyCode, _ in
                switch keyCode {
                case KeyCode.escape:
                    return false
                case KeyCode.returnKey:
                    onConfirm()
                    return true
                default:
                    return false
                }
            },
            currentDialogType: "confirm",
            onAskDifferently: onAskDifferently
        ) { expandedTool in
            VStack(spacing: 0) {
                DialogHeader(icon: "questionmark", title: title, body: bodyText)
                    .padding(.bottom, 12)

                DialogToolbar(
                    expandedTool: expandedTool,
                    currentDialogType: "confirm",
                    onSnooze: onSnooze,
                    onFeedback: onFeedback,
                    onAskDifferently: onAskDifferently
                )

                DialogFooter(
                    hints: [
                        KeyboardHint(key: "⏎", label: "confirm"),
                        KeyboardHint(key: "Esc", label: "cancel"),
                    ] + KeyboardHint.toolbarHints,
                    buttons: [
                        .init(cancelLabel, action: onCancel),
                        .init(confirmLabel, isPrimary: true, showReturnHint: true, action: onConfirm)
                    ]
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("\(title). \(bodyText)"))
        }
    }
}
