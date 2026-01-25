# consult-user-mcp-server

An MCP server for interacting with users through native macOS dialogs.

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

- macOS (uses native Swift dialog CLI)
- Node.js 18+

## Installation

```bash
bun install
bun run build
```

## Usage with Claude Desktop

Add to your Claude Desktop config (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "consult-user-mcp": {
      "command": "node",
      "args": ["/path/to/consult-user-mcp-server/dist/index.js"]
    }
  }
}
```

## Example Interactions

**Confirmation:**
```
LLM: "Should I proceed with deleting these files?"
-> ask_confirmation with confirm_label="Delete", cancel_label="Cancel"
-> User clicks "Delete"
-> Returns: { confirmed: true, cancelled: false, answer: "Delete" }
```

**Multiple choice:**
```
LLM: "Which deployment target?"
-> ask_multiple_choice with choices ["staging", "production", "dev"]
-> User selects "staging"
-> Returns: { answer: "staging", cancelled: false }
```

**Text input:**
```
LLM: "What should I name the project?"
-> ask_text_input with body "Enter project name"
-> User types "my-app"
-> Returns: { answer: "my-app", cancelled: false }
```

