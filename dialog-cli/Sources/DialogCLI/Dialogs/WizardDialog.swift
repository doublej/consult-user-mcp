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
    @Binding var answer: QuestionAnswer
    @Binding var textValue: String
    @Binding var focusedIndex: Int

    private var selectedIndices: Set<Int> {
        if case .choices(let set) = answer { return set }
        return []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.question)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if question.type == .text {
                FocusableTextField(
                    placeholder: question.placeholder ?? "Enter your answer...",
                    text: $textValue
                )
                .frame(height: 48)
                .onChange(of: textValue) { newValue in
                    answer = .text(newValue)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                        FocusableChoiceCard(
                            title: option.label,
                            subtitle: option.description,
                            isSelected: selectedIndices.contains(index),
                            isMultiSelect: question.multiSelect,
                            onTap: { toggleSelection(at: index) }
                        )
                        .frame(minHeight: 48)
                        .id(index)
                    }
                }
            }
        }
    }

    private func toggleSelection(at index: Int) {
        var current = selectedIndices
        if question.multiSelect {
            if current.contains(index) {
                current.remove(index)
            } else {
                current.insert(index)
            }
        } else {
            current = [index]
        }
        answer = .choices(current)
    }
}

// MARK: - Wizard Mode Dialog

struct SwiftUIWizardDialog: View {
    let questions: [QuestionItem]
    let onComplete: ([String: QuestionAnswer]) -> Void
    let onCancel: () -> Void
    let onSnooze: (Int) -> Void
    let onFeedback: (String) -> Void

    @State private var currentIndex = 0
    @State private var answers: [String: QuestionAnswer] = [:]
    @State private var focusedOptionIndex: Int = 0
    @State private var textInputs: [String: String] = [:]
    @State private var expandedTool: DialogToolbar.ToolbarTool?

    private var currentQuestion: QuestionItem { questions[currentIndex] }
    private var currentAnswer: QuestionAnswer { answers[currentQuestion.id] ?? (currentQuestion.type == .text ? .text("") : .choices([])) }
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
                            answer: Binding(
                                get: { currentAnswer },
                                set: { answers[currentQuestion.id] = $0 }
                            ),
                            textValue: Binding(
                                get: { textInputs[currentQuestion.id] ?? "" },
                                set: { textInputs[currentQuestion.id] = $0 }
                            ),
                            focusedIndex: $focusedOptionIndex
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 4)  // Space for focus ring glow
                        .padding(.bottom, 8)
                    }
                    .scrollClipDisabled()
                    .frame(maxHeight: 420)
                    .onChange(of: focusedOptionIndex) { newIndex in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }

                DialogToolbar(
                    expandedTool: $expandedTool,
                    onSnooze: onSnooze,
                    onFeedback: onFeedback
                )

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
                            FocusableButton(title: "Cancel", isPrimary: false, action: onCancel)
                                .frame(height: 48)
                        } else {
                            FocusableButton(title: "Back", isPrimary: false, action: goBack)
                                .frame(height: 48)
                        }

                        if isLast {
                            FocusableButton(title: "Done", isPrimary: true, isDisabled: currentAnswer.isEmpty, showReturnHint: true, action: {
                                onComplete(answers)
                            })
                            .frame(height: 48)
                        } else {
                            FocusableButton(title: "Next", isPrimary: true, isDisabled: currentAnswer.isEmpty, showReturnHint: true, action: goNext)
                                .frame(height: 48)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .onChange(of: currentIndex) { _ in
            focusedOptionIndex = 0
            // Focus first element (delay to let view tree update)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                FocusManager.shared.focusFirst()
            }
        }
    }

    private func handleKeyPress(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> Bool {
        // Navigation (Tab, up/down arrows) and Space handled by FocusManager + focused views
        switch keyCode {
        case 53: // ESC
            onCancel()
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

    private func goNext() {
        currentIndex += 1
    }

    private func goBack() {
        currentIndex -= 1
    }
}
