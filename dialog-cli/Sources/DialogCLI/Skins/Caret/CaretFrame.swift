import AppKit
import SwiftUI

/// What the surface hands the key router.
struct CaretBindings {
    var canSubmit: () -> Bool = { false }
    var onSubmit: () -> Void = {}
    var onCancel: () -> Void = {}
    var onArrowLeft: (() -> Bool)? = nil
    var onArrowRight: (() -> Bool)? = nil
    var onArrowUp: (() -> Bool)? = nil
    var onArrowDown: (() -> Bool)? = nil
}

/// The container. Everything below the skin seam belongs to this layer, so
/// this is where the key router is installed and torn down, where the Escape
/// stack is defined, where the cooldown is watched, and where the annotation
/// pane and the report flow live.
struct CaretFrame<Content: View>: View {
    let kind: CaretKind
    let title: String?
    let position: DialogPosition
    @ObservedObject var model: CaretSurfaceModel
    /// The floor this kind's window is sized to. The surface adopts it as its
    /// own ideal width so the two never disagree.
    var minSurfaceWidth: CGFloat = 440
    var leadingAction: CaretActionSpec?
    var trailingAction: CaretActionSpec?
    var counter: String?
    var bindings = CaretBindings()
    var noteCaption: (String) -> String = { _ in "NOTE ON THIS DIALOG" }
    var noteSubject: (String) -> String? = { _ in nil }
    var onSnooze: (Int) -> Void = { _ in }
    var onAskDifferently: (String) -> Void = { _ in }
    @ViewBuilder var content: () -> Content

    @Environment(\.caretPalette) private var palette
    @ObservedObject private var expiry = DialogExpiry.shared
    @State private var monitor: KeyboardNavigationMonitor?
    @State private var shapeKeys: CaretShapeKeyMonitor?
    @State private var toolFocus: String?
    @State private var leadingFocused = false
    @State private var trailingFocused = false
    /// The width of the box the window measured this surface into, once it is
    /// known. See `surface`.
    @State private var measuredWidth: CGFloat?

    /// One inset all round, so the mark's corners nest concentrically inside
    /// the window's own radius.
    private var inset: CGFloat { CaretStyle.caretRail / 2 }
    private var armInset: CGFloat { CaretStyle.u(9) }

    var body: some View {
        surface
            .background(palette.window)
            .clipShape(RoundedRectangle(cornerRadius: CaretStyle.windowRadius, style: .continuous))
            .environment(\.caretPalette, palette)
            .overlay(reportFlow)
            .overlay {
                if expiry.isExpired {
                    ExpiredOverlay(onClose: { expiry.closeExpiredDialog() })
                }
            }
            .onAppear(perform: appear)
            .onDisappear { monitor = nil; shapeKeys = nil; model.stopClock() }
            .onReceive(NotificationCenter.default.publisher(for: .cooldownDidChange)) { _ in model.startClock() }
    }

    // MARK: - The surface itself

