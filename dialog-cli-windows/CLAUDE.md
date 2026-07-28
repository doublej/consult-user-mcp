# Dialog CLI (Windows)

## What this is

The Windows counterpart to `dialog-cli/`. Ephemeral WPF process, spawned per dialog, prints the same JSON contract, exits. .NET 8, `net8.0-windows`, `<UseWPF>true</UseWPF>`.

**Cannot be built or run from macOS.** See the `windows-build` skill.

## Mental model

Mirrors the macOS structure deliberately, so a change on one side has an obvious counterpart on the other:

| Here | macOS equivalent |
|---|---|
| `Services/DialogManager.*.cs` | `Services/DialogManager+*.swift` |
| `Dialogs/*.cs` | `Dialogs/SwiftUI*Dialog.swift` |
| `Components/DialogBase.cs` | `Window/BorderlessWindow.swift` + `DialogContainer` |
| `Theme/DialogTheme.cs` | `Theme/Theme.swift` |
| `Services/SettingsReader.cs` | `Utilities/UserSettings.swift` |

`DialogManager.Shared` is the singleton, split into partial classes — one file per dialog type. `DialogBase` is the abstract WPF `Window`: borderless, dark, draggable.

There is **no skin seam here.** That is a macOS-only concept so far; `DIALOG_SKIN` is ignored.

## Important invariants

- **The response JSON must match the macOS CLI exactly.** `mcp-server` runs both through one `DialogProvider` interface and one `compact.ts`. A field named differently here is a silent bug on Windows only.
- **`tweak` and `propose_layout` do not exist here.** `WindowsDialogProvider` throws before reaching this binary. Do not stub them into the command switch.
- **This directory cannot be renamed to `dialog-cli/`.** It would collide with the macOS Swift CLI.
- **`%APPDATA%\ConsultUserMCP` cannot be renamed.** Existing users' settings and snooze state live there.
- JSON convention: camelCase names, string enum converter, nulls ignored on write.

## Common change patterns

**Porting a macOS dialog change** → find the mirrored file from the table above. Keep the request and response models in lockstep; the models are the contract, the WPF layout is not.

**Adding a dialog type** → `Program.cs` command switch, `Services/DialogManager.<Type>.cs`, `Dialogs/<Type>Dialog.cs`, request/response models. Then the cross-platform checklist in `.claude/rules/dialog-parity.md`.

## Verification

On the Windows machine only:

```
cd dialog-cli-windows
dotnet publish -r win-x64 --self-contained -p:PublishSingleFile=true
dialog-cli.exe confirm "{\"body\":\"test\",\"title\":\"t\"}"
```

Compare the printed JSON against the macOS CLI for the same input. That diff is the real test.

## Related context

- `.claude/skills/windows-build/SKILL.md` — SSH access, prerequisites, gotchas
- `../dialog-cli/CLAUDE.md` — the implementation this mirrors
- `../windows-app/CLAUDE.md` — the tray app that writes the settings this reads
- `.claude/rules/dialog-parity.md`
