import SwiftUI
import AppKit

// MARK: - Snooze Duration

enum SnoozeDuration: Int, CaseIterable {
    case oneMinute = 1
    case fiveMinutes = 5
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60

    var label: String {
        switch self {
        case .oneMinute: return "1m"
        case .fiveMinutes: return "5m"
        case .fifteenMinutes: return "15m"
        case .thirtyMinutes: return "30m"
        case .oneHour: return "1h"
        }
    }
}

// MARK: - Dialog Toolbar

struct DialogToolbar: View {
    @Binding var expandedTool: ToolbarTool?
    @State private var feedbackText: String = ""
    let onSnooze: (Int) -> Void
    let onFeedback: (String) -> Void

    enum ToolbarTool {
        case snooze
        case feedback
    }

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // Expanded content
            if let tool = expandedTool {
                expandedContent(for: tool)
                    .transition(reduceMotion ? .identity : .opacity.combined(with: .move(edge: .bottom)))
            }

            // Collapsed toolbar buttons
            HStack(spacing: 12) {
                ToolbarButton(
                    icon: "clock.arrow.circlepath",
                    label: "Snooze",
                    isActive: expandedTool == .snooze,
                    action: { toggleTool(.snooze) }
                )

                ToolbarButton(
                    icon: "bubble.left",
                    label: "Feedback",
                    isActive: expandedTool == .feedback,
                    action: { toggleTool(.feedback) }
                )

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .background(Theme.Colors.cardBackground.opacity(0.5))
        .onChange(of: expandedTool) { newTool in
            if newTool == .feedback {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    FocusManager.shared.focusLast()
                }
            }
        }
    }

    private func toggleTool(_ tool: ToolbarTool) {
        if reduceMotion {
            expandedTool = expandedTool == tool ? nil : tool
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                expandedTool = expandedTool == tool ? nil : tool
            }
        }
    }

    @ViewBuilder
    private func expandedContent(for tool: ToolbarTool) -> some View {
        switch tool {
        case .snooze:
            snoozePanel
        case .feedback:
            feedbackPanel
        }
    }

    private var snoozePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ask me again in:")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)

            HStack(spacing: 8) {
                ForEach(SnoozeDuration.allCases, id: \.rawValue) { duration in
                    SnoozeButton(label: duration.label) {
                        onSnooze(duration.rawValue)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var feedbackPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Send feedback to agent:")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)

            HStack(spacing: 8) {
                FocusableTextField(
                    placeholder: "Type your feedback...",
                    text: $feedbackText,
                    onSubmit: { submitFeedback() }
                )
                .frame(height: 40)

                FocusableButton(
                    title: "Send",
                    isPrimary: true,
                    isDisabled: feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    action: { submitFeedback() }
                )
                .frame(width: 70, height: 40)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func submitFeedback() {
        let trimmed = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onFeedback(trimmed)
    }
}

// MARK: - Toolbar Button

private struct ToolbarButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isActive ? Theme.Colors.accentBlue : Theme.Colors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Theme.Colors.accentBlue.opacity(0.15) : (isHovered ? Theme.Colors.cardHover : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Snooze Button

private struct SnoozeButton: View {
    let label: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isHovered ? .white : Theme.Colors.textPrimary)
                .frame(width: 48, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Theme.Colors.accentBlue : Theme.Colors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Theme.Colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
