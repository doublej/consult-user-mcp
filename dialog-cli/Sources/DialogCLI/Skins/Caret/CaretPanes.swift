import AppKit
import SwiftUI

// MARK: - Annotation

/// The annotation editor (§3.6), drawn inside the surface.
///
/// It is an expansion rather than a panel beside the surface, which §3.6
/// permits explicitly and which means §2.2's width rule and §2.4's anchor rule
/// do not apply to it: the surface's width never changes, and the note opens
/// downward from the fixed top edge.
struct CaretNotePanel: View {
    @ObservedObject var model: CaretSurfaceModel
    let caption: String
    let subject: String?

    @State private var clearFocused = false
    @State private var closeFocused = false
    @Environment(\.caretPalette) private var palette

    private var key: String { model.openNote ?? "" }
    private var empty: Bool { !model.hasNote(key) }

    var body: some View {
        VStack(alignment: .leading, spacing: CaretStyle.u(8)) {
            HStack(alignment: .firstTextBaseline, spacing: CaretStyle.u(12)) {
                Text(caption)
                    .font(Font(CaretStyle.monoTiny))
                    .kerning(CaretStyle.monoTiny.pointSize * CaretStyle.railTracking)
                    .foregroundStyle(palette.caret)
                Spacer(minLength: CaretStyle.u(12))
                paneAction("Clear", enabled: !empty, focused: $clearFocused) {
                    model.noteDrafts[key] = ""
                }
                paneAction("Close", enabled: true, focused: $closeFocused) {
                    model.openNote = nil
                    model.editing = false
                    model.reflow()
                }
            }

            if let subject, !subject.isEmpty {
                CaretProseText(
                    raw: subject,
                    font: CaretStyle.label,
                    emphasis: NSFont.systemFont(ofSize: CaretStyle.u(10.5), weight: .bold),
                    colour: palette.context,
                    selectable: false
                )
            }

            CaretNoteEditor(text: model.binding(key), onFocus: { model.editing = $0 })
                .frame(maxWidth: .infinity, alignment: .topLeading)
                // A range, not a pin. Pinned, the editor could not give way
                // when the question above it grew, so the surface ran out of
                // room at the bottom and the pane was drawn straight through
                // Cancel and Next — the two controls a person needs most when
                // a surface has gone wrong. It scrolls, so a shorter editor
                // costs a line of visible draft; a covered footer costs the
                // way out.
                .frame(minHeight: CaretStyle.u(40), maxHeight: CaretStyle.u(62))
            Rectangle()
                .fill(palette.caret)
                .frame(height: CaretStyle.caretWidth)
        }
        .accessibilityLabel(Text(caption))
    }

    private func paneAction(_ label: String, enabled: Bool, focused: Binding<Bool>, run: @escaping () -> Void) -> some View {
        Text(label)
            .font(Font(CaretStyle.monoTiny))
            .kerning(CaretStyle.monoTiny.pointSize * CaretStyle.railTracking)
            .foregroundStyle(enabled ? (focused.wrappedValue ? palette.ink : palette.inkMuted) : palette.inkMuted.opacity(0.45))
            .frame(width: CaretStyle.width(label.uppercased(), font: CaretStyle.monoTiny, tracking: CaretStyle.railTracking) + CaretStyle.u(10),
                   height: CaretStyle.u(15))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(focused.wrappedValue ? palette.caret : Color.clear)
                    .frame(height: CaretStyle.hair)
            }
            .contentShape(Rectangle())
            .overlay(
                CaretTarget(isContent: false, isEnabled: enabled, takesReturn: true, onActivate: run,
                            onFocusChange: { focused.wrappedValue = $0 })
            )
            .help(label == "Close" ? "Close (note is preserved)" : "Clear this note")
    }
}

// MARK: - Report

/// The two-step report flow (§3.12), drawn over a picture of the surface as it
/// looked when the flow opened. Everything beneath is inert and every key
/// except Escape belongs to the flow.
struct CaretReportFlow: View {
    @ObservedObject var model: CaretSurfaceModel
    @State private var cancelFocused = false
    @State private var nextFocused = false
    @Environment(\.caretPalette) private var palette

