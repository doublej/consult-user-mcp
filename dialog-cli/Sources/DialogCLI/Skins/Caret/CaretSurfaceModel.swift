import AppKit
import SwiftUI

/// The six shapes a question can be re-posed as (§3.7), in the fixed order the
/// spec gives them.
struct CaretShape {
    let title: String
    let id: String

    static let all: [CaretShape] = [
        CaretShape(title: "Confirmation", id: "confirm"),
        CaretShape(title: "Single Select", id: "pick"),
        CaretShape(title: "Multi Select", id: "pick-multi"),
        CaretShape(title: "Text Input", id: "text"),
        CaretShape(title: "Password", id: "text-hidden"),
        CaretShape(title: "Wizard Form", id: "form-wizard"),
    ]
}

/// Which surface this is. The badge is drawn on the top-leading arm so a
/// masked field is tellable from a plain one, and a multi-select set from a
/// single-select one, before the person does anything (§1.1).
enum CaretKind {
    case confirm
    case pick
    case pickMulti
    case text
    case secret
    case form
    case notify
    case preview

    var badge: String {
        switch self {
        case .confirm: return "CONFIRM"
        case .pick: return "PICK"
        case .pickMulti: return "PICK-MULTI"
        case .text: return "INPUT"
        case .secret: return "SECRET"
        case .form: return "FORM"
        case .notify: return "NOTIFY"
        case .preview: return "PREVIEW"
        }
    }

    /// The entry the shape list marks as current and unavailable.
    var currentShape: String? {
        switch self {
        case .confirm: return "confirm"
        case .pick: return "pick"
        case .pickMulti: return "pick-multi"
        case .text: return "text"
        case .secret: return "text-hidden"
        case .form: return "form-wizard"
        case .notify, .preview: return nil
        }
    }

    var interactive: Bool {
        switch self {
        case .notify, .preview: return false
        default: return true
        }
    }
}

/// One way out.
struct CaretActionSpec {
    var label: String
    var role: CaretActionRole
    var key: String?
    var keyAvailable: Bool = true
    var enabled: Bool = true
    var run: () -> Void
}

/// Everything the container holds on the surface's behalf: the annotation
/// drafts, which tool is expanded, the report flow's position, where the caret
/// stands, and how much of the opening cooldown is left.
@MainActor
final class CaretSurfaceModel: ObservableObject {
    /// Keyed by annotation target. `""` is the surface- or form-level note.
    @Published var noteDrafts: [String: String] = [:]
    @Published var openNote: String?
    @Published var trayOpen = false
    @Published var shapesOpen = false
    @Published var reportStep = 0
    @Published var reportText = ""
    @Published var focusRect: CGRect?
    /// True while a caret sits in any field — §3.8 needs this to say which
    /// keys are actually available right now.
    @Published var editing = false
    @Published var cooldown: Double = 1

    var reportShot: Data?

    /// Whitespace-only counts as empty everywhere (§3.6).
    func note(_ key: String) -> String? {
        let trimmed = (noteDrafts[key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func hasNote(_ key: String) -> Bool { note(key) != nil }

    var anyNote: Bool { noteDrafts.keys.contains { hasNote($0) } }

    var surfaceNote: String? { note("") }

    func binding(_ key: String) -> Binding<String> {
        Binding(
            get: { self.noteDrafts[key] ?? "" },
            set: { self.noteDrafts[key] = $0 }
        )
    }

    /// The shape list and the report flow take the whole surface; while either
    /// is up the targets beneath must not be focusable or clickable.
    var inert: Bool { shapesOpen || reportStep > 0 }

    /// Live key availability (§3.8, and the fix for §10.4).
    var lettersLive: Bool { cooldown >= 1 && !editing && openNote == nil && !inert }
    var chordLive: Bool { cooldown >= 1 && openNote == nil && !inert }
    var commitKeyLive: Bool { cooldown >= 1 && !inert }

    func reflow(resizingWidth: Bool = false) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .dialogContentSizeChanged,
                object: nil,
                userInfo: resizingWidth ? ["resizeWidth": true] : nil
            )
        }
    }
}

// MARK: - Inertness

private struct CaretInertKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var caretInert: Bool {
        get { self[CaretInertKey.self] }
        set { self[CaretInertKey.self] = newValue }
    }
}

// MARK: - The one key the router delegates

/// `A` is LAW (§4.1) and the router binds it to the default style's shape
/// menu. This layer draws its own, so the router is handed no
/// `onAskDifferently` — which makes it pass `A` through untouched — and this
/// monitor picks it up. It handles exactly one key and no policy: everything
/// else, including the Escape stack that closes the list, stays with the
/// router.
final class CaretShapeKeyMonitor {
    private var monitor: Any?

    init(shouldHandle: @escaping () -> Bool, toggle: @escaping () -> Void) {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.keyCode == KeyCode.a,
                  !event.modifierFlags.contains(.command),
                  !CooldownManager.shared.shouldBlockKey(event.keyCode),
                  !KeyboardContext.isEditingText,
                  shouldHandle()
            else { return event }
            toggle()
            return nil
        }
    }

    deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
    }
}
