import AppKit
import SwiftUI

// MARK: - Annotation

/// The note pane (§3.6). It attaches beside the surface with a fixed extent,
/// which is the one thing allowed to change the surface's width (§2.2), and it
/// opens away from the wall the surface is anchored against (§2.4).
struct CaretNotePane: View {
    @ObservedObject var model: CaretSurfaceModel
    let caption: String
    let subject: String?
    let onLeading: Bool

    @State private var clearFocused = false
    @State private var closeFocused = false
    @Environment(\.caretPalette) private var palette

    private var key: String { model.openNote ?? "" }
    private var empty: Bool { !model.hasNote(key) }

    var body: some View {
        VStack(alignment: .leading, spacing: CaretStyle.u(10)) {
            Text(caption)
                .font(Font(CaretStyle.monoTiny))
                .kerning(CaretStyle.monoTiny.pointSize * CaretStyle.railTracking)
                .foregroundStyle(palette.caret)

            if let subject, !subject.isEmpty {
                CaretProseText(
                    raw: subject,
                    font: CaretStyle.label,
                    emphasis: NSFont.systemFont(ofSize: CaretStyle.u(10.5), weight: .bold),
                    colour: palette.context,
                    measure: CaretStyle.paneWidth - CaretStyle.u(36),
                    selectable: false
                )
            }

            CaretNoteEditor(text: model.binding(key), onFocus: { model.editing = $0 })
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .frame(minHeight: CaretStyle.u(90))

            HStack(spacing: CaretStyle.u(16)) {
                paneAction("Clear", enabled: !empty, focused: $clearFocused) {
                    model.noteDrafts[key] = ""
                }
                Spacer(minLength: 0)
                paneAction("Close", enabled: true, focused: $closeFocused) {
                    model.openNote = nil
                    model.reflow(resizingWidth: true)
                }
            }
        }
        .padding(.horizontal, CaretStyle.u(18))
        .padding(.vertical, CaretStyle.u(16))
        .frame(maxHeight: .infinity, alignment: .top)
        .background(palette.channel)
        .overlay(alignment: onLeading ? .trailing : .leading) {
            Rectangle().fill(palette.rail).frame(width: CaretStyle.hair)
        }
        .accessibilityLabel(Text(caption))
    }

    private func paneAction(_ label: String, enabled: Bool, focused: Binding<Bool>, run: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: CaretStyle.u(5)) {
            Text(label)
                .font(Font(CaretStyle.label))
                .foregroundStyle(enabled ? (focused.wrappedValue ? palette.ink : palette.inkSecond) : palette.inkMuted.opacity(0.5))
            Rectangle()
                .fill(enabled ? (focused.wrappedValue ? palette.caret : palette.rail) : palette.rail.opacity(0.5))
                .frame(height: focused.wrappedValue ? CaretStyle.caretWidth : CaretStyle.hair)
        }
        .frame(width: CaretStyle.width(label, font: CaretStyle.label) + CaretStyle.u(6))
        .contentShape(Rectangle())
        .overlay(
            CaretTarget(isContent: false, isEnabled: enabled, takesReturn: true, onActivate: run,
                        onFocusChange: { focused.wrappedValue = $0 })
        )
        .help(label == "Close" ? "Close pane (note is preserved)" : "Clear this note")
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
