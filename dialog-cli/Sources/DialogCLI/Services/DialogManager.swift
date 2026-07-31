import AppKit
import SwiftUI

class DialogManager {
    static let shared = DialogManager()
    private var clientName = "MCP"
    private var projectPath: String?
    var testPane: String?
    private var userSettings = UserSettings.load()
    var sizeObserver: WindowSizeObserver?
    var currentCommand: String?
    var currentCallJSON: String?
    /// Resolves a question id to its display label so the FeedbackPane header
    /// can show what the note belongs to. Set per-dialog by form dialogs.
    var questionLabelLookup: ((String) -> String?)?
    /// Live binding to the consult-level (.global) feedback draft owned by
    /// the current `DialogContainer`. Single-question dialogs use this to
    /// retrieve the draft on submit; forms read it for the consult-level note.
    var globalFeedbackBinding: Binding<String>?

    func setClientName(_ name: String) {
        clientName = name
    }

    func getClientName() -> String {
        clientName
    }

    func setProjectPath(_ path: String?) {
        projectPath = path
    }

    func getProjectPath() -> String? {
        projectPath
    }

    func getProjectName() -> String? {
        guard let path = projectPath else { return nil }
        return URL(fileURLWithPath: path).lastPathComponent
    }

    func getSettings() -> UserSettings {
        userSettings
    }

    func playShowSound(for context: UserSettings.SoundContext = .question) {
        if userSettings.shouldPlaySound(for: context) {
            userSettings.playSound()
        }
        if context == .question {
            CooldownManager.shared.startCooldown()
        }
    }

    func effectivePosition(_ requestedPosition: DialogPosition?) -> DialogPosition {
        return requestedPosition ?? DialogPosition(rawValue: userSettings.position) ?? .center
    }

    func buildTitle() -> String {
        clientName
    }

    func snoozeInstruction(minutes: Int) -> String {
        "Set a timer for \(minutes) minute\(minutes == 1 ? "" : "s") and re-ask this question when it fires."
    }

    func snoozeActiveInstruction(remaining: Int) -> String {
        let count = SnoozedRequestsManager.count()
        let missed = count > 0 ? " \(count) dialog\(count == 1 ? "" : "s") missed so far." : ""
        return "Snooze active. Wait \(remaining) seconds before re-asking.\(missed)"
    }

    func createWindow(width: CGFloat, height: CGFloat) -> (NSWindow, DraggableView) {
        let window = BorderlessWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = userSettings.alwaysOnTop ? .floating : .normal
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.acceptsMouseMovedEvents = true

        let bgView = DraggableView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        window.contentView = bgView

        return (window, bgView)
    }

    func createAutoSizedWindow<Content: View>(
        content: Content,
        minWidth: CGFloat = 420,
        minHeight: CGFloat = 300,
        maxHeightRatio: CGFloat = 0.85,
        initialHeight: CGFloat? = nil,
        position: DialogPosition = .center
    ) -> (NSWindow, NSHostingView<Content>, DraggableView) {
        let hostingView = NSHostingView(rootView: content)

        let screenHeight = NSScreen.main?.visibleFrame.height ?? 800
        let maxHeight = screenHeight * maxHeightRatio

        // Two-pass layout: first pass determines width, second pass gets
        // correct height after text views know their wrapping width.
        hostingView.layout()
        let fittingSize = hostingView.fittingSize
        let width = max(minWidth, fittingSize.width) + 16

        // Set width so NSTextView containers wrap correctly, then re-layout.
        //
        // Once is not enough. A pass can report a height that leaves out rows
        // whose text has not resolved yet — the notify surface came back 116pt
        // when it went on to draw 185, so the window was built 69pt too short
        // and SwiftUI centred the overflow: the header row and the last line
        // of the body were drawn outside the window, top and bottom.
        //
        // So measure until it stops growing. It settles on the second pass in
        // practice; the cap is there because a layout that never converges
        // must not hang the dialog, and the largest measurement seen is the
        // safe one to build from either way.
        hostingView.frame = NSRect(x: 0, y: 0, width: width - 16, height: 10000)
        hostingView.layout()
        var constrainedSize = hostingView.fittingSize

        // `fittingSize` is what SwiftUI *says* it needs; the layer it draws
        // into is what it actually took. On the notify surface those differed
        // by 69pt — it reported 116 and laid out at 185 — so the window was
        // built too short and SwiftUI centred the overflow, putting the header
        // row above the top edge and cutting the last line of the body off the
        // bottom. Neither is visible to `fittingSize`, which is why the audit
        // could see the escape while the geometry looked self-consistent.
        //
        // So: give it exactly the height it asked for and look at what it
        // does with it. Anything that grows past that box is overflow by
        // definition, and its own height is the honest number.
        //
        // Measured at the box it asked for, not at the 10000pt one used
        // above — a view that stretches to fill would report 10000 there and
        // every dialog would open at the height cap.
        hostingView.frame = NSRect(x: 0, y: 0, width: width - 16, height: constrainedSize.height)
        hostingView.layout()
        let drawn = hostingView.subviews.map { $0.frame.height }.max() ?? 0
        if drawn > constrainedSize.height {
            constrainedSize.height = drawn
        }

        let height: CGFloat
        if let initial = initialHeight {
            height = min(max(initial, minHeight), maxHeight)
        } else {
            height = min(max(constrainedSize.height + 16, minHeight), maxHeight)
        }

        let (window, bgView) = createWindow(width: width, height: height)

        hostingView.frame = NSRect(x: 8, y: 8, width: width - 16, height: height - 16)
        bgView.addSubview(hostingView)

        sizeObserver = WindowSizeObserver(
            window: window,
            hostingView: hostingView,
            bgView: bgView,
            minWidth: minWidth,
            minHeight: minHeight,
            maxHeight: maxHeight,
            position: position
        )

        return (window, hostingView, bgView)
    }

    /// Builds the dialog window from the active skin: the skin supplies both
    /// the view and the window metrics, so a skin can size its dialogs
    /// differently without touching `DialogManager`.
    func createSkinnedWindow(
        _ kind: DialogKind,
        position: DialogPosition,
        build: (DialogSkin) -> AnyView
    ) -> (NSWindow, NSHostingView<AnyView>, DraggableView) {
        let skin = SkinRegistry.active
        let metrics = skin.metrics(for: kind)
        return createAutoSizedWindow(
            content: build(skin),
            minWidth: metrics.minWidth,
            minHeight: metrics.minHeight,
            maxHeightRatio: metrics.maxHeightRatio,
            position: position
        )
    }

    func captureWindowScreenshot() -> Data? {
        let window = NSApp.modalWindow
            ?? NSApp.windows.first(where: { $0 is BorderlessWindow && $0.isVisible })
        guard let contentView = window?.contentView,
              let rep = contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds)
        else { return nil }
        contentView.cacheDisplay(in: contentView.bounds, to: rep)
        return rep.representation(using: .png, properties: [:])
    }

    func positionWindow(_ window: NSWindow, position: DialogPosition) {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame

        let x: CGFloat
        switch position {
        case .left:
            x = screenFrame.minX + 40
        case .right:
            x = screenFrame.maxX - windowFrame.width - 40
        case .center:
            x = screenFrame.midX - windowFrame.width / 2
        }

        let y = screenFrame.maxY - windowFrame.height - 80
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
