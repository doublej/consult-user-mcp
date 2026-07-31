import SwiftUI

/// §5.4 — several questions, one at a time.
///
/// Progress is answered twice over, as §7.2 allows: a segmented bar whose
/// current step counts as complete, and the `<N> of <M>` counter beside it. The
/// kind label carries the step too, so the surface still announces what it is.
struct BracketQuestionsView: View {
    let spec: QuestionsSpec

    @StateObject private var clock = CooldownClock()
    @StateObject private var caret = CaretTracker()

    @State private var step = 0
    @State private var choices: [String: Set<Int>] = [:]
    @State private var texts: [String: String] = [:]
    @State private var otherSelected: [String: Bool] = [:]
    @State private var otherTexts: [String: String] = [:]
    @State private var notes: [String: String] = [:]
    @State private var touched: Set<String> = []

    private var total: Int { spec.questions.count }
    private var current: QuestionItem { spec.questions[min(step, total - 1)] }
    private var isLast: Bool { step >= total - 1 }
    private var isFirst: Bool { step == 0 }

    var body: some View {
        DialogContainer(
            bindings: DialogKeyBindings(
                canSubmit: { isValid(current) },
                onSubmit: { advance() },
                onCancel: { cancel() },
                onArrowLeft: { KeyboardContext.isEditingText ? false : goBack() },
                onArrowRight: { KeyboardContext.isEditingText ? false : advance() }
            ),
            currentDialogType: "questions",
            dialogPosition: spec.position,
            contentMinWidth: BracketSkin.width(for: .questions),
            globalFeedbackSubject: FeedbackSubject(kind: .form, text: spec.body),
            onAskDifferently: spec.onAskDifferently,
            feedbackBindingForQuestion: { id in
                Binding(get: { notes[id] ?? "" }, set: { notes[id] = $0 })
            }
        ) { controller in
            BracketSurface {
                VStack(alignment: .leading, spacing: 0) {
                    BracketHeader(typeLabel: stepLabel, title: spec.title)
                        .padding(.bottom, 12)

                    if let intro = spec.body, !intro.isEmpty {
                        BracketBody(text: intro)
                            .padding(.bottom, 14)
                    }

                    progressRow
                        .padding(.bottom, 14)

                    AutoSizingScrollView {
                        questionArea(controller: controller)
                            .padding(.trailing, 2)
                    }

                    if touched.contains(current.id) && !isValid(current) {
                        BracketHelperLine(text: helperText(for: current))
                            .padding(.top, 12)
                    }

                    Spacer(minLength: 18)

                    BracketFooter(
                        expandedTool: controller.expandedTool,
                        hasNote: controller.hasFeedback(.global),
                        currentShape: "form-wizard",
                        readiness: clock.progress,
                        hints: [
                            ("↑↓", "navigate"),
                            ("Space", "select"),
                            ("⏎", isLast ? "done" : "next"),
                        ],
                        isEditing: caret.isEditing,
                        isPaneOpen: controller.currentTarget != nil,
                        onSnooze: spec.onSnooze,
                        onOpenFeedback: { controller.openFeedback(.global) },
                        onAskDifferently: spec.onAskDifferently,
                        secondary: (secondaryLabel, { secondaryAction() }),
                        primary: (isLast ? "Done" : "Next", isValid(current), { advance() })
                    )
                    .padding(.top, 4)
                }
                .padding(.horizontal, BracketStyle.Space.gutter)
                .padding(.top, 16)
                .padding(.bottom, 14)
            }
            .onAppear { clock.start() }
        }
    }

    private var stepLabel: String {
        String(format: "FORM %02d/%02d", step + 1, total)
    }

    private var progressRow: some View {
        HStack(spacing: 12) {
            // §5.4 — the current step counts as complete.
            BracketProgress(step: step + 1, total: total)
            Text("\(step + 1) of \(total)")
                .font(BracketStyle.monoFont(BracketStyle.Size.label, .medium))
                .foregroundColor(BracketStyle.inkMuted)
                .fixedSize()
        }
        .accessibilityHidden(false)
    }

    @ViewBuilder
    private func questionArea(controller: FeedbackController) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                MarkdownText(
                    current.question,
                    fontSize: BracketStyle.Size.statement,
                    color: BracketStyle.ink,
                    alignment: .left
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                BracketNoteControl(
                    hasNote: hasNote(current.id),
                    action: { controller.openFeedback(.question(id: current.id)) }
                )
                .padding(.top, 2)
            }

