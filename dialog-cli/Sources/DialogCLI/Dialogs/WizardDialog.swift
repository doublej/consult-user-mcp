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
    @Binding var otherSelected: Bool
    @Binding var otherText: String

    private var selectedIndices: Set<Int> {
        if case .choices(let set) = answer { return set }
        return []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SelectableText(
                question.question,
                fontSize: 15,
                weight: .semibold,
                color: Theme.Colors.textPrimary,
                alignment: .left
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            if question.type == .text {
                FocusableTextField(
                    placeholder: question.placeholder ?? "Enter your answer...",
                    isSecure: question.hidden,
                    text: $textValue
                )
                .frame(minHeight: 48)
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
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 48)
                        .id(index)
                    }
                    if question.allowOther {
                        OtherChoiceCard(
                            isSelected: otherSelected,
                            isMultiSelect: question.multiSelect,
                            text: $otherText,
                            onTap: { toggleOther() }
                        )
                        .id(question.options.count)
                    }
                }
            }
        }
    }

    private func toggleSelection(at index: Int) {
        if !question.multiSelect {
            otherSelected = false
        }
        var current = selectedIndices
        current.toggle(index, multiSelect: question.multiSelect)
        answer = .choices(current)
    }

    private func toggleOther() {
        if question.multiSelect {
            otherSelected.toggle()
        } else {
            answer = .choices([])
            otherSelected = true
        }
    }
}

// MARK: - Wizard Mode Dialog

struct SwiftUIWizardDialog: View {
    let title: String
    let bodyText: String?
    let questions: [QuestionItem]
    let onComplete: ([String: QuestionAnswer], [String: Bool], [String: String]) -> Void
    let onCancel: () -> Void
    let onSnooze: (Int) -> Void
    let onFeedback: (String, [String: QuestionAnswer], [String: Bool], [String: String]) -> Void
    let onAskDifferently: (String) -> Void

    @State private var currentIndex = 0
    @State private var answers: [String: QuestionAnswer] = [:]
    @State private var focusedOptionIndex: Int = 0
    @State private var textInputs: [String: String] = [:]
    @State private var otherSelections: [String: Bool] = [:]
    @State private var otherTexts: [String: String] = [:]

    private var currentQuestion: QuestionItem { questions[currentIndex] }
    private var currentAnswer: QuestionAnswer { answers[currentQuestion.id] ?? (currentQuestion.type == .text ? .text("") : .choices([])) }
    private var isFirst: Bool { currentIndex == 0 }
    private var isLast: Bool { currentIndex == questions.count - 1 }

    private var currentHasValidAnswer: Bool {
        if !currentAnswer.isEmpty { return true }
        let hasOther = otherSelections[currentQuestion.id] == true
        let other = otherTexts[currentQuestion.id] ?? ""
        return hasOther && !other.isEmpty
    }

    var body: some View {
        DialogContainer(
            keyHandler: handleKeyPress,
            currentDialogType: "form-wizard",
            onAskDifferently: onAskDifferently
        ) { expandedTool in
            VStack(spacing: 0) {
                DialogHeader(
                    icon: "list.number",
                    title: title,
                    body: bodyText
                )
                .padding(.bottom, 8)

                // Progress bar
                ProgressBar(current: currentIndex + 1, total: questions.count)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                // Progress text
                Text("\(currentIndex + 1) of \(questions.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textMuted)
                    .padding(.bottom, 16)

                // Question content
                ScrollViewReader { proxy in
                    AutoSizingScrollView {
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
                            focusedIndex: $focusedOptionIndex,
                            otherSelected: Binding(
                                get: { otherSelections[currentQuestion.id] ?? false },
                                set: { otherSelections[currentQuestion.id] = $0 }
                            ),
                            otherText: Binding(
                                get: { otherTexts[currentQuestion.id] ?? "" },
                                set: { otherTexts[currentQuestion.id] = $0 }
                            )
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 8)
                    }
                    .onChange(of: focusedOptionIndex) { newIndex in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
                .clipped()

                VStack(spacing: 0) {
                    DialogToolbar(
                        expandedTool: expandedTool,
                        currentDialogType: "form-wizard",
                        onSnooze: onSnooze,
                        onFeedback: { feedback in onFeedback(feedback, answers, otherSelections, otherTexts) },
                        onAskDifferently: onAskDifferently
                    )

                    // Navigation buttons
                    VStack(spacing: 8) {
                        KeyboardHintsView(hints: [
                            KeyboardHint(key: "↑↓", label: "navigate"),
                            KeyboardHint(key: "Space", label: "select"),
                            KeyboardHint(key: "⏎", label: isLast ? "done" : "next"),
                        ] + KeyboardHint.toolbarHints)
                        HStack(spacing: 10) {
                            if isFirst {
                                FocusableButton(title: "Cancel", isPrimary: false, action: onCancel)
                                    .frame(height: 48)
                            } else {
                                FocusableButton(title: "Back", isPrimary: false, action: goBack)
                                    .frame(height: 48)
                            }

                            if isLast {
                                FocusableButton(title: "Done", isPrimary: true, isDisabled: !currentHasValidAnswer, showReturnHint: true, action: {
                                    onComplete(answers, otherSelections, otherTexts)
                                })
                                .frame(height: 48)
                            } else {
                                FocusableButton(title: "Next", isPrimary: true, isDisabled: !currentHasValidAnswer, showReturnHint: true, action: goNext)
                                    .frame(height: 48)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Theme.Colors.windowBackground)
            }
        }
        .onChange(of: currentIndex) { _ in
            focusedOptionIndex = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                FocusManager.shared.focusFirst()
                NotificationCenter.default.post(name: .dialogContentSizeChanged, object: nil)
            }
        }
    }

    private func handleKeyPress(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> Bool {
        switch keyCode {
        case KeyCode.escape:
            onCancel()
            return true
        case KeyCode.returnKey:
            if currentHasValidAnswer {
                if isLast { onComplete(answers, otherSelections, otherTexts) } else { goNext() }
            }
            return true
        case KeyCode.rightArrow:
            if !isLast && currentHasValidAnswer { goNext() }
            return true
        case KeyCode.leftArrow:
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
