import AppKit
import Combine

/// Mirrors the MCP server's dialog timeout inside the CLI process. The server
/// passes its timeout via MCP_DIALOG_TIMEOUT_MS; when it elapses the server
/// has already returned a timeout error and the agent has continued, so the
/// dialog flips into an inert "the agent has moved on" state instead of
/// silently collecting an answer nobody will read.
///
/// The server's own timer starts slightly *before* this process spawns, so
/// this one always fires after the server has genuinely given up — the
/// expired state never shows while the server is still listening.
///
/// `isExpired` flips synchronously on the main queue, so the key router can
/// gate on it without racing async focus (see the hotkey guard pattern in
/// DialogKeyRouter).
final class DialogExpiry: ObservableObject {
    static let shared = DialogExpiry()

    @Published private(set) var isExpired = false

    /// Reads MCP_DIALOG_TIMEOUT_MS and arms the timer. Called once at launch;
    /// does nothing when the env var is absent (debug menu, test runner).
    func armFromEnvironment() {
        guard let raw = ProcessInfo.processInfo.environment["MCP_DIALOG_TIMEOUT_MS"],
              let ms = Double(raw), ms > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + ms / 1000) { [weak self] in
            self?.isExpired = true
        }
    }

    /// Ends the modal session for the expired dialog. The response printed on
    /// exit is the standard dismissal — the server discarded this dialog's
    /// promise at its own timeout, so the content no longer matters.
    func closeExpiredDialog() {
        NSApp.stopModal()
    }
}
