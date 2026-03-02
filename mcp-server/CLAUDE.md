# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
bun install          # Install dependencies
bun run build        # Compile TypeScript + Swift CLI
bun run build:ts     # TypeScript only
bun run start        # Run the compiled server
bun run dev          # Watch mode for development
bun test             # Run tests
```

## Architecture

This is an MCP (Model Context Protocol) server that exposes native UI dialogs as tools for LLMs. Supports macOS (Swift/AppKit) and Windows (WPF/.NET).

```
src/
├── index.ts                 # MCP server + tool registration (ask, notify, tweak, propose_layout)
├── compact.ts               # Response transformer (provider → compact output)
├── css-resolver.ts          # CSS selector/property → file location resolver (for tweak)
├── humanize.ts              # Optional human-readable response formatting
├── resolve-utils.ts         # Shared resolution utilities for tweak parameters
├── settings.ts              # User settings reader
├── text-search-resolver.ts  # Text pattern search → file location resolver (for tweak)
├── types.ts                 # Shared types and interfaces
├── update-check.ts          # GitHub release update checker
├── validate-choices.ts      # Choice validation (no "all of above")
├── index.test.ts            # Tests
├── providers/
│   ├── interface.ts         # DialogProvider interface
│   ├── swift.ts             # macOS: Swift CLI + sketch CLI implementation
│   └── windows.ts           # Windows: WPF CLI implementation
```

**Provider pattern**: Platform-specific code is abstracted behind `DialogProvider` interface. `createProvider()` in `index.ts` selects `WindowsDialogProvider` on Windows, `SwiftDialogProvider` on macOS.

**Tool architecture**: Each tool in `index.ts`:
1. Defines Zod schema for inputs
2. Registers via `server.registerTool()` with metadata
3. Delegates to `provider.methodName()` for platform execution

**Key files**:
- `types.ts`: `DialogPosition`, option interfaces, result types
- `providers/interface.ts`: `DialogProvider` interface contract
- `providers/swift.ts`: macOS implementation using Swift CLI
- `providers/windows.ts`: Windows implementation using WPF CLI

## Available Tools

| Tool | Purpose |
|------|---------|
| `ask` | Unified interactive dialog (type: confirm/pick/text/form) |
| `notify` | Notification banner |
| `tweak` | Real-time numeric value adjustment with live file writes |
| `propose_layout` | Interactive grid layout editor (macOS only) |

The `ask` tool routes to provider methods via `type` field:
- `confirm` → `provider.confirm()` — Yes/No
- `pick` → `provider.choose()` — List picker (single or multi-select)
- `text` → `provider.textInput()` — Free-form input (supports password masking)
- `form` → `provider.questions()` — Multi-question (wizard or accordion)

Responses are transformed by `compact.ts` to strip verbose/null fields.

## Checkpoints & Rewind Limitations

**IMPORTANT**: These tools are designed as checkpoints to replace `AskUserQuestion` in MCP workflows, BUT they have a critical limitation with Claude Code's rewind feature:

- ❌ **MCP tool interactions do NOT create rewind points**
- ✅ **Only user text messages create rewind points**

This means:
- When Claude uses `ask`, your response via the dialog won't appear in the rewind timeline
- You cannot rewind to restore code/conversation state at MCP interaction points
- Only your typed messages in the chat create restore points

**Recommended Workaround**: Use pre/post-change hooks to commit to a `claude/*` branch:

```bash
# In your Claude Code settings, configure hooks:
# Pre-change hook (before MCP checkpoint):
git add -A && git commit -m "checkpoint: before $(date +%H:%M:%S)" --allow-empty

# Post-change hook (after MCP response):
git add -A && git commit -m "checkpoint: after user response $(date +%H:%M:%S)"
```

This creates git commits at each checkpoint, giving you:
- ✅ Actual code state snapshots
- ✅ Easy revert via `git checkout <commit>`
- ✅ Timeline of all checkpoints via `git log`
- ✅ Works independently of Claude Code's rewind feature

**Alternative**: Send a brief text message (e.g., "approved") after checkpoints to create a rewind point, but this only restores conversation, not code state.

**Why this matters**: While these tools provide excellent control over Claude's workflow, they're invisible to the rewind feature, making it harder to jump back to key decision points without git-based checkpoints.

## Common Parameters

All dialog tools support:
- `position`: `"left"` | `"right"` | `"center"` (default: `"left"`) - screen position
- Titles are automatically prefixed with the calling client name (e.g., "Claude Desktop - Confirmation")

## Handling Snooze & Feedback Responses

All interactive dialogs can return three types of responses:

### Normal Response
User answered the question. The `answer` field contains: `true/false` (confirm), `string` (pick single/text), `string[]` (pick multi), or `Record<string, string>` (form).

### Snooze Response

**CRITICAL**: When `snoozed: true` is returned, you MUST:
1. **Actually wait** using `sleep` command (NOT just say "waiting")
2. **Re-ask the same question** after the wait

```bash
# Example: User snoozed for 5 minutes (remainingSeconds: 300)
sleep 300
```

**Response fields when snoozed:**
- `snoozed: true`
- `snoozeMinutes: 1 | 5 | 15 | 30 | 60` (original duration chosen by user)
- `remainingSeconds: <int>` (seconds until snooze expires)
- Normal response fields will be null/empty

**Snooze is enforced globally**: During the snooze period, ALL subsequent dialog calls return immediately with `{ snoozed: true, remainingSeconds: X }` WITHOUT showing any dialog. This prevents interrupting the user.

**Example handling:**
```
Tool response: { "snoozed": true, "snoozeMinutes": 1, "remainingSeconds": 60 }

CORRECT:
1. Run: sleep 60
2. Re-call the same tool with same parameters

WRONG:
- Just saying "I'll wait" without running sleep
- Asking a different question immediately
- Moving on without re-asking
```

### Feedback Response
User provided text feedback instead of answering. The `feedbackText` field contains their message - read it and adjust your approach accordingly.

**Response fields when feedback given:**
- `feedbackText: "user's message here"`
- Normal response fields will be null/empty

## Additional Tool Options

`ask` with `type: "pick"` additionally supports:
- `descriptions`: Array of description strings matching choices array. Displayed as `"Choice → Description"` format.

## Platform Requirements

- macOS (Swift CLI) or Windows (WPF CLI)
- Node.js 18+

## Creating a New Provider

To add support for a new platform, implement the `DialogProvider` interface in `providers/interface.ts`:

### 1. Create provider file

```typescript
// src/providers/linux.ts
import type { DialogProvider } from "./interface.js";

export class LinuxDialogProvider implements DialogProvider {
  private clientName = "MCP";

  setClientName(name: string): void { this.clientName = name; }
  async pulse(): Promise<void> { /* keep-alive, can be no-op */ }
  async confirm(opts) { /* zenity, kdialog, etc. */ }
  async choose(opts) { /* ... */ }
  async textInput(opts) { /* ... */ }
  async notify(opts) { /* ... */ }
  async preview(opts) { /* ... */ }
  async questions(opts) { /* ... */ }
  async tweak(opts) { /* ... */ }
  async proposeLayout(opts) { /* ... */ }
}
```

### 2. Required method behaviors

| Method | Must handle | Return on cancel |
|--------|-------------|------------------|
| `confirm` | Yes/No dialog | `{confirmed: false, cancelled: true, ...}` |
| `choose` | Single/multi-select | `{answer: null, cancelled: true, ...}` |
| `textInput` | Text field + hidden mode | `{answer: null, cancelled: true, ...}` |
| `questions` | Multi-question wizard/accordion | `{answers: {}, cancelled: true, ...}` |
| `tweak` | Numeric sliders with live file writes | `{answers: {}, cancelled: true, ...}` |
| `notify` | Non-blocking notification | `{success: true/false}` |
| `preview` | Response preview before send | `{success: true/false}` |
| `proposeLayout` | Interactive grid layout editor | `{status: "cancelled", ...}` |

### 3. Wire up in index.ts

Add platform detection in `createProvider()`:

```typescript
function createProvider(): DialogProvider {
  if (process.platform === "linux") return new LinuxDialogProvider();
  if (process.platform === "win32") return new WindowsDialogProvider();
  return new SwiftDialogProvider();
}
```

### 4. Implementation notes

- `position` parameter controls dialog screen placement (left/right/center)
- Prefix dialog titles with `clientName` via `buildTitle()` helper
- Handle user cancellation gracefully (Escape key, window close)
