# Tray App (Windows)

## What this is

The Windows counterpart to `macos-app/`. Persistent WPF tray application: settings, snooze, history, projects, updates, MCP auto-install, startup registration, and a debug dialog runner.

**Cannot be built or run from macOS.** See the `windows-build` skill.

## Mental model

Same two-process split as macOS. This app never shows a dialog; it configures the [[Dialog CLI]] that does, through files under `%APPDATA%\ConsultUserMCP\`:

- `settings.json` — user preferences, written here, read by the CLI
- `snooze-state.json` — snooze, written by whichever side the user triggered it from

Services are singletons (`SettingsManager`, `SnoozeManager`, `UpdateManager`). Settings views are plain WPF XAML + code-behind — there is no MVVM framework, and adding one is not a drive-by change.

`Hardcodet.NotifyIcon.Wpf` provides the tray icon; `System.Drawing.Common` generates icon images at runtime.

## Important invariants

- **Settings writes are atomic** — write to a temp file, then rename. A torn `settings.json` breaks every subsequent dialog.
- **`%APPDATA%\ConsultUserMCP` cannot be renamed.** Existing users' data lives there.
- **The Velopack bootstrap is deliberate and fragile.** `App.xaml` is a `Page`, not an `ApplicationDefinition`; the entry point is a custom `Main` with `StartupObject` set in the csproj. Reverting this to the WPF default breaks updates.
- **`MCPInstaller` writes outside this app.** It auto-configures the Claude Code MCP server on first run. Changes here affect a file the user may also edit by hand.
- **`StartupManager` writes to `HKCU\...\Run`.** Registry, not a config file.
- A settings key added here is invisible to dialogs until `SettingsReader.cs` in `dialog-cli-windows/` reads it too.

## Common change patterns

**Adding a setting** → the model in `Models/DialogSettings.cs`, the write in `Services/SettingsManager.cs`, a control in the relevant `Settings/*SettingsView.xaml`, and the reader in `dialog-cli-windows/Services/SettingsReader.cs`.

**Porting a macOS tray feature** → the service layout mirrors `macos-app/Sources/`. Match behaviour, not code shape; the UI frameworks are not comparable.

**Touching the installer** → `scripts/build-windows-installer.ps1`. It runs with `$ErrorActionPreference = "Stop"`, so any command that writes to stderr aborts the build. Wrap npm/npx calls the way the existing ones are wrapped.

## Verification

On the Windows machine only:

```
cd windows-app && dotnet build
powershell -ExecutionPolicy Bypass -File scripts\build-windows-installer.ps1
```

No automated tests. Verify by hand through the tray debug menu, and check that a settings change reaches a live dialog.

## Related context

- `.claude/skills/windows-build/SKILL.md` — SSH access, prerequisites, gotchas
- `.claude/skills/release-app/SKILL.md` — Windows release requires assets on the release
- `../dialog-cli-windows/CLAUDE.md` — the process on the other side of `settings.json`
- `../macos-app/CLAUDE.md` — the equivalent this mirrors
