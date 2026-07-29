import AppKit
import Foundation

// Offscreen state renderer.
//
// The shell harness this replaces launched one dialog process per state, and
// every one of them called `NSApp.activate(ignoringOtherApps:)` and took the
// keyboard away from whatever the person was doing — eighty times a run.
//
// This does the same work in one process without ever activating the app:
//   - it builds each window through `DialogManager.createSkinnedWindow`, so the
//     real two-pass sizing, the real size observer and the real skin all run;
//   - it parks the window far outside every display and orders it front there,
//     so `viewDidMoveToWindow`, `onAppear` and layout all happen for real;
//   - it pumps `NSApp` itself, so the key router's local monitor, the cooldown
//     and `DIALOG_TEST_KEYS` behave exactly as they do in the product;
//   - it captures with `cacheDisplay`, which reads the view hierarchy rather
//     than the screen, so no `screencapture` and no window ever shows.
//
// One fidelity gap, and it is the only one: an app that never activates has no
// key window, and `KeyboardContext.isEditingText` asks `NSApp.keyWindow` for
// its first responder. So the router cannot tell that a caret is in a field
// and will read a typed `s`, `f` or `a` as the shortcut it is elsewhere. The
// surfaces themselves are unaffected — they track their own editing state —
// and the manifest simply keeps those three letters out of typed text.
//
// Usage:  render <states.tsv> <outdir> <skin> [name-filter]

// MARK: - Setup

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
app.finishLaunching()

let args = CommandLine.arguments
guard args.count >= 4 else {
    FileHandle.standardError.write("usage: render <states.tsv> <outdir> <skin> [filter]\n".data(using: .utf8)!)
    exit(2)
}
let manifestPath = args[1]
let outDir = args[2]
let skinID = args[3]
/// A leading `=` means "this exact state and nothing else". The shell driver
/// uses it to give every state its own process: a surface installs a key
/// monitor and a size observer, and sharing a process between states let one
/// state's leftovers eat the next state's script.
let filter = args.count > 4 ? args[4] : ""
let exact = filter.hasPrefix("=") ? String(filter.dropFirst()) : nil

/// Most fixtures name a project, so the identity on the top arm has something
/// to show. `MCP_PROJECT_PATH` overrides it; a manifest row can clear it with
/// `none` to shoot the no-project case.
let defaultProject = ProcessInfo.processInfo.environment["MCP_PROJECT_PATH"]
    ?? "/Users/example/projects/consult-user-mcp"
DialogManager.shared.setClientName(ProcessInfo.processInfo.environment["MCP_CLIENT_NAME"] ?? "Claude Code")

setenv("DIALOG_SKIN", skinID, 1)
SkinRegistry.resolve(settings: UserSettings.load())
if let theme = ProcessInfo.processInfo.environment["DIALOG_THEME"] {
    ThemeManager.shared.setTheme(named: theme)
}

let manifestURL = URL(fileURLWithPath: manifestPath)
let root = manifestURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
let sharedCases = root.appendingPathComponent("test-cases/cases")
let localFixtures = manifestURL.deletingLastPathComponent().appendingPathComponent("fixtures")
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

// MARK: - Snooze guard
//
// A stray quiet period suppresses every interactive surface, so a whole run
// would come back empty. Park it and put it back on the way out.

let settingsURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
    .appendingPathComponent("ConsultUserMCP/settings.json")
var settingsBackup: Data?
if let settingsURL, let data = FileManager.default.contents(atPath: settingsURL.path) {
    settingsBackup = data
    if var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       json.removeValue(forKey: "snoozeUntil") != nil,
       let stripped = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
        try? stripped.write(to: settingsURL)
    }
}
func restoreSettings() {
    if let settingsURL, let settingsBackup { try? settingsBackup.write(to: settingsURL) }
}
atexit { restoreSettings() }

// MARK: - Manifest

struct RenderState {
    var name: String
    var dir: String
    var fixture: String
    var settle: Double
    var pane: String?
    var keys: String?
    var project: String?
}

