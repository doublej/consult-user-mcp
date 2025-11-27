# speak-mcp-server

An MCP server for interacting with users through native macOS dialogs and speech.

## Tools

| Tool | Description |
|------|-------------|
| `ask_confirmation` | Display a dialog with custom buttons (Yes/No, Save/Cancel, etc.) |
| `ask_multiple_choice` | Show a scrollable list picker for selecting from many options |
| `ask_text_input` | Prompt for free-form text input (with optional password masking) |
| `notify_user` | Send a macOS notification banner (non-blocking) |
| `speak_to_user` | Use text-to-speech to speak aloud |

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
