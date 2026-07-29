import AppKit
import SwiftUI

/// Pick (§5.2). One option from a set, or several.
///
/// The agent's words are inset and set to a bounded measure; the set itself
/// runs stem to stem, because the answer is the person's and it owns the
/// frame.
struct CaretChooseView: View {
    let spec: ChooseSpec

    @StateObject private var model = CaretSurfaceModel()
    @State private var selected: Set<Int> = []
    @State private var otherSelected = false
    @State private var otherText = ""
    @State private var focusedRow: Int?
    @State private var touched = false
    @State private var rowViews: [Int: NSView] = [:]
    @State private var didLand = false
    @Environment(\.caretPalette) private var palette

    private var multi: Bool { spec.allowMultiple }
    private var otherOrdinal: Int { spec.choices.count + 1 }

    /// Free text chosen but empty counts as nothing chosen. The text is not
    /// trimmed first, so a single space is an answer.
    private var answered: Bool {
        !selected.isEmpty || (otherSelected && !otherText.isEmpty)
    }

    private var chosenCount: Int {
        selected.count + ((otherSelected && !otherText.isEmpty) ? 1 : 0)
    }

    var body: some View {
        CaretFrame(
            kind: multi ? .pickMulti : .pick,
            title: spec.title,
            position: spec.position,
            model: model,
            minSurfaceWidth: CaretSkin.surfaceWidth(for: .choose),
            leadingAction: CaretActionSpec(label: "Cancel", role: .decline, key: "esc", run: decline),
            trailingAction: CaretActionSpec(label: "Done", role: .commit, key: "⏎",
                                            keyAvailable: answered, enabled: answered, run: commit),
            bindings: CaretBindings(canSubmit: { answered }, onSubmit: commit, onCancel: decline),
            noteCaption: { _ in "NOTE ON THIS DIALOG" },
            noteSubject: { _ in nil },
            onSnooze: spec.onSnooze,
            onAskDifferently: spec.onAskDifferently
        ) {
            VStack(alignment: .leading, spacing: 0) {
                CaretTitle(text: spec.title, suppressing: DialogManager.shared.getClientName())
                    .padding(.bottom, CaretStyle.u(8))
                CaretBody(raw: spec.body)
                    .padding(.bottom, CaretStyle.u(16))

                CaretSetHeader(multi: multi, count: chosenCount)
                    .padding(.bottom, CaretStyle.u(7))

                CaretChannel(centre: focusedRow) {
                    VStack(alignment: .leading, spacing: CaretStyle.u(2)) {
                        ForEach(Array(spec.choices.enumerated()), id: \.offset) { index, choice in
                            CaretRow(
                                ordinal: index + 1,
                                label: choice,
                                description: spec.descriptions?[safe: index],
                                chosen: selected.contains(index),
                                onActivate: { choose(index) },
                                onFocus: { if $0 { focusedRow = index } },
                                register: { view in rowViews[index] = view }
                            )
                            .id(index)
                        }

                        if spec.allowOther { otherRow }
                    }
                    .padding(.trailing, CaretStyle.u(2))
                }
                .accessibilityLabel(Text(multi
                    ? "Select one or more options. Use arrow keys to navigate, Space to select."
                    : "Select one option. Use arrow keys to navigate, Space to select."))

                if touched, !answered {
                    CaretHelper(text: helper)
                        .padding(.top, CaretStyle.u(12))
                }
            }
            .onAppear(perform: land)
        }
    }

    // MARK: - Free text

    /// §10.9: the free-text entry carries the same state model as any other
    /// option, with its field's own focus treatment layered on top. Its target
    /// covers the label line only, so clicking the field places a caret rather
    /// than toggling the row.
    private var otherRow: some View {
        CaretRow(
            ordinal: otherOrdinal,
            label: "Other",
            description: nil,
            chosen: otherSelected,
            onActivate: { chooseOther(focusField: true) },
            onFocus: { if $0 { focusedRow = otherOrdinal } },
            trailingContent: {
                VStack(alignment: .leading, spacing: CaretStyle.u(5)) {
                    CaretField(
                        text: $otherText,
                        placeholder: "Type your answer...",
                        onFocus: { focused in
                            model.editing = focused
                            if focused { focusedRow = otherOrdinal }
                        }
                    )
                    .frame(height: CaretStyle.u(19))
                    CaretFieldRule(focused: otherSelected, tone: otherSelected ? nil : palette.rail)
                }
                .padding(.top, CaretStyle.u(4))
                .onChange(of: otherText) { _, value in
                    // Typing any character chooses it.
                    if !value.isEmpty && !otherSelected { chooseOther(focusField: false) }
                    touched = true
                }
            }
        )
        .id(otherOrdinal)
    }

    private var helper: String {
        if otherSelected && otherText.isEmpty { return "Type your custom answer to continue" }
        return multi ? "Select at least one option to continue" : "Select an option to continue"
    }

    // MARK: - Choosing

    private func choose(_ index: Int) {
        touched = true
        if multi {
            if selected.contains(index) { selected.remove(index) } else { selected.insert(index) }
        } else if selected.contains(index) {
            // Choosing an already-chosen option deselects it, leaving the
            // question unanswered.
            selected.removeAll()
        } else {
            selected = [index]
            // In single mode a listed option clears the free-text choice. The
            // typed text stays visible; it is simply no longer the answer.
            otherSelected = false
        }
    }

    private func chooseOther(focusField: Bool) {
        touched = true
        if multi {
            otherSelected.toggle()
        } else {
            otherSelected = true
            selected.removeAll()
        }
    }

    // MARK: - Landing

    /// §4.5: focus lands on the first content element shortly after the
    /// surface appears — and on the preselected default when there is one, so
    /// commit is live on the first frame (§5.2).
    private func land() {
        guard !didLand else { return }
        didLand = true
        if let value = spec.defaultSelection,
           let index = spec.choices.firstIndex(of: value) {
            selected = [index]
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                if let view = rowViews[index] { FocusManager.shared.focus(view) }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                FocusManager.shared.focusFirst()
            }
        }
    }

    // MARK: - Outcomes

    private func commit() {
        let text = (otherSelected && !otherText.isEmpty) ? otherText : nil
        spec.onComplete(selected, text, model.surfaceNote)
    }

    private func decline() {
        spec.onCancel(model.surfaceNote)
    }
}
