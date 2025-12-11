import AppKit
import SwiftUI

// MARK: - Questionnaire Mode Dialog (all visible)

struct SwiftUIQuestionnaireDialog: View {
    let questions: [QuestionItem]
    let onComplete: ([String: QuestionAnswer]) -> Void
    let onCancel: () -> Void
    let onSnooze: (Int) -> Void
    let onFeedback: (String) -> Void

    @State private var answers: [String: QuestionAnswer] = [:]
    @State private var textInputs: [String: String] = [:]
    @State private var focusedQuestionIndex: Int = 0
    @State private var focusedOptionIndex: Int = 0
    @State private var expandedTool: DialogToolbar.ToolbarTool?

    private var answeredCount: Int {
        answers.values.filter { !$0.isEmpty }.count
    }

    private var focusedQuestion: QuestionItem? {
        guard focusedQuestionIndex < questions.count else { return nil }
        return questions[focusedQuestionIndex]
    }

    private func isAnswered(_ questionId: String) -> Bool {
        if let answer = answers[questionId] {
            return !answer.isEmpty
        }
        return false
    }

    private func selectedIndices(for questionId: String) -> Set<Int> {
        if case .choices(let set) = answers[questionId] { return set }
        return []
    }

    var body: some View {
        DialogContainer(keyHandler: handleKeyPress) {
            VStack(spacing: 0) {
                // Header with progress
                HStack {
                    Text("Questions")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Spacer()

                    Text("\(answeredCount)/\(questions.count) answered")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

                // All questions visible
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(Array(questions.enumerated()), id: \.element.id) { qIndex, question in
                                VStack(alignment: .leading, spacing: 0) {
                                    // Question number badge
                                    HStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(isAnswered(question.id) ? Theme.Colors.accentBlue : Theme.Colors.border)
                                                .frame(width: 24, height: 24)

                                            Text("\(qIndex + 1)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        }

                                        Text(question.question)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Theme.Colors.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.bottom, 12)
                                    .id("q\(qIndex)")

                                    // Options or text input
                                    VStack(spacing: 8) {
                                        if question.type == .text {
                                            FocusableTextField(
                                                placeholder: question.placeholder ?? "Enter your answer...",
                                                text: Binding(
                                                    get: { textInputs[question.id] ?? "" },
                                                    set: { newValue in
                                                        textInputs[question.id] = newValue
                                                        answers[question.id] = .text(newValue)
                                                    }
                                                )
                                            )
                                            .frame(height: 48)
                                            .id("q\(qIndex)o0")
                                        } else {
                                            ForEach(Array(question.options.enumerated()), id: \.offset) { optIndex, option in
                                                FocusableChoiceCard(
                                                    title: option.label,
                                                    subtitle: option.description,
                                                    isSelected: selectedIndices(for: question.id).contains(optIndex),
                                                    isMultiSelect: question.multiSelect,
                                                    onTap: { toggleSelection(questionId: question.id, optionIndex: optIndex, multiSelect: question.multiSelect) }
                                                )
                                                .frame(minHeight: 48)
                                                .id("q\(qIndex)o\(optIndex)")
                                            }
                                        }
                                    }
                                }

                                if qIndex < questions.count - 1 {
                                    Rectangle()
                                        .fill(Theme.Colors.border.opacity(0.8))
                                        .frame(height: 1)
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)  // Space for focus ring glow
                        .padding(.bottom, 16)
                    }
                    .scrollClipDisabled()
                    .frame(maxHeight: 450)
                    .onChange(of: focusedQuestionIndex) { _ in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo("q\(focusedQuestionIndex)", anchor: .top)
                        }
                    }
                    .onChange(of: focusedOptionIndex) { _ in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo("q\(focusedQuestionIndex)o\(focusedOptionIndex)", anchor: .center)
                        }
                    }
                }

                DialogToolbar(
                    expandedTool: $expandedTool,
                    onSnooze: onSnooze,
                    onFeedback: onFeedback
                )

                // Footer buttons
                VStack(spacing: 8) {
                    KeyboardHintsView(hints: [
                        KeyboardHint(key: "↑↓", label: "navigate"),
                        KeyboardHint(key: "Space", label: "select"),
                        KeyboardHint(key: "Tab", label: "question"),
                        KeyboardHint(key: "⏎", label: "done")
                    ])
                    HStack(spacing: 10) {
                        FocusableButton(title: "Cancel", isPrimary: false, action: onCancel)
                            .frame(height: 48)
                        FocusableButton(title: "Done", isPrimary: true, isDisabled: answeredCount == 0, showReturnHint: true, action: {
                            onComplete(answers)
                        })
                        .frame(height: 48)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
    }

    private func toggleSelection(questionId: String, optionIndex: Int, multiSelect: Bool) {
        var current = selectedIndices(for: questionId)
        if multiSelect {
            if current.contains(optionIndex) {
                current.remove(optionIndex)
            } else {
                current.insert(optionIndex)
            }
        } else {
            current = [optionIndex]
        }
        answers[questionId] = .choices(current)
    }

    private func handleKeyPress(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> Bool {
        // Navigation (Tab, arrows) and Space handled by FocusManager + focused views
        switch keyCode {
        case 53: // ESC
            onCancel()
            return true
        case 36: // Enter/Return - complete if any answers
            if answeredCount > 0 {
                onComplete(answers)
            }
            return true
        default:
            return false
        }
    }
}