func loadManifest() -> [RenderState] {
    guard let text = try? String(contentsOf: manifestURL, encoding: .utf8) else { return [] }
    return text.split(separator: "\n", omittingEmptySubsequences: false).compactMap { line in
        let raw = String(line)
        guard !raw.isEmpty, !raw.hasPrefix("#") else { return nil }
        let cols = raw.components(separatedBy: "\t")
        guard cols.count >= 4, let settle = Double(cols[3]) else { return nil }
        func opt(_ i: Int) -> String? {
            guard cols.count > i else { return nil }
            let v = cols[i].trimmingCharacters(in: .whitespaces)
            return (v.isEmpty || v == "-") ? nil : v
        }
        return RenderState(name: cols[0], dir: cols[1], fixture: cols[2], settle: settle,
                     pane: opt(4), keys: opt(5), project: opt(6))
    }
}

func fixtureData(_ state: RenderState) -> Data? {
    let shared = sharedCases.appendingPathComponent("\(state.dir)/\(state.fixture).json")
    if let data = FileManager.default.contents(atPath: shared.path) { return data }
    let local = localFixtures.appendingPathComponent("\(state.dir)/\(state.fixture).json")
    return FileManager.default.contents(atPath: local.path)
}

// MARK: - Capture

let parkedOrigin = NSPoint(x: -30_000, y: -30_000)

/// The window the current state is being rendered into, so `pump` knows where
/// to hand a key the router did not take.
var liveWindow: NSWindow?


// MARK: - Keys
//
// The product's own `TestKeyDriver` is env-var driven and has no token for
// Space — every `space` in the manifest was being dropped on the floor, which
// looked exactly like a broken option row. This plans the same token language
// plus Space onto a timeline the pump executes, so a state's script is
// deterministic rather than racing `asyncAfter` against the settle delay.
//
//   d<seconds>  wait · p<millis> typing pause · t:<text> type · c:<char> ⌘-chord
//   space left right up down esc return tab

struct KeyStep {
    var at: TimeInterval
    var keyCode: UInt16
    var characters: String
    var modifiers: NSEvent.ModifierFlags = []
}

let specialKeys: [String: (UInt16, String)] = [
    "left": (123, ""), "right": (124, ""), "down": (125, ""), "up": (126, ""),
    "esc": (53, ""), "return": (36, ""), "tab": (48, ""), "space": (49, " "),
]

let qwerty: [Character: UInt16] = [
    "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7,
    "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15,
    "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22,
    "5": 23, "9": 25, "7": 26, "8": 28, "0": 29, "o": 31, "u": 32,
    "i": 34, "p": 35, "l": 37, "j": 38, "k": 40, "n": 45, "m": 46,
    " ": 49, ".": 47, ",": 43, "-": 27,
]

func plan(_ script: String) -> [KeyStep] {
    var steps: [KeyStep] = []
    var clock: TimeInterval = 0
    var typingPause: TimeInterval = 0

    for token in script.components(separatedBy: ";") where !token.isEmpty {
        if token.hasPrefix("d"), let seconds = Double(token.dropFirst()) {
            clock += seconds
        } else if token.hasPrefix("p"), let millis = Double(token.dropFirst()) {
            typingPause = millis / 1000
        } else if token.hasPrefix("t:") {
            for character in token.dropFirst(2) {
                let code = qwerty[Character(character.lowercased())] ?? 0
                steps.append(KeyStep(at: clock, keyCode: code, characters: String(character)))
                clock += max(typingPause, 0.012)
            }
        } else if token.hasPrefix("c:"), let character = token.dropFirst(2).first {
            let code = qwerty[Character(character.lowercased())] ?? 0
            steps.append(KeyStep(at: clock, keyCode: code, characters: String(character), modifiers: .command))
            clock += 0.05
        } else if let (code, characters) = specialKeys[token] {
            steps.append(KeyStep(at: clock, keyCode: code, characters: characters))
            clock += 0.05
        } else {
            FileHandle.standardError.write("unknown key token '\(token)'\n".data(using: .utf8)!)
        }
    }
    return steps
}

func post(_ step: KeyStep) {
    let number = liveWindow?.windowNumber ?? 0
    for type in [NSEvent.EventType.keyDown, .keyUp] {
        guard let event = NSEvent.keyEvent(
            with: type, location: .zero, modifierFlags: step.modifiers,
            timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: number,
            context: nil, characters: step.characters,
            charactersIgnoringModifiers: step.characters, isARepeat: false, keyCode: step.keyCode
        ) else { continue }
        NSApp.postEvent(event, atStart: false)
    }
}

