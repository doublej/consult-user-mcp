import AppKit
import SwiftUI

/// Text (§5.3). One typed answer, optionally masked.
///
/// The field runs stem to stem like every other answer control, under a rule
/// that is the same hairline the frame's arms are drawn with — a field is a
/// short piece of the same structure.
struct CaretTextInputView: View {
    let spec: TextInputSpec

    @StateObject private var model = CaretSurfaceModel()
    @State private var text: String = ""
    @State private var focused = false
    @State private var didLand = false
    @Environment(\.caretPalette) private var palette

    var body: some View {
        CaretFrame(
            kind: spec.isHidden ? .secret : .text,
            title: spec.title,
            position: spec.position,
            model: model,
            minSurfaceWidth: CaretSkin.surfaceWidth(for: .textInput),
            leadingAction: CaretActionSpec(label: "Cancel", role: .decline, key: "esc", run: decline),
            // The field is always in a submittable state; an empty submit
            // returns an empty string.
            trailingAction: CaretActionSpec(label: "Submit", role: .commit, key: "⏎", run: commit),
            bindings: CaretBindings(canSubmit: { true }, onSubmit: commit, onCancel: decline),
            noteCaption: { _ in "NOTE ON THIS DIALOG" },
            noteSubject: { _ in nil },
            onSnooze: spec.onSnooze,
            onAskDifferently: spec.onAskDifferently
        ) {
            VStack(alignment: .leading, spacing: 0) {
                CaretChannel {
                    VStack(alignment: .leading, spacing: CaretStyle.u(10)) {
                        CaretTitle(text: spec.title, suppressing: "Input")
                        CaretBody(raw: spec.body)
                    }
                }

                VStack(alignment: .leading, spacing: CaretStyle.u(7)) {
                    HStack(spacing: CaretStyle.u(10)) {
                        CaretField(
                            text: $text,
                            // §5.3 has no placeholder at all, which leaves an
                            // empty prefill as a blank box. §7.5 allows one.
                            placeholder: spec.isHidden ? "••••••••" : "Type your answer...",
                            masked: spec.isHidden,
                            onFocus: { focused = $0; model.editing = $0 }
                        )
                        .frame(height: CaretStyle.u(21))

                        // §10.13: a masked field cannot be verified, and §3.11
                        // forbids ever revealing it — so the one thing that can
                        // be said safely is said.
                        if spec.isHidden && model.capsLock {
                            Text("CAPS LOCK")
                                .font(Font(CaretStyle.monoTiny))
                                .kerning(CaretStyle.monoTiny.pointSize * CaretStyle.railTracking)
                                .foregroundStyle(palette.danger)
                                .fixedSize()
                        }
                    }
                    CaretFieldRule(focused: focused)
                }
                .padding(.top, CaretStyle.u(20))
            }
            .onAppear(perform: land)
        }
    }

    /// §5.3: the field takes focus shortly after the surface appears, so the
    /// person can type immediately, and a prefilled value arrives selected.
    private func land() {
        guard !didLand else { return }
        didLand = true
        text = spec.defaultValue
        model.watchCaps = spec.isHidden
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            FocusManager.shared.focusFirst()
        }
    }

    private func commit() {
        // No trimming, no validation, no length limit.
        spec.onSubmit(text, model.surfaceNote)
    }

    private func decline() {
        spec.onCancel(model.surfaceNote)
    }
}
