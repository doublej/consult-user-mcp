import AppKit
import SwiftUI

// MARK: - SwiftUI Confirm Dialog

struct SwiftUIConfirmDialog: View {
    let title: String
    let bodyText: String
    let confirmLabel: String
    let cancelLabel: String
    let position: DialogPosition
    let onConfirm: (String?) -> Void
    let onCancel: (String?) -> Void
    let onSnooze: (Int) -> Void
    let onAskDifferently: (String) -> Void

    private func globalDraft() -> String? {
        let raw = DialogManager.shared.globalFeedbackBinding?.wrappedValue ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var body: some View {
        DialogContainer(
            bindings: DialogKeyBindings(
                canSubmit: { true },
                onSubmit: { onConfirm(globalDraft()) },
                onCancel: { onCancel(globalDraft()) }
            ),
            currentDialogType: "confirm",
            dialogPosition: position,
            onAskDifferently: onAskDifferently
        ) { controller in
            VStack(spacing: 0) {
                DialogHeader(icon: "questionmark", title: title, body: bodyText)
                    .padding(.bottom, 12)

                DialogToolbar(
                    expandedTool: controller.expandedTool,
                    currentDialogType: "confirm",
                    hasFeedback: controller.hasFeedback(.global),
                    onSnooze: onSnooze,
                    onOpenFeedback: { controller.openFeedback(.global) },
                    onAskDifferently: onAskDifferently
                )

                DialogFooter(
                    hints: [
                        KeyboardHint(key: "⏎", label: "confirm"),
                        KeyboardHint(key: "Esc", label: "cancel"),
                    ] + KeyboardHint.toolbarHints,
                    buttons: [
                        .init(cancelLabel, action: { onCancel(globalDraft()) }),
                        .init(confirmLabel, isPrimary: true, showReturnHint: true, action: { onConfirm(globalDraft()) })
                    ]
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("\(title). \(bodyText)"))
        }
    }
}
