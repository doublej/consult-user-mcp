import SwiftUI

// MARK: - SwiftUI Text Input Dialog

struct SwiftUITextInputDialog: View {
    let title: String
    let bodyText: String
    let isHidden: Bool
    let defaultValue: String
    let position: DialogPosition
    let onSubmit: (String, String?) -> Void
    let onCancel: (String?) -> Void
    let onSnooze: (Int) -> Void
    let onAskDifferently: (String) -> Void

    @State private var inputText: String

    init(
        title: String,
        bodyText: String,
        isHidden: Bool,
        defaultValue: String,
        position: DialogPosition,
        onSubmit: @escaping (String, String?) -> Void,
        onCancel: @escaping (String?) -> Void,
        onSnooze: @escaping (Int) -> Void,
        onAskDifferently: @escaping (String) -> Void
    ) {
        self.title = title
        self.bodyText = bodyText
        self.isHidden = isHidden
        self.defaultValue = defaultValue
        self.position = position
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self.onSnooze = onSnooze
        self.onAskDifferently = onAskDifferently
        self._inputText = State(initialValue: defaultValue)
    }

    private func globalDraft() -> String? {
        let raw = DialogManager.shared.globalFeedbackBinding?.wrappedValue ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var body: some View {
        DialogContainer(
            bindings: DialogKeyBindings(
                canSubmit: { true },
                onSubmit: { onSubmit(inputText, globalDraft()) },
                onCancel: { onCancel(globalDraft()) }
            ),
            currentDialogType: isHidden ? "text-hidden" : "text",
            dialogPosition: position,
            globalFeedbackSubject: FeedbackSubject(kind: .dialog, text: bodyText),
            onAskDifferently: onAskDifferently
        ) { controller in
            VStack(spacing: 0) {
                DialogHeader(
                    icon: isHidden ? "lock.fill" : "text.cursor",
                    title: title,
                    body: bodyText
                )
                .padding(.bottom, 12)

                FocusableTextField(
                    isSecure: isHidden,
                    text: $inputText,
                    onSubmit: { onSubmit(inputText, globalDraft()) }
                )
                .frame(height: 48)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                DialogToolbar(
                    expandedTool: controller.expandedTool,
                    currentDialogType: isHidden ? "text-hidden" : "text",
                    hasFeedback: controller.hasFeedback(.global),
                    onSnooze: onSnooze,
                    onOpenFeedback: { controller.openFeedback(.global) },
                    onAskDifferently: onAskDifferently
                )

                DialogFooter(
                    hints: [
                        KeyboardHint(key: "⏎", label: "submit"),
                        KeyboardHint(key: "Esc", label: "cancel"),
                    ] + KeyboardHint.toolbarHints,
                    buttons: [
                        .init("Cancel", action: { onCancel(globalDraft()) }),
                        .init("Submit", isPrimary: true, showReturnHint: true, action: { onSubmit(inputText, globalDraft()) })
                    ]
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("\(title). \(bodyText)"))
        }
    }
}
