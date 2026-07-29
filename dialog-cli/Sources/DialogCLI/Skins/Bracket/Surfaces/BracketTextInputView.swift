import SwiftUI

/// §5.3 — one typed line, optionally masked.
///
/// The masked variant is identifiable before a character is typed on two
/// channels: the kind label reads `SECRET` rather than `INPUT`, and the empty
/// field carries a dotted placeholder instead of a worded one. The default build
/// renders no placeholder at all (§5.3) — §7.2 explicitly lets a style add one,
/// so this one does.
struct BracketTextInputView: View {
    let spec: TextInputSpec

    @StateObject private var clock = CooldownClock()
    @StateObject private var caret = CaretTracker()
    @State private var text = ""

    var body: some View {
        DialogContainer(
            bindings: DialogKeyBindings(
                canSubmit: { true },
                onSubmit: { submit() },
                onCancel: { spec.onCancel(BracketNote.current()) }
            ),
            currentDialogType: "textInput",
            dialogPosition: spec.position,
            contentMinWidth: BracketSkin.width(for: .textInput),
            globalFeedbackSubject: FeedbackSubject(kind: .question, text: spec.body),
            onAskDifferently: spec.onAskDifferently
        ) { controller in
            BracketSurface {
                VStack(alignment: .leading, spacing: 0) {
                    BracketHeader(
                        typeLabel: spec.isHidden ? "SECRET" : "INPUT",
                        title: spec.title
                    )
                    .padding(.bottom, 14)

                    // §10.2 — the default build clips a long prompt here.
                    AutoSizingScrollView {
                        BracketBody(text: spec.body)
                            .padding(.trailing, 2)
                    }

                    BracketTextField(
                        placeholder: spec.isHidden ? "••••••••" : "Type your answer…",
                        isSecure: spec.isHidden,
                        text: $text,
                        selectAllOnFocus: !spec.defaultValue.isEmpty,
                        onFocusChange: { caret.isEditing = $0 }
                    )
                    .padding(.top, 16)

                    Spacer(minLength: 18)

                    BracketFooter(
                        expandedTool: controller.expandedTool,
                        hasNote: controller.hasFeedback(.global),
                        currentShape: spec.isHidden ? "text-hidden" : "text",
                        readiness: clock.progress,
                        hints: [("⏎", "submit"), ("Esc", "cancel")],
                        isEditing: caret.isEditing,
                        isPaneOpen: controller.currentTarget != nil,
                        onSnooze: spec.onSnooze,
                        onOpenFeedback: { controller.openFeedback(.global) },
                        onAskDifferently: spec.onAskDifferently,
                        secondary: ("Cancel", { spec.onCancel(BracketNote.current()) }),
                        // §5.3 — the field is always in a submittable state.
                        primary: ("Submit", true, { submit() })
                    )
                    .padding(.top, 4)
                }
                .padding(.horizontal, BracketStyle.Space.gutter)
                .padding(.top, 16)
                .padding(.bottom, 14)
            }
            .onAppear {
                clock.start()
                text = spec.defaultValue
            }
        }
    }

    private func submit() {
        spec.onSubmit(text, BracketNote.current())
    }
}
