# Tray App (macOS)

## What this is

The persistent half of the macOS product. A menu-bar app that owns user settings, dialog history, project tracking, updates, the install wizard, and a debug menu for firing test dialogs. It never shows a dialog itself — it configures the [[Dialog CLI]] that does.

Swift + SwiftUI + AppKit, flat `Sources/`. ~7.8k LOC.

## Mental model

**Two processes, one file.** The Tray App and the Dialog CLI never talk directly. They share `~/Library/Application Support/ConsultUserMCP/settings.json`.

The direction of travel is not one-way:

- Tray App → file: user preferences, exported from `@AppStorage`.
- Dialog CLI → file: `snoozeUntil`, written when the user snoozes from inside a dialog.
- Tray App polls the file (`pollTimer` + `lastModified` in `DialogSettings.swift`) to notice snoozes it did not make.

So `@AppStorage`/`UserDefaults` is the tray app's own store, and `settings.json` is the **contract** with the CLI. A setting that only exists in `@AppStorage` is invisible to dialogs.

**The app bundle is the delivery mechanism.** `Contents/Resources/` carries the [[Baseprompt]], the Dialog CLI binary, and the Sketch CLI binary. `bun run dev` is what refreshes them.

## Important invariants

- **The debug menu loads dialog JSON from `test-cases/cases/`.** Never hardcode dialog JSON in `AppDelegate.swift`. Adding a dialog type means adding fixtures there and wiring a menu item — not pasting a literal.
- **A new user-facing setting needs three edits, not one:** the `@AppStorage` property here, the export into `settings.json`, and the reader in `dialog-cli/Sources/DialogCLI/Utilities/UserSettings.swift`. Miss the third and the setting appears to work and does nothing.
- **`~/Library/Application Support/ConsultUserMCP/` cannot be renamed.** Existing users' settings, history, and snooze state live there.
- **The bundled `base-prompt.md` is what clients actually receive.** Editing the source under `Sources/Resources/` changes nothing until `bun run dev` copies it. See `.claude/rules/baseprompt.md`.
- **AFK mode short-circuits everything.** When on, dialogs return `{"afk": true}` without being shown. Auto-triggers on sleep and idle are separate flags from the manual toggle (`afkAutoEnabled`), so a manual toggle is not auto-cleared.

## Common change patterns

**Adding a setting** → `DialogSettings.swift` property, the settings.json export, the CLI reader, and a control in the relevant `*SettingsView.swift`.

**Adding a debug-menu dialog** → a fixture in `test-cases/cases/<type>/`, then a menu item in `AppDelegate.swift` that loads it.

**Touching install or update flows** → `InstallWizard.swift`, `InstallHelper.swift`, `ClaudeMdInstaller.swift`, `UpdateManager.swift`. These write outside the app's own container; test on a clean-ish account if you can.

`AppDelegate.swift` is ~33KB and does menu construction, notifications, and dialog spawning. Split it along those seams if you are already in there — but keep the debug-menu-loads-from-fixtures invariant intact.

## Verification

```bash
bun run dev     # from repo root — builds and installs, then restart the tray app
```

There are no automated tests here. Verify by hand: open the debug menu, fire each dialog type, confirm settings changes reach a live dialog.

`bash scripts/validate-baseprompt-version.sh` gates baseprompt edits.

## Related context

- `../dialog-cli/CLAUDE.md` — the process on the other side of `settings.json`
- `../test-cases/CLAUDE.md` — where debug-menu fixtures come from
- `.claude/rules/baseprompt.md`, `.claude/skills/release-app/SKILL.md`
