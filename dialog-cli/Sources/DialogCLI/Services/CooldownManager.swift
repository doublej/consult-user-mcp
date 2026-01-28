import Foundation

extension Notification.Name {
    static let cooldownDidChange = Notification.Name("com.consult-user-mcp.cooldownDidChange")
}

/// Manages dialog-wide cooldown state for preventing accidental key presses
final class CooldownManager {
    static let shared = CooldownManager()

    private var cooldownStartTime: Date?
    private var cooldownDuration: TimeInterval = 0
    private var cooldownEndTime: Date?
    private var timer: DispatchSourceTimer?

    private init() {}

    /// Start cooldown timer based on user settings
    func startCooldown() {
        let settings = UserSettings.load()
        guard settings.buttonCooldownEnabled else {
            reset()
            return
        }

        let duration = max(0, settings.buttonCooldownDuration)
        guard duration > 0 else {
            reset()
            return
        }

        cooldownStartTime = Date()
        cooldownDuration = duration
        cooldownEndTime = cooldownStartTime?.addingTimeInterval(duration)

        timer?.cancel()
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now() + duration)
        t.setEventHandler { [weak self] in
            self?.reset()
        }
        t.resume()
        timer = t
        NotificationCenter.default.post(name: .cooldownDidChange, object: nil)
    }

    /// Check if cooldown is currently active
    var isCoolingDown: Bool {
        guard let endTime = cooldownEndTime else { return false }
        return Date() < endTime
    }

    /// Cooldown progress from 0 to 1 (1 when not cooling down)
    var progress: Double {
        guard let startTime = cooldownStartTime, cooldownDuration > 0 else { return 1 }
        let elapsed = Date().timeIntervalSince(startTime)
        return min(1, max(0, elapsed / cooldownDuration))
    }

    /// Check if a key code is an action key that should be blocked during cooldown
    func isActionKey(_ keyCode: UInt16) -> Bool {
        keyCode == KeyCode.escape ||
        keyCode == KeyCode.returnKey ||
        keyCode == KeyCode.s ||
        keyCode == KeyCode.f ||
        keyCode == KeyCode.space
    }

    /// Returns true if the key should be blocked (is an action key during cooldown)
    func shouldBlockKey(_ keyCode: UInt16) -> Bool {
        isCoolingDown && isActionKey(keyCode)
    }

    /// Reset cooldown state
    func reset() {
        timer?.cancel()
        timer = nil
        cooldownStartTime = nil
        cooldownDuration = 0
        cooldownEndTime = nil
        NotificationCenter.default.post(name: .cooldownDidChange, object: nil)
    }
}