/// Pumps for `seconds`, posting each planned key as its moment arrives.
func pump(_ seconds: TimeInterval, script: [KeyStep] = []) {
    let start = Date()
    let deadline = start.addingTimeInterval(seconds)
    var next = 0
    while Date() < deadline {
        while next < script.count, Date().timeIntervalSince(start) >= script[next].at {
            post(script[next])
            next += 1
        }
        let slice = min(deadline, Date().addingTimeInterval(0.008))
        guard let event = app.nextEvent(matching: .any, until: slice, inMode: .default, dequeue: true) else { continue }
        // `NSApplication.sendEvent` reaches the responder chain through the
        // event's own window, so a parked window still gets its keys and the
        // router's local monitor still runs first. Forwarding a second copy
        // to the window here delivers everything twice, which reads as a
        // control that ignores every other press.
        app.sendEvent(event)
    }
}

func capture(_ window: NSWindow, to path: String) -> Bool {
    guard let content = window.contentView else { return false }
    let bounds = content.bounds
    guard bounds.width > 1, bounds.height > 1 else { return false }
    let scale: CGFloat = 2
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(bounds.width * scale),
        pixelsHigh: Int(bounds.height * scale),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return false }
    rep.size = bounds.size

    NSGraphicsContext.saveGraphicsState()
    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
        NSGraphicsContext.restoreGraphicsState()
        return false
    }
    NSGraphicsContext.current = ctx
    content.displayIfNeeded()
    content.layer?.render(in: ctx.cgContext)
    ctx.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:]) else { return false }
    return (try? png.write(to: URL(fileURLWithPath: path))) != nil
}

// MARK: - Surfaces

func makeWindow(_ state: RenderState, data: Data) -> NSWindow? {
    let decoder = JSONDecoder()
    let position = DialogPosition.center
    let noop: (String?) -> Void = { _ in }

    switch state.dir {
    case "confirm":
        guard let r = try? decoder.decode(ConfirmRequest.self, from: data) else { return nil }
        let spec = ConfirmSpec(title: r.title, body: r.body, confirmLabel: r.confirmLabel,
                               cancelLabel: r.cancelLabel, position: r.position ?? position,
                               onConfirm: noop, onCancel: noop, onSnooze: { _ in }, onAskDifferently: { _ in })
        return DialogManager.shared.createSkinnedWindow(.confirm, position: spec.position) { $0.confirmView(spec) }.0

    case "choose":
        guard let r = try? decoder.decode(ChooseRequest.self, from: data) else { return nil }
        let spec = ChooseSpec(title: r.title ?? DialogManager.shared.getClientName(), body: r.body,
                              choices: r.choices, descriptions: r.descriptions,
                              allowMultiple: r.allowMultiple, allowOther: r.allowOther,
                              defaultSelection: r.defaultSelection, position: r.position ?? position,
                              onComplete: { _, _, _ in }, onCancel: noop, onSnooze: { _ in }, onAskDifferently: { _ in })
        return DialogManager.shared.createSkinnedWindow(.choose, position: spec.position) { $0.chooseView(spec) }.0

    case "text-input":
        guard let r = try? decoder.decode(TextInputRequest.self, from: data) else { return nil }
        let spec = TextInputSpec(title: r.title, body: r.body, isHidden: r.hidden,
                                 defaultValue: r.defaultValue, position: r.position ?? position,
                                 onSubmit: { _, _ in }, onCancel: noop, onSnooze: { _ in }, onAskDifferently: { _ in })
        return DialogManager.shared.createSkinnedWindow(.textInput, position: spec.position) { $0.textInputView(spec) }.0

    case "questions":
        guard let r = try? decoder.decode(QuestionsRequest.self, from: data) else { return nil }
        let spec = QuestionsSpec(title: r.title ?? DialogManager.shared.getClientName(), body: r.body,
                                 questions: r.questions, position: r.position ?? position,
                                 onComplete: { _, _, _, _, _ in }, onCancel: { _, _ in },
                                 onSnooze: { _ in }, onAskDifferently: { _ in })
        return DialogManager.shared.createSkinnedWindow(.questions, position: spec.position) { $0.questionsView(spec) }.0

    case "notify":
        guard let r = try? decoder.decode(NotifyRequest.self, from: data) else { return nil }
        let spec = NotifySpec(title: r.title, body: r.body)
        return DialogManager.shared.createSkinnedWindow(.notify, position: position) { $0.notifyView(spec) }.0

    case "preview":
        guard let r = try? decoder.decode(PreviewRequest.self, from: data) else { return nil }
        let spec = PreviewSpec(body: r.body)
        return DialogManager.shared.createSkinnedWindow(.preview, position: position) { $0.previewView(spec) }.0

    default:
        return nil
    }
}

