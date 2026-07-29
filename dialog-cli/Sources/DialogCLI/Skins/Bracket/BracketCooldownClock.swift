import Foundation
import SwiftUI

/// Drives the §4.6 damped state and the "how much time remains" indication.
///
/// `CooldownManager` publishes nothing and exposes no duration, so this polls
/// `isCoolingDown` for the state and reads the person's configured length
/// straight out of the settings file for the drain. If the two ever disagree,
/// `isCoolingDown` wins: the bar disappears the moment input is live, so the
/// indication never outlives the block it describes.
final class CooldownClock: ObservableObject {
    /// 0 → just opened, 1 → live. Drives both the drain bar and the damping.
    @Published private(set) var progress: CGFloat = 1

    private var timer: Timer?
    private var started = Date()
    private var ticks = 0
    private lazy var duration: TimeInterval = Self.configuredDuration()

    func start() {
        guard timer == nil else { return }
        started = Date()
        progress = 0
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        ticks += 1
        // The cooldown is armed a beat after the view appears; give it a few
        // frames before concluding it is switched off entirely.
        if !CooldownManager.shared.isCoolingDown && ticks > 3 {
            timer?.invalidate()
            timer = nil
            progress = 1
            return
        }
        let elapsed = Date().timeIntervalSince(started)
        progress = min(0.97, CGFloat(elapsed / max(duration, 0.1)))
    }

    /// §9 — 2.0s by default, adjustable from 0.1s to 3.0s, or off.
    private static func configuredDuration() -> TimeInterval {
        let url = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/ConsultUserMCP/settings.json")
        guard let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let seconds = object["buttonCooldownDuration"] as? Double,
              seconds > 0 else { return 2.0 }
        return seconds
    }

    deinit {
        timer?.invalidate()
    }
}
