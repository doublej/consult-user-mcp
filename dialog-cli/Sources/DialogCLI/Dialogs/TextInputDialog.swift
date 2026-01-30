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

    @State private var inputText: String
    @State private var expandedTool: DialogToolbar.ToolbarTool?

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    init(
        title: String,
        bodyText: String,
        isHidden: Bool,
        defaultValue: String,
        onSubmit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void,
        onSnooze: @escaping (Int) -> Void,
        onFeedback: @escaping (String) -> Void
    ) {
        self.title = title
        self.bodyText = bodyText
        self.isHidden = isHidden
        self.defaultValue = defaultValue
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self.onSnooze = onSnooze
        self.onFeedback = onFeedback
        self._inputText = State(initialValue: defaultValue)
    }

    var body: some View {
        DialogContainer(keyHandler: { keyCode, _ in
            if CooldownManager.shared.shouldBlockKey(keyCode) {
                return true
            }

            switch keyCode {
            case KeyCode.escape:
                if expandedTool != nil {
                    toggleTool(expandedTool!)
                    return true
                }
                onCancel()
                return true
            case KeyCode.returnKey:
                if expandedTool == .feedback { return false }
                onSubmit(inputText)
                return true
            case KeyCode.s:
                if expandedTool == .feedback { return false }
                toggleTool(.snooze)
                return true
            case KeyCode.f:
                if expandedTool == .feedback { return false }
                toggleTool(.feedback)
                return true
            default:
                return false
            }
        }) {
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
                    expandedTool: $expandedTool,
                    onSnooze: onSnooze,
                    onFeedback: onFeedback
                )

                DialogFooter(
                    hints: [
                        KeyboardHint(key: "⏎", label: "submit"),
                        KeyboardHint(key: "Esc", label: "cancel"),
                        KeyboardHint(key: "S", label: "snooze"),
                        KeyboardHint(key: "F", label: "feedback")
                    ],
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

    private func toggleTool(_ tool: DialogToolbar.ToolbarTool) {
        if reduceMotion {
            expandedTool = expandedTool == tool ? nil : tool
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                expandedTool = expandedTool == tool ? nil : tool
            }
        }
    }
}