    private var surface: some View {
        VStack(spacing: 0) {
            topBar
            if model.trayOpen { snoozeTray.caretReveal() }
            if model.shapesOpen { shapeList.caretReveal() }

            content()
                .padding(.horizontal, CaretStyle.caretRail + CaretStyle.gutter)
                .padding(.top, CaretStyle.u(18))
                .padding(.bottom, CaretStyle.u(22))
                .environment(\.caretInert, model.inert)

            // Above the note panel and below the question: an attached image
            // is part of the answer, where a note is an aside about it.
            CaretAttachmentStrip()

            // Collapsible to nothing on purpose. While the window is still
            // travelling to its new height the frame is briefly shorter than
            // the content; a gap that can give way absorbs that, where a
            // floored one would push the lower arms outside the clip and let
            // them slide back in.
            if model.openNote != nil { notePanel.caretReveal() }

            Spacer(minLength: 0)

            if leadingAction != nil || trailingAction != nil {
                // Stated, so it is counted. A row whose height the measurement
                // misses ends up drawn below the window's own bottom edge.
                actionBar.frame(height: CaretStyle.u(22))
            }
        }
        .padding(.top, inset + CaretStyle.u(10))
        .padding(.bottom, inset + CaretStyle.u(18))
        // A ceiling as well as a floor. Nothing above this stops a window
        // growing: an option whose description happens not to break — a path,
        // an identifier — is measured unwrapped, and the surface would ask for
        // every point of it. A 1300-point dialog for one long line is not a
        // dialog. Past this the line wraps instead.
        .frame(minWidth: minSurfaceWidth, maxWidth: CaretStyle.u(660), alignment: .top)
        // §2.2 measured once, and then held to it.
        //
        // Until the window exists the surface asks for its ideal width, which
        // is what the two-pass measurement reads. From the moment the box is
        // known the surface is pinned to it and stops asking. That is the whole
        // point: the window's width is fixed for life, so a surface that went
        // on recomputing an ideal would keep changing its mind inside a window
        // that cannot follow — and, being fixed-size, would be *centred* on
        // each new answer, which is the entire jitter. Every later change of
        // mind is now ignored: the annotation key growing from a letter to a
        // chord, the form's labels changing at each step, the note panel's own
        // caption row. Only the height still reflows.
        .frame(width: measuredWidth)
        // Width is held; height is not. A window has a floor of its own, so a
        // short surface is put in a box taller than it asks for — and the frame
        // has to reach the bottom of that box, not stop halfway down it with
        // the ways out stranded in the middle. Letting the height give means
        // the `Spacer` above the action bar takes up whatever the box has
        // spare, so the top stays where it is and only the gap grows.
        .fixedSize(horizontal: measuredWidth == nil, vertical: false)
        .coordinateSpace(name: CaretSpace.surface)
        .onPreferenceChange(CaretFocusKey.self) { rect in model.focusRect = rect }
        .overlay(
            CaretRails(
                topLeading: topLeadingArm,
                topTrailing: topTrailingArm,
                bottomLeading: arm(leadingAction, focused: leadingFocused),
                bottomTrailing: arm(trailingAction, focused: trailingFocused),
                focusRect: model.focusRect,
                cooldown: model.cooldown,
                dimmed: model.inert
            )
        )
        .background(palette.window)
        // Pinned to the corner the window itself is pinned to.
        //
        // The box this sits in is animated to its new size over 0.2s while the
        // surface, being fixed-size, already has its final one. A fixed-size
        // view that refuses the size it is offered is *centred* in it by
        // default, so for the whole of that 0.2s the surface would be offset by
        // half the difference and would slide into place as the box caught up —
        // which is the whole of the jitter: every arm, every line and the
        // question itself travelling while the window travels. Anchored here it
        // simply stands still and the window grows away from it, downward from
        // a top edge that never moves.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            GeometryReader { box in
                Color.clear
                    .onAppear { adopt(box.size.width) }
                    .onChange(of: box.size.width) { _, width in adopt(width) }
            }
        )
    }

    /// Takes the width of the box the window put this surface in. Runs after
    /// layout, never during it.
    private func adopt(_ width: CGFloat) {
        guard width > 1, measuredWidth != width else { return }
        measuredWidth = width
    }

    // MARK: - Top arms

    private var badgeText: String {
        var parts = [kind.badge]
        if let project = DialogManager.shared.getProjectName() { parts.append(project) }
        return parts.joined(separator: " · ")
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: CaretStyle.u(20)) {
            // §3.2: the project's last segment, its full path on hover, and
            // nothing at all when the caller supplied none.
            Text(badgeText)
                .font(Font(CaretStyle.mono))
                .kerning(CaretStyle.mono.pointSize * CaretStyle.railTracking)
                .foregroundStyle(palette.inkMuted)
                .lineLimit(1)
                .fixedSize()
                .padding(.leading, armInset)
                .help(DialogManager.shared.getProjectPath() ?? "")

            Spacer(minLength: 0)

            if kind.interactive {
                tools.padding(.trailing, armInset)
            } else if let counter {
                Text(counter)
                    .font(Font(CaretStyle.mono))
                    .kerning(CaretStyle.mono.pointSize * CaretStyle.railTracking)
                    .foregroundStyle(palette.inkMuted)
                    .fixedSize()
                    .padding(.trailing, armInset)
            }
        }
        .padding(.horizontal, inset)
        .frame(height: CaretStyle.u(16))
    }

    private var tools: some View {
        HStack(spacing: CaretStyle.u(14)) {
            CaretToolMark(
                key: "S", keyLive: model.lettersLive, name: "SNOOZE",
                help: "Ask me again later", open: model.trayOpen,
                focused: toolFocus == "S", focusLift: 3,
                onFocus: { toolFocus = $0 ? "S" : nil }
            ) {
                model.shapesOpen = false
                model.trayOpen.toggle()
                model.reflow()
            }
            CaretToolMark(
                key: model.editing ? "⌘F" : "F", keyLive: model.editing ? model.chordLive : model.lettersLive,
                reserving: "⌘F",
                name: "NOTE", help: "Write a note for the agent",
                open: model.openNote != nil, marked: model.anyNote,
                focused: toolFocus == "F", focusLift: 2,
                onFocus: { toolFocus = $0 ? "F" : nil }
            ) {
                model.openNote = ""
                model.reflow()
            }
            CaretToolMark(
                key: "A", keyLive: model.lettersLive, name: "RESHAPE",
                help: "Ask this a different way", open: model.shapesOpen,
                focused: toolFocus == "A", focusLift: 1,
                onFocus: { toolFocus = $0 ? "A" : nil }
            ) {
                model.trayOpen = false
                model.shapesOpen.toggle()
                model.reflow()
            }
            CaretToolMark(
                key: nil, keyLive: true, name: "REPORT",
                help: "Report a bug or suggestion",
                focused: toolFocus == "R", onFocus: { toolFocus = $0 ? "R" : nil },
                action: openReport
            )
        }
    }

    private var toolsWidth: CGFloat {
        guard kind.interactive else {
            guard let counter else { return 0 }
            return CaretStyle.width(counter, font: CaretStyle.mono, tracking: CaretStyle.railTracking)
        }
        // The chord, always — the row's width cannot depend on which name the
        // annotation key currently goes by.
        let marks: [(String?, String)] = [("S", "SNOOZE"), ("⌘F", "NOTE"), ("A", "RESHAPE"), (nil, "REPORT")]
        let widths = marks.map { CaretToolMark.width(key: $0.0, name: $0.1) }
        return widths.reduce(0, +) + CGFloat(marks.count - 1) * CaretStyle.u(14)
    }

    private var topLeadingArm: CGFloat {
        armInset + CaretStyle.width(badgeText, font: CaretStyle.mono, tracking: CaretStyle.railTracking) + CaretStyle.u(10)
    }

    private var topTrailingArm: CGFloat {
        armInset + toolsWidth + CaretStyle.u(10)
    }

    /// The lower corners carry the ways out, so their length is the action's
    /// own measured width and their colour is the action's state.
    private func arm(_ spec: CaretActionSpec?, focused: Bool) -> CaretArmStyle {
        guard let spec else { return CaretArmStyle(length: CaretStyle.u(26)) }
        return CaretArmStyle(
            length: CaretAction.armLength(label: spec.label, key: spec.key),
            tone: CaretAction.armTone(
                role: spec.role,
                enabled: spec.enabled && !model.inert,
                damped: model.cooldown < 1,
                focused: focused,
                palette: palette
            ),
            thick: focused
        )
    }

    // MARK: - Lower arms

    private var actionBar: some View {
        HStack(alignment: .bottom, spacing: CaretStyle.u(24)) {
            if let spec = leadingAction {
                CaretAction(label: spec.label, role: spec.role, key: spec.key,
                            keyAvailable: spec.keyAvailable && model.commitKeyLive,
                            enabled: spec.enabled && !model.inert,
                            damped: model.cooldown < 1,
                            trailing: false, reserving: spec.reserving, reservingKey: spec.reservingKey, focusLift: 3,
                            onFocus: { leadingFocused = $0 }, action: spec.run)
            }
            Spacer(minLength: CaretStyle.u(20))
            if let spec = trailingAction {
                CaretAction(label: spec.label, role: spec.role, key: spec.key,
                            keyAvailable: spec.keyAvailable && model.commitKeyLive,
                            enabled: spec.enabled && !model.inert,
                            damped: model.cooldown < 1,
                            trailing: true, reserving: spec.reserving, reservingKey: spec.reservingKey,
                            onFocus: { trailingFocused = $0 }, action: spec.run)
            }
        }
        .padding(.horizontal, inset)
        .environment(\.caretInert, model.inert)
    }

    // MARK: - Postpone

    /// §3.5 with §10.7 fixed: every duration is a focus stop, so arrows reach
    /// them and Space or Return chooses.
    private var snoozeTray: some View {
        HStack(alignment: .center, spacing: CaretStyle.u(10)) {
            Spacer(minLength: 0)
            Text("ASK ME AGAIN IN")
                .font(Font(CaretStyle.monoTiny))
                .kerning(CaretStyle.monoTiny.pointSize * CaretStyle.railTracking)
                .foregroundStyle(palette.inkMuted)
                .fixedSize()
            ForEach([1, 5, 15, 30, 60], id: \.self) { minutes in
                CaretDuration(minutes: minutes) { onSnooze(minutes) }
            }
        }
        .padding(.horizontal, inset + armInset)
        .padding(.top, CaretStyle.u(14))
    }

    // MARK: - Reject the shape

    /// §3.7 drawn in the surface rather than handed to a host menu. The entry
    /// matching what is on screen is marked and cannot be chosen, so there is
    /// always exactly one and the person can always tell where they are.
    private var shapeList: some View {
        VStack(alignment: .trailing, spacing: CaretStyle.u(2)) {
            Text("ASK THIS AS")
                .font(Font(CaretStyle.monoTiny))
                .kerning(CaretStyle.monoTiny.pointSize * CaretStyle.railTracking)
                .foregroundStyle(palette.inkMuted)
                .padding(.bottom, CaretStyle.u(4))
            ForEach(CaretShape.all, id: \.id) { shape in
                CaretShapeEntry(
                    shape: shape,
                    current: shape.id == kind.currentShape,
                    action: { onAskDifferently(shape.id) }
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, inset + armInset)
        .padding(.top, CaretStyle.u(14))
        .environment(\.caretInert, false)
    }

    // MARK: - Annotation

    /// The annotation editor (§3.6), opened *inside* the surface rather than
    /// attached beside it.
    ///
    /// §3.6 leaves the form open — panel, overlay, sheet, expansion, mode or
    /// second window — and says that only something attached beside the
    /// surface brings §2.2's width rule and §2.4's anchor rule with it. Nothing
    /// here attaches, so the width of this surface never changes for any
    /// reason at all: the note opens downward from a fixed top edge, which is
    /// the one direction the window is already free to move in. That removes
    /// the entire class of problem where the layout lands a frame before the
    /// window does and the question walks across the screen while it catches
    /// up.
    private var notePanel: some View {
        CaretNotePanel(
            model: model,
            caption: noteCaption(model.openNote ?? ""),
            subject: noteSubject(model.openNote ?? "")
        )
        // Stated rather than inferred. The editor is an `NSScrollView` behind a
        // representable, which reports no intrinsic height of its own, and a
        // region whose height the measurement under-reads leaves the window
        // short of its own content and clips the ways out.
        // Stated rather than inferred: the editor is an `NSScrollView` behind
        // a representable and reports no intrinsic height of its own.
        .frame(height: CaretStyle.u(104))
        .padding(.horizontal, CaretStyle.caretRail + CaretStyle.gutter)
        .padding(.top, CaretStyle.u(16))
        .environment(\.caretInert, false)
    }

    // MARK: - Report

    private var reportFlow: some View {
        Group {
            if model.reportStep > 0 {
                CaretReportFlow(model: model)
                    .environment(\.caretPalette, palette)
                    .environment(\.caretInert, false)
                    .caretReveal()
            }
        }
    }

    private func openReport() {
        // §3.12: the transient surfaces cannot host a two-step flow inside a
        // four-second lifetime, so they open the issue page directly. §10.10
        // asks that the divergence be predictable rather than hidden, which
        // is what the tool's own description says.
        guard kind.interactive else {
            GitHubReporter.openIssue(description: "", screenshotData: nil, copyToClipboard: false)
            return
        }
        model.reportShot = DialogManager.shared.captureWindowScreenshot()
        model.reportText = ""
        model.reportStep = 1
        model.reflow()
    }

    // MARK: - Lifecycle

    private func appear() {
        model.startClock()

        guard kind.interactive else { return }

        monitor = DialogKeyRouter.install(
            bindings: DialogKeyBindings(
                canSubmit: { !model.inert && bindings.canSubmit() },
                onSubmit: bindings.onSubmit,
                onCancel: bindings.onCancel,
                onArrowLeft: bindings.onArrowLeft,
                onArrowRight: bindings.onArrowRight,
                onArrowUp: bindings.onArrowUp,
                onArrowDown: bindings.onArrowDown
            ),
            currentDialogType: kind.currentShape ?? "",
            // Left nil on purpose: `A` is picked up by this layer's own
            // one-key monitor so the shape list drawn above is what opens.
            onAskDifferently: nil,
            expandedTool: Binding(
                get: { model.trayOpen ? .snooze : nil },
                set: { model.trayOpen = $0 != nil }
            ),
            // The shape list is modal in the same way the pane is: it owns
            // Escape and it suppresses the single-letter shortcuts.
            isFeedbackPaneOpen: { model.openNote != nil || model.shapesOpen },
            showReportOverlay: Binding(
                get: { model.reportStep > 0 },
                set: { if !$0 { model.reportStep = 0 } }
            ),
            toggleSnooze: {
                model.shapesOpen = false
                model.trayOpen.toggle()
                model.reflow()
            },
            openFeedback: {
                model.openNote = ""
                model.reflow()
            },
            closePane: {
                if model.shapesOpen {
                    model.shapesOpen = false
                } else {
                    // The draft survives every route out of the editor. The
                    // caret does not, so the bare letter works again and the
                    // tool has to stop advertising the chord (§3.8).
                    model.openNote = nil
                    model.editing = false
                }
                model.reflow()
            },
            dismissOverlay: {
                model.reportStep = 0
                model.reflow()
            }
        )

        shapeKeys = CaretShapeKeyMonitor(
            shouldHandle: { model.reportStep == 0 && model.openNote == nil },
            toggle: {
                model.trayOpen = false
                model.shapesOpen.toggle()
                model.reflow()
            }
        )

        // §8.4: a surface may open with something already revealed, sized for
        // it from the first frame.
        if let demo = DialogManager.shared.testPane {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                if demo == "snooze" { model.trayOpen = true }
                if demo == "feedback" { model.openNote = "" }
                model.reflow()
            }
        }
    }

}

