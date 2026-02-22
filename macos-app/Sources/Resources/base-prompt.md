<!-- version: 2.7.0 -->
# Consult User MCP — Required Usage

<critical_rules>
**NEVER use the built-in `AskUserQuestion` tool.** It is DISABLED. Use only consult-user-mcp tools.

**BATCH questions when you have 2+ questions.** Use `ask` with `type: "form"` to ask multiple questions at once.

**CONTINUE smoothly after getting answers.** Don't check back in or ask "should I proceed?" — just use the answers and keep working.

**ALWAYS pass `project_path`** on your first `ask`, `notify`, or `tweak` call. It's cached for the session — subsequent calls can omit it.
</critical_rules>

## Tools

Three tools: `ask` (interactive dialogs), `notify` (fire-and-forget notifications), and `tweak` (real-time value adjustment).

### ask — Interactive Dialog

| Type | Purpose | Key params |
|------|---------|-----------|
| `confirm` | Yes/no decision | `yes`, `no` (custom labels) |
| `pick` | Select from list | `choices`, `multi`, `descriptions`, `default` |
| `text` | Free-form input | `hidden`, `default` |
| `form` | Multi-question | `questions`, `mode` (`"wizard"` \| `"accordion"`) |

All types share: `body` (required), `title`, `position` (`"left"` \| `"center"` \| `"right"`), `project_path`.

### notify — Notification

Params: `body` (required), `title`, `sound`, `project_path`.

### tweak — Value Adjustment Pane

Opens a slider panel for real-time numeric value adjustment with live file writes.

**Offer tweak when:**
1. User adjusts visual/layout values — subjective choices benefit from interactive tuning
2. User rejects your numeric guess — offer tweak instead of guessing again
3. Multiple related values need coordinated tuning

**Workflow:** Confirm first, then open if accepted:
1. `ask` → `{"type": "confirm", "body": "Adjust font-size and line-height interactively?", "yes": "Open tweak", "no": "Just pick values"}`
2. If confirmed → call `tweak` with parameters
3. `action: "file"` → values already written to disk. `action: "agent"` → files reverted, apply returned values yourself.

**Parameter formats** (one per slider):

| Format | When to use | Required fields |
|--------|-------------|----------------|
| **Text search** | Any file type | `label`, `file`, `search` (pattern with `{v}`), `min`, `max` |
| **CSS reference** | Stylesheets (preferred) | `label`, `file`, `selector`, `property`, `min`, `max` |
| **Direct** | Fallback / computed locations | `label`, `file`, `line`, `column`, `expectedText`, `current`, `min`, `max` |

- `label` is required for all formats; `id` auto-derives as kebab-case if omitted.
- Optional: `step`, `unit`, `index` (for multi-value CSS like `margin: 10px 20px`), `fn` (for CSS functions like `rotateY`).
- CSS reference auto-resolves `line`, `column`, `expectedText`, `current`, `unit`.

**Response:** `{"answer": {"<id>": <number>}, "action": "file" | "agent"}`

## Examples

```jsonc
// Confirm with custom labels
{"type": "confirm", "body": "Deploy to production?", "yes": "Deploy", "no": "Cancel", "project_path": "/path/to/project"}

// Pick with descriptions
{"type": "pick", "body": "Which database?", "choices": ["PostgreSQL", "MySQL", "SQLite"], "descriptions": ["Best for complex queries", "Widely supported", "Zero config"]}

// Multi-select
{"type": "pick", "body": "Select features:", "choices": ["Auth", "API", "UI"], "multi": true}

// Password input
{"type": "text", "body": "Enter API key:", "hidden": true}

// Batch questions as form
{"type": "form", "body": "Project setup", "questions": [
  {"id": "lang", "question": "Language?", "options": ["TypeScript", "Python"]},
  {"id": "test", "question": "Test framework?", "options": ["Jest", "Vitest"]}
]}

// Tweak (text search format)
// tweak tool: {"body": "Adjust card layout", "parameters": [
//   {"label": "Padding", "file": "style.css", "search": "padding: {v}px", "min": 0, "max": 60},
//   {"label": "Border Radius", "file": "style.css", "search": "border-radius: {v}px", "min": 0, "max": 24}
// ]}
```

## Batching

Use `type: "form"` for 2+ questions. Only ask sequentially when answer #1 determines whether to ask #2, or questions are separated by significant work.

## Responses

| Type | Normal answer |
|------|---------------|
| confirm | `{"answer": true}` or `{"answer": false}` |
| pick | `{"answer": "PostgreSQL"}` or `{"answer": ["Auth", "UI"]}` |
| text | `{"answer": "user input"}` |
| form | `{"answer": {"lang": "TypeScript"}, "completedCount": 2}` |
| tweak | `{"answer": {"font-size": 18}, "action": "file"}` |

### Special responses (priority order — only one per response)

| State | Shape | Action required |
|-------|-------|-----------------|
| Snoozed | `{"snoozed": true, "remainingSeconds": N}` | Run `sleep N` via Bash, then retry the **exact** same question. Do NOT proceed or ask something else. |
| Ask differently | `{"askDifferently": "<type>"}` | Re-ask the **same question** as the requested type. Do NOT skip or change topic. |
| Feedback | `{"feedbackText": "..."}` | Read feedback and adjust. If it asks for context, provide it. If it says "cancel"/"skip", use a reasonable default. |
| Cancelled | `{"cancelled": true}` | Proceed with a reasonable default. |

### askDifferently type mapping

| Value | Re-ask as |
|-------|-----------|
| `confirm` | Yes/no confirmation |
| `pick` | Single-select list |
| `pick-multi` | Multi-select list (`multi: true`) |
| `text` | Free-form text input |
| `text-hidden` | Password input (`hidden: true`) |
| `form-wizard` | Wizard form (`mode: "wizard"`) |
| `form-accordion` | Accordion form (`mode: "accordion"`) |
