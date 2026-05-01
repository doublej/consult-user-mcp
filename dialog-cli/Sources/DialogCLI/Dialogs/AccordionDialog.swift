import AppKit
import SwiftUI

// MARK: - Accordion Mode Dialog

struct AccordionSection: View {
    let question: QuestionItem
    let isExpanded: Bool
    let isAnswered: Bool
    @Binding var answer: QuestionAnswer
    @Binding var textValue: String
    @Binding var focusedIndex: Int
    @Binding var otherSelected: Bool
    @Binding var otherText: String
    let onToggle: () -> Void
    let onAutoAdvance: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isHovered = false

    private var selectedIndices: Set<Int> {
        if case .choices(let set) = answer { return set }
        return []
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack {
                    // Status indicator
                    ZStack {
                        Circle()
                            .fill(isAnswered ? Theme.Colors.accentBlue : Theme.Colors.cardBackground)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Circle()
                                    .strokeBorder(isAnswered ? Color.clear : Theme.Colors.border, lineWidth: 2)
                            )

                        if isAnswered {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Circle()
                                .fill(Theme.Colors.textMuted)
                                .frame(width: 6, height: 6)
                        }
                    }

                    Text(question.question)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isHovered ? Theme.Colors.cardHover : Theme.Colors.cardBackground)
                )
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
                if reduceMotion {
                    isHovered = hovering
                } else {
                    withAnimation(.easeOut(duration: Theme.Animation.hover)) {
                        isHovered = hovering
                    }
                }
            }

            // Expanded content
            if isExpanded {
                VStack(spacing: 8) {
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
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .transition(reduceMotion ? .identity : .opacity)
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
        if !question.multiSelect {
            DispatchQueue.main.asyncAfter(deadline: .now() + Theme.Timing.accordionAutoAdvance) {
                onAutoAdvance()
            }
        }
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

struct SwiftUIAccordionDialog: View {
    let title: String
    let bodyText: String?
    let questions: [QuestionItem]
    let onComplete: ([String: QuestionAnswer], [String: Bool], [String: String]) -> Void
    let onCancel: () -> Void
    let onSnooze: (Int) -> Void
    let onFeedback: (String, [String: QuestionAnswer], [String: Bool], [String: String]) -> Void
    let onAskDifferently: (String) -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var expandedId: String?
    @State private var focusedOptionIndex: Int = 0
    @StateObject private var formState = QuestionFormState()

    private var answeredCount: Int {
        questions.filter { formState.isAnswered($0.id) }.count
    }

    private var expandedQuestion: QuestionItem? {
        questions.first { $0.id == expandedId }
    }

    var body: some View {
        DialogContainer(
            bindings: DialogKeyBindings(
                canSubmit: { answeredCount > 0 },
                onSubmit: { onComplete(formState.answers, formState.otherSelections, formState.otherTexts) },
                onCancel: onCancel,
                onTab: { modifiers in jumpSection(reverse: modifiers.contains(.shift)) }
            ),
            currentDialogType: "form-accordion",
            onAskDifferently: onAskDifferently
        ) { expandedTool in
            VStack(spacing: 0) {
                DialogHeader(
                    icon: "rectangle.stack",
                    title: title,
                    body: bodyText
                )
                .padding(.bottom, 4)

                // Progress
                HStack {
                    Spacer()
                    Text("\(answeredCount)/\(questions.count) answered")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                // Accordion sections
                ScrollViewReader { proxy in
                    AutoSizingScrollView {
                        VStack(spacing: 8) {
                            ForEach(questions, id: \.id) { question in
                                AccordionSection(
                                    question: question,
                                    isExpanded: expandedId == question.id,
                                    isAnswered: formState.isAnswered(question.id),
                                    answer: formState.bindingForAnswer(question),
                                    textValue: formState.bindingForText(question.id),
                                    focusedIndex: Binding(
                                        get: { expandedId == question.id ? focusedOptionIndex : -1 },
                                        set: { if expandedId == question.id { focusedOptionIndex = $0 } }
                                    ),
                                    otherSelected: formState.bindingForOtherSelected(question.id),
                                    otherText: formState.bindingForOtherText(question.id),
                                    onToggle: { toggleExpanded(question.id) },
                                    onAutoAdvance: { advanceToNextSection(from: question.id) }
                                )
                                .id(question.id)
                            }
                        }
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
                        expandedTool: expandedTool,
                        currentDialogType: "form-accordion",
                        onSnooze: onSnooze,
                        onFeedback: { feedback in onFeedback(feedback, formState.answers, formState.otherSelections, formState.otherTexts) },
                        onAskDifferently: onAskDifferently
                    )

                    DialogFooter(
                        hints: [
                            KeyboardHint(key: "↑↓", label: "navigate"),
                            KeyboardHint(key: "Space", label: "select"),
                            KeyboardHint(key: "⏎", label: "done"),
                        ] + KeyboardHint.toolbarHints,
                        buttons: [
                            .init("Cancel", action: onCancel),
                            .init("Done", isPrimary: true, isDisabled: answeredCount == 0, showReturnHint: true, action: {
                                onComplete(formState.answers, formState.otherSelections, formState.otherTexts)
                            }),
                        ]
                    )
                }
                .background(Theme.Colors.windowBackground)
            }
        }
        .onAppear {
            if let first = questions.first {
                expandedId = first.id
            }
        }
        .onChange(of: expandedId) { _ in
            focusedOptionIndex = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + Theme.Timing.focusAfterExpand) {
                FocusManager.shared.focusFirst()
                NotificationCenter.default.post(name: .dialogContentSizeChanged, object: nil)
            }
        }
    }

    private func toggleExpanded(_ questionId: String) {
        withConditionalAnimation {
            expandedId = expandedId == questionId ? nil : questionId
        }
    }

    private func advanceToNextSection(from questionId: String) {
        guard let currentIdx = questions.firstIndex(where: { $0.id == questionId }) else { return }
        let nextIdx = currentIdx + 1
        if nextIdx < questions.count {
            withConditionalAnimation {
                expandedId = questions[nextIdx].id
            }
        }
    }

    private func jumpSection(reverse: Bool) -> Bool {
        guard let currentId = expandedId,
              let currentIdx = questions.firstIndex(where: { $0.id == currentId }) else {
            return false
        }
        let targetIdx = reverse ? currentIdx - 1 : currentIdx + 1
        guard targetIdx >= 0, targetIdx < questions.count else { return false }
        withConditionalAnimation {
            expandedId = questions[targetIdx].id
        }
        return true
    }
}
