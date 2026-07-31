#!/usr/bin/env swift
import Cocoa

// Print the CGWindowID of a dialog window, for `screencapture -l`.
//
// Usage: capture-dialog.swift [pid]
//
// The pid is what makes the answer trustworthy. Matching on the owner name
// alone returns the first DialogCLI window in the list, which is not
// necessarily the one that was just launched — and a single dialog left on
// screen by an earlier hung invocation then wins every lookup for the rest
// of the run. That is not hypothetical: it produced eighty screenshots of
// one stale window, each captioned with the fixture it was not showing.
//
// With a pid, a window that does not belong to that process is never
// returned; the caller gets nothing and reports a miss, which is the honest
// outcome.

let wantedPID: pid_t? = CommandLine.arguments.count > 1
    ? pid_t(CommandLine.arguments[1]) : nil

guard let windowList = CGWindowListCopyWindowInfo(
    [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
) as? [[String: Any]] else {
    exit(1)
}

func isDialog(_ window: [String: Any]) -> Bool {
    let owner = (window[kCGWindowOwnerName as String] as? String ?? "").lowercased()
    if owner.contains("dialogcli") || owner.contains("dialog-cli") { return true }

    // Fallback for the pid-less case only: a floating panel that looks like
    // one of ours. Kept because the sketch CLI reports a different owner.
    let layer = window[kCGWindowLayer as String] as? Int ?? 0
    let name = window[kCGWindowName as String] as? String ?? ""
    return layer == 3 && (
        name.contains("Confirmation") || name.contains("Input")
            || name.contains("Choose") || name.contains("Questions")
            || name.contains("Notification") || name.contains("Notice")
            || name.isEmpty
    )
}

for window in windowList {
    if let wanted = wantedPID {
        // Exact ownership, nothing else. A stale window cannot satisfy this.
        guard window[kCGWindowOwnerPID as String] as? pid_t == wanted else { continue }
        // Skip the zero-sized helper windows AppKit keeps around.
        let bounds = window[kCGWindowBounds as String] as? [String: Double] ?? [:]
        guard (bounds["Width"] ?? 0) > 1, (bounds["Height"] ?? 0) > 1 else { continue }
    } else {
        guard isDialog(window) else { continue }
    }
    if let wid = window[kCGWindowNumber as String] as? Int {
        print(wid)
        exit(0)
    }
}

// Nothing matched. Describe what was on screen so the miss is diagnosable
// rather than just a blank line.
if let wanted = wantedPID {
    fputs("no on-screen window owned by pid \(wanted)\n", stderr)
}
for window in windowList {
    let owner = window[kCGWindowOwnerName as String] as? String ?? ""
    let pid = window[kCGWindowOwnerPID as String] as? pid_t ?? 0
    let name = window[kCGWindowName as String] as? String ?? ""
    let layer = window[kCGWindowLayer as String] as? Int ?? 0
    fputs("Window: owner=\(owner), pid=\(pid), name=\(name), layer=\(layer)\n", stderr)
}

exit(1)
