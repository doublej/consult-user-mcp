import AppKit
import SwiftUI

// MARK: - Accordion Mode Dialog

struct AccordionSection: View {
    let question: QuestionItem
    let isExpanded: Bool
    let isAnswered: Bool
    @Binding var selectedIndices: Set<Int>
    @Binding var focusedIndex: Int
    let onToggle: () -> Void
    let onAutoAdvance: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isHovered = false

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
                        .lineLimit(1)
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
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .transition(reduceMotion ? .identity : .opacity)
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
            // Auto-advance to next section after single-select
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onAutoAdvance()
            }
        }
    }
}

struct SwiftUIAccordionDialog: View {
    let questions: [QuestionItem]
    let onComplete: ([String: Set<Int>]) -> Void
    let onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var expandedId: String?
    @State private var answers: [String: Set<Int>] = [:]
    @State private var focusedOptionIndex: Int = 0

    private var answeredCount: Int {
        answers.values.filter { !$0.isEmpty }.count
    }

    private var expandedQuestion: QuestionItem? {
        questions.first { $0.id == expandedId }
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

                // Accordion sections
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(questions, id: \.id) { question in
                                AccordionSection(
                                    question: question,
                                    isExpanded: expandedId == question.id,
                                    isAnswered: !(answers[question.id] ?? []).isEmpty,
                                    selectedIndices: Binding(
                                        get: { answers[question.id] ?? [] },
                                        set: { answers[question.id] = $0 }
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
                        .padding(.bottom, 8)
                    }
                    .frame(maxHeight: 450)
                    .onChange(of: focusedOptionIndex) { newIndex in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }

                // Footer buttons
                VStack(spacing: 8) {
                    KeyboardHintsView(hints: [
                        KeyboardHint(key: "↑↓", label: "navigate"),
                        KeyboardHint(key: "Space", label: "select"),
                        KeyboardHint(key: "Tab", label: "section"),
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
                .padding(.vertical, 16)
            }
        }
        .onAppear {
            if let first = questions.first {
                expandedId = first.id
            }
        }
        .onChange(of: expandedId) { _ in focusedOptionIndex = 0 }
    }

    private func toggleExpanded(_ questionId: String) {
        if reduceMotion {
            expandedId = expandedId == questionId ? nil : questionId
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                expandedId = expandedId == questionId ? nil : questionId
            }
        }
    }

    private func advanceToNextSection(from questionId: String) {
        guard let currentIdx = questions.firstIndex(where: { $0.id == questionId }) else { return }
        let nextIdx = currentIdx + 1
        if nextIdx < questions.count {
            if reduceMotion {
                expandedId = questions[nextIdx].id
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    expandedId = questions[nextIdx].id
                }
            }
        }
        // If last question, stay expanded (user can click Done)
    }

    private func handleKeyPress(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags) -> Bool {
        // ESC to cancel
        if keyCode == 53 {
            onCancel()
            return true
        }

        guard let question = expandedQuestion else {
            // No section expanded - Tab opens first/last, Enter completes if any answers
            if keyCode == 48 {
                if modifiers.contains(.shift) {
                    if let last = questions.last { toggleExpanded(last.id) }
                } else {
                    if let first = questions.first { toggleExpanded(first.id) }
                }
                return true
            }
            if keyCode == 36 && answeredCount > 0 {
                onComplete(answers)
                return true
            }
            return false
        }

        switch keyCode {
        case 125: // Down arrow
            if focusedOptionIndex < question.options.count - 1 { focusedOptionIndex += 1 }
            return true
        case 126: // Up arrow
            if focusedOptionIndex > 0 { focusedOptionIndex -= 1 }
            return true
        case 49: // Space - toggle selection
            toggleSelection(for: question, at: focusedOptionIndex)
            return true
        case 36: // Enter/Return - advance or complete
            let currentAnswered = !(answers[question.id] ?? []).isEmpty
            if currentAnswered {
                if let idx = questions.firstIndex(where: { $0.id == expandedId }) {
                    if idx + 1 < questions.count {
                        advanceToNextSection(from: question.id)
                        return true
                    }
                }
            }
            if answeredCount > 0 { onComplete(answers) }
            return true
        case 48: // Tab - navigate accordion sections
            if let idx = questions.firstIndex(where: { $0.id == expandedId }) {
                let nextIdx = modifiers.contains(.shift)
                    ? (idx - 1 + questions.count) % questions.count
                    : (idx + 1) % questions.count
                toggleExpanded(questions[nextIdx].id)
            }
            return true
        default:
            return false
        }
    }

    private func toggleSelection(for question: QuestionItem, at index: Int) {
        var current = answers[question.id] ?? []
        if question.multiSelect {
            if current.contains(index) {
                current.remove(index)
            } else {
                current.insert(index)
            }
        } else {
            current = [index]
        }
        answers[question.id] = current
    }
}