    private var describable: Bool {
        !model.reportText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            if let data = model.reportShot, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: CaretStyle.u(6))
            }
            palette.veil
            content
        }
        .clipShape(RoundedRectangle(cornerRadius: CaretStyle.windowRadius, style: .continuous))
    }

    @ViewBuilder
    private var content: some View {
        if model.reportStep == 1 {
            step(
                badge: "REPORT",
                title: "Report Issue",
                body: "Describe the problem below.",
                hint: "⏎ next",
                leading: ("Cancel", true, { close() }),
                trailing: ("Next →", describable, { advance() })
            ) {
                VStack(alignment: .leading, spacing: CaretStyle.u(7)) {
                    Text("What happened?")
                        .font(Font(CaretStyle.monoTiny))
                        .kerning(CaretStyle.monoTiny.pointSize * CaretStyle.railTracking)
                        .foregroundStyle(palette.inkMuted)
                    CaretField(
                        text: $model.reportText,
                        placeholder: "Briefly describe the issue...",
                        autofocus: true,
                        onFocus: { model.editing = $0 },
                        onEnter: { if describable { advance() } }
                    )
                    .frame(height: CaretStyle.u(20))
                    CaretFieldRule(focused: true)
                }
                .frame(maxWidth: CaretStyle.u(400), alignment: .leading)
            }
        } else {
            step(
                badge: "REPORT 2/2",
                title: "Save Screenshot?",
                body: "Can we save a screenshot of this dialog to your clipboard? You can paste it directly into the GitHub issue with ⌘V.",
                hint: "⏎ copy & open",
                leading: ("Skip", true, { file(copy: false) }),
                trailing: ("Yes, Copy Screenshot", true, { file(copy: true) })
            ) { EmptyView() }
        }
    }

    @ViewBuilder
    private func step<Inner: View>(
        badge: String,
        title: String,
        body: String,
        hint: String,
        leading: (String, Bool, () -> Void),
        trailing: (String, Bool, () -> Void),
        @ViewBuilder inner: () -> Inner
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(badge)
                .font(Font(CaretStyle.mono))
                .kerning(CaretStyle.mono.pointSize * CaretStyle.railTracking)
                .foregroundStyle(palette.caret)
            Text(title)
                .font(Font(CaretStyle.statement))
                .kerning(CaretStyle.statement.pointSize * CaretStyle.displayTracking)
                .foregroundStyle(palette.ink)
                .padding(.top, CaretStyle.u(12))
            Text(body)
                .font(Font(CaretStyle.body))
                .foregroundStyle(palette.context)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: CaretStyle.u(400), alignment: .leading)
                .padding(.top, CaretStyle.u(6))

            inner().padding(.top, CaretStyle.u(20))

            Spacer(minLength: CaretStyle.u(22))

            HStack(alignment: .bottom, spacing: CaretStyle.u(24)) {
                CaretAction(label: leading.0, role: .decline, key: "esc",
                            enabled: leading.1, trailing: false, action: leading.2)
                Spacer(minLength: CaretStyle.u(16))
                CaretAction(label: trailing.0, role: .commit, key: "⏎",
                            keyAvailable: trailing.1, enabled: trailing.1,
                            trailing: true, autofocus: model.reportStep == 2,
                            action: trailing.2)
            }
            .accessibilityHint(Text(hint))
        }
        .padding(.horizontal, CaretStyle.caretRail + CaretStyle.gutter)
        .padding(.vertical, CaretStyle.u(22))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func close() {
        model.reportStep = 0
        model.reflow()
    }

    private func advance() {
        model.reportStep = 2
        model.reflow()
    }

    private func file(copy: Bool) {
        let text = model.reportText.trimmingCharacters(in: .whitespacesAndNewlines)
        GitHubReporter.openIssue(description: text, screenshotData: model.reportShot, copyToClipboard: copy)
        model.reportStep = 0
        model.reflow()
    }
}
