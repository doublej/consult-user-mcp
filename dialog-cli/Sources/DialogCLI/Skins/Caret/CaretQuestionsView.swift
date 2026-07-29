import AppKit
import SwiftUI

/// How far through the batch (§5.4).
///
/// One tick per question, drawn as the caret's own stem at small scale: spent
/// ticks are amber, the rest are rail. The current step counts as complete, so
/// the indication reads full on the last one. Decorative — not a target, never
/// focusable, and there is no way to jump.
struct CaretProgress: View {
    let step: Int
    let total: Int
    @Environment(\.caretPalette) private var palette

    var body: some View {
        HStack(spacing: CaretStyle.u(9)) {
            Text(String(format: "STEP %02d / %02d", step + 1, total))
                .font(Font(CaretStyle.monoTiny))
                .kerning(CaretStyle.monoTiny.pointSize * CaretStyle.railTracking)
                .foregroundStyle(palette.inkMuted)
            HStack(spacing: CaretStyle.u(4)) {
                ForEach(0..<total, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? palette.caret : palette.rail)
                        .frame(width: CaretStyle.caretWidth, height: CaretStyle.u(10))
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Step \(step + 1) of \(total)"))
        .accessibilityValue(Text("\(Int((Double(step + 1) / Double(total)) * 100)) percent complete"))
    }
}

/// Form (§5.4). Several questions, one at a time.
struct CaretQuestionsView: View {
    let spec: QuestionsSpec

    @StateObject private var model = CaretSurfaceModel()
    @StateObject private var form = QuestionFormState()
    @State private var step = 0
    @State private var focusedRow: Int?
    @State private var touched: Set<String> = []
    @State private var fieldFocused = false
    @State private var landed: Int?
    @Environment(\.caretPalette) private var palette

    private var total: Int { max(1, spec.questions.count) }
    private var question: QuestionItem { spec.questions[min(step, spec.questions.count - 1)] }
    private var isLast: Bool { step == spec.questions.count - 1 }
    private var answered: Bool { form.isAnswered(question.id) }

    var body: some View {
        CaretFrame(
            kind: .form,
            title: spec.title,
            position: spec.position,
            model: model,
            minSurfaceWidth: CaretSkin.surfaceWidth(for: .questions),
            leadingAction: CaretActionSpec(
                label: step == 0 ? "Cancel" : "Back",
                role: .decline,
                key: step == 0 ? "esc" : "←",
                run: retreat
            ),
            trailingAction: CaretActionSpec(
                label: isLast ? "Done" : "Next",
                role: .commit,
                key: "⏎",
                keyAvailable: answered,
                enabled: answered,
                run: advance
            ),
            bindings: CaretBindings(
                canSubmit: { answered },
                onSubmit: advance,
                onCancel: cancel,
                onArrowLeft: { retreat(); return true },
                onArrowRight: { if answered { advance() }; return true }
            ),
            noteCaption: { key in key.isEmpty ? "NOTE ON THIS FORM" : "NOTE ON THIS QUESTION" },
            noteSubject: { key in
                if key.isEmpty { return spec.body }
                let match = spec.questions.first { $0.id == key }
                return match?.question ?? "(this question)"
            },
            onSnooze: spec.onSnooze,
            onAskDifferently: spec.onAskDifferently
        ) {
            VStack(alignment: .leading, spacing: 0) {
                CaretProgress(step: step, total: total)
                    .padding(.bottom, CaretStyle.u(14))

                CaretChannel(centre: focusedRow) {
                    VStack(alignment: .leading, spacing: CaretStyle.u(14)) {
                        questionHead
                        answerControl
                    }
                    .padding(.trailing, CaretStyle.u(2))
                }

                if touched.contains(question.id), !answered {
                    CaretHelper(text: helper).padding(.top, CaretStyle.u(12))
                }
            }
            .id(step)
            .onAppear { land() }
            .onChange(of: step) { _, _ in land() }
        }
    }

    // MARK: - The question

    private var questionHead: some View {
        VStack(alignment: .leading, spacing: CaretStyle.u(8)) {
            CaretProseText(
                raw: question.question,
                font: CaretStyle.question,
                emphasis: NSFont.systemFont(ofSize: CaretStyle.u(14), weight: .heavy),
                colour: palette.ink
            )
            noteMark
        }
    }

    /// The per-question annotation target. The form-level one is the `F` tool;
    /// this is the other of §3.6's three, and triggering either while the other
    /// is open swaps the pane's contents rather than closing it.
    private var noteMark: some View {
        let has = model.hasNote(question.id)
        return Button {
            model.openNote = question.id
            model.reflow()
        } label: {
            HStack(spacing: CaretStyle.u(6)) {
                Rectangle()
                    .fill(has ? palette.caret : palette.rail)
                    .frame(width: CaretStyle.caretWidth, height: CaretStyle.u(10))
                    .clipShape(Capsule())
                Text(has ? "EDIT NOTE" : "ADD A NOTE FOR THE AGENT")
                    .font(Font(CaretStyle.monoTiny))
                    .kerning(CaretStyle.monoTiny.pointSize * CaretStyle.railTracking)
                    .foregroundStyle(has ? palette.caret : palette.inkMuted)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - The answer

    @ViewBuilder
    private var answerControl: some View {
        if question.type == .text {
            VStack(alignment: .leading, spacing: CaretStyle.u(7)) {
                CaretField(
                    text: form.bindingForText(question.id),
                    placeholder: question.placeholder ?? "Enter your answer...",
                    masked: question.hidden,
                    onFocus: { fieldFocused = $0; model.editing = $0 }
                )
                .frame(height: CaretStyle.u(21))
                CaretFieldRule(focused: fieldFocused)
            }
            .onChange(of: form.textInputs[question.id] ?? "") { _, value in
                touched.insert(question.id)
                form.answers[question.id] = .text(value)
            }
        } else {
            VStack(alignment: .leading, spacing: CaretStyle.u(2)) {
                CaretSetHeader(multi: question.multiSelect, count: chosenCount)
                    .padding(.bottom, CaretStyle.u(5))

                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    CaretRow(
                        ordinal: index + 1,
                        label: option.label,
                        description: option.description,
                        chosen: chosen(index),
                        multi: question.multiSelect,
                        onActivate: { choose(index) },
                        onFocus: { if $0 { focusedRow = index } }
                    )
                    .id(index)
                }

                if question.allowOther { otherRow }
            }
            .accessibilityLabel(Text(question.multiSelect
                ? "Select one or more options. Use arrow keys to navigate, Space to select."
                : "Select one option. Use arrow keys to navigate, Space to select."))
        }
    }

    private var otherRow: some View {
        let ordinal = question.options.count + 1
        return CaretRow(
            ordinal: ordinal,
            label: "Other",
            description: nil,
            chosen: form.otherSelections[question.id] ?? false,
            multi: question.multiSelect,
            onActivate: { chooseOther() },
            onFocus: { if $0 { focusedRow = ordinal } },
            trailingContent: {
                VStack(alignment: .leading, spacing: CaretStyle.u(5)) {
                    CaretField(
                        text: form.bindingForOtherText(question.id),
                        placeholder: "Type your answer...",
                        onFocus: { model.editing = $0 }
                    )
                    .frame(height: CaretStyle.u(19))
                    CaretFieldRule(focused: form.otherSelections[question.id] ?? false)
                }
                .padding(.top, CaretStyle.u(4))
                .onChange(of: form.otherTexts[question.id] ?? "") { _, value in
                    touched.insert(question.id)
                    if !value.isEmpty && !(form.otherSelections[question.id] ?? false) { chooseOther() }
                }
            }
        )
        .id(ordinal)
    }

    // MARK: - Choosing

    private func chosen(_ index: Int) -> Bool {
        if case .choices(let set) = form.answer(for: question) { return set.contains(index) }
        return false
    }

    private var chosenCount: Int {
        var count = 0
        if case .choices(let set) = form.answer(for: question) { count = set.count }
        if (form.otherSelections[question.id] ?? false), !(form.otherTexts[question.id] ?? "").isEmpty { count += 1 }
        return count
    }

    private func choose(_ index: Int) {
        touched.insert(question.id)
        let result = QuestionAnswer.toggling(
            choice: index,
            in: form.answer(for: question),
            otherSelected: form.otherSelections[question.id] ?? false,
            multiSelect: question.multiSelect
        )
        form.answers[question.id] = result.answer
        form.otherSelections[question.id] = result.otherSelected
    }

    private func chooseOther() {
        touched.insert(question.id)
        let result = QuestionAnswer.togglingOther(
            in: form.answer(for: question),
            otherSelected: form.otherSelections[question.id] ?? false,
            multiSelect: question.multiSelect
        )
        form.answers[question.id] = result.answer
        form.otherSelections[question.id] = result.otherSelected
    }

    private var helper: String {
        if question.type == .text { return "Type an answer to continue" }
        if (form.otherSelections[question.id] ?? false) { return "Type your custom answer to continue" }
        return question.multiSelect ? "Select at least one option to continue" : "Select an option to continue"
    }

    // MARK: - Moving

    /// §5.4: step changes are instantaneous and every previously entered
    /// answer survives movement in both directions.
    private func advance() {
        guard answered else { return }
        if isLast {
            spec.onComplete(form.answers, form.otherSelections, form.otherTexts,
                            form.feedbackDrafts, model.surfaceNote)
        } else {
            step += 1
            model.reflow()
        }
    }

    private func retreat() {
        if step == 0 { cancel() } else { step -= 1; model.reflow() }
    }

    private func cancel() {
        spec.onCancel(model.surfaceNote, form.feedbackDrafts)
    }

    /// Focus lands on the new step's first answer element shortly after it
    /// appears, and the answer region returns to the top.
    private func land() {
        guard landed != step else { return }
        landed = step
        focusedRow = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            FocusManager.shared.focusFirst()
        }
    }
}
