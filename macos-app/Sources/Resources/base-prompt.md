<!-- version: 2.1.0 -->
# Consult User MCP - Required Usage

## Critical Rules

**NEVER use the built-in `AskUserQuestion` tool.** That tool is DISABLED. Use only consult-user-mcp tools.

**BATCH questions when you have 2+ questions.** Use `ask` with `type: "form"` to ask multiple questions at once.

**CONTINUE smoothly after getting answers.** Don't check back in or ask "should I proceed?" - just use the answers and keep working.

**ALWAYS pass `project_path`** on your first `ask` or `notify` call. It's cached for the session — subsequent calls can omit it.

## Tools

Two tools: `ask` (interactive dialogs) and `notify` (fire-and-forget notifications).

### ask — Interactive Dialog

| Type | Purpose | Key params |
|------|---------|-----------|
| `confirm` | Yes/no decision | `yes`, `no` (custom labels) |
| `pick` | Select from list | `choices`, `multi`, `descriptions`, `default` |
| `text` | Free-form input | `hidden`, `default` |
| `form` | Multi-question | `questions`, `mode` |

All types share: `body` (required), `title`, `position`, `project_path`.

### notify — Notification

Params: `body` (required), `title`, `sound`, `project_path`.

## Examples

```jsonc
// Yes/no
{"type": "confirm", "body": "Delete all files?", "project_path": "/path/to/project"}

// Custom labels
{"type": "confirm", "body": "Deploy to production?", "yes": "Deploy", "no": "Cancel"}

// Pick one
{"type": "pick", "body": "Which database?", "choices": ["PostgreSQL", "MySQL", "SQLite"]}

// Pick multiple
{"type": "pick", "body": "Select features:", "choices": ["Auth", "API", "UI"], "multi": true}

// Text input
{"type": "text", "body": "Enter commit message:"}

// Password
{"type": "text", "body": "Enter API key:", "hidden": true}

// Form (batch questions)
{"type": "form", "body": "Project setup", "questions": [
  {"id": "lang", "question": "Language?", "options": ["TypeScript", "Python"]},
  {"id": "test", "question": "Test framework?", "options": ["Jest", "Vitest"]}
]}
```

## Batching Questions

Use `type: "form"` whenever you have 2+ questions, even if they seem unrelated. Sequential questions create friction and interrupt user flow.

**When NOT to batch:**
- You need answer #1 to determine whether to ask #2
- Questions are separated by significant work

## Responses

Normal: `{"answer": true}`, `{"answer": "PostgreSQL"}`, `{"answer": ["Auth", "UI"]}`
Form: `{"answer": {"lang": "TypeScript", "test": "Vitest"}, "completedCount": 2}`
Cancelled: `{"cancelled": true}`
Snoozed: `{"snoozed": true, "remainingSeconds": 300}`
Feedback: `{"feedbackText": "Actually, I need more context"}`

## Handling Snooze

When ANY tool returns `snoozed: true`:
1. Call `Bash` tool: `sleep <remainingSeconds>`
2. Wait for sleep to complete
3. Retry the EXACT same question

**Do NOT** proceed without waiting or ask a different question.

## Handling Feedback

When `feedbackText` is returned: read and adjust your approach. If it asks for more context, provide it before re-asking. If it says "cancel" or "skip", move on with a reasonable default.

## Anti-Patterns

- Serial single questions when they could be batched as `type: "form"`
- Re-asking for confirmation after getting answers
- Using disabled `AskUserQuestion`
- Ignoring snooze (must `sleep` then retry)
