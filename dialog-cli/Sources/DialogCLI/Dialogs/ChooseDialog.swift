import AppKit
import SwiftUI

// MARK: - Other Choice Card

struct OtherChoiceCard: View {
    let isSelected: Bool
    let isMultiSelect: Bool
    @Binding var text: String
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Other")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                Spacer()
                SelectionIndicator(isSelected: isSelected, isMultiSelect: isMultiSelect)
            }
            FocusableTextField(
                placeholder: "Type your answer...",
                text: $text
            )
            .frame(minHeight: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Theme.Colors.accentBlue.opacity(0.15) : Theme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Theme.Colors.accentBlue : Theme.Colors.border, lineWidth: isSelected ? 2 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .onChange(of: text) { newValue in
            if !newValue.isEmpty && !isSelected {
                onTap()
            }
        }
    }
}

// MARK: - Selection Indicator

struct SelectionIndicator: View {
    let isSelected: Bool
    let isMultiSelect: Bool

    var body: some View {
        ZStack {
            if isMultiSelect {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? Theme.Colors.accentBlue : Theme.Colors.border, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isSelected ? Theme.Colors.accentBlue : Color.clear)
                    )
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            } else {
                Circle()
                    .stroke(isSelected ? Theme.Colors.accentBlue : Theme.Colors.border, lineWidth: 2)
                    .frame(width: 24, height: 24)
                if isSelected {
                    Circle()
                        .fill(Theme.Colors.accentBlue)
                        .frame(width: 12, height: 12)
                }
            }
        }
    }
}

// MARK: - SwiftUI Choose Dialog

struct SwiftUIChooseDialog: View {
    let title: String
    let bodyText: String
    let choices: [String]
    let descriptions: [String]?
    let allowMultiple: Bool
    let allowOther: Bool
    let defaultSelection: String?
    let onComplete: (Set<Int>, String?) -> Void
    let onCancel: () -> Void
    let onSnooze: (Int) -> Void
    let onFeedback: (String, Set<Int>, String?) -> Void
    let onAskDifferently: (String) -> Void

    @State private var selectedIndices: Set<Int> = []
    @State private var focusedIndex: Int = 0
    @State private var otherSelected: Bool = false
    @State private var otherText: String = ""

    private var hasValidOther: Bool { otherSelected && !otherText.isEmpty }
    private var hasValidSelection: Bool { !selectedIndices.isEmpty || hasValidOther }

    init(title: String, body: String, choices: [String], descriptions: [String]?, allowMultiple: Bool, allowOther: Bool = true, defaultSelection: String?, onComplete: @escaping (Set<Int>, String?) -> Void, onCancel: @escaping () -> Void, onSnooze: @escaping (Int) -> Void, onFeedback: @escaping (String, Set<Int>, String?) -> Void, onAskDifferently: @escaping (String) -> Void) {
        self.title = title
        self.bodyText = body
        self.choices = choices
        self.descriptions = descriptions
        self.allowMultiple = allowMultiple
        self.allowOther = allowOther
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
                    onFeedback: { feedback in onFeedback(feedback, selectedIndices, otherSelected ? otherText : nil) },
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
                    if allowOther {
                        OtherChoiceCard(
                            isSelected: otherSelected,
                            isMultiSelect: allowMultiple,
                            text: $otherText,
                            onTap: { toggleOther() }
                        )
                        .id(choices.count)
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
                .init("Done", isPrimary: true, isDisabled: !hasValidSelection, showReturnHint: true, action: {
                    onComplete(selectedIndices, otherSelected ? otherText : nil)
                })
            ]
        )
    }

    private func handleKeyPress(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> Bool {
        switch keyCode {
        case KeyCode.escape:
            return false
        case KeyCode.returnKey:
            if hasValidSelection {
                onComplete(selectedIndices, otherSelected ? otherText : nil)
            }
            return true
        default:
            return false
        }
    }

    private func toggleSelection(at index: Int) {
        if !allowMultiple {
            otherSelected = false
        }
        selectedIndices.toggle(index, multiSelect: allowMultiple)
    }

    private func toggleOther() {
        if allowMultiple {
            otherSelected.toggle()
        } else {
            selectedIndices = []
            otherSelected = true
        }
    }
}
