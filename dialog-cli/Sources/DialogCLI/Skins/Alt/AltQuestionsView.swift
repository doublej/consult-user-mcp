import SwiftUI

struct AltQuestionsView: View {
    let spec: QuestionsSpec

    @State private var currentIndex = 0
    @State private var focusedOptionIndex = 0
    @StateObject private var formState = QuestionFormState()

    private var currentQuestion: QuestionItem { spec.questions[currentIndex] }
    private var isFirst: Bool { currentIndex == 0 }
    private var isLast: Bool { currentIndex == spec.questions.count - 1 }
    private var canAdvance: Bool { formState.isAnswered(currentQuestion.id) }

    var body: some View {
        DialogContainer(
            bindings: DialogKeyBindings(
                canSubmit: { canAdvance },
                onSubmit: { isLast ? complete() : goNext() },
                onCancel: { spec.onCancel(AltFeedback.globalDraft(), formState.feedbackDrafts) },
                onArrowLeft: {
                    if KeyboardContext.isEditingText { return false }
                    if !isFirst { goBack() }
                    return true
                },
                onArrowRight: {
                    if KeyboardContext.isEditingText { return false }
                    if !isLast && canAdvance { goNext() }
                    return true
                }
            ),
            currentDialogType: "form-wizard",
            dialogPosition: spec.position,
            contentMinWidth: 460,
            globalFeedbackSubject: FeedbackSubject(kind: .form, text: spec.body),
            onAskDifferently: spec.onAskDifferently,
            feedbackBindingForQuestion: { id in formState.bindingForFeedback(id) }
        ) { controller in
            AltPanel {
                AltHeader(
                    kicker: "form \(String(format: "%02d", currentIndex + 1))/\(String(format: "%02d", spec.questions.count))",
                    title: spec.title,
                    body: spec.body
                )
                .padding(.bottom, 12)

                AltProgressLine(current: currentIndex + 1, total: spec.questions.count)
                    .padding(.horizontal, AltMetrics.contentPadding)
                    .padding(.bottom, 14)

                ScrollViewReader { proxy in
                    AutoSizingScrollView {
                        AltQuestionBody(
                            question: currentQuestion,
                            answer: formState.bindingForAnswer(currentQuestion),
                            textValue: formState.bindingForText(currentQuestion.id),
                            otherSelected: formState.bindingForOtherSelected(currentQuestion.id),
                            otherText: formState.bindingForOtherText(currentQuestion.id),
                            hasFeedback: formState.hasFeedback(currentQuestion.id),
                            onOpenFeedback: { controller.openFeedback(.question(id: currentQuestion.id)) }
                        )
                        .padding(.horizontal, AltMetrics.contentPadding)
                        .padding(.bottom, 10)
                    }
                    .onChange(of: focusedOptionIndex) { newIndex in
                        withAnimation(.easeOut(duration: Theme.Animation.card)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
                .clipped()

                DialogToolbar(
                    expandedTool: controller.expandedTool,
                    currentDialogType: "form-wizard",
                    hasFeedback: controller.hasFeedback(.global),
                    onSnooze: spec.onSnooze,
                    onOpenFeedback: { controller.openFeedback(.global) },
                    onAskDifferently: spec.onAskDifferently
                )

                AltActionBar(
                    hints: [
                        KeyboardHint(key: "↑↓", label: "navigate"),
                        KeyboardHint(key: "Space", label: "select"),
                        KeyboardHint(key: "⏎", label: isLast ? "done" : "next"),
                    ] + KeyboardHint.toolbarHints,
                    actions: [
                        isFirst
                            ? .init("Cancel", action: { spec.onCancel(AltFeedback.globalDraft(), formState.feedbackDrafts) })
                            : .init("Back", action: goBack),
                        isLast
                            ? .init("Done", isPrimary: true, isDisabled: !canAdvance, showReturnHint: true, action: complete)
                            : .init("Next", isPrimary: true, isDisabled: !canAdvance, showReturnHint: true, action: goNext),
                    ]
                )
            }
        }
        .onAppear {
            DialogManager.shared.questionLabelLookup = { id in
                spec.questions.first(where: { $0.id == id })?.question
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

    private func complete() {
        spec.onComplete(
            formState.answers,
            formState.otherSelections,
            formState.otherTexts,
            formState.feedbackDrafts,
            AltFeedback.globalDraft()
        )
    }

    private func goNext() { currentIndex += 1 }
    private func goBack() { currentIndex -= 1 }
}

// MARK: - Progress Line

/// One continuous rule with a filled leading portion. Classic uses discrete
/// capsules; this reads as a single measure instead.
struct AltProgressLine: View {
    let current: Int
    let total: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Theme.Colors.border.opacity(0.5))
                    .frame(height: 2)

                Rectangle()
                    .fill(Theme.Colors.accentBlue)
                    .frame(width: geo.size.width * CGFloat(current) / CGFloat(max(total, 1)), height: 2)
            }
            .frame(height: geo.size.height, alignment: .center)
        }
        .frame(height: 2)
        .accessibilityLabel(Text("Step \(current) of \(total)"))
    }
}

// MARK: - Question Body

struct AltQuestionBody: View {
    let question: QuestionItem
    @Binding var answer: QuestionAnswer
    @Binding var textValue: String
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
                    .frame(idealWidth: AltMetrics.contentIdealWidth, maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                QuestionNoteAffordance(hasFeedback: hasFeedback, action: onOpenFeedback)
            }

            if question.type == .text {
                FocusableTextField(
                    placeholder: question.placeholder ?? "Type your answer…",
                    isSecure: question.hidden,
                    text: $textValue
                )
                .frame(minHeight: 44)
                .onChange(of: textValue) { newValue in
                    answer = .text(newValue)
                }
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                        AltChoiceRow(index: index) {
                            FocusableChoiceCard(
                                title: option.label,
                                subtitle: option.description,
                                isSelected: selectedIndices.contains(index),
                                isMultiSelect: question.multiSelect,
                                onTap: { toggleSelection(at: index) }
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(minHeight: 46)
                        }
                        .id(index)
                    }

                    if question.allowOther {
                        AltChoiceRow(index: question.options.count) {
                            OtherChoiceCard(
                                isSelected: otherSelected,
                                isMultiSelect: question.multiSelect,
                                text: $otherText,
                                onTap: { toggleOther() }
                            )
                        }
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
