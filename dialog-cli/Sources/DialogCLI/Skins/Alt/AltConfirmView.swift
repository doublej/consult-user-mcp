import SwiftUI

struct AltConfirmView: View {
    let spec: ConfirmSpec

    var body: some View {
        DialogContainer(
            bindings: DialogKeyBindings(
                canSubmit: { true },
                onSubmit: { spec.onConfirm(AltFeedback.globalDraft()) },
                onCancel: { spec.onCancel(AltFeedback.globalDraft()) }
            ),
            currentDialogType: "confirm",
            dialogPosition: spec.position,
            globalFeedbackSubject: FeedbackSubject(kind: .dialog, text: spec.body),
            onAskDifferently: spec.onAskDifferently
        ) { controller in
            AltPanel {
                AltHeader(kicker: "confirm", title: spec.title, body: spec.body)
                    .padding(.bottom, AltMetrics.sectionSpacing)

                DialogToolbar(
                    expandedTool: controller.expandedTool,
                    currentDialogType: "confirm",
                    hasFeedback: controller.hasFeedback(.global),
                    onSnooze: spec.onSnooze,
                    onOpenFeedback: { controller.openFeedback(.global) },
                    onAskDifferently: spec.onAskDifferently
                )

                AltActionBar(
                    hints: [
                        KeyboardHint(key: "⏎", label: "confirm"),
                        KeyboardHint(key: "Esc", label: "cancel"),
                    ] + KeyboardHint.toolbarHints,
                    actions: [
                        .init(spec.cancelLabel, action: { spec.onCancel(AltFeedback.globalDraft()) }),
                        .init(spec.confirmLabel, isPrimary: true, showReturnHint: true, action: {
                            spec.onConfirm(AltFeedback.globalDraft())
                        }),
                    ]
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("\(spec.title). \(spec.body)"))
        }
    }
}

// MARK: - Feedback Draft Access

/// The consult-level feedback draft lives in `DialogContainer` and is exposed
/// through `DialogManager.globalFeedbackBinding`. Every Alt dialog reads it
/// the same way on submit/cancel.
enum AltFeedback {
    static func globalDraft() -> String? {
        let raw = DialogManager.shared.globalFeedbackBinding?.wrappedValue ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
