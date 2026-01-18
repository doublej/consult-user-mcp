import Foundation

extension DialogManager {
    func notify(_ request: NotifyRequest) -> NotifyResponse {
        let title = buildTitle(request.title)
        var script = "display notification \"\(escapeForAppleScript(request.body))\" with title \"\(escapeForAppleScript(title))\""
        if request.sound {
            script += " sound name \"default\""
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let success: Bool
        do {
            try process.run()
            process.waitUntilExit()
            success = process.terminationStatus == 0
        } catch {
            success = false
        }

        return NotifyResponse(dialogType: "notify", success: success)
    }

    func escapeForAppleScript(_ str: String) -> String {
        return str.replacingOccurrences(of: "\\", with: "\\\\")
                  .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
