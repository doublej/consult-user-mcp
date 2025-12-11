# speak-mcp-server

An MCP server for interacting with users through native macOS dialogs and speech.

## Tools

| Tool | Description |
|------|-------------|
| `ask_confirmation` | Yes/No dialog with custom buttons |
| `ask_multiple_choice` | Scrollable list picker (single or multi-select) |
| `ask_text_input` | Free-form text input (supports password masking) |
| `ask_questions` | Multi-question dialog (wizard or accordion mode) |
| `notify_user` | macOS notification banner (non-blocking) |

All interactive dialogs support **snooze** (defer with 1-60 min delay) and **feedback** (user provides text instead of answering).

## Requirements

- macOS (uses `osascript` and `say` commands)
- Node.js 18+

## Installation

```bash
npm install
npm run build
```

## Usage with Claude Desktop

Add to your Claude Desktop config (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "speak": {
      "command": "node",
      "args": ["/path/to/speak-mcp-server/dist/index.js"]
    }
  }
}
```

## Example Interactions

**Confirmation:**
```
LLM: "Should I proceed with deleting these files?"
-> ask_confirmation with buttons ["Delete", "Cancel"]
-> User clicks "Delete"
-> Returns: { selection: "Delete" }
```

**Multiple choice:**
```
LLM: "Which deployment target?"
-> ask_multiple_choice with options ["staging", "production", "dev"]
-> User selects "staging"
-> Returns: { selection: "staging" }
```

**Text input:**
```
LLM: "What should I name the project?"
-> ask_text_input with prompt "Enter project name"
-> User types "my-app"
-> Returns: { text: "my-app" }
```

## Available Voices

Run `say -v ?` in Terminal to see all available voices on your system.

Common voices: Samantha, Alex, Daniel, Karen, Moira, Tessa, Veena, Fiona
