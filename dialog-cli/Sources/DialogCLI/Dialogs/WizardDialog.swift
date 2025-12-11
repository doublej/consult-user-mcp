import AppKit
import SwiftUI

// MARK: - Progress Bar

struct ProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < current ? Theme.Colors.accentBlue : Theme.Colors.cardBackground)
                    .frame(height: index < current ? 6 : 4)
                    .overlay(
                        Capsule()
                            .strokeBorder(index < current ? Color.clear : Theme.Colors.border.opacity(0.5), lineWidth: 1)
                    )
            }
        }
        .frame(height: 6)
        .accessibilityLabel(Text("Step \(current) of \(total)"))
        .accessibilityValue(Text("\(Int(Double(current) / Double(total) * 100)) percent complete"))
    }
}

// MARK: - Question Section (shared component)

struct QuestionSection: View {
    let question: QuestionItem
    @Binding var selectedIndices: Set<Int>
    @Binding var focusedIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.question)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    SwiftUIChoiceCard(
                        title: option.label,
                        subtitle: option.description,
                        isSelected: selectedIndices.contains(index),
                        isMultiSelect: question.multiSelect,
                        isFocused: focusedIndex == index,
                        onTap: { toggleSelection(at: index) }
                    )
                    .id(index)
                }
            }
        }
    }

    private func toggleSelection(at index: Int) {
        if question.multiSelect {
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

// MARK: - Wizard Mode Dialog

struct SwiftUIWizardDialog: View {
    let questions: [QuestionItem]
    let onComplete: ([String: Set<Int>]) -> Void
    let onCancel: () -> Void

    @State private var currentIndex = 0
    @State private var answers: [String: Set<Int>] = [:]
    @State private var focusedOptionIndex: Int = 0

    private var currentQuestion: QuestionItem { questions[currentIndex] }
    private var currentAnswer: Set<Int> { answers[currentQuestion.id] ?? [] }
    private var isFirst: Bool { currentIndex == 0 }
    private var isLast: Bool { currentIndex == questions.count - 1 }

    var body: some View {
        DialogContainer(keyHandler: handleKeyPress) {
            VStack(spacing: 0) {
                // Progress bar
                ProgressBar(current: currentIndex + 1, total: questions.count)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                // Progress text
                Text("\(currentIndex + 1) of \(questions.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textMuted)
                    .padding(.bottom, 16)

                // Question content
                ScrollViewReader { proxy in
                    ScrollView {
                        QuestionSection(
                            question: currentQuestion,
                            selectedIndices: Binding(
                                get: { currentAnswer },
                                set: { answers[currentQuestion.id] = $0 }
                            ),
                            focusedIndex: $focusedOptionIndex
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                    .frame(maxHeight: 420)
                    .onChange(of: focusedOptionIndex) { newIndex in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }

                // Navigation buttons
                VStack(spacing: 8) {
                    KeyboardHintsView(hints: [
                        KeyboardHint(key: "↑↓", label: "navigate"),
                        KeyboardHint(key: "Space", label: "select"),
                        KeyboardHint(key: "⏎", label: isLast ? "done" : "next"),
                        KeyboardHint(key: "Esc", label: "cancel")
                    ])
                    HStack(spacing: 10) {
                        if isFirst {
                            SwiftUIModernButton(title: "Cancel", isPrimary: false, action: onCancel)
                        } else {
                            SwiftUIModernButton(title: "Back", isPrimary: false, action: goBack)
                        }

                        if isLast {
                            SwiftUIModernButton(title: "Done", isPrimary: true, isDisabled: currentAnswer.isEmpty, showReturnHint: true, action: {
                                onComplete(answers)
                            })
                        } else {
                            SwiftUIModernButton(title: "Next", isPrimary: true, isDisabled: currentAnswer.isEmpty, showReturnHint: true, action: goNext)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .onChange(of: currentIndex) { _ in focusedOptionIndex = 0 }
    }

    private func handleKeyPress(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> Bool {
        switch keyCode {
        case 53: // ESC
            onCancel()
            return true
        case 48: // Tab
            if modifiers.contains(.shift) {
                if focusedOptionIndex > 0 { focusedOptionIndex -= 1 }
            } else {
                if focusedOptionIndex < currentQuestion.options.count - 1 { focusedOptionIndex += 1 }
            }
            return true
        case 125: // Down arrow
            if focusedOptionIndex < currentQuestion.options.count - 1 { focusedOptionIndex += 1 }
            return true
        case 126: // Up arrow
            if focusedOptionIndex > 0 { focusedOptionIndex -= 1 }
            return true
        case 49: // Space - toggle selection
            toggleSelection(at: focusedOptionIndex)
            return true
        case 36: // Enter/Return - next or complete
            if !currentAnswer.isEmpty {
                if isLast { onComplete(answers) } else { goNext() }
            }
            return true
        case 124: // Right arrow - next question
            if !isLast && !currentAnswer.isEmpty { goNext() }
            return true
        case 123: // Left arrow - previous question
            if !isFirst { goBack() }
            return true
        default:
            return false
        }
    }

    private func toggleSelection(at index: Int) {
        var current = answers[currentQuestion.id] ?? []
        if currentQuestion.multiSelect {
            if current.contains(index) {
                current.remove(index)
            } else {
                current.insert(index)
            }
        } else {
            current = [index]
        }
        answers[currentQuestion.id] = current
    }

    private func goNext() {
        currentIndex += 1
    }

    private func goBack() {
        currentIndex -= 1
    }
}
