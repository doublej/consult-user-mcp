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
                if reduceMotion {
                    isHovered = hovering
                } else {
                    withAnimation(.easeOut(duration: 0.12)) {
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
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .transition(reduceMotion ? .identity : .opacity)
            }
        }
    }

    private func toggleSelection(at index: Int) {
        var current = selectedIndices
        current.toggle(index, multiSelect: question.multiSelect)
        if !question.multiSelect {
            // Auto-advance to next section after single-select
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onAutoAdvance()
            }
        }
        answer = .choices(current)
    }
}

struct SwiftUIAccordionDialog: View {
    let title: String
    let bodyText: String?
    let questions: [QuestionItem]
    let onComplete: ([String: QuestionAnswer]) -> Void
    let onCancel: () -> Void
    let onSnooze: (Int) -> Void
    let onFeedback: (String, [String: QuestionAnswer]) -> Void
    let onAskDifferently: (String) -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var expandedId: String?
    @State private var answers: [String: QuestionAnswer] = [:]
    @State private var textInputs: [String: String] = [:]
    @State private var focusedOptionIndex: Int = 0

    private var answeredCount: Int {
        answers.values.filter { !$0.isEmpty }.count
    }

    private func isAnswered(_ questionId: String) -> Bool {
        if let answer = answers[questionId] {
            return !answer.isEmpty
        }
        return false
    }

    private var expandedQuestion: QuestionItem? {
        questions.first { $0.id == expandedId }
    }

    var body: some View {
        DialogContainer(
            keyHandler: handleKeyPress,
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
                                    isAnswered: isAnswered(question.id),
                                    answer: Binding(
                                        get: { answers[question.id] ?? (question.type == .text ? .text("") : .choices([])) },
                                        set: { answers[question.id] = $0 }
                                    ),
                                    textValue: Binding(
                                        get: { textInputs[question.id] ?? "" },
                                        set: { textInputs[question.id] = $0 }
                                    ),
                                    focusedIndex: Binding(
                                        get: { expandedId == question.id ? focusedOptionIndex : -1 },
                                        set: { if expandedId == question.id { focusedOptionIndex = $0 } }
                                    ),
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
                        withAnimation(.easeOut(duration: 0.15)) {
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
                        onFeedback: { feedback in onFeedback(feedback, answers) },
                        onAskDifferently: onAskDifferently
                    )

                    // Footer buttons
                    VStack(spacing: 8) {
                        KeyboardHintsView(hints: [
                            KeyboardHint(key: "↑↓", label: "navigate"),
                            KeyboardHint(key: "Space", label: "select"),
                            KeyboardHint(key: "⏎", label: "done"),
                        ] + KeyboardHint.toolbarHints)
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
                    .padding(.vertical, 16)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
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

    private func handleKeyPress(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> Bool {
        switch keyCode {
        case KeyCode.escape:
            onCancel()
            return true
        case KeyCode.returnKey:
            if answeredCount > 0 {
                onComplete(answers)
            }
            return true
        case KeyCode.tab:
            if modifiers.contains(.shift) {
                if let currentId = expandedId,
                   let currentIdx = questions.firstIndex(where: { $0.id == currentId }),
                   currentIdx > 0 {
                    let prevIdx = currentIdx - 1
                    withConditionalAnimation {
                        expandedId = questions[prevIdx].id
                    }
                    return true
                }
            } else {
                if let currentId = expandedId,
                   let currentIdx = questions.firstIndex(where: { $0.id == currentId }) {
                    if currentIdx < questions.count - 1 {
                        let nextIdx = currentIdx + 1
                        withConditionalAnimation {
                            expandedId = questions[nextIdx].id
                        }
                        return true
                    }
                }
            }
            return false
        default:
            return false
        }
    }
}
