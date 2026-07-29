import Foundation

/// The switch. Resolves which `DialogSkin` renders this invocation and hands
/// it to every `DialogManager` entry point.
///
/// Precedence: `DIALOG_SKIN` env var → `skin` in settings.json → classic.
enum SkinRegistry {
    struct Entry {
        let id: String
        let displayName: String
        let make: () -> DialogSkin
    }

    /// The only wiring a new skin needs: add an entry, it becomes selectable.
    static let entries: [Entry] = [
        Entry(id: ClassicSkin.identifier, displayName: "Classic", make: { ClassicSkin() }),
        Entry(id: AltSkin.identifier, displayName: "Alt", make: { AltSkin() }),
        Entry(id: BracketSkin.identifier, displayName: "Bracket", make: { BracketSkin() }),
        Entry(id: CaretSkin.identifier, displayName: "Caret", make: { CaretSkin() }),
    ]

    static let fallbackID = ClassicSkin.identifier

    private(set) static var active: DialogSkin = ClassicSkin()

    static var availableIDs: [String] { entries.map(\.id) }

    /// Called once from `Main.run()` before any dialog is built.
    static func resolve(settings: UserSettings) {
        let requested = ProcessInfo.processInfo.environment["DIALOG_SKIN"] ?? settings.skin
        activate(named: requested)
    }

    static func activate(named name: String) {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard let entry = entries.first(where: { $0.id == key }) else {
            if !key.isEmpty {
                fputs("Unknown skin '\(name)'. Available: \(availableIDs.joined(separator: ", ")). Using \(fallbackID).\n", stderr)
            }
            active = ClassicSkin()
            return
        }

        active = entry.make()
        if let theme = active.preferredTheme {
            ThemeManager.shared.setTheme(theme)
        }
    }
}