// MARK: - Tool mark

/// One capability on the top-trailing arm: the key that reaches it, and the
/// name of what it does. The key renders unavailable whenever it is actually
/// suppressed, which is the whole of §3.8's live-availability requirement.
struct CaretToolMark: View {
    let key: String?
    var keyLive: Bool = true
    /// The widest name this key will ever have, when it has more than one. See
    /// `CaretKeycap.reserving`.
    var reserving: String? = nil
    let name: String
    let help: String
    var open: Bool = false
    var marked: Bool = false
    var focused: Bool = false
    /// Points the focus target is extended upward by. `FocusManager` sorts a
    /// ring by vertical position only, so controls that share a row need a
    /// hair of separation to land in reading order (§4.5). Invisible.
    var focusLift: CGFloat = 0
    var onFocus: (Bool) -> Void = { _ in }
    let action: () -> Void

    @Environment(\.caretPalette) private var palette

    static func width(key: String?, name: String) -> CGFloat {
        var w = CaretStyle.width(name, font: CaretStyle.monoTiny, tracking: CaretStyle.railTracking)
        if let key {
            w += CaretStyle.width(key, font: CaretStyle.monoKey, tracking: 0.06) + CaretStyle.u(10) + CaretStyle.u(6)
        }
        return ceil(w) + CaretStyle.u(2)
    }

