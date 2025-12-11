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

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        DialogContainer(keyHandler: { keyCode, _ in
            switch keyCode {
            case 53: // Esc - close panel first, then dismiss
                if expandedTool != nil {
                    toggleTool(expandedTool!)
                    return true
                }
                return false // Let DialogContainer handle dismiss
            case 36: // Enter/Return - confirm
                // Don't intercept Enter if feedback panel is expanded (let text field handle it)
                if expandedTool == .feedback { return false }
                onConfirm()
                return true
            case 1: // S - toggle snooze (skip if typing in feedback)
                if expandedTool == .feedback { return false }
                toggleTool(.snooze)
                return true
            case 3: // F - toggle feedback (skip if already typing)
                if expandedTool == .feedback { return false }
                toggleTool(.feedback)
                return true
            default:
                return false
            }
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
                        KeyboardHint(key: "Esc", label: "cancel"),
                        KeyboardHint(key: "S", label: "snooze"),
                        KeyboardHint(key: "F", label: "feedback")
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
