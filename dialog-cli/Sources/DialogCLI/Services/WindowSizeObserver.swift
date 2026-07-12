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
            let newHostingFrame = NSRect(x: 8, y: 8, width: newWidth - 16, height: newHeight - 16)
            let newBgFrame = NSRect(x: 0, y: 0, width: newWidth, height: newHeight)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                context.allowsImplicitAnimation = true
                window.animator().setFrame(newFrame, display: true)
                hostingView.animator().frame = newHostingFrame
                bgView.animator().frame = newBgFrame
            }
        }
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
