# Consult User MCP

Native macOS dialog system for MCP (Model Context Protocol) servers.

## Install

### Option 1: MCP Server Only

```bash
git clone https://github.com/doublej/consult-user-mcp.git
cd consult-user-mcp/mcp-server
pnpm install && pnpm build
```

Add to your MCP config:

```json
{
  "mcpServers": {
    "consult-user-mcp": {
      "command": "node",
      "args": ["/path/to/consult-user-mcp/mcp-server/dist/index.js"]
    }
  }
}
```

### Option 2: With macOS App (Optional)

The menu bar app provides a settings UI for dialog position, sounds, and speech rate. It's not required for the MCP server to work.

1. Download **Consult User MCP.app.zip** from [Releases](../../releases)
2. Unzip and drag to `/Applications`
3. Launch it - a menu bar icon appears with settings access

Use the bundled MCP server:

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

## Build from Source

```bash
pnpm install
pnpm build
```

Creates `Consult User MCP.app` in project root (optional).

## Structure

```
consult-user-mcp/
├── dialog-cli/          # Native Swift CLI for dialogs
├── mcp-server/          # MCP server (TypeScript)
├── macos-app/           # SwiftUI menu bar app source
└── Consult User MCP.app # Built app bundle
```

## MCP Tools

- `ask_confirmation` - Yes/No dialog
- `ask_multiple_choice` - List picker
- `ask_text_input` - Text input
- `notify_user` - System notification
- `tts` - Text-to-speech
