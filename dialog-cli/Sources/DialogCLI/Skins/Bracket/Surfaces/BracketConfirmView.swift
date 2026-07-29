import SwiftUI

/// §5.1 — one yes-or-no question.
///
/// Nothing is focused on open (§4.5): the surface registers no content
/// elements, so no caret is lit until Tab moves to an action control. The body
/// sits in its own scroll region, which the default build does not have — §10.2
/// is a visual defect this skin declines to reproduce.
struct BracketConfirmView: View {
    let spec: ConfirmSpec

    @StateObject private var clock = CooldownClock()

    var body: some View {
        DialogContainer(
            bindings: DialogKeyBindings(
                canSubmit: { true },
                onSubmit: { finish(confirmed: true) },
                onCancel: { finish(confirmed: false) }
            ),
            currentDialogType: "confirm",
            dialogPosition: spec.position,
            contentMinWidth: BracketSkin.width(for: .confirm),
            globalFeedbackSubject: FeedbackSubject(kind: .dialog, text: spec.body),
            onAskDifferently: spec.onAskDifferently
        ) { controller in
            BracketSurface {
                VStack(alignment: .leading, spacing: 0) {
                    BracketHeader(typeLabel: "CONFIRM", title: spec.title)
                        .padding(.bottom, 14)

                    AutoSizingScrollView {
                        BracketBody(text: spec.body)
                            .padding(.trailing, 2)
                    }

                    Spacer(minLength: 20)

                    BracketFooter(
                        expandedTool: controller.expandedTool,
                        hasNote: controller.hasFeedback(.global),
                        currentShape: "confirm",
                        readiness: clock.progress,
                        hints: [("⏎", "confirm"), ("Esc", "cancel")],
                        isEditing: false,
                        isPaneOpen: controller.currentTarget != nil,
                        onSnooze: spec.onSnooze,
                        onOpenFeedback: { controller.openFeedback(.global) },
                        onAskDifferently: spec.onAskDifferently,
                        secondary: (spec.cancelLabel, { finish(confirmed: false) }),
                        // §5.1 — the primary is never disabled here.
                        primary: (spec.confirmLabel, true, { finish(confirmed: true) })
                    )
                }
                .padding(.horizontal, BracketStyle.Space.gutter)
                .padding(.top, 16)
                .padding(.bottom, 14)
            }
            .onAppear { clock.start() }
        }
    }

    private func finish(confirmed: Bool) {
        let note = BracketNote.current()
        if confirmed {
            spec.onConfirm(note)
        } else {
            spec.onCancel(note)
        }
    }
}
