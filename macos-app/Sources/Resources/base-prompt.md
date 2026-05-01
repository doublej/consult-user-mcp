<!-- version: 2.12.1 -->
# Consult User MCP — Required Usage

<critical_rules>
**ALWAYS use consult-user-mcp tools (`ask`, `notify`, `tweak`) for all user interaction.** The built-in `AskUserQuestion` tool is disabled.

Batch 2+ questions using `ask` with `type: "form"` instead of asking one at a time.

Pass `project_path` on your first `ask`, `notify`, or `tweak` call. It's cached for the session — subsequent calls can omit it.
</critical_rules>

<anti_patterns>
Common mistakes — do this instead:
- Asking "should I proceed?" after getting an answer → just use the answer and keep working
- Asking questions one at a time when you have multiple → use `type: "form"` to batch them
- Guessing numeric values repeatedly when the user rejects them → offer `tweak` instead
- Using `other: false` on open-ended questions → only set it for closed-ended lists (environments, predefined options)
</anti_patterns>

## Tools

Three tools: `ask` (interactive dialogs), `notify` (fire-and-forget notifications), and `tweak` (real-time value adjustment).

### ask — Interactive Dialog

| Type | Purpose | Key params |
|------|---------|-----------|
| `confirm` | Yes/no decision | `yes`, `no` (custom labels) |
| `pick` | Select from list | `choices`, `multi`, `descriptions`, `default`, `other` (default `true`) |
| `text` | Free-form input | `hidden`, `default` |
| `form` | Multi-question | `questions`, `mode` (`"wizard"` \| `"accordion"`). Questions support `type: "choice"` (default, `other` default `true`) or `"text"` |

All types share: `body` (required), `title`, `position` (`"left"` \| `"center"` \| `"right"`), `project_path`.

"Other" option: Pick dialogs and form choice questions include an "Other" option by default (`other: true`), allowing users to type a custom answer. The custom text is returned as the `answer` value (never the literal "Other"). Set `other: false` only for closed-ended questions.

### notify — Notification

Params: `body` (required), `title`, `sound`, `project_path`.

### tweak — Value Adjustment Pane

Opens a slider panel for real-time numeric value adjustment with live file writes.

Offer tweak when:
1. User adjusts visual/layout values — subjective choices benefit from interactive tuning
2. User rejects your numeric guess — offer tweak instead of guessing again
3. Multiple related values need coordinated tuning

### Workflow

Confirm first, then open if accepted:
1. `ask` → `{"type": "confirm", "body": "Adjust values interactively?", "yes": "Open tweak", "no": "Just pick values"}`
2. If confirmed → call `tweak` with parameters
3. `action: "file"` → values already written to disk. `action: "agent"` → files reverted, apply returned values yourself.

### Parameter formats

One per slider:

| Format | When to use | Required fields |
|--------|-------------|----------------|
| **Text search** | Any file type | `label`, `file`, `search` (pattern with single `{v}`), `current`, `min`, `max` |
| **CSS reference** | Stylesheets (preferred) | `label`, `file`, `selector`, `property`, `min`, `max` |
| **Direct** | Fallback / computed locations | `label`, `file`, `line`, `column`, `expectedText`, `current`, `min`, `max` |

For text search: `current` must equal the actual numeric value at the file location. When two parameters share the same `search` pattern in the same file, `current` is what disambiguates them — pass `current: 8` for the line that reads `8px` and `current: 10` for the line that reads `10px`.

- `label` is required for all formats; `id` auto-derives as kebab-case if omitted.
- Optional: `step`, `unit`, `index` (for multi-value CSS like `margin: 10px 20px`), `fn` (for CSS functions like `rotateY`).
- CSS reference auto-resolves `line`, `column`, `expectedText`, `current`, `unit`.

Response: `{"answer": {"<id>": <number>}, "action": "file" | "agent"}`

### CSS animation replay

Before calling tweak on a page with CSS animations, inject the replay client via claude-in-chrome:
```javascript
// mcp__claude-in-chrome__javascript_tool
if (!window.__tweakReplayConnected) {
  window.__tweakReplayConnected = true;
  const ws = new WebSocket('ws://localhost:19876');
  ws.onmessage = (e) => {
    if (JSON.parse(e.data).type === 'replay') {
      document.querySelectorAll('*').forEach(el => {
        const s = getComputedStyle(el);
        if (s.animationName !== 'none') {
          el.style.animation = 'none';
          void el.offsetHeight;
          el.style.animation = '';
        }
      });
    }
  };
  ws.onclose = () => { window.__tweakReplayConnected = false; };
}
```

### Trigger patterns

| User prompt | Why tweak? |
|-------------|-----------|
| "Make the padding feel right" | Subjective — no correct answer |
| "The spacing looks off" | Visual judgment needed |
| "Hmm, that's too small" | Rejected your guess |
| "Balance the margins and padding together" | Multiple related values |
| "Let me adjust this interactively" | Explicit request |

## Responses

| Type | Normal answer |
|------|---------------|
| confirm | `{"answer": true}` or `{"answer": false}` |
| pick | `{"answer": "PostgreSQL"}` or `{"answer": ["Auth", "UI"]}` |
| text | `{"answer": "user input"}` |
| form | `{"answer": {"lang": "TypeScript"}, "completedCount": 2}` |
| tweak | `{"answer": {"font-size": 18}, "action": "file", "replayAnimations": true}` |

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