    var body: some View {
        HStack(spacing: CaretStyle.u(6)) {
            if let key { CaretKeycap(glyph: key, available: keyLive, reserving: reserving) }
            Text(name)
                .font(Font(CaretStyle.monoTiny))
                .kerning(CaretStyle.monoTiny.pointSize * CaretStyle.railTracking)
                .foregroundStyle(tint)
                .fixedSize()
        }
        .frame(width: Self.width(key: key, name: name), height: CaretStyle.u(16), alignment: .trailing)
        .overlay(alignment: .bottom) {
            // A note already drafted is the only signal that unsent work is
            // pending (§3.6), so it gets its own mark rather than a colour.
            if marked {
                Rectangle().fill(palette.caret).frame(width: CaretStyle.u(5), height: CaretStyle.hair)
                    .offset(y: CaretStyle.u(3))
            }
        }
        .contentShape(Rectangle())
        .overlay(
            CaretTarget(
                isContent: false,
                takesReturn: true,
                onActivate: action,
                onFocusChange: onFocus
            )
            .padding(.top, -focusLift)
        )
        .caretStop(focused)
        .help(help)
        .accessibilityLabel(Text(help))
    }

    private var tint: Color {
        if open { return palette.caret }
        if focused { return palette.ink }
        return palette.inkMuted
    }
}

