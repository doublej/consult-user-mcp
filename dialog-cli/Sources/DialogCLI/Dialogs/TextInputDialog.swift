import SwiftUI

// MARK: - SwiftUI Text Input Dialog

struct SwiftUITextInputDialog: View {
    let title: String
    let bodyText: String
    let isHidden: Bool
    let defaultValue: String
    let onSubmit: (String) -> Void
    let onCancel: () -> Void
    let onSnooze: (Int) -> Void
    let onFeedback: (String) -> Void
    let onAskDifferently: (String) -> Void

    @State private var inputText: String

    init(
        title: String,
        bodyText: String,
        isHidden: Bool,
        defaultValue: String,
        onSubmit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void,
        onSnooze: @escaping (Int) -> Void,
        onFeedback: @escaping (String) -> Void,
        onAskDifferently: @escaping (String) -> Void
    ) {
        self.title = title
        self.bodyText = bodyText
        self.isHidden = isHidden
        self.defaultValue = defaultValue
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self.onSnooze = onSnooze
        self.onFeedback = onFeedback
        self.onAskDifferently = onAskDifferently
        self._inputText = State(initialValue: defaultValue)
    }

    var body: some View {
        DialogContainer(
            keyHandler: { keyCode, _ in
                switch keyCode {
                case KeyCode.escape:
                    onCancel()
                    return true
                case KeyCode.returnKey:
                    onSubmit(inputText)
                    return true
                default:
                    return false
                }
            },
            currentDialogType: isHidden ? "text-hidden" : "text",
            onAskDifferently: onAskDifferently
        ) { expandedTool in
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
                    onSubmit: { onSubmit(inputText) }
                )
                .frame(height: 48)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                DialogToolbar(
                    expandedTool: expandedTool,
                    currentDialogType: isHidden ? "text-hidden" : "text",
                    onSnooze: onSnooze,
                    onFeedback: onFeedback,
                    onAskDifferently: onAskDifferently
                )

                DialogFooter(
                    hints: [
                        KeyboardHint(key: "⏎", label: "submit"),
                        KeyboardHint(key: "Esc", label: "cancel"),
                    ] + KeyboardHint.toolbarHints,
                    buttons: [
                        .init("Cancel", action: onCancel),
                        .init("Submit", isPrimary: true, showReturnHint: true, action: { onSubmit(inputText) })
                    ]
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("\(title). \(bodyText)"))
        }
    }
}
