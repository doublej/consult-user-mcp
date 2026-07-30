<!-- version: 2.16.0 -->
# Consult User MCP — Required Usage

<critical_rules>
**ALWAYS use consult-user-mcp tools (`ask`, `notify`, `tweak`) for all user interaction.** The built-in `AskUserQuestion` tool is disabled.

Batch 2+ questions using `ask` with `type: "form"` instead of asking one at a time.

Pass `project_path` on your first `ask`, `notify`, or `tweak` call. It's cached for the session — subsequent calls can omit it.
</critical_rules>

<response_handling>
Every interactive dialog returns structured JSON. Special states (at most one per response) and the required reaction:

| State | Shape | Required action |
|-------|-------|-----------------|
| Snoozed | `{"snoozed": true, "remainingSeconds": N}` | Run `sleep N` via Bash, then retry the **exact** same question. Do NOT proceed or ask something else. |
| Ask differently | `{"askDifferently": "<type>"}` | Re-ask the **same question** as the requested type: `confirm`, `pick`, `pick-multi` (`multi: true`), `text`, `text-hidden` (`hidden: true`), or `form-wizard` (`type: "form"`). Do NOT skip or change topic. |
| Cancelled | `{"cancelled": true}` | Proceed with a reasonable default. |
| AFK | `{"afk": true}` | Away mode — no dialog was shown. Proceed autonomously with defaults; note open questions in your final response. |

Feedback is an annotation, not a redirect: `feedbackText` (any dialog) and `feedbackByQuestion` (forms, keyed by question id) arrive **alongside** the answer. Accept the answer, incorporate the note, do not re-ask. If the user cancelled but left a note, the response carries the note without `cancelled: true` — treat as "user redirected: read the note, adjust, continue."

Normal answers: boolean (confirm), string (pick/text — a custom "Other" answer arrives as typed), string[] (pick with `multi`), question-id → answer map plus `completedCount` (form), parameter-id → number map plus `action` (tweak).

Images: the user can paste or drag pictures onto any dialog. They arrive as image blocks alongside the answer, named and numbered in a preceding line. Treat them as part of the reply — look at them before acting, and do not ask for a file path.
</response_handling>

<anti_patterns>
Common mistakes — do this instead:
- Asking "should I proceed?" after getting an answer → just use the answer and keep working
- Asking questions one at a time when you have multiple → use `type: "form"` to batch them
- Guessing numeric values repeatedly when the user rejects them → offer `tweak` instead
- Using `other: false` on open-ended questions → only set it for closed-ended lists (environments, predefined options)
</anti_patterns>

## Tools

- `ask` — interactive dialog. `type`: `confirm` (yes/no), `pick` (select from list, `multi` for multi-select), `text` (free input, `hidden` for passwords), `form` (multi-question wizard — the batching tool).
- `notify` — fire-and-forget notification.
- `tweak` — always-on-top slider pane for real-time numeric value adjustment with live file writes.
- `propose_layout` — interactive grid layout editor (macOS only).

Parameter details are in each tool's input schema. Pick dialogs and form choice questions include an "Other" free-text option by default (`other: true`); the custom text is returned as the answer value (never the literal "Other").

## tweak — when and how

Offer tweak when:
1. The user tunes visual/layout values — subjective choices benefit from interactive tuning ("make the padding feel right", "the spacing looks off")
2. The user rejects your numeric guess ("that's too small") — offer tweak instead of guessing again
3. Multiple related values need coordinated tuning
4. The user asks for it ("let me adjust this interactively")

Workflow — confirm first, then open if accepted:
1. `ask` → `{"type": "confirm", "body": "Adjust values interactively?", "yes": "Open tweak", "no": "Just pick values"}`
2. If confirmed → call `tweak`, one parameter per slider, using one of three formats:
   - **Text search** (any file type): `search` pattern with a single `{v}` placeholder (e.g. `padding: {v}rem`) plus `current` equal to the actual numeric value at that location — it disambiguates duplicate matches and seeds the slider
   - **CSS reference** (stylesheets, preferred): `selector` + `property` — auto-resolves location, current value and unit
   - **Direct** (fallback / computed locations): `line` + `column` + `expectedText` + `current`
3. Response `action: "file"` → values already written to disk. `action: "agent"` → files reverted; apply the returned values yourself.

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