// MARK: - Postpone duration

struct CaretDuration: View {
    let minutes: Int
    let action: () -> Void
    @State private var focused = false
    @State private var hovered = false
    @Environment(\.caretPalette) private var palette

    private var label: String { minutes < 60 ? "\(minutes)m" : "\(minutes / 60)h" }

    var body: some View {
        Text(label)
            .font(Font(CaretStyle.monoKey))
            .foregroundStyle(focused || hovered ? palette.onCaret : palette.inkSecond)
            .frame(width: CaretStyle.width(label, font: CaretStyle.monoKey) + CaretStyle.u(14),
                   height: CaretStyle.u(20))
            .background(
                RoundedRectangle(cornerRadius: CaretStyle.u(3), style: .continuous)
                    .fill(focused || hovered ? palette.caret : palette.channel)
            )
            .overlay(
                CaretTarget(isContent: true, takesReturn: true, onActivate: action,
                            onFocusChange: { focused = $0 }, onHoverChange: { hovered = $0 })
            )
            .caretStop(focused)
            .accessibilityLabel(Text("Ask me again in \(label)"))
    }
}

// MARK: - Shape entry

struct CaretShapeEntry: View {
    let shape: CaretShape
    let current: Bool
    let action: () -> Void
    @State private var focused = false
    @State private var hovered = false
    @Environment(\.caretPalette) private var palette

    var body: some View {
        HStack(spacing: CaretStyle.u(8)) {
            Text(current ? "CURRENT" : "")
                .font(Font(CaretStyle.monoTiny))
                .kerning(CaretStyle.monoTiny.pointSize * CaretStyle.railTracking)
                .foregroundStyle(palette.caret)
                .frame(width: CaretStyle.width("CURRENT", font: CaretStyle.monoTiny, tracking: CaretStyle.railTracking),
                       alignment: .trailing)
            Text(shape.title)
                .font(Font(CaretStyle.label))
                .foregroundStyle(current ? palette.inkMuted.opacity(0.6) : (focused || hovered ? palette.ink : palette.inkSecond))
                .frame(width: CaretStyle.u(104), alignment: .trailing)
        }
        .frame(height: CaretStyle.u(21))
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(focused ? palette.caret : Color.clear)
                .frame(width: CaretStyle.caretWidth)
                .offset(x: CaretStyle.u(7))
        }
        .contentShape(Rectangle())
        .overlay(
            CaretTarget(isContent: true, isEnabled: !current, takesReturn: true,
                        onActivate: action,
                        onFocusChange: { focused = $0 }, onHoverChange: { hovered = $0 })
        )
        .caretStop(focused)
    }
}
