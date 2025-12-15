# CLAUDE.md

## Project Overview

**Consult User MCP** - Native macOS dialog system for MCP (Model Context Protocol) servers. Lets LLMs ask users questions via native dialogs instead of text-only chat.

## Components

```
consult-user-mcp/
├── dialog-cli/      # Swift CLI - native macOS dialogs
├── mcp-server/      # Node.js MCP server - protocol bridge
├── macos-app/       # Swift menu bar app - settings UI
└── scripts/         # Build automation
```

### 1. dialog-cli (Swift)

Native macOS dialog renderer using AppKit. Invoked as subprocess by mcp-server.

**Commands:** `confirm`, `choose`, `textInput`, `notify`, `tts`, `questions`, `pulse`

**Build:** `cd dialog-cli && swift build -c release`

**Output:** `.build/release/DialogCLI`

### 2. mcp-server (TypeScript)

MCP protocol server exposing dialog tools to LLMs.

**Tools:** `ask_confirmation`, `ask_multiple_choice`, `ask_text_input`, `ask_questions`, `notify_user`

**Build:** `cd mcp-server && bun run build`

**Entry:** `dist/index.js`

**Key files:**
- `src/index.ts` - MCP server, tool registration
- `src/providers/swift.ts` - dialog-cli integration
- `src/types.ts` - shared types

### 3. macos-app (Swift)

Menu bar app for settings and installation guide.

**Features:**
- Dialog position preference (left/center/right)
- Speech rate setting
- Auto-install to Claude Desktop/Code/Codex configs
- Debug menu (right-click) to test dialogs

**Build:** `cd macos-app && swift build -c release`

## Build Commands

```bash
# Individual builds
bun run build        # mcp-server only
bun run build:cli    # dialog-cli only
bun run build:app    # macos-app only

# Full app bundle (builds all + packages to /Applications)
bun run build:bundle
```

## App Bundle Structure

```
/Applications/Consult User MCP.app/
└── Contents/
    ├── MacOS/ConsultUserMCP
    ├── Resources/
    │   ├── AppIcon.icns
    │   ├── dialog-cli/dialog-cli
    │   └── mcp-server/
    │       ├── dist/index.js
    │       ├── node_modules/
    │       └── package.json
    └── Info.plist
```

## MCP Configuration

Add to `~/.claude.json` (Claude Code) or `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "consult-user-mcp": {
      "command": "node",
      "args": ["/Applications/Consult User MCP.app/Contents/Resources/mcp-server/dist/index.js"]
    }
  }
}
```

## Path Resolution

`mcp-server/src/providers/swift.ts` finds dialog-cli via:
1. **App bundle:** `../../../dialog-cli/dialog-cli` (relative to `dist/providers/`)
2. **Dev:** `../../../dialog-cli/.build/release/DialogCLI`

## Dialog Features

All dialogs support:
- **Position:** `left` | `center` | `right`
- **Snooze:** Defer response (1/5/15/30/60 min)
- **Feedback:** Text feedback instead of answering
- **Keyboard:** Full navigation (Tab, Enter, Escape, arrows)

## Testing

```bash
cd mcp-server && node test.js  # Interactive dialog tests
```

Or right-click the menu bar icon → Debug menu.
