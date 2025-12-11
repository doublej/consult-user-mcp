import AppKit
import SwiftUI

// MARK: - Questionnaire Mode Dialog (all visible)

struct SwiftUIQuestionnaireDialog: View {
    let questions: [QuestionItem]
    let onComplete: ([String: Set<Int>]) -> Void
    let onCancel: () -> Void

    @State private var answers: [String: Set<Int>] = [:]
    @State private var focusedQuestionIndex: Int = 0
    @State private var focusedOptionIndex: Int = 0

    private var answeredCount: Int {
        answers.values.filter { !$0.isEmpty }.count
    }

    private var focusedQuestion: QuestionItem? {
        guard focusedQuestionIndex < questions.count else { return nil }
        return questions[focusedQuestionIndex]
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
                                                .fill(!(answers[question.id] ?? []).isEmpty ? Theme.Colors.accentBlue : Theme.Colors.border)
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

                                    // Options
                                    VStack(spacing: 8) {
                                        ForEach(Array(question.options.enumerated()), id: \.offset) { optIndex, option in
                                            SwiftUIChoiceCard(
                                                title: option.label,
                                                subtitle: option.description,
                                                isSelected: (answers[question.id] ?? []).contains(optIndex),
                                                isMultiSelect: question.multiSelect,
                                                isFocused: focusedQuestionIndex == qIndex && focusedOptionIndex == optIndex,
                                                onTap: { toggleSelection(questionId: question.id, optionIndex: optIndex, multiSelect: question.multiSelect) }
                                            )
                                            .id("q\(qIndex)o\(optIndex)")
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
                        .padding(.bottom, 16)
                    }
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

                // Footer buttons
                VStack(spacing: 8) {
                    KeyboardHintsView(hints: [
                        KeyboardHint(key: "↑↓", label: "navigate"),
                        KeyboardHint(key: "Space", label: "select"),
                        KeyboardHint(key: "Tab", label: "question"),
                        KeyboardHint(key: "⏎", label: "done")
                    ])
                    HStack(spacing: 10) {
                        SwiftUIModernButton(title: "Cancel", isPrimary: false, action: onCancel)
                        SwiftUIModernButton(title: "Done", isPrimary: true, isDisabled: answeredCount == 0, showReturnHint: true, action: {
                            onComplete(answers)
                        })
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
    }

    private func toggleSelection(questionId: String, optionIndex: Int, multiSelect: Bool) {
        var current = answers[questionId] ?? []
        if multiSelect {
            if current.contains(optionIndex) {
                current.remove(optionIndex)
            } else {
                current.insert(optionIndex)
            }
        } else {
            current = [optionIndex]
        }
        answers[questionId] = current
    }

    private func handleKeyPress(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> Bool {
        // ESC to cancel
        if keyCode == 53 {
            onCancel()
            return true
        }

        guard let question = focusedQuestion else { return false }

        switch keyCode {
        case 125: // Down arrow - next option or next question
            if focusedOptionIndex < question.options.count - 1 {
                focusedOptionIndex += 1
            } else if focusedQuestionIndex < questions.count - 1 {
                focusedQuestionIndex += 1
                focusedOptionIndex = 0
            }
            return true
        case 126: // Up arrow - previous option or previous question
            if focusedOptionIndex > 0 {
                focusedOptionIndex -= 1
            } else if focusedQuestionIndex > 0 {
                focusedQuestionIndex -= 1
                focusedOptionIndex = questions[focusedQuestionIndex].options.count - 1
            }
            return true
        case 49: // Space - toggle selection
            toggleSelection(questionId: question.id, optionIndex: focusedOptionIndex, multiSelect: question.multiSelect)
            return true
        case 48: // Tab - next/previous question
            if modifiers.contains(.shift) {
                if focusedQuestionIndex > 0 {
                    focusedQuestionIndex -= 1
                    focusedOptionIndex = 0
                }
            } else {
                if focusedQuestionIndex < questions.count - 1 {
                    focusedQuestionIndex += 1
                    focusedOptionIndex = 0
                }
            }
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
