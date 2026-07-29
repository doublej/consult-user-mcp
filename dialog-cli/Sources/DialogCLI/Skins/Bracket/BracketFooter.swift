import SwiftUI

/// Everything below the answer: the tool strip, the action controls and the
/// hint strip. Identical on every interactive surface, which is most of what
/// makes the seven screens read as one system.
struct BracketFooter<Leading: View>: View {
    @Binding var expandedTool: DialogToolbar.ToolbarTool?
    var hasNote: Bool
    var currentShape: String
    var readiness: CGFloat
    var hints: [(key: String, word: String)]
    var isEditing: Bool
    var isPaneOpen: Bool
    var onSnooze: (Int) -> Void
    var onOpenFeedback: () -> Void
    var onAskDifferently: (String) -> Void

    @ViewBuilder var leadingAction: () -> Leading
    var secondary: (title: String, action: () -> Void)?
    var tertiary: (title: String, action: () -> Void)?
    var primary: (title: String, isEnabled: Bool, action: () -> Void)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Rectangle()
                .fill(BracketStyle.line.opacity(0.7))
                .frame(height: 1)

            BracketToolStrip(
                expandedTool: $expandedTool,
                hasNote: hasNote,
                currentShape: currentShape,
                readiness: readiness,
                onSnooze: onSnooze,
                onOpenFeedback: onOpenFeedback,
                onAskDifferently: onAskDifferently
            )

            BracketActionBar(
                readiness: readiness,
                leading: leadingAction,
                secondary: secondary,
                tertiary: tertiary,
                primary: primary
            )

            BracketHintStrip(
                leading: hints,
                isEditing: isEditing,
                isPaneOpen: isPaneOpen,
                readiness: readiness
            )
        }
    }
}

extension BracketFooter where Leading == EmptyView {
    init(
        expandedTool: Binding<DialogToolbar.ToolbarTool?>,
        hasNote: Bool,
        currentShape: String,
        readiness: CGFloat,
        hints: [(key: String, word: String)],
        isEditing: Bool,
        isPaneOpen: Bool,
        onSnooze: @escaping (Int) -> Void,
        onOpenFeedback: @escaping () -> Void,
        onAskDifferently: @escaping (String) -> Void,
        secondary: (title: String, action: () -> Void)?,
        primary: (title: String, isEnabled: Bool, action: () -> Void)
    ) {
        self.init(
            expandedTool: expandedTool,
            hasNote: hasNote,
            currentShape: currentShape,
            readiness: readiness,
            hints: hints,
            isEditing: isEditing,
            isPaneOpen: isPaneOpen,
            onSnooze: onSnooze,
            onOpenFeedback: onOpenFeedback,
            onAskDifferently: onAskDifferently,
            leadingAction: { EmptyView() },
            secondary: secondary,
            tertiary: nil,
            primary: primary
        )
    }
}

/// §4.8 — the drafted note travels alongside the answer. A whitespace-only
/// draft counts as empty everywhere.
enum BracketNote {
    static func current() -> String? {
        let raw = DialogManager.shared.globalFeedbackBinding?.wrappedValue ?? ""
        return raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : raw
    }
}
