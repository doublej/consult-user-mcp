import AppKit

extension Notification.Name {
    static let dialogContentSizeChanged = Notification.Name("dialogContentSizeChanged")
    static let dismissReportOverlay = Notification.Name("dismissReportOverlay")
}

extension Notification {
    var shouldResizeDialogWidth: Bool {
        userInfo?["resizeWidth"] as? Bool == true
    }
}

class WindowSizeObserver: NSObject {
    private weak var window: NSWindow?
    private weak var hostingView: NSView?
    private weak var bgView: NSView?
    private let minWidth: CGFloat
    private let minHeight: CGFloat
    private let maxHeight: CGFloat
    private let position: DialogPosition
    private var notificationObserver: NSObjectProtocol?

    init(window: NSWindow, hostingView: NSView, bgView: NSView, minWidth: CGFloat, minHeight: CGFloat, maxHeight: CGFloat, position: DialogPosition) {
        self.window = window
        self.hostingView = hostingView
        self.bgView = bgView
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.position = position
        super.init()

        // Let AppKit carry the subviews, instead of animating their frames
        // alongside the window's.
        //
        // AppKit's origin is bottom-left, so a subview given an explicit frame
        // in a window that grows upward-from-a-fixed-top keeps its distance
        // from the *bottom* and its top margin is what changes. Three separate
        // animations — window, background, hosting view — also have to agree
        // frame for frame, and any disagreement is content sliding inside the
        // window while it travels.
        //
        // A flexible width and height with fixed margins is the standard fix:
        // the 8-point inset is held on all four sides and the resize happens as
        // part of the window's own animated setFrame, so there is exactly one
        // animation and the content cannot drift against it.
        bgView.autoresizingMask = [.width, .height]
        hostingView.autoresizingMask = [.width, .height]

        notificationObserver = NotificationCenter.default.addObserver(
            forName: .dialogContentSizeChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.updateWindowSize(resizeWidth: notification.shouldResizeDialogWidth)
        }
    }

    private func updateWindowSize(resizeWidth: Bool = false) {
        guard let window = window, let hostingView = hostingView, let bgView = bgView else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let currentFrame = window.frame

            // Width is fixed for the window's lifetime — it's determined once by
            // the two-pass layout in createAutoSizedWindow. Recomputing it here
            // from a single-pass fittingSize couples width to the current text-wrap
            // state, which feeds back into wrapping and makes the window oscillate
            // endlessly (scrollbar appears → narrower → wraps taller → repeat).
            // At runtime only height reflows, except explicit pane transitions
            // that add/remove a fixed-width side panel.
            let fittingSize = hostingView.fittingSize
            let screenWidth = NSScreen.main?.visibleFrame.width ?? 1200
            let maxWidth = max(self.minWidth + 16, screenWidth - 80)
            let fittedWidth = min(max(fittingSize.width + 16, self.minWidth + 16), maxWidth)
            let newWidth = resizeWidth ? fittedWidth : currentFrame.width
            let newHeight = min(max(fittingSize.height + 16, self.minHeight), self.maxHeight)

            let widthDelta = abs(currentFrame.width - newWidth)
            let heightDelta = abs(currentFrame.height - newHeight)
            if widthDelta < 1 && heightDelta < 1 { return }

            let newY = currentFrame.origin.y + currentFrame.height - newHeight
            let newX: CGFloat
            switch self.position {
            case .left:
                newX = currentFrame.origin.x
            case .right:
                newX = currentFrame.origin.x + currentFrame.width - newWidth
            case .center:
                newX = currentFrame.origin.x + (currentFrame.width - newWidth) / 2
            }
            let newFrame = NSRect(x: newX, y: newY, width: newWidth, height: newHeight)

            // No animation, deliberately.
            //
            // A SwiftUI layout change lands in a single frame; an animated
            // window frame lands over many. There is no cheap way to keep the
            // two in step — the content is at its final size from the first
            // frame and the window spends the whole travel smaller than it,
            // so everything the content cannot fit is pushed outside the clip
            // and slides back in as the window catches up. Animating the
            // content instead does not work either: this observer sizes the
            // window from `fittingSize`, so a content height that is still
            // travelling is the height the window would adopt.
            //
            // Changing the size in the same turn as the layout removes the
            // gap rather than trying to hide it. The arrival is softened in
            // the skin, by fading the new region in — opacity costs no layout
            // and so cannot be caught mid-measurement.
            window.setFrame(newFrame, display: true)

            if ProcessInfo.processInfo.environment["DIALOG_TEST_DEBUG_LAYOUT"] != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    let fs = hostingView.fittingSize
                    fputs("LAYOUT window=\(window.frame.width)x\(window.frame.height) " +
                          "hosting=\(hostingView.frame) fitting=\(fs) " +
                          "subviews=\(hostingView.subviews.map { $0.frame })\n", stderr)
                }
            }
        }
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
