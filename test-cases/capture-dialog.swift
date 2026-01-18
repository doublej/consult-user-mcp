#!/usr/bin/env swift
import Cocoa

// Find DialogCLI window and output its CGWindowID for screencapture -l
guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
    exit(1)
}

// Find DialogCLI window
for window in windowList {
    let owner = window[kCGWindowOwnerName as String] as? String ?? ""
    if owner == "DialogCLI" {
        if let wid = window[kCGWindowNumber as String] as? Int {
            print(wid)
            exit(0)
        }
    }
}
exit(1)
