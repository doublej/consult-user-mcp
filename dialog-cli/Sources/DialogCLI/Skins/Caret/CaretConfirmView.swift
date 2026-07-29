import AppKit
import SwiftUI

/// Confirm (§5.1). Two ways out, nothing focused on open, commit never
/// unavailable — so on the first frame the caret rail is empty and the only
/// amber on the surface is the commit arm, which is exactly the promise that
/// Return will work.
struct CaretConfirmView: View {
    let spec: ConfirmSpec
    @StateObject private var model = CaretSurfaceModel()

    var body: some View {
        CaretFrame(
            kind: .confirm,
            title: spec.title,
            position: spec.position,
            model: model,
            leadingAction: CaretActionSpec(label: spec.cancelLabel, role: .decline, key: "esc", run: decline),
            trailingAction: CaretActionSpec(label: spec.confirmLabel, role: .commit, key: "⏎", run: commit),
            bindings: CaretBindings(canSubmit: { true }, onSubmit: commit, onCancel: decline),
            noteCaption: { _ in "NOTE ON THIS DIALOG" },
            noteSubject: { _ in nil },
            onSnooze: spec.onSnooze,
            onAskDifferently: spec.onAskDifferently
        ) {
            CaretChannel {
                VStack(alignment: .leading, spacing: CaretStyle.u(10)) {
                    CaretTitle(text: spec.title, suppressing: "Confirmation")
                    CaretBody(raw: spec.body)
                }
            }
        }
    }

    private func commit() {
        spec.onConfirm(model.surfaceNote)
    }

    /// §4.8: declining with a note drafted is a redirection, not a cancel.
    private func decline() {
        spec.onCancel(model.surfaceNote)
    }
}
