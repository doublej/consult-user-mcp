import Foundation

/// macOS virtual key codes for keyboard handling
enum KeyCode {
    static let escape: UInt16 = 53
    static let returnKey: UInt16 = 36
    static let space: UInt16 = 49
    static let tab: UInt16 = 48

    // Letter keys
    static let a: UInt16 = 0
    static let s: UInt16 = 1
    static let f: UInt16 = 3

    // Arrow keys
    static let leftArrow: UInt16 = 123
    static let rightArrow: UInt16 = 124
    static let downArrow: UInt16 = 125
    static let upArrow: UInt16 = 126
}
