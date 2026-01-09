import AppKit
import SwiftUI

// MARK: - SwiftUI Choose Dialog

struct SwiftUIChooseDialog: View {
    let bodyText: String
    let choices: [String]
    let descriptions: [String]?
    let allowMultiple: Bool
    let defaultSelection: String?
    let onComplete: (Set<Int>) -> Void
    let onCancel: () -> Void
    let onSnooze: (Int) -> Void
    let onFeedback: (String) -> Void

    @State private var selectedIndices: Set<Int> = []
    @State private var focusedIndex: Int = 0
    @State private var expandedTool: DialogToolbar.ToolbarTool?

    init(body: String, choices: [String], descriptions: [String]?, allowMultiple: Bool, defaultSelection: String?, onComplete: @escaping (Set<Int>) -> Void, onCancel: @escaping () -> Void, onSnooze: @escaping (Int) -> Void, onFeedback: @escaping (String) -> Void) {
        self.bodyText = body
        self.choices = choices
        self.descriptions = descriptions
        self.allowMultiple = allowMultiple
        self.defaultSelection = defaultSelection
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onSnooze = onSnooze
        self.onFeedback = onFeedback

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

                DialogToolbar(
                    expandedTool: $expandedTool,
                    onSnooze: onSnooze,
                    onFeedback: onFeedback
                )

                footerView
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(bodyText))
            .accessibilityHint(allowMultiple ? "Select one or more options. Use arrow keys to navigate, Space to select." : "Select one option. Use arrow keys to navigate, Space to select.")
        }
    }

    private var headerView: some View {
        MarkdownText(bodyText, font: .system(size: 17, weight: .bold), color: Theme.Colors.textPrimary)
            .frame(width: 380, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
    }

    private var choicesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                        FocusableChoiceCard(
                            title: choice,
                            subtitle: descriptions?[safe: index],
                            isSelected: selectedIndices.contains(index),
                            isMultiSelect: allowMultiple,
                            onTap: { toggleSelection(at: index) }
                        )
                        .frame(minHeight: 48)
                        .id(index)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
            .scrollClipDisabled()
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
                KeyboardHint(key: "S", label: "snooze"),
                KeyboardHint(key: "F", label: "feedback")
            ],
            buttons: [
                .init("Cancel", action: onCancel),
                .init("Done", isPrimary: true, isDisabled: selectedIndices.isEmpty, showReturnHint: true, action: { onComplete(selectedIndices) })
            ]
        )
    }

    private func handleKeyPress(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> Bool {
        // Navigation (Tab, arrows) and Space handled by FocusManager + focused views
        switch keyCode {
        case 53: // Esc - close panel first, then dismiss
            if expandedTool != nil {
                toggleTool(expandedTool!)
                return true
            }
            return false // Let DialogContainer handle dismiss
        case 36: // Enter/Return - confirm if selection made
            // Don't intercept Enter if feedback panel is expanded (let text field handle it)
            if expandedTool == .feedback { return false }
            if !selectedIndices.isEmpty { onComplete(selectedIndices) }
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
    }

    private func toggleTool(_ tool: DialogToolbar.ToolbarTool) {
        withAnimation(.easeOut(duration: 0.2)) {
            expandedTool = expandedTool == tool ? nil : tool
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
