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

// MARK: - Run loop

/// Drives `NSApp` directly. Local event monitors are invoked from `sendEvent`,
/// so the key router sees injected keys exactly as it sees real ones, and the
/// main queue drains so cooldown timers and reflow notifications land.
func pump(_ seconds: TimeInterval) {
    let deadline = Date().addingTimeInterval(seconds)
    while Date() < deadline {
        guard let event = app.nextEvent(matching: .any, until: deadline, inMode: .default, dequeue: true) else { continue }
        app.sendEvent(event)
    }
}

// MARK: - Capture

let parkedOrigin = NSPoint(x: -30_000, y: -30_000)

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
    if let keys = state.keys { setenv("DIALOG_TEST_KEYS", keys, 1) } else { unsetenv("DIALOG_TEST_KEYS") }

    guard let window = makeWindow(state, data: data) else {
        missed.append("\(state.name) (unknown kind \(state.dir))")
        continue
    }

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
    TestKeyDriver.installIfRequested()

    pump(state.settle)

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
    unsetenv("DIALOG_TEST_KEYS")
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
