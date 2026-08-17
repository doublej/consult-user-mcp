import SwiftUI

/// §5.2 — one option from a list, or several.
///
/// Three things tell the person which mode they are in before they touch
/// anything: the kind label (`PICK` / `PICK-MULTI`), the indicator's **form**
/// (disc / square), and the status line (`select one` / `select any`). Selection
/// and focus never share a channel — see `BracketOptionRow`.
struct BracketChooseView: View {
    let spec: ChooseSpec

    @StateObject private var clock = CooldownClock()
    @StateObject private var caret = CaretTracker()
    @State private var selected: Set<Int> = []
    @State private var otherSelected = false
    @State private var otherText = ""
    @State private var didInteract = false
    /// Set when Other is chosen, so the caret lands in the field the choice
    /// exists to fill rather than leaving the next keystroke to the router.
    @State private var focusOtherField = false

    private var otherIndex: Int { spec.choices.count }

    private var isAnswered: Bool {
        // §3.13 — "Other" selected but empty counts as nothing selected.
        // The text is deliberately not trimmed: a single space is an answer.
        !selected.isEmpty || (otherSelected && !otherText.isEmpty)
    }

    private var statusLine: String {
        guard spec.allowMultiple else { return "select one" }
        let count = selected.count + (otherSelected ? 1 : 0)
        return count == 0 ? "select any" : "\(count) selected"
    }

    private var helperText: String {
        spec.allowMultiple
            ? "Select at least one option to continue"
            : "Select an option to continue"
    }

    var body: some View {
        DialogContainer(
            bindings: DialogKeyBindings(
                canSubmit: { isAnswered },
                onSubmit: { submit() },
                onCancel: { spec.onCancel(BracketNote.current()) }
            ),
            currentDialogType: "choose",
            dialogPosition: spec.position,
            contentMinWidth: BracketSkin.width(for: .choose),
            globalFeedbackSubject: FeedbackSubject(kind: .question, text: spec.body),
            onAskDifferently: spec.onAskDifferently
        ) { controller in
            BracketSurface {
                VStack(alignment: .leading, spacing: 0) {
                    BracketHeader(
                        typeLabel: spec.allowMultiple ? "PICK-MULTI" : "PICK",
                        title: spec.title
                    )
                    .padding(.bottom, 12)

                    BracketBody(text: spec.body)
                        .padding(.bottom, 14)

                    HStack {
                        BracketStatusLine(text: statusLine)
                        Spacer(minLength: 8)
                    }
                    .padding(.bottom, 9)

                    AutoSizingScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(spec.choices.enumerated()), id: \.offset) { index, choice in
                                BracketOptionRow(
                                    ordinal: index + 1,
                                    label: choice,
                                    detail: description(at: index),
                                    isSelected: selected.contains(index),
                                    isMultiSelect: spec.allowMultiple,
                                    onTap: { toggle(index) }
                                )
                            }

                            if spec.allowOther {
                                otherRow
                            }
                        }
                        .padding(.trailing, 2)
                    }
                    .accessibilityLabel(
                        spec.allowMultiple
                            ? "Select one or more options. Use arrow keys to navigate, Space to select."
                            : "Select one option. Use arrow keys to navigate, Space to select."
                    )

                    // §10.14 — explain the dead primary, but only once the
                    // person has actually touched the list.
                    if didInteract && !isAnswered {
                        BracketHelperLine(text: helperText)
                            .padding(.top, 12)
                    }

                    Spacer(minLength: 18)

                    BracketFooter(
                        expandedTool: controller.expandedTool,
                        hasNote: controller.hasFeedback(.global),
                        currentShape: spec.allowMultiple ? "pick-multi" : "pick",
                        readiness: clock.progress,
                        hints: [("↑↓", "navigate"), ("Space", "select"), ("⏎", "done")],
                        isEditing: caret.isEditing,
                        isPaneOpen: controller.currentTarget != nil,
                        onSnooze: spec.onSnooze,
                        onOpenFeedback: { controller.openFeedback(.global) },
                        onAskDifferently: spec.onAskDifferently,
                        secondary: ("Cancel", { spec.onCancel(BracketNote.current()) }),
                        primary: ("Done", isAnswered, { submit() })
                    )
                    .padding(.top, 4)
                }
                .padding(.horizontal, BracketStyle.Space.gutter)
                .padding(.top, 16)
                .padding(.bottom, 14)
            }
            .onAppear {
                clock.start()
                applyDefaultSelection()
            }
        }
    }

    /// §3.13 — the "Other" row is an ordinary row with its field layered inside,
    /// not the weaker variant §10.9 describes.
    private var otherRow: some View {
        BracketOptionRow(
            ordinal: otherIndex + 1,
            label: "Other",
            detail: nil,
            isSelected: otherSelected,
            isMultiSelect: spec.allowMultiple,
            onTap: { toggleOther(force: true, focusField: true) },
            accessory: {
                BracketTextField(
                    placeholder: "Type your answer...",
                    text: $otherText,
                    autofocus: focusOtherField,
                    onFocusChange: { caret.isEditing = $0 }
                )
                .padding(.top, 6)
                .onChange(of: otherText) { value in
                    // Typing any character auto-selects the row.
                    if !value.isEmpty && !otherSelected { toggleOther(force: true) }
                    didInteract = true
                }
            }
        )
    }

    private func description(at index: Int) -> String? {
        guard let descriptions = spec.descriptions, index < descriptions.count else { return nil }
        let text = descriptions[index]
        return text.isEmpty ? nil : text
    }

    private func toggle(_ index: Int) {
        didInteract = true
        if spec.allowMultiple {
            if selected.contains(index) { selected.remove(index) } else { selected.insert(index) }
        } else {
            selected = selected.contains(index) ? [] : [index]
            if !selected.isEmpty { otherSelected = false }
        }
    }

    private func toggleOther(force: Bool, focusField: Bool = false) {
        didInteract = true
        if spec.allowMultiple {
            otherSelected = force ? true : !otherSelected
        } else {
            otherSelected = true
            selected = []
        }
        if focusField && otherSelected { focusOtherField = true }
    }

    private func applyDefaultSelection() {
        guard let value = spec.defaultSelection,
              let index = spec.choices.firstIndex(of: value) else { return }
        selected = [index]
    }

    private func submit() {
        guard isAnswered else { return }
        let custom = (otherSelected && !otherText.isEmpty) ? otherText : nil
        spec.onComplete(selected, custom, BracketNote.current())
    }
}
