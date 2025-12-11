import AppKit
import SwiftUI

// MARK: - SwiftUI Choose Dialog

struct SwiftUIChooseDialog: View {
    let prompt: String
    let choices: [String]
    let descriptions: [String]?
    let allowMultiple: Bool
    let defaultSelection: String?
    let onComplete: (Set<Int>) -> Void
    let onCancel: () -> Void

    @State private var selectedIndices: Set<Int> = []
    @State private var focusedIndex: Int = 0

    init(prompt: String, choices: [String], descriptions: [String]?, allowMultiple: Bool, defaultSelection: String?, onComplete: @escaping (Set<Int>) -> Void, onCancel: @escaping () -> Void) {
        self.prompt = prompt
        self.choices = choices
        self.descriptions = descriptions
        self.allowMultiple = allowMultiple
        self.defaultSelection = defaultSelection
        self.onComplete = onComplete
        self.onCancel = onCancel

        if let defaultSel = defaultSelection, let idx = choices.firstIndex(of: defaultSel) {
            _selectedIndices = State(initialValue: [idx])
            _focusedIndex = State(initialValue: idx)
        }
    }

    var body: some View {
        DialogContainer(keyHandler: handleKeyPress) {
            VStack(spacing: 0) {
                headerView
                choicesScrollView
                footerView
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(prompt))
            .accessibilityHint(allowMultiple ? "Select one or more options. Use arrow keys to navigate, Space to select." : "Select one option. Use arrow keys to navigate, Space to select.")
        }
    }

    private var headerView: some View {
        Text(prompt)
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(Theme.Colors.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
    }

    private var choicesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                        SwiftUIChoiceCard(
                            title: choice,
                            subtitle: descriptions?[safe: index],
                            isSelected: selectedIndices.contains(index),
                            isMultiSelect: allowMultiple,
                            isFocused: focusedIndex == index,
                            onTap: { toggleSelection(at: index) }
                        )
                        .id(index)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 500)
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
                KeyboardHint(key: "Esc", label: "cancel")
            ],
            buttons: [
                .init("Cancel", action: onCancel),
                .init("Done", isPrimary: true, isDisabled: selectedIndices.isEmpty, showReturnHint: true, action: { onComplete(selectedIndices) })
            ]
        )
    }

    private func handleKeyPress(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> Bool {
        switch keyCode {
        case 48: // Tab
            if modifiers.contains(.shift) {
                if focusedIndex > 0 { focusedIndex -= 1 }
            } else {
                if focusedIndex < choices.count - 1 { focusedIndex += 1 }
            }
            return true
        case 125: // Down arrow
            if focusedIndex < choices.count - 1 { focusedIndex += 1 }
            return true
        case 126: // Up arrow
            if focusedIndex > 0 { focusedIndex -= 1 }
            return true
        case 49: // Space - toggle selection
            toggleSelection(at: focusedIndex)
            return true
        case 36: // Enter/Return - confirm if selection made
            if !selectedIndices.isEmpty { onComplete(selectedIndices) }
            return true
        default:
            return false
        }
    }

    private func toggleSelection(at index: Int) {
        if allowMultiple {
            if selectedIndices.contains(index) {
                selectedIndices.remove(index)
            } else {
                selectedIndices.insert(index)
            }
        } else {
            selectedIndices = [index]
        }
    }
}
