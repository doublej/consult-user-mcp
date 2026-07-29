import SwiftUI

/// §3.9 — the per-question note control. Three states, and the has-note one is
/// the amber cursor again: the same mark that means "focus is here" on a row
/// means "something of yours is here" on a note. No note is a hollow slot;
/// hover only lifts the border.
struct BracketNoteControl: View {
    var hasNote: Bool
    var action: () -> Void

    @State private var isHovering = false

    private var border: Color {
        if hasNote { return BracketStyle.amber.opacity(0.55) }
        return isHovering ? BracketStyle.inkMuted : BracketStyle.line
    }

    var body: some View {
        RoundedRectangle(cornerRadius: BracketStyle.Radius.chip, style: .continuous)
            .strokeBorder(border, lineWidth: 1)
            .frame(width: 22, height: 22)
            .overlay(
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(hasNote ? BracketStyle.amber : BracketStyle.inkMuted.opacity(0.55))
                    .frame(width: 3, height: 10)
            )
            .contentShape(Rectangle())
            .onHover { isHovering = $0 }
            .gesture(DragGesture(minimumDistance: 0).onEnded { value in
                if value.translation.width.magnitude < 6, value.translation.height.magnitude < 6 {
                    action()
                }
            })
            .help(hasNote ? "Edit note" : "Add a note for the agent")
            .accessibilityLabel(hasNote ? "Edit note" : "Add a note for the agent")
    }
}
