import AppKit
import SwiftUI

class DialogManager {
    static let shared = DialogManager()
    private var clientName = "MCP"
    private var userSettings = UserSettings.load()
    var sizeObserver: WindowSizeObserver?

    func setClientName(_ name: String) {
        clientName = name
    }

    func effectivePosition(_ requestedPosition: DialogPosition) -> DialogPosition {
        return DialogPosition(rawValue: userSettings.position) ?? .center
    }

    func buildTitle(_ baseTitle: String) -> String {
        "\(clientName)"
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
        window.level = .floating
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
        maxHeightRatio: CGFloat = 0.85
    ) -> (NSWindow, NSHostingView<Content>, DraggableView) {
        let hostingView = NSHostingView(rootView: content)

        let screenHeight = NSScreen.main?.visibleFrame.height ?? 800
        let maxHeight = screenHeight * maxHeightRatio

        hostingView.layout()
        let fittingSize = hostingView.fittingSize
        let width = max(minWidth, fittingSize.width) + 16
        let height = min(max(fittingSize.height + 16, minHeight), maxHeight)

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
