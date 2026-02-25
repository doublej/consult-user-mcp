# Consult User MCP

## Development Workflow

The installed app at `/Applications/Consult User MCP.app` runs its own bundled binaries. Local builds do NOT update the installed app.

**MUST use `bun run dev` for all development builds.** Builds dialog-cli, mcp-server, macos-app in debug mode and copies binaries into the installed app bundle. Restart the tray app after to pick up changes.

```bash
bun run dev          # Build all + install to /Applications (dev workflow)
bun run build        # Build mcp-server + dialog-cli only (no install)
bun run build:bundle # Full release build + create app bundle from scratch
```

**NEVER** use bare `swift build` or `bun run build` during development — those compile locally but do not update the running app.

## Release Checklist

### macOS

1. Update `macos-app/VERSION` with the new version number
2. **If baseprompt changed:** update version in `macos-app/Sources/Resources/base-prompt.md` (first line comment)
3. Update `docs/src/lib/data/releases.json` (single source of truth)
4. Generate CHANGELOG: `bun run changelog`
5. Validate versions: `bash scripts/validate-baseprompt-version.sh`
6. Commit all changes
7. Run: `bash scripts/release.sh --platform macos` — builds, zips, tags, creates GitHub release

Use `--dry-run` to validate preconditions without executing.


## Dialog Types & MCP Tools

3 MCP tools: `ask` (interactive), `notify` (fire-and-forget), and `tweak` (value adjustment pane). When adding features, fixing bugs, or writing tests — **ALL dialog types MUST be considered**.

**Invariant:** The debug menu loads test cases from `test-cases/cases/` JSON files — no hardcoded dialog JSON in AppDelegate. When adding a new dialog type, add JSON files to `test-cases/cases/` and wire them into the debug menu. The `test-runner.sh` command mapping must also include the new type.

### All dialog types (flattened)

| # | Dialog | `ask` type | CLI command | Key params | Response |
|---|--------|-----------|-------------|------------|----------|
| 1 | **Confirm** | `confirm` | `confirm` | `body`, `title`, `yes`, `no` | `answer: bool` |
| 2 | **Single-select** | `pick` | `choose` | `body`, `choices[]`, `descriptions[]?`, `default?` | `answer: string` |
| 3 | **Multi-select** | `pick` | `choose` | `body`, `choices[]`, `descriptions[]?`, `multi: true` | `answer: string[]` |
| 4 | **Text input** | `text` | `textInput` | `body`, `title`, `default` | `answer: string` |
| 5 | **Password input** | `text` | `textInput` | `body`, `title`, `hidden: true` | `answer: string` |
| 6 | **Wizard form** | `form` | `questions` | `body`, `questions[]`, `mode: "wizard"` | `answer: Record<id, string\|string[]>` |
| 7 | **Accordion form** | `form` | `questions` | `body`, `questions[]`, `mode: "accordion"` | `answer: Record<id, string\|string[]>` |
| 8 | **Notification** | — (`notify`) | `notify` | `body`, `title`, `sound` | fire-and-forget |
| 9 | **Value tweak** | — (`tweak`) | `tweak` | `body`, `parameters[]` | `answer: Record<id, number>` |

`questions[]` items: `id`, `question`, `type?` (`"choice"` default, `"text"`), `options[]` (required for choice), `descriptions[]?`, `multi`, `placeholder?`, `hidden?`.

`parameters[]` items: `id`, `label`, `file`, `line`, `column`, `expectedText`, `current`, `min`, `max`, `step?`, `unit?`.

### Shared parameters (all `ask` and `tweak` types)

`position` (`"left"` / `"center"` / `"right"`), `project_path` (shows project badge), `MCP_CLIENT_NAME` env var (prefixes title), `DIALOG_THEME` env var (`"sunset"` / `"midnight"` / system default).

### Shared response states (all interactive dialogs)

Every `ask` and `tweak` dialog can return: normal `answer`, `snoozed: true`, `askDifferently: "<type>"`, `feedbackText`, or `cancelled: true`. Responses compacted by `compact.ts` (strips null fields, maps `confirmed` → `answer: bool`, merges `dismissed` into `cancelled`). Compact priority: snoozed > askDifferently > feedbackText > cancelled > answer.

### Windows (MUST run on Windows machine)

.NET/WPF and Velopack require a Windows environment.

```bash
ssh user@192.168.178.197
```

Repo: `C:\Users\jurre\PycharmProjects\consult-user-mcp`. Commands run via `cmd.exe` by default; use `powershell -Command "..."` or `powershell -ExecutionPolicy Bypass -File ...` for PowerShell.

**Prerequisites:** `dotnet` SDK 8.0, `node`/`npm`, `gh` CLI (authenticated), `vpk` (`dotnet tool install -g vpk`).

**Steps:**

1. On macOS: update `windows-app/VERSION`, `releases.json`, `bun run changelog`, commit + push
2. On Windows (via SSH):
   ```bash
   cd C:\Users\jurre\PycharmProjects\consult-user-mcp
   git checkout main && git pull
   powershell -ExecutionPolicy Bypass -File scripts\build-windows-installer.ps1
   ```
3. Create release from Windows (gh is authenticated, assets are local):
   ```bash
   git tag windows/vX.Y.Z HEAD && git push origin windows/vX.Y.Z
   gh release create windows/vX.Y.Z --title "Windows vX.Y.Z — ..." --notes "..." releases/windows/*
   ```

**NEVER** run `gh release create` without attaching assets — releases without assets break the auto-updater.

**Gotcha:** The build script uses `$ErrorActionPreference = "Stop"`, so Node.js stderr warnings (e.g. ExperimentalWarning) can abort it. The script temporarily sets `Continue` around npm/npx commands. Wrap new npm commands the same way.

## Baseprompt Versioning

The base prompt has an independent version number.

- **Location:** `macos-app/Sources/Resources/base-prompt.md` (first line: `<!-- version: X.Y.Z -->`)
- **Current:** v2.9.0
- **Validate:** `bash scripts/validate-baseprompt-version.sh` (also runs in CI)
- **Bump:** Major = breaking tool/workflow changes, Minor = new features/guidance, Patch = fixes/typos

## Windows Project Structure

| Directory | Output | Purpose |
|-----------|--------|---------|
| `dialog-cli-windows/` | `dialog-cli.exe` | WPF dialog CLI (ephemeral, spawned per dialog) |
| `windows-app/` | `consult-user-mcp.exe` | WPF tray app (persistent background process) |

Installer: Velopack-based (`scripts/build-windows-installer.ps1`), delta updates from GitHub Releases. First-run auto-configures Claude Code MCP server. User data: `%APPDATA%\ConsultUserMCP\`.

## Documentation Structure

- **`docs/src/lib/data/releases.json`** — single source of truth for app releases. Feeds /docs page, generates CHANGELOG.md via `bun run changelog`. Only app changes, never docs-only.
- **`CHANGELOG.md`** — auto-generated from releases.json. Do not edit manually.
- **`docs/src/lib/data/releases.schema.json`** — JSON schema for validation.

### Writing Changelists

Write **user-facing features and benefits**, not commit messages:

| Bad (commit-style) | Good (user-facing) |
|---|---|
| Add markdown support | Text input dialogs now support markdown formatting |
| Fix snooze crash | Snooze feature now works reliably without crashes |
| Refactor DialogManager | Dialogs now focus correctly when switching apps |
| Add execute permission | Installation script now runs without permission errors |
