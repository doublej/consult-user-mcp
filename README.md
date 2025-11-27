# Speak MCP

Native macOS dialog system for MCP (Model Context Protocol) servers.

## Install

### Option 1: App Bundle (Recommended)

```bash
pnpm install
pnpm build
cp -r "Speak MCP.app" /Applications/
```

Then launch **Speak MCP** from Applications. A menu bar icon will appear.

### Option 2: MCP Server Only

Add to your Claude Code MCP config:

```json
{
  "mcpServers": {
    "speak": {
      "command": "node",
      "args": ["/path/to/speak/mcp-server/dist/index.js"]
    }
  }
}
```

## Build

```bash
pnpm install
pnpm build
```

This builds:
- `dialog-cli/dialog-cli` - Native dialog binary
- `mcp-server/dist/` - MCP server
- `Speak MCP.app` - Menu bar settings app

## Structure

```
speak/
├── dialog-cli/          # Native Swift CLI for dialogs
├── mcp-server/          # MCP server (TypeScript)
├── macos-app/           # SwiftUI menu bar app source
└── Speak MCP.app        # Built app bundle
```

## MCP Tools

- `ask_confirmation` - Yes/No dialog
- `ask_multiple_choice` - List picker
- `ask_text_input` - Text input
- `notify_user` - System notification
- `speak_text` - Text-to-speech
