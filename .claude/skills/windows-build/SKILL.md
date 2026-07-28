---
name: windows-build
description: Build, run, or debug the Windows side of Consult User MCP (dialog-cli-windows WPF CLI, windows-app tray app, Velopack installer) over SSH to the Windows machine. Use when asked to build/test/fix anything Windows in this project, when a change touches dialog-cli-windows/ or windows-app/, or when the Windows installer needs rebuilding.
---

# Windows builds

Nothing Windows can be built or tested from macOS. .NET/WPF and Velopack need the real environment.

```bash
ssh user@192.168.178.197
```

Repo: `C:\Users\jurre\PycharmProjects\consult-user-mcp`

Commands run through `cmd.exe` by default. For PowerShell use `powershell -Command "..."` or `powershell -ExecutionPolicy Bypass -File ...`.

## Prerequisites on that machine

`dotnet` SDK 8.0 · `node`/`npm` · `gh` CLI (authenticated) · `vpk` (`dotnet tool install -g vpk`)

## Builds

```bash
cd dialog-cli-windows && dotnet publish -r win-x64 --self-contained -p:PublishSingleFile=true
cd windows-app && dotnet build                    # dev
cd windows-app && dotnet publish -c Release -r win-x64 --self-contained
powershell -ExecutionPolicy Bypass -File scripts\build-windows-installer.ps1
```

## Gotchas

- **stderr aborts the installer script.** `build-windows-installer.ps1` sets `$ErrorActionPreference = "Stop"`, so a Node.js `ExperimentalWarning` on stderr kills the build. The script flips it to `Continue` around npm/npx calls — wrap any new npm command the same way.
- **`dialog-cli-windows/` cannot be renamed to `dialog-cli/`.** It would collide with the macOS Swift CLI directory.
- **`%APPDATA%\ConsultUserMCP` cannot be renamed.** Existing users' settings and snooze state live there.
- **Velopack + WPF setup is unusual.** `App.xaml` is a `Page`, not an `ApplicationDefinition`; the entry point is a custom `Main` with `StartupObject` set in the csproj. Do not "fix" this back to the WPF default.
- `<UseWPF>true</UseWPF>` and a `net8.0-windows` target are both required.
- `System.Drawing` needs an explicit `System.Drawing.Common` NuGet reference on .NET 8.

## Parity

The Windows dialog CLI must accept the same JSON and print the same response shape as the macOS one — `mcp-server` calls both through one `DialogProvider` interface. See `.claude/rules/dialog-parity.md`.

`tweak` and `propose_layout` are macOS-only; `WindowsDialogProvider` throws for both. That is intentional, not a bug to fix incidentally.
