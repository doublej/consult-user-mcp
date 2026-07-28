# Consult User MCP

An MCP server that gives an agent a way to actually ask the user something — native dialogs on macOS and Windows, returning structured JSON. The agent blocks until the user answers, snoozes, or cancels.

<vocabulary>
Canonical terms are defined in GLOSSARY.md. Use these names exactly — they are this project's ubiquitous language.
Core: Dialog, Pane, Feedback, Form, Wizard, Snooze, Ask Differently, Skin, Theme, Baseprompt, Provider, Dialog CLI, Tray App.
The same dialog has a different name at each layer (MCP `pick` = CLI `choose` = `SwiftUIChooseDialog`). That is by design — see the Layer Translation table in GLOSSARY.md before renaming anything.
Full glossary: ./GLOSSARY.md
</vocabulary>

## Architecture map

One MCP server, two platform implementations behind a single `DialogProvider` interface.

| Folder | What it is |
|---|---|
| `mcp-server/` | The MCP server. Tool surface, response compaction, provider selection. TypeScript, Bun. |
| `dialog-cli/` | macOS Dialog CLI. Ephemeral — spawned per dialog, prints JSON, exits. Swift/SwiftUI. |
| `macos-app/` | macOS Tray App. Persistent. Owns settings, history, updates, install, debug menu. |
| `dialog-cli-windows/` | Windows Dialog CLI. Mirrors `dialog-cli/`. .NET/WPF. |
| `windows-app/` | Windows Tray App. Mirrors `macos-app/`. .NET/WPF. |
| `sketch-cli/` | Grid layout editor behind `propose_layout`. Separate Swift CLI, macOS only. |
| `test-cases/` | JSON fixtures + screenshot runner. Feeds both the test runner and the debug menu. |
| `docs/` | SvelteKit docs site. Owns `releases.json`, the release source of truth. |
| `scripts/` | Build, install, release, and validation shell scripts. |

The two processes on each platform talk through files, not IPC: the Tray App writes `settings.json` and snooze state, the Dialog CLI reads them on launch.

## Context boundaries

Read the folder's `CLAUDE.md` before editing inside it. Each one carries invariants that are expensive to rediscover:

- `dialog-cli/CLAUDE.md` — before touching any dialog, skin, or keyboard behaviour
- `macos-app/CLAUDE.md` — before touching settings, the debug menu, or install/update flows
- `mcp-server/CLAUDE.md` — before touching the tool surface or providers
- `dialog-cli-windows/CLAUDE.md`, `windows-app/CLAUDE.md` — before any Windows work
- `test-cases/CLAUDE.md` — before adding a dialog type or changing a fixture
- `docs/CLAUDE.md`, `sketch-cli/CLAUDE.md`

## Global invariants

- **Development builds must go through `bun run dev`.** The installed app at `/Applications/Consult User MCP.app` runs its own bundled binaries. A bare `swift build` compiles locally and changes nothing about what actually runs. Restart the tray app afterwards.
- **All dialog types must be considered together.** Adding or changing one touches the MCP server, both CLIs, the test fixtures, the test runner, and the debug menu. The full checklist is in `.claude/rules/dialog-parity.md`.
- **Nothing Windows can be built or verified from macOS.** See the `windows-build` skill.
- **`CHANGELOG.md` is generated** from `docs/src/lib/data/releases.json`. Never hand-edit it.
- **The Baseprompt is versioned independently** of the apps, and its content and version bump together. See `.claude/rules/baseprompt.md`.

## Dialog types

Eight surfaces across four MCP tools: `ask` (interactive), `notify`, `tweak`, `propose_layout` (macOS only).

| Dialog | `ask` type | CLI command | Response |
|---|---|---|---|
| Confirm | `confirm` | `confirm` | `answer: bool` |
| Single-select | `pick` | `choose` | `answer: string` |
| Multi-select | `pick` + `multi` | `choose` | `answer: string[]` |
| Text input | `text` | `textInput` | `answer: string` |
| Password input | `text` + `hidden` | `textInput` | `answer: string` |
| Form | `form` | `questions` | `answer: Record<id, string \| string[]>` |
| Notification | — (`notify`) | `notify` | fire-and-forget |
| Value tweak | — (`tweak`) | `tweak` | `answer: Record<id, number>` |

Every interactive dialog can also return `snoozed`, `askDifferently`, `feedbackText`, or `cancelled`. Field-level detail lives in the tool schemas and `mcp-server/CLAUDE.md`.

Shared inputs: `position` (`left`/`center`/`right`), `project_path`, and the env vars `MCP_CLIENT_NAME`, `DIALOG_THEME`, `DIALOG_SKIN`.

## Commands

```bash
bun run dev            # build all + install to /Applications — the dev workflow
bun run build          # mcp-server + dialog-cli only, no install
bun run build:bundle   # full release bundle from scratch
bun test               # mcp-server tests
bun run test:visual    # screenshot every test case
bun run changelog      # regenerate CHANGELOG.md from releases.json
```

`just` also has recipes — `just --list`. Release procedures are in the `release-app` skill; Windows builds in `windows-build`.
