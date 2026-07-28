import SwiftUI

struct AltChooseView: View {
    let spec: ChooseSpec

    @State private var selectedIndices: Set<Int>
    @State private var focusedIndex: Int
    @State private var otherSelected = false
    @State private var otherText = ""

    init(spec: ChooseSpec) {
        self.spec = spec
        if let value = spec.defaultSelection, let index = spec.choices.firstIndex(of: value) {
            _selectedIndices = State(initialValue: [index])
            _focusedIndex = State(initialValue: index)
        } else {
            _selectedIndices = State(initialValue: [])
            _focusedIndex = State(initialValue: 0)
        }
    }

    private var dialogType: String { spec.allowMultiple ? "pick-multi" : "pick" }

    private var hasValidSelection: Bool {
        QuestionAnswer.isAnswered(
            answer: .choices(selectedIndices),
            otherSelected: otherSelected,
            otherText: otherText
        )
    }

    private var selectionSummary: String {
        guard spec.allowMultiple else { return "select one" }
        let count = selectedIndices.count + (otherSelected ? 1 : 0)
        return count == 0 ? "select any" : "\(count) selected"
    }

    var body: some View {
        DialogContainer(
            bindings: DialogKeyBindings(
                canSubmit: { hasValidSelection },
                onSubmit: { submit() },
                onCancel: { spec.onCancel(AltFeedback.globalDraft()) }
            ),
            currentDialogType: dialogType,
            dialogPosition: spec.position,
            globalFeedbackSubject: FeedbackSubject(kind: .dialog, text: spec.body),
            onAskDifferently: spec.onAskDifferently
        ) { controller in
            AltPanel {
                AltHeader(kicker: dialogType, title: spec.title, body: spec.body)

                HStack {
                    Text(selectionSummary)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.Colors.textMuted)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, AltMetrics.contentPadding)
                .padding(.top, 12)
                .padding(.bottom, 6)

                choicesList
                    .clipped()

                DialogToolbar(
                    expandedTool: controller.expandedTool,
                    currentDialogType: dialogType,
                    hasFeedback: controller.hasFeedback(.global),
                    onSnooze: spec.onSnooze,
                    onOpenFeedback: { controller.openFeedback(.global) },
                    onAskDifferently: spec.onAskDifferently
                )

                AltActionBar(
                    hints: [
                        KeyboardHint(key: "↑↓", label: "navigate"),
                        KeyboardHint(key: "Space", label: "select"),
                        KeyboardHint(key: "⏎", label: "done"),
                    ] + KeyboardHint.toolbarHints,
                    actions: [
                        .init("Cancel", action: { spec.onCancel(AltFeedback.globalDraft()) }),
                        .init("Done", isPrimary: true, isDisabled: !hasValidSelection, showReturnHint: true, action: { submit() }),
                    ]
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(spec.body))
            .accessibilityHint(spec.allowMultiple
                ? "Select one or more options. Use arrow keys to navigate, Space to select."
                : "Select one option. Use arrow keys to navigate, Space to select.")
        }
    }

    private var choicesList: some View {
        ScrollViewReader { proxy in
            AutoSizingScrollView {
                VStack(spacing: 6) {
                    ForEach(Array(spec.choices.enumerated()), id: \.offset) { index, choice in
                        AltChoiceRow(index: index) {
                            FocusableChoiceCard(
                                title: choice,
                                subtitle: spec.descriptions?[safe: index],
                                isSelected: selectedIndices.contains(index),
                                isMultiSelect: spec.allowMultiple,
                                onTap: { toggleSelection(at: index) }
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(minHeight: 46)
                        }
                        .id(index)
                    }

                    if spec.allowOther {
                        AltChoiceRow(index: spec.choices.count) {
                            OtherChoiceCard(
                                isSelected: otherSelected,
                                isMultiSelect: spec.allowMultiple,
                                text: $otherText,
                                onTap: { toggleOther() }
                            )
                        }
                        .id(spec.choices.count)
                    }
                }
                .padding(.horizontal, AltMetrics.contentPadding)
                .padding(.bottom, 10)
            }
            .onChange(of: focusedIndex) { newIndex in
                withAnimation(.easeOut(duration: Theme.Animation.card)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    private func submit() {
        spec.onComplete(selectedIndices, otherSelected ? otherText : nil, AltFeedback.globalDraft())
    }

    private func toggleSelection(at index: Int) {
        let result = QuestionAnswer.toggling(
            choice: index,
            in: .choices(selectedIndices),
            otherSelected: otherSelected,
            multiSelect: spec.allowMultiple
        )
        if case .choices(let set) = result.answer { selectedIndices = set }
        otherSelected = result.otherSelected
    }

    private func toggleOther() {
        let result = QuestionAnswer.togglingOther(
            in: .choices(selectedIndices),
            otherSelected: otherSelected,
            multiSelect: spec.allowMultiple
        )
        if case .choices(let set) = result.answer { selectedIndices = set }
        otherSelected = result.otherSelected
    }
}

// MARK: - Numbered Row

/// Monospaced ordinal gutter beside each option — Classic has no gutter.
struct AltChoiceRow<Content: View>: View {
    let index: Int
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(String(format: "%02d", index + 1))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.Colors.textMuted)
                .frame(width: 18, alignment: .trailing)
                .padding(.top, 16)

            content
        }
    }
}
