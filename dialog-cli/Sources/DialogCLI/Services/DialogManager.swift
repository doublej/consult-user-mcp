import AppKit
import SwiftUI

class DialogManager {
    static let shared = DialogManager()
    private var clientName = "MCP"
    private var projectPath: String?
    private var userSettings = UserSettings.load()
    var sizeObserver: WindowSizeObserver?

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

    func effectivePosition(_ requestedPosition: DialogPosition) -> DialogPosition {
        return DialogPosition(rawValue: userSettings.position) ?? .center
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
        initialHeight: CGFloat? = nil
    ) -> (NSWindow, NSHostingView<Content>, DraggableView) {
        let hostingView = NSHostingView(rootView: content)

        let screenHeight = NSScreen.main?.visibleFrame.height ?? 800
        let maxHeight = screenHeight * maxHeightRatio

        hostingView.layout()
        let fittingSize = hostingView.fittingSize
        let width = max(minWidth, fittingSize.width) + 16
        let height: CGFloat
        if let initial = initialHeight {
            height = min(max(initial, minHeight), maxHeight)
        } else {
            height = min(max(fittingSize.height + 16, minHeight), maxHeight)
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
            maxHeight: maxHeight
        )

        return (window, hostingView, bgView)
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
