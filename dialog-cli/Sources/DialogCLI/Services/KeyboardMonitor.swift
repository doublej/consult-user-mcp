import AppKit

// MARK: - Keyboard Navigation Monitor

class KeyboardNavigationMonitor {
    private var monitor: Any?
    private let onKeyDown: (UInt16, NSEvent.ModifierFlags) -> Bool

    init(onKeyDown: @escaping (UInt16, NSEvent.ModifierFlags) -> Bool) {
        self.onKeyDown = onKeyDown
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            if self.onKeyDown(event.keyCode, event.modifierFlags) {
                return nil // Consume event
            }
            return event
        }
    }

    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
