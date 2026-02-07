#!/usr/bin/env swift
import Cocoa

// Find DialogCLI window and output its CGWindowID for screencapture -l
guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
    exit(1)
}

// Look for window by owner name containing "Dialog" or by window layer (floating panels)
for window in windowList {
    let owner = window[kCGWindowOwnerName as String] as? String ?? ""
    let layer = window[kCGWindowLayer as String] as? Int ?? 0
    let name = window[kCGWindowName as String] as? String ?? ""

    // Match by owner name (DialogCLI, dialog-cli, etc.)
    let ownerLower = owner.lowercased()
    let isDialogOwner = ownerLower.contains("dialogcli") || ownerLower.contains("dialog-cli")

    // Match by window characteristics: floating panel layer with typical dialog names
    let isDialogWindow = layer == 3 && (
        name.contains("Confirmation") ||
        name.contains("Input") ||
        name.contains("Choose") ||
        name.contains("Questions") ||
        name.contains("Notification") ||
        name.contains("Notice") ||
        name.isEmpty  // DialogCLI windows often have empty names
    )

    if isDialogOwner || isDialogWindow {
        if let wid = window[kCGWindowNumber as String] as? Int {
            print(wid)
            exit(0)
        }
    }
}

// Debug: print all windows if not found (to stderr so it doesn't affect output)
for window in windowList {
    let owner = window[kCGWindowOwnerName as String] as? String ?? ""
    let name = window[kCGWindowName as String] as? String ?? ""
    let layer = window[kCGWindowLayer as String] as? Int ?? 0
    fputs("Window: owner=\(owner), name=\(name), layer=\(layer)\n", stderr)
}

exit(1)