            switch current.type {
            case .choice:
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(current.options.enumerated()), id: \.offset) { index, option in
                        BracketOptionRow(
                            ordinal: index + 1,
                            label: option.label,
                            detail: option.description,
                            isSelected: (choices[current.id] ?? []).contains(index),
                            isMultiSelect: current.multiSelect,
                            onTap: { toggle(index, in: current) }
                        )
                    }
                    // §5.4 — text steps never show an "Other" row.
                    if current.allowOther {
                        otherRow(for: current)
                    }
                }
            case .text:
                BracketTextField(
                    placeholder: current.placeholder ?? "Enter your answer...",
                    isSecure: current.hidden,
                    text: Binding(
                        get: { texts[current.id] ?? "" },
                        set: { texts[current.id] = $0; touched.insert(current.id) }
                    ),
                    onFocusChange: { caret.isEditing = $0 }
                )
            }
        }
        .id(current.id)
    }

    private func otherRow(for item: QuestionItem) -> some View {
        BracketOptionRow(
            ordinal: item.options.count + 1,
            label: "Other",
            detail: nil,
            isSelected: otherSelected[item.id] ?? false,
            isMultiSelect: item.multiSelect,
            onTap: { selectOther(in: item) },
            accessory: {
                BracketTextField(
                    placeholder: "Type your answer...",
                    text: Binding(
                        get: { otherTexts[item.id] ?? "" },
                        set: { value in
                            otherTexts[item.id] = value
                            touched.insert(item.id)
                            if !value.isEmpty && !(otherSelected[item.id] ?? false) {
                                selectOther(in: item)
                            }
                        }
                    ),
                    onFocusChange: { caret.isEditing = $0 }
                )
                .padding(.top, 6)
            }
        )
    }

    // MARK: - Answer state

    private func toggle(_ index: Int, in item: QuestionItem) {
        touched.insert(item.id)
        var set = choices[item.id] ?? []
        if item.multiSelect {
            if set.contains(index) { set.remove(index) } else { set.insert(index) }
        } else {
            set = set.contains(index) ? [] : [index]
            if !set.isEmpty { otherSelected[item.id] = false }
        }
        choices[item.id] = set
    }

    private func selectOther(in item: QuestionItem) {
        touched.insert(item.id)
        if item.multiSelect {
            otherSelected[item.id] = !(otherSelected[item.id] ?? false)
        } else {
            otherSelected[item.id] = true
            choices[item.id] = []
        }
    }

    private func hasNote(_ id: String) -> Bool {
        !(notes[id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func isValid(_ item: QuestionItem) -> Bool {
        switch item.type {
        case .text:
            return !(texts[item.id] ?? "").isEmpty
        case .choice:
            let picked = !(choices[item.id] ?? []).isEmpty
            let other = (otherSelected[item.id] ?? false) && !(otherTexts[item.id] ?? "").isEmpty
            return picked || other
        }
    }

    private func helperText(for item: QuestionItem) -> String {
        switch item.type {
        case .text:
            return "Type an answer to continue"
        case .choice:
            if otherSelected[item.id] ?? false { return "Type your custom answer to continue" }
            return item.multiSelect
                ? "Select at least one option to continue"
                : "Select an option to continue"
        }
    }

    // MARK: - Navigation

    private var secondaryLabel: String {
        isFirst ? "Cancel" : "Back"
    }

    private func secondaryAction() {
        if isFirst { cancel() } else { _ = goBack() }
    }

    @discardableResult
    private func advance() -> Bool {
        guard isValid(current) else { return false }
        if isLast {
            complete()
        } else {
            step += 1
            refocus()
        }
        return true
    }

    @discardableResult
    private func goBack() -> Bool {
        guard !isFirst else { return false }
        step -= 1
        refocus()
        return true
    }

    /// §9 — focus lands on the new step's first answer element ~0.15s after the
    /// step advances, deliberately not instantly.
    private func refocus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            FocusManager.shared.focusFirst()
        }
    }

    // MARK: - Outcome

    private func perQuestionNotes() -> [String: String] {
        notes.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func complete() {
        var answers: [String: QuestionAnswer] = [:]
        for item in spec.questions where isValid(item) {
            switch item.type {
            case .choice: answers[item.id] = .choices(choices[item.id] ?? [])
            case .text: answers[item.id] = .text(texts[item.id] ?? "")
            }
        }
        spec.onComplete(
            answers,
            otherSelected.filter { $0.value },
            otherTexts.filter { !$0.value.isEmpty },
            perQuestionNotes(),
            BracketNote.current()
        )
    }

    private func cancel() {
        // §5.4 — answers are discarded, but every note still travels back.
        spec.onCancel(BracketNote.current(), perQuestionNotes())
    }
}
