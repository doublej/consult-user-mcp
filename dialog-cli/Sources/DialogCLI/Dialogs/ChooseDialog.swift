import AppKit
import SwiftUI

// MARK: - SwiftUI Choose Dialog

struct SwiftUIChooseDialog: View {
    let title: String
    let bodyText: String
    let choices: [String]
    let descriptions: [String]?
    let allowMultiple: Bool
    let defaultSelection: String?
    let onComplete: (Set<Int>) -> Void
    let onCancel: () -> Void
    let onSnooze: (Int) -> Void
    let onFeedback: (String, Set<Int>) -> Void
    let onAskDifferently: (String) -> Void

    @State private var selectedIndices: Set<Int> = []
    @State private var focusedIndex: Int = 0

    init(title: String, body: String, choices: [String], descriptions: [String]?, allowMultiple: Bool, defaultSelection: String?, onComplete: @escaping (Set<Int>) -> Void, onCancel: @escaping () -> Void, onSnooze: @escaping (Int) -> Void, onFeedback: @escaping (String, Set<Int>) -> Void, onAskDifferently: @escaping (String) -> Void) {
        self.title = title
        self.bodyText = body
        self.choices = choices
        self.descriptions = descriptions
        self.allowMultiple = allowMultiple
        self.defaultSelection = defaultSelection
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onSnooze = onSnooze
        self.onFeedback = onFeedback
        self.onAskDifferently = onAskDifferently

        if let defaultSel = defaultSelection, let idx = choices.firstIndex(of: defaultSel) {
            _selectedIndices = State(initialValue: [idx])
            _focusedIndex = State(initialValue: idx)
        }
    }

    var body: some View {
        DialogContainer(
            keyHandler: handleKeyPress,
            currentDialogType: allowMultiple ? "pick-multi" : "pick",
            onAskDifferently: onAskDifferently
        ) { expandedTool in
            VStack(spacing: 0) {
                headerView
                choicesScrollView
                    .clipped()

                DialogToolbar(
                    expandedTool: expandedTool,
                    currentDialogType: allowMultiple ? "pick-multi" : "pick",
                    onSnooze: onSnooze,
                    onFeedback: { feedback in onFeedback(feedback, selectedIndices) },
                    onAskDifferently: onAskDifferently
                )

                footerView
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(bodyText))
            .accessibilityHint(allowMultiple ? "Select one or more options. Use arrow keys to navigate, Space to select." : "Select one option. Use arrow keys to navigate, Space to select.")
        }
    }

    private var headerView: some View {
        DialogHeader(
            icon: allowMultiple ? "checklist" : "list.bullet",
            title: title,
            body: bodyText
        )
        .padding(.bottom, 4)
    }

    private var choicesScrollView: some View {
        ScrollViewReader { proxy in
            AutoSizingScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                        FocusableChoiceCard(
                            title: choice,
                            subtitle: descriptions?[safe: index],
                            isSelected: selectedIndices.contains(index),
                            isMultiSelect: allowMultiple,
                            onTap: { toggleSelection(at: index) }
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 48)
                        .id(index)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
            .onChange(of: focusedIndex) { newIndex in
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    private var footerView: some View {
        DialogFooter(
            hints: [
                KeyboardHint(key: "↑↓", label: "navigate"),
                KeyboardHint(key: "Space", label: "select"),
                KeyboardHint(key: "⏎", label: "done"),
            ] + KeyboardHint.toolbarHints,
            buttons: [
                .init("Cancel", action: onCancel),
                .init("Done", isPrimary: true, isDisabled: selectedIndices.isEmpty, showReturnHint: true, action: { onComplete(selectedIndices) })
            ]
        )
    }

    private func handleKeyPress(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> Bool {
        switch keyCode {
        case KeyCode.escape:
            return false
        case KeyCode.returnKey:
            if !selectedIndices.isEmpty { onComplete(selectedIndices) }
            return true
        default:
            return false
        }
    }

    private func toggleSelection(at index: Int) {
        selectedIndices.toggle(index, multiSelect: allowMultiple)
    }
}
