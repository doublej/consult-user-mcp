# consult-user-mcp-server

An MCP server for interacting with users through native macOS dialogs.

## Tools

| Tool | Description |
|------|-------------|
| `ask` | Interactive dialog — type: `confirm` (yes/no), `pick` (list picker), `text` (free-form input), `form` (multi-question wizard/accordion) |
| `notify` | macOS notification banner (non-blocking) |

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
-> ask with type="confirm", yes="Delete", no="Cancel"
-> User clicks "Delete"
-> Returns: { answer: true }
```

**Pick from list:**
```
LLM: "Which deployment target?"
-> ask with type="pick", choices=["staging", "production", "dev"]
-> User selects "staging"
-> Returns: { answer: "staging" }
```

**Text input:**
```
LLM: "What should I name the project?"
-> ask with type="text", body="Enter project name"
-> User types "my-app"
-> Returns: { answer: "my-app" }
```
