import SwiftUI

// MARK: - Keyboard Hints View

struct KeyboardHint: Identifiable {
    let id = UUID()
    let key: String
    let label: String
}

extension KeyboardHint {
    static let snooze = KeyboardHint(key: "S", label: "snooze")
    static let feedback = KeyboardHint(key: "F", label: "feedback")
    static let toolbarHints: [KeyboardHint] = [.snooze, .feedback]
}

struct KeyboardHintsView: View {
    let hints: [KeyboardHint]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(hints) { hint in
                HStack(spacing: 3) {
                    Text(hint.key)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Theme.Colors.cardBackground)
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(Theme.Colors.border.opacity(0.6), lineWidth: 1)
                        )
                    Text(hint.label)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Theme.Colors.textMuted)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
