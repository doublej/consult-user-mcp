import SwiftUI

struct AltTextInputView: View {
    let spec: TextInputSpec

    @State private var inputText: String

    init(spec: TextInputSpec) {
        self.spec = spec
        _inputText = State(initialValue: spec.defaultValue)
    }

    private var dialogType: String { spec.isHidden ? "text-hidden" : "text" }

    var body: some View {
        DialogContainer(
            bindings: DialogKeyBindings(
                canSubmit: { true },
                onSubmit: { spec.onSubmit(inputText, AltFeedback.globalDraft()) },
                onCancel: { spec.onCancel(AltFeedback.globalDraft()) }
            ),
            currentDialogType: dialogType,
            dialogPosition: spec.position,
            globalFeedbackSubject: FeedbackSubject(kind: .dialog, text: spec.body),
            onAskDifferently: spec.onAskDifferently
        ) { controller in
            AltPanel {
                AltHeader(
                    kicker: spec.isHidden ? "secret" : "input",
                    title: spec.title,
                    body: spec.body
                )
                .padding(.bottom, AltMetrics.sectionSpacing)

                FocusableTextField(
                    placeholder: spec.isHidden ? "••••••••" : "Type your answer…",
                    isSecure: spec.isHidden,
                    text: $inputText,
                    onSubmit: { spec.onSubmit(inputText, AltFeedback.globalDraft()) }
                )
                .frame(height: 44)
                .padding(.horizontal, AltMetrics.contentPadding)
                .padding(.bottom, AltMetrics.sectionSpacing)

                DialogToolbar(
                    expandedTool: controller.expandedTool,
                    currentDialogType: dialogType,
                    hasFeedback: controller.hasFeedback(.global),
                    onSnooze: spec.onSnooze,
                    onOpenFeedback: { controller.openFeedback(.global) },
                    onAskDifferently: spec.onAskDifferently
                )

                AltActionBar(
                    hints: [
                        KeyboardHint(key: "⏎", label: "submit"),
                        KeyboardHint(key: "Esc", label: "cancel"),
                    ] + KeyboardHint.toolbarHints,
                    actions: [
                        .init("Cancel", action: { spec.onCancel(AltFeedback.globalDraft()) }),
                        .init("Submit", isPrimary: true, showReturnHint: true, action: {
                            spec.onSubmit(inputText, AltFeedback.globalDraft())
                        }),
                    ]
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("\(spec.title). \(spec.body)"))
        }
    }
}
