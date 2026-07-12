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
    let hasFeedback: Bool
    let onOpenFeedback: () -> Void

    private var selectedIndices: Set<Int> {
        if case .choices(let set) = answer { return set }
        return []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                Text(question.question)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .textSelection(.enabled)
                    .frame(idealWidth: 380, maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                QuestionNoteAffordance(hasFeedback: hasFeedback, action: onOpenFeedback)
            }

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
        let result = QuestionAnswer.toggling(
            choice: index,
            in: answer,
            otherSelected: otherSelected,
            multiSelect: question.multiSelect
        )
        answer = result.answer
        otherSelected = result.otherSelected
    }

    private func toggleOther() {
        let result = QuestionAnswer.togglingOther(
            in: answer,
            otherSelected: otherSelected,
            multiSelect: question.multiSelect
        )
        answer = result.answer
        otherSelected = result.otherSelected
    }
}

// MARK: - Per-question Note Affordance

struct QuestionNoteAffordance: View {
    let hasFeedback: Bool
    let action: () -> Void

    @State private var isHovered = false

    private var backgroundOpacity: Double {
        if hasFeedback { return 0.18 }
        if isHovered { return 0.15 }
        return 0.06
    }

    private var backgroundColor: Color {
        hasFeedback ? Theme.Colors.accentBlue : Theme.Colors.textMuted
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: "bubble.left.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(hasFeedback ? Theme.Colors.accentBlue : Theme.Colors.textMuted)
                .frame(width: 28, height: 28)
                .background(
                    Circle().fill(backgroundColor.opacity(backgroundOpacity))
                )
                .overlay(
                    Circle()
                        .strokeBorder(Theme.Colors.accentBlue.opacity(hasFeedback ? 0.9 : 0), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(hasFeedback ? "Edit note" : "Add a note for the agent")
    }
}

// MARK: - Wizard Mode Dialog

struct SwiftUIWizardDialog: View {
    let title: String
    let bodyText: String?
    let questions: [QuestionItem]
    let position: DialogPosition
    let onComplete: ([String: QuestionAnswer], [String: Bool], [String: String], [String: String], String?) -> Void
    let onCancel: (String?, [String: String]) -> Void
    let onSnooze: (Int) -> Void
    let onAskDifferently: (String) -> Void

    @State private var currentIndex = 0
    @State private var focusedOptionIndex: Int = 0
    @StateObject private var formState = QuestionFormState()

    private var currentQuestion: QuestionItem { questions[currentIndex] }
    private var currentAnswer: QuestionAnswer { formState.answer(for: currentQuestion) }
    private var isFirst: Bool { currentIndex == 0 }
    private var isLast: Bool { currentIndex == questions.count - 1 }

    private var currentHasValidAnswer: Bool {
        formState.isAnswered(currentQuestion.id)
    }

    private func globalDraft() -> String? {
        let raw = DialogManager.shared.globalFeedbackBinding?.wrappedValue ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var body: some View {
        DialogContainer(
            bindings: DialogKeyBindings(
                canSubmit: { currentHasValidAnswer },
                onSubmit: {
                    if isLast {
                        onComplete(formState.answers, formState.otherSelections, formState.otherTexts, formState.feedbackDrafts, globalDraft())
                    } else {
                        goNext()
                    }
                },
                onCancel: { onCancel(globalDraft(), formState.feedbackDrafts) },
                onArrowLeft: {
                    if KeyboardContext.isEditingText { return false }
                    if !isFirst { goBack() }
                    return true
                },
                onArrowRight: {
                    if KeyboardContext.isEditingText { return false }
                    if !isLast && currentHasValidAnswer { goNext() }
                    return true
                }
            ),
            currentDialogType: "form-wizard",
            dialogPosition: position,
            contentMinWidth: 460,
            globalFeedbackSubject: FeedbackSubject(kind: .form, text: bodyText),
            onAskDifferently: onAskDifferently,
            feedbackBindingForQuestion: { id in formState.bindingForFeedback(id) }
        ) { controller in
            VStack(spacing: 0) {
                DialogHeader(
                    icon: "list.number",
                    title: title,
                    body: bodyText
                )
                .padding(.bottom, 8)

                ProgressBar(current: currentIndex + 1, total: questions.count)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                Text("\(currentIndex + 1) of \(questions.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textMuted)
                    .padding(.bottom, 16)

                ScrollViewReader { proxy in
                    AutoSizingScrollView {
                        QuestionSection(
                            question: currentQuestion,
                            answer: formState.bindingForAnswer(currentQuestion),
                            textValue: formState.bindingForText(currentQuestion.id),
                            focusedIndex: $focusedOptionIndex,
                            otherSelected: formState.bindingForOtherSelected(currentQuestion.id),
                            otherText: formState.bindingForOtherText(currentQuestion.id),
                            hasFeedback: formState.hasFeedback(currentQuestion.id),
                            onOpenFeedback: { controller.openFeedback(.question(id: currentQuestion.id)) }
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 8)
                    }
                    .onChange(of: focusedOptionIndex) { newIndex in
                        withAnimation(.easeOut(duration: Theme.Animation.card)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
                .clipped()

                VStack(spacing: 0) {
                    DialogToolbar(
                        expandedTool: controller.expandedTool,
                        currentDialogType: "form-wizard",
                        hasFeedback: controller.hasFeedback(.global),
                        onSnooze: onSnooze,
                        onOpenFeedback: { controller.openFeedback(.global) },
                        onAskDifferently: onAskDifferently
                    )

                    DialogFooter(
                        hints: [
                            KeyboardHint(key: "↑↓", label: "navigate"),
                            KeyboardHint(key: "Space", label: "select"),
                            KeyboardHint(key: "⏎", label: isLast ? "done" : "next"),
                        ] + KeyboardHint.toolbarHints,
                        buttons: [
                            isFirst
                                ? .init("Cancel", action: { onCancel(globalDraft(), formState.feedbackDrafts) })
                                : .init("Back", action: goBack),
                            isLast
                                ? .init("Done", isPrimary: true, isDisabled: !currentHasValidAnswer, showReturnHint: true, action: {
                                    onComplete(formState.answers, formState.otherSelections, formState.otherTexts, formState.feedbackDrafts, globalDraft())
                                })
                                : .init("Next", isPrimary: true, isDisabled: !currentHasValidAnswer, showReturnHint: true, action: goNext),
                        ]
                    )
                }
                .background(Theme.Colors.windowBackground)
            }
        }
        .onAppear {
            DialogManager.shared.questionLabelLookup = { id in
                questions.first(where: { $0.id == id })?.question
            }
        }
        .onDisappear {
            DialogManager.shared.questionLabelLookup = nil
        }
        .onChange(of: currentIndex) { _ in
            focusedOptionIndex = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + Theme.Timing.focusAfterTransition) {
                FocusManager.shared.focusFirst()
                NotificationCenter.default.post(name: .dialogContentSizeChanged, object: nil)
            }
        }
    }

    private func goNext() {
        currentIndex += 1
    }

    private func goBack() {
        currentIndex -= 1
    }
}