// MARK: - Drive

let states = loadManifest().filter { state in
    if let exact { return state.name == exact }
    return filter.isEmpty || state.name.contains(filter)
}
var shot: [String] = []
var missed: [String] = []

for state in states {
    guard let data = fixtureData(state) else {
        missed.append("\(state.name) (no fixture)")
        continue
    }

    DialogManager.shared.setProjectPath(state.project == "none" ? nil : (state.project ?? defaultProject))
    DialogManager.shared.testPane = state.pane

    guard let window = makeWindow(state, data: data) else {
        missed.append("\(state.name) (unknown kind \(state.dir))")
        continue
    }

    liveWindow = window
    window.setFrameOrigin(parkedOrigin)
    window.orderFront(nil)
    window.makeKey()
    window.becomeKey()
    if ProcessInfo.processInfo.environment["RENDER_DEBUG"] != nil {
        print("   keyWindow=\(NSApp.keyWindow != nil) isKey=\(window.isKeyWindow) active=\(NSApp.isActive)")
    }

    // The product arms the cooldown as the surface comes forward.
    if state.dir != "notify" && state.dir != "preview" {
        CooldownManager.shared.startCooldown()
    }
    pump(state.settle, script: plan(state.keys ?? ""))

    if ProcessInfo.processInfo.environment["RENDER_DEBUG"] != nil {
        let responder = window.firstResponder.map { String(describing: type(of: $0)) } ?? "nil"
        print("   firstResponder=\(responder) cooling=\(CooldownManager.shared.isCoolingDown) progress=\(CooldownManager.shared.progress)")
    }
    if capture(window, to: "\(outDir)/\(state.name).png") {
        shot.append(state.name)
        print("ok   \(state.name)")
    } else {
        missed.append(state.name)
        print("MISS \(state.name)")
    }

    // Tear the view tree down before the next state is built. Each surface
    // installs a key monitor and holds it until `onDisappear`; leave one alive
    // and it eats the next state's keys, which shows up as a surface that
    // ignored its script. Dropping the content view forces the teardown, and
    // the pump gives SwiftUI the turn it needs to run it.
    liveWindow = nil
    window.orderOut(nil)
    window.contentView = nil
    window.close()
    DialogManager.shared.sizeObserver = nil
    DialogManager.shared.testPane = nil
    pump(0.30)
    FocusManager.shared.reset()
    CooldownManager.shared.reset()
}

// MARK: - Contact sheet
//
// Skipped when driven one state per process; the shell assembles it then.

if exact != nil {
    restoreSettings()
    exit(missed.isEmpty ? 0 : 1)
}

let sheet = """
<!doctype html><meta charset=utf-8><title>\(skinID) states</title>
<style>body{background:#141416;color:#e8e8ea;font:13px -apple-system,sans-serif;margin:24px}
h1{font-size:15px;letter-spacing:.08em;text-transform:uppercase;color:#98989f}
.g{display:grid;grid-template-columns:repeat(auto-fill,minmax(420px,1fr));gap:20px}
figure{margin:0}figcaption{font:11px ui-monospace,monospace;color:#98989f;padding:6px 0}
img{max-width:100%;border-radius:8px;display:block}</style>
<h1>\(skinID) — \(shot.count) states\(missed.isEmpty ? "" : ", \(missed.count) missed")</h1>
<div class=g>
\(shot.map { "<figure><img src=\"\(outDir)/\($0).png\"><figcaption>\($0)</figcaption></figure>" }.joined(separator: "\n"))
</div>
"""
let sheetPath = manifestURL.deletingLastPathComponent().appendingPathComponent("index.html")
try? sheet.write(to: sheetPath, atomically: true, encoding: .utf8)

if !missed.isEmpty { print("missed: \(missed.joined(separator: ", "))") }
print("contact sheet: \(sheetPath.path)")
restoreSettings()
exit(missed.isEmpty ? 0 : 1)
