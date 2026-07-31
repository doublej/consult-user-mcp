import AppKit

/// Automated keystroke injection for the test harness (`DIALOG_TEST_KEYS`).
/// Posts synthesized `NSEvent` keyDown/keyUp pairs through `NSApp.postEvent`,
/// so events travel the exact same dispatch path as real typing — including
/// the `DialogKeyRouter` local monitor — without needing Accessibility
/// permission the way CGEvent/System Events injection does.
///
/// Script format: semicolon-separated tokens, executed in order.
///   d<seconds>   wait (e.g. `d0.5`)
///   p<millis>    pause between the following typed characters (default 0)
///   t:<text>     type text, one key event pair per character
///   c:<char>     ⌘-chord (e.g. `c:f` for ⌘F)
///   left / right / up / down / esc / return / tab / space   special keys
///   +<special>   shift form of a special key (e.g. `+tab` for ⇧⇥)
///
/// Example: `DIALOG_TEST_KEYS="d1.0;t:f;t:some note;esc;return"`
enum TestKeyDriver {
    static func installIfRequested() {
        guard let script = ProcessInfo.processInfo.environment["DIALOG_TEST_KEYS"],
              !script.isEmpty else { return }
        let tokens = script.split(separator: ";").map(String.init)
        run(tokens: tokens, index: 0, typingPauseMs: 0)
    }

    private static func run(tokens: [String], index: Int, typingPauseMs: Int) {
        guard index < tokens.count else { return }
        let token = tokens[index].trimmingCharacters(in: .whitespaces)
        var pause = typingPauseMs

        func proceed(after delay: Double) {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                run(tokens: tokens, index: index + 1, typingPauseMs: pause)
            }
        }

        if token.hasPrefix("d"), let seconds = Double(token.dropFirst()) {
            proceed(after: seconds)
            return
        }
        if token.hasPrefix("p"), let ms = Int(token.dropFirst()) {
            pause = ms
            proceed(after: 0)
            return
        }
        if token.hasPrefix("t:") {
            let text = String(token.dropFirst(2))
            typeText(text, pauseMs: pause) {
                run(tokens: tokens, index: index + 1, typingPauseMs: pause)
            }
            return
        }
        if token.hasPrefix("c:"), let char = token.dropFirst(2).first {
            post(char: char, modifiers: .command)
            proceed(after: 0.05)
            return
        }
        // `+name` is the shift form. Tab order can only be proved by walking
        // it in both directions, and shift-tab was previously unreachable.
        if token.hasPrefix("+"), let special = specialKeys[String(token.dropFirst())] {
            post(keyCode: special.code, characters: special.characters, modifiers: .shift)
            proceed(after: 0.05)
            return
        }
        if let special = specialKeys[token] {
            post(keyCode: special.code, characters: special.characters)
            proceed(after: 0.05)
            return
        }
        fputs("TestKeyDriver: unknown token '\(token)'\n", stderr)
        proceed(after: 0)
    }

    private static func typeText(_ text: String, pauseMs: Int, completion: @escaping () -> Void) {
        var chars = Array(text)
        func next() {
            guard !chars.isEmpty else { completion(); return }
            let char = chars.removeFirst()
            post(char: char, modifiers: [])
            let delay = Double(pauseMs) / 1000.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { next() }
        }
        next()
    }

    private static func post(char: Character, modifiers: NSEvent.ModifierFlags) {
        let keyCode = usQwertyKeyCodes[Character(char.lowercased())] ?? 0
        post(keyCode: keyCode, characters: String(char), modifiers: modifiers)
    }

    private static func post(keyCode: UInt16, characters: String,
                             modifiers: NSEvent.ModifierFlags = []) {
        let windowNumber = (NSApp.keyWindow ?? NSApp.windows.first)?.windowNumber ?? 0
        for type in [NSEvent.EventType.keyDown, .keyUp] {
            if let event = NSEvent.keyEvent(
                with: type,
                location: .zero,
                modifierFlags: modifiers,
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: windowNumber,
                context: nil,
                characters: characters,
                charactersIgnoringModifiers: characters,
                isARepeat: false,
                keyCode: keyCode
            ) {
                NSApp.postEvent(event, atStart: false)
            }
        }
    }

    /// `space` carries its character because the surfaces that care read
    /// `characters` rather than the key code, and an empty string there is
    /// not the space bar. Its absence is why nothing could test the one key
    /// that toggles a choice.
    private static let specialKeys: [String: (code: UInt16, characters: String)] = [
        "left": (123, ""), "right": (124, ""), "down": (125, ""), "up": (126, ""),
        "esc": (53, ""), "return": (36, ""), "tab": (48, ""),
        "space": (49, " "),
    ]

    private static let usQwertyKeyCodes: [Character: UInt16] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7,
        "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15,
        "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22,
        "5": 23, "9": 25, "7": 26, "8": 28, "0": 29, "o": 31, "u": 32,
        "i": 34, "p": 35, "l": 37, "j": 38, "k": 40, "n": 45, "m": 46,
        " ": 49, ".": 47, ",": 43, "-": 27,
    ]
}
