# Consult User MCP — Behavioural Specification

**Companion to `UI-SPECIFICATION.md`.** Same coverage, no visual design.

---

## 0. What this is

This document specifies **how the interface behaves** — what exists, when it appears, what it does, what it
says, and what comes back. It carries no visual design at all, so it can be paired with any visual language.

### Deliberately absent

No colours. No type sizes, weights or faces. No dimensions, spacing, padding, insets or corner radii. No
opacity values, borders or shadows. No animation durations or easing. No geometric layout — nothing about which
region sits where, how anything is aligned, or how wide it is.

Where the full specification prescribes the exact fill, border weight and colour of a selected option, this one
says only *"a selected option MUST be visually distinct from an unselected one, through a channel that focus
does not also use."* The requirement survives; the drawing does not.

### Deliberately present

Behaviour, states, rules, sequence, copy, and the caller contract. Also three things that look like layout but
are not:

- **Order**, where it carries meaning — focus order, button precedence, list order, step order, the sequence
  Escape unwinds in. These determine what a key does, so they are behaviour.
- **Adjacency**, where it carries meaning — a note is attached to a specific question, a description belongs to
  a specific option.
- **Anchoring**, as a concept — a surface can be asked to appear at one of three anchors, and a side pane opens
  away from the wall the surface is against. The distances are gone; the rule is not.

### Deliberately present but not visual

Functional durations and limits — how long input is ignored, how long a popup lives, when a request is
abandoned. These change what happens, not how it looks. They are collected in §9.

### Conformance language

| Word | Meaning |
|---|---|
| **MUST** | Required. A build without it is not this product. |
| **SHOULD** | Strongly expected. Deviating needs a reason. |
| **MAY** | Genuinely optional. |
| ⚠️ | A known behavioural defect or contradiction. §10 carries the full list. |

### Two audiences

- **The person** — the human being interrupted. §1–§5 are about them.
- **The calling agent** — the AI assistant that requested the interruption. §6 is the surface it drives. Text
  the agent receives is never shown on screen and is collected separately in §8.3.

---

## 1. What the interface is

An AI assistant working on the person's behalf sometimes needs a decision, a secret, a preference, or a
judgement call it cannot make alone. This interface is the channel for that: a surface appears over whatever
the person is doing, asks exactly one thing, and gets out of the way.

Every structural decision follows from one tension:

> **The interruption must be cheap to answer and cheap to refuse.**

- It appears in a predictable place, so locating it costs nothing.
- It is entirely keyboard-driven, so answering never requires the pointer.
- It opens inert, so a keystroke already in flight cannot answer it by accident.
- It offers three exits that are neither "answer" nor "cancel" — postpone it, annotate it, or reject the
  *shape* of the question — so the person is never forced to choose between a bad answer and no answer.

### 1.1 The eight surfaces

| # | Surface | Asks for | Blocks the agent |
|---|---|---|---|
| 1 | **Confirm** | A yes or a no | Yes |
| 2 | **Pick** | One option from a list, or several | Yes |
| 3 | **Text** | A typed line, optionally masked | Yes |
| 4 | **Form** | Several questions, one at a time | Yes |
| 5 | **Notify** | Nothing — it announces | No |
| 6 | **Response preview** | Nothing — it shows what is about to be sent | No |
| 7 | **Value tweak** | Numbers, tuned live against real files | Yes |
| 8 | **Layout sketch** | A screen layout, dragged into shape | Yes |

Surfaces 1–4 and 7 are **interactive**: they share one keyboard model, one outcome model, and the three exits.
Surfaces 5–6 are **transient popups**: no controls, self-dismissing. Surface 8 is a **workspace**: resizable,
with undo.

Each surface MUST be identifiable at a glance as the kind of thing it is. In particular, a **masked** text
surface MUST be distinguishable from a plain one before the person types, and a **multi-select** list MUST be
distinguishable from a single-select one before they choose.

### 1.2 The interruption contract

An interactive surface is shown only when all of these hold:

1. No quiet period ("snooze") is running.
2. Away mode is off.
3. No other interactive surface is already on screen.

If any fails, **nothing is drawn** and the agent is told what to do instead (§4.7). Notifications are exempt
from 1 and 2 and MAY appear on top of an open interactive surface.

---

## 2. The window model

### 2.1 The surface is its own frame

Every surface provides its own frame. It has no host-system title bar, no close or minimise controls, and — for
everything except the layout sketch editor — no resize handle. The person cannot resize an interactive surface.

### 2.2 The sizing law

This is the most consequential structural rule in the product.

> **A surface is measured once, when it appears. Its width is then fixed for the rest of its life. Only its
> height reflows.**

The reason is directly observable: if width were recomputed from wrapped text, text would rewrap, which would
change the measured width, which would rewrap the text. The surface would oscillate. So it does not.

Rules:

- On appearance the surface is exactly as wide as its content needs, floored at a per-surface minimum and
  capped so it always fits the screen; and exactly as tall as that content is once wrapped to that width,
  floored at a per-surface minimum and capped at a fraction of the usable screen height.
- Height reflows freely whenever content changes.
- Width changes for exactly one reason: **a side pane attaching or detaching**, which changes it by exactly the
  pane's fixed width.
- **The same request MUST always produce a surface of the same size.** Nothing about its dimensions may depend
  on what was shown before it, or on the order in which its content settles.
- Changes below one layout unit are ignored — the surface does not twitch or re-anchor for them.

The height cap for the two transient popups is **noticeably lower** than for interactive surfaces: they are
meant to be glanced at, not read.

### 2.3 Overflow

When content exceeds the height cap, the surface stops growing and **one designated region scrolls
internally**. The header, the tool strip and the footer never scroll away.

| Surface | Scrolling region |
|---|---|
| Pick | The option list |
| Form | The question area |
| Value tweak | The parameter list |
| Notify | The message |
| Response preview | The body |
| **Confirm** | ⚠️ **none — a long body is clipped** |
| **Text** | ⚠️ **none — a long prompt is clipped** |

⚠️ See §10.2.

### 2.4 Anchoring

A surface is placed once, on appearance, against one of three horizontal anchors — **left**, **centre** or
**right** — a fixed distance below the top of the usable screen area (the screen minus any always-present
system chrome).

**Under resize, the top edge is always fixed** — the surface grows and shrinks downward. Horizontally, a
left-anchored surface keeps its left edge, a right-anchored surface keeps its right edge, a centred surface
keeps its centre.

The anchor also decides **which side a side pane opens on** — always away from the wall the surface is against:

| Anchor | Pane side |
|---|---|
| Left | Right |
| Right | Left |
| Centre | Whichever side has more room |
| Indeterminate | Right |

The two transient popups read the person's **saved anchor preference only**; a per-call anchor is accepted by
the caller contract but never applied to them.

⚠️ **Multi-display behaviour is unspecified** — every surface is placed on one primary display regardless of
where the person is working. See §10.5.

### 2.5 Moving

Pressing and dragging a surface's **empty background** moves it, and it stays wherever it is dropped.

Pressing any **control** — a button, an option row, a text field, a note editor and its scroll area, a slider,
a parameter list, a tool chip — activates that control and **never** moves the surface.

Clicking an inactive surface brings it forward and gives it keyboard focus first, then delivers the click.

### 2.6 Stacking

Interactive surfaces float above other applications by default. This follows a person-level preference; when it
is off they behave as ordinary windows.

Notifications float **unconditionally** and appear **without stealing keyboard focus** from whatever the person
was doing.

The value-tweak console panel shares the tweak surface's stacking level exactly, and follows it when it moves
or resizes.

---

## 3. Shared components

Everything here appears on more than one surface and MUST behave identically wherever it appears.

### 3.1 Report control

Present on **every** surface, including read-only ones, so a broken surface can always be reported without
answering it.

- Label: `Report`. Tooltip: `Report a bug or suggestion`.
- It MUST have a distinct hover state.
- Its behaviour differs by surface — see §3.12.

### 3.2 Project badge

Present only when the caller supplies a project path. It shows the **final path segment only**, and its tooltip
is the full path. When no path is known it is absent entirely.

⚠️ The layout sketch editor shows no project badge (§10.6).

### 3.3 Header

Every surface carries a title and, on most, a body.

- **Title** wraps to as many lines as needed and never truncates — except on the two transient popups, where it
  is clamped and truncated.
- **Body** MUST be selectable and copyable.
- **The presentation-switch rule.** A body with no line break and a body containing one MUST be presented
  differently — the first as a single statement, the second as prose. **The trigger is the presence of a line
  break, not the length.** The intent is that a one-line question reads as a headline while multi-paragraph or
  list-like text reads as a passage. It applies to every surface's body.

### 3.4 Inline text formatting

Agent-supplied prose supports a small fixed set of inline formats. **Markers are consumed and never shown
literally.**

| Written as | Renders as |
|---|---|
| `**bold**` | Bold |
| `*italic*` | Italic (single asterisks not adjacent to another asterisk) |
| `` `code` `` | A distinct code treatment |
| `[label](url)` | Clickable text showing only the label; opens in the default browser |

Everything else renders literally. **Block-level formatting is not interpreted** — headings, bullet lists,
block quotes, fenced blocks and tables appear as raw characters. A malformed link stays literal. Formats are
applied in the order links → bold → italic → code.

Escaped newline and tab sequences in the incoming text are converted to real ones before display — which means
a body written with escaped newlines trips the presentation switch in §3.3 and is presented as prose.

**Where it applies:** the body of every *interactive* surface, the form's question text, and a note pane's
quoted subject.
**Where it does not:** ⚠️ the notification and response-preview bodies render exactly the characters supplied
(§10.3).

### 3.5 Tool strip

Three controls, present on every interactive surface, in this order:

| Control | Opens |
|---|---|
| `Snooze` | The duration tray |
| `Feedback` | The note pane |
| `Ask differently` | The alternative-shape menu |

State rules:

- **Only `Snooze` shows an active state** while its tray is expanded. `Feedback` never does, even while its
  pane is open.
- The **only** signal that a note exists is a change to the `Feedback` control's own indicator. It MUST be
  distinguishable at a glance from the no-note state.
- ⚠️ **Asymmetry:** the `S` key **only opens** the snooze tray; it never closes it. Clicking the control
  **toggles** it. Escape collapses it.

### 3.6 Snooze tray

Prompt: `Ask me again in:` — then five durations: **`1m` · `5m` · `15m` · `30m` · `1h`**.

Choosing one closes the surface immediately and starts a **global quiet period** of that length (§4.7).

⚠️ The durations are pointer-only on some surfaces, so a keyboard user can open the tray and then be unable to
pick (§10.7).

### 3.7 Ask-differently menu

Six entries, fixed order:

`Confirmation` · `Single Select` · `Multi Select` · `Text Input` · `Password` · `Wizard Form`

The entry matching the surface currently on screen is **marked as current and disabled**, so there is always
exactly one such row and the person can always tell which shape they are in.

Choosing an entry closes the surface immediately and asks the agent to re-pose the same question in that shape.
**Any in-progress answer and any drafted note are discarded** (§4.8).

Arrow keys move the highlight, Return chooses, Escape dismisses with no effect. Dismissing without choosing
leaves the surface exactly as it was.

### 3.8 Note pane

A side pane where the person writes a free-text remark that travels back *alongside* the answer.

Its width is **fixed** — it never stretches or shrinks. Opening it widens the surface by exactly that amount;
closing it narrows it back.

Contents: a caption naming what is being annotated; optionally a quoted **subject** showing the text being
annotated; a labelled multi-line editor supporting undo; and two controls, `Clear` and `Close`.

| Opened from | Caption | Subject shown |
|---|---|---|
| A single-question surface | `NOTE ON THIS DIALOG` | **No** — the question is already visible beside it |
| A form's `Feedback` control | `NOTE ON THIS FORM` | The form's intro text; **omitted if there is none** |
| A form's per-question control | `NOTE ON THIS QUESTION` | **Always** — that question's own text, falling back to the literal `(this question)` if it cannot be resolved |

Editor label: `YOUR NOTE`.

Behaviour:

- The editor **holds the caret from the first frame the pane begins to appear**, so a key pressed while it is
  still opening is typed into the note rather than treated as a shortcut.
- `Clear` empties the draft in place. It is **disabled while the draft is empty**.
- `Close`, the close control, Escape, or re-triggering the same target all close the pane and **preserve the
  draft**. Reopening restores it and re-focuses the editor.
- Triggering a **different** note target while the pane is open **swaps its contents** rather than closing it.
- A **whitespace-only draft counts as empty** everywhere: the tool-strip indicator stays in its no-note state,
  `Clear` stays disabled, and nothing is delivered.
- Tooltips: close control → `Close pane (Esc)`; `Close` → `Close pane (note is preserved)`.

### 3.9 Per-question note control

Only in the form, attached to each question. Three states: **no note**, **hovered**, **has a note**. The
has-note state MUST be distinguishable from the other two.

Tooltips: `Add a note for the agent` (empty) and `Edit note` (once a note exists).

### 3.10 Keyboard hint strip

Present on every interactive surface and on both steps of the report flow. It names the available shortcuts so
the person never has to guess.

Contents by surface — the three tool hints `S snooze` · `F feedback` · `A ask differently` always trail:

| Surface | Leading hints |
|---|---|
| Confirm | `⏎ confirm` · `Esc cancel` |
| Pick | `↑↓ navigate` · `Space select` · `⏎ done` |
| Text | `⏎ submit` · `Esc cancel` |
| Form | `↑↓ navigate` · `Space select` · `⏎ next` (`⏎ done` on the last step) |
| Value tweak | `↑↓ navigate` · `←→ adjust` · `⏎ save` or `⏎ cancel` · `Esc cancel` |
| Report flow | step 1 `⏎ next` · step 2 `⏎ copy & open` |

⚠️ The strip is static and advertises shortcuts that are currently suppressed (§10.4).

### 3.11 Action controls

Every surface ends in one to three action controls. There are four variants — **primary**, **secondary**,
**destructive** and **disabled** — and they MUST be distinguishable from one another.

Rules:

- **Ordering is always secondary first, primary last.** Cancel/Back on one side, Confirm/Done/Submit/Next on
  the other. This determines Tab order and muscle memory.
- The primary control MUST indicate that Return activates it — **but only while it is enabled.** A disabled
  primary MUST drop that indication, so the affordance never promises a key that will not work.
- A **disabled control is not focusable and is skipped by Tab** — never focused-and-inert.
- Activation requires press *and* release on the same control; dragging off cancels it.
- Labels that do not fit are truncated. A control never grows and the surface never widens to fit a label.

⚠️ The **destructive** variant exists but no surface uses it and no caller can request it, so a "delete 47
files" confirmation is indistinguishable from a harmless one (§10.8).

### 3.12 Report flow

**On an interactive surface**, the report control first captures a picture of the surface as it currently
looks, then covers it with a **two-step flow**. While that flow is up the surface beneath is inert, and every
key except Escape goes to the flow.

**Step 1 — describe.**
- Title `Report Issue`, body `Describe the problem below.`
- Field labelled `What happened?` with the placeholder `Briefly describe the issue...`
- Controls: `Cancel` and `Next →`. Hint `⏎ next`.
- `Next →` is **disabled while the description is empty or whitespace-only**, and Return does nothing.
- The description is trimmed before use.

**Step 2 — screenshot consent.**
- Title `Save Screenshot?`, body `Can we save a screenshot of this dialog to your clipboard? You can paste it
  directly into the GitHub issue with ⌘V.`
- Controls: `Skip` and `Yes, Copy Screenshot`. Hint `⏎ copy & open`. Both always enabled.

Escape closes the flow and **only** the flow; the surface underneath is untouched and regains focus.

**The outcome** is that the default browser opens a pre-filled issue page. **That page is the confirmation** —
there is no in-app success message. Its body carries, in order: a Description section with the typed text; a
section naming the request kind and reproducing it; an Environment section listing the project and the client;
a Screenshot placeholder line if consent was given; and a credit line. The title is the first 72 characters of
the description. The issue is pre-labelled as a bug.

If the picture cannot be captured, the flow still completes; only the clipboard copy is skipped.

**The control behaves differently by surface:**

| Surface | Behaviour |
|---|---|
| Confirm, Pick, Text, Form, Value tweak | Two-step flow, screenshot offered |
| Notify, Response preview | **Opens the issue page immediately** — no flow, no description, no screenshot |
| Layout sketch | **Opens the issue page immediately**, seeded with a `Layout editor: ` title prefix and an Environment section naming the layout editor |

⚠️ Nothing distinguishes these (§10.10).

### 3.13 Option row

The selectable element used by the pick surface and by every choice step of the form.

Carries a **label** and an optional **description**, plus a **selection indicator**.

**Required states:** default, hover, pressed, **selected**, **focused**. There is no disabled state — every
listed option is always selectable.

**Selection and focus MUST be separate visual channels.** A row can be focused-and-unselected,
selected-and-unfocused, or both at once, and all four combinations MUST be distinguishable. Focus MUST NOT be
signalled by the same channel selection uses.

⚠️ The focus indicator is currently delegated entirely to the host system and specified nowhere. Any rebuild
MUST define it explicitly (§10.26).

Long labels wrap rather than truncate, so an uneven stack is expected and correct. Rows do not shrink to fit
short labels.

⚠️ **Row labels and descriptions cannot be selected or copied.** Only surface body text and form question text
can.

#### Selection indicator

| Mode | Behaviour |
|---|---|
| **Single** | Choosing a row replaces the selection |
| **Multi** | Choosing a row toggles it independently |

The indicator's form MUST differ between the two modes, because — besides the surface's own identity cue — it
is the **only** thing telling the person whether they may choose more than one. Its state change is immediate;
there is no draw-in.

The indicator is **not a separate click target** — the whole row is.

#### The "Other" row

Appended as the **last item** of every option list unless the caller turns it off. Present by default.

- Fixed label `Other`, plus its own text field with the placeholder `Type your answer...`.
- Clicking anywhere on it selects it **and** places the caret in its field.
- Typing any character auto-selects it.
- In single-select, selecting it clears every other selection, and selecting a listed option clears it — the
  typed text stays visible but is no longer the answer.
- In multi-select it toggles independently and combines freely.
- **Selected-but-empty counts as unanswered.**
- The word `Other` is **never** returned. Only the typed text is.
- Text is **not trimmed** before being judged non-empty, so a single space counts as an answer.

⚠️ It currently behaves inconsistently with ordinary rows (§10.9).

### 3.14 Text field

The shared single-line input, used for text answers, masked answers, the "Other" custom answer and the report
description.

**Required states:** rest, **focused**, masked, and overflowing.

- Clicking anywhere in the field — not only directly on the text — places the caret.
- A prefilled value opens **with its text selected**, so the first keystroke replaces it. This is required
  behaviour, not a host-platform accident.
- Long content scrolls within the field; the field never grows and the surface never widens.
- Standard cut / copy / paste / select-all are available.
- No length limit is enforced and no trimming is applied on submit.
- A masked field renders substitute characters and MUST NOT reveal the real ones in any state.

---

## 4. The interaction model

These laws apply to every interactive surface. They are the reason the product feels like one thing.

### 4.1 The complete keyboard map

| Key | Does | Active when |
|---|---|---|
| `Return` | The surface's primary action | Always, unless a rule below overrides |
| `Escape` | Unwinds exactly one layer (§4.3) | Always |
| `Space` | Toggles the focused option row, or presses the focused control | Not while a caret is in a text field |
| `↑` / `↓` | Move focus between **content** elements, wrapping at both ends | Not while typing |
| `←` / `→` | Form: previous / next step. Value tweak: decrease / increase the focused value by one step | Not while typing |
| `Tab` / `Shift+Tab` | Cycle focus through **everything**, including action controls | Always |
| `S` | Opens the snooze tray | §4.2 |
| `F` | Opens the note pane | §4.2 |
| `A` | Opens the ask-differently menu | §4.2 |
| `Modifier+F` | Opens the note pane **regardless of focus** | Always |
| Cut / copy / paste / select-all | Standard editing | In any text field |

Modifier keys are written with the host platform's own glyphs; the binding is the platform's primary modifier
plus the named key.

**Arrow keys never reach the action controls.** Those are reachable by Tab alone. This is deliberate — it keeps
arrow navigation inside the answer, where it belongs.

### 4.2 The shortcut suppression law

Plain single-letter shortcuts (`S`, `F`, `A`) are **suppressed** in three situations:

1. While a caret sits in **any** text field, including the note editor, and including while the note pane is
   still opening.
2. While the note pane is open.
3. During the opening cooldown.

In all three the letter is typed literally. **The modifier-chorded feedback shortcut survives all three** — it
exists precisely because a bare `F` is unreachable on a text surface.

`Return`, `Tab`, the arrow keys and modifier chords always route to the surface. `Return` has one exception:
inside the note editor it inserts a newline.

### 4.3 The Escape unwinding law

Escape peels back **exactly one layer per press**, in this fixed order. It never skips a layer and never closes
two at once.

```
1. Report flow open?         → close the flow              (the surface is untouched)
2. Note pane open?           → close the pane              (the draft is preserved)
3. Snooze tray expanded?     → collapse the tray           (nothing is snoozed)
4. otherwise                 → cancel the surface
```

### 4.4 The Return law

Return first attempts the surface's **primary action**. If the primary action is unavailable because the
current answer is incomplete, the key **falls through to the focused control** — so a focused Back control
activates and a focused text field receives it. When nothing is focused, the key is consumed and nothing
happens.

### 4.5 The focus order law

- Focus order follows **reading order**: top to bottom, and left to right within a row. It wraps.
- It follows *presented* order, not creation order. Controls that appear or disappear join or leave the ring in
  their presented position.
- **Disabled controls are skipped entirely.**
- On appearance, focus lands on the **first content element — never an action control**. The same after a form
  step advances, and after the report flow closes. It lands shortly after, not instantly (§9).
- **The confirm surface registers no content elements**, so nothing is focused on open and no focus indicator
  is visible until the person presses Tab. `↑`/`↓` do nothing there. Return still confirms, because the primary
  action is bound at the surface level rather than to a focused control.

  This is deliberate: focusing the confirm control on open would let a stray Space answer the question the
  instant the cooldown ends.

### 4.6 The opening cooldown

For a short period after an interactive surface appears (§9):

- Every action control renders in a **damped, clearly-not-yet-ready state**, with a **visible indication of how
  much time remains**.
- Clicks are swallowed. `Return`, `Escape`, `Space`, `S`, `F` and `A` all do nothing.
- **Typing is never blocked.**

Escape is blocked at two independent levels during the cooldown, so it is inert even when the report flow is
open. Nothing indicates the block beyond the damped controls and their remaining-time indication.

The cooldown is adjustable and can be switched off entirely. When off, controls are live immediately and no
remaining-time indication is drawn.

**Transient popups never trigger a cooldown**, so Escape works on them from the first frame.

The purpose is narrow and worth stating: a surface appears over whatever the person was doing, and a keystroke
already in flight must not be able to answer it.

### 4.7 Availability

**Quiet period (snooze).** Global, not per surface. While one runs:

- No interactive surface is drawn at all. Each suppressed request is counted.
- Sounds are muted (a preference, on by default).
- **Notifications still appear.**
- Suppressed requests are **not** written to the interaction history.
- An expired period is cleared the next time a surface is requested.

**Away mode.** Suppresses every interactive surface entirely; the agent is told to proceed on its own defaults.
Notifications are unaffected.

**One at a time.** Only one interactive surface can exist. A second request while one is open **resolves to the
open surface's outcome** — no second surface appears. Notifications are exempt.

**Timeout.** An unanswered request is abandoned after a fixed period (§9). ⚠️ Nothing counts down, warns, or
states what happens at that moment (§10.29).

### 4.8 The outcome model

Every interactive surface ends in exactly one of six ways. **At most one special state is reported at a time**,
in this priority:

```
quiet period  >  re-ask request  >  note  >  cancellation  >  answer
```

**The note matrix** — which outcomes carry a drafted note:

| Outcome | Note | Reported as |
|---|---|---|
| Answer | **delivered alongside** | An answer, annotated |
| Decline / cancel **with** a note | **delivered** | A **redirection**, not a cancel — the agent reads the note, adjusts, and continues |
| Decline / cancel **without** a note | — | A plain cancel; the agent proceeds with a sensible default |
| Snooze | **discarded** | Duration and remaining wait only |
| Ask differently | **discarded** | The requested shape only |
| Timeout | discarded | Nothing |

A note is an **annotation, never a redirect**. It never replaces an answer, and closing the pane never discards
it. Whitespace-only notes count as empty everywhere.

⚠️ Snooze and ask-differently silently throw away typed work (§10.11).

### 4.9 Sound

A short sound MAY play as a surface appears. It is gated three ways, and the caller can only ever *ask*, never
force:

1. The caller asked for sound.
2. The person's preference for that category is on — **questions make sound by default, notifications do not**.
3. No quiet period is muting sounds.

Four options, one global preference: **`subtle`** (default — a short dry tick), **`pop`** (a soft percussive
pop), **`chime`** (a glassy bell), **`none`**.

⚠️ The notification's sound currently plays *after* the popup is already on screen, so it trails the appearance
rather than announcing it. It SHOULD play as the surface comes forward.

### 4.10 History

Every surface the person **answered or cancelled** appears in the interaction history, with its time, the
asking client, a summary of the question, and the answer (multiple selections joined with `, `). Suppressed
requests never do. A multi-question entry is summarised by its first question, with the answers on one line as
`key: value; key: value`.

---

## 5. The surfaces

### 5.1 Confirm

> One yes-or-no question. The simplest surface, and the only one with no invalid state.

**Default title:** `Confirmation`. **Body:** the question, per §3.3.

**Actions:** exactly two. Decline (secondary) then confirm (primary). Default labels `No` and `Yes`; both are
caller-supplied.

**Hints:** `⏎ confirm` · `Esc cancel` · the three tool hints.

**Behaviour:**

- The primary control is **never disabled**; Return always confirms once the cooldown has elapsed.
- Confirming reports *yes*. Declining reports *no* — and, with a note drafted, the note travels with it, making
  it a redirection rather than a cancel (§4.8).
- Nothing is focused on open (§4.5).

**Edge cases:**

- Over-long action labels truncate; the control does not grow and the surface does not widen.
- ⚠️ A very long title has no truncation rule and there is no scroll region, so it can push the actions past
  the height cap.
- A raw URL or file path renders as-is and is not clickable — only bracketed links are.

---

### 5.2 Pick

> One option from a list, or several. 2–20 options.

**Default title:** the calling client's name. **Body:** the question, per §3.3.

**Content:** a list of option rows (§3.13) in the order supplied. **The "Other" row is always the final item**
when present. The list is the scrolling region.

**Actions:** `Cancel` (secondary) and `Done` (primary).

**Hints:** `↑↓ navigate` · `Space select` · `⏎ done` · the three tool hints.

**Validity:**

- Nothing selected → `Done` is **disabled**, drops its Return indication, and Return does nothing.
- "Other" selected but empty → counts as nothing selected.
- A preselected default opens already selected **with focus on it**, so `Done` is live on the first frame.

**Selection semantics:**

| | Single | Multi |
|---|---|---|
| Choosing a listed option | Replaces the selection; clears "Other" | Toggles independently; leaves everything else |
| Choosing the selected option | Deselects it, leaving the question unanswered | Deselects it |
| The returned answer | One string, or the typed custom text | A list in list order, with any typed custom text **appended last** |

**Accessibility description:** multi → `Select one or more options. Use arrow keys to navigate, Space to
select.` · single → `Select one option. Use arrow keys to navigate, Space to select.`

**Edge cases:**

- Focus moving to a row **scrolls it to the centre of the list**.
- Fewer than 2 or more than 20 options is refused before any surface appears.
- Options phrased as "All of the above", "Select all", "Everything" or "None of the above" are **rejected
  outright** (§6.4).
- ⚠️ Duplicate option strings produce two indistinguishable rows; a default matching more than one silently
  picks the first.
- A default matching no option preselects nothing.
- ⚠️ No selection counter, no select-all or clear-all, no way to require a minimum or maximum count (§10.12).

---

### 5.3 Text

> One typed line. Optionally masked.

**Default title:** `Input`. **Body:** the prompt, per §3.3. Because there is no in-field hint, **all guidance
must live here.**

**Content:** exactly one text field (§3.14).

**Actions:** `Cancel` (secondary) and `Submit` (primary).

**Hints:** `⏎ submit` · `Esc cancel` · the three tool hints.

**Behaviour:**

- The field **takes focus automatically shortly after the surface appears** — the person can type immediately.
- Return submits; a newline can never be inserted. The field is strictly single-line, and pasting multi-line
  text yields one line.
- **The field is always in a submittable state.** `Submit` is never disabled and an empty submit returns an
  empty string. There is no validation, no length limit, no required-field concept and no error state.
- ⚠️ **No placeholder is rendered**, even though the shared field supports one and the form's text steps use
  one. An empty prefill gives a completely blank box.
- A prefilled value opens **pre-selected**, so the first keystroke replaces it.

**Masked variant.** Identical in every respect except that it is identifiable as masked before typing, and
characters are substituted.

⚠️ **No reveal control, no caps-lock warning** — someone who mistypes a long secret cannot verify it before
submitting, and a prefilled secret is indistinguishable from typed input (§10.13).

The ask-differently menu marks `Text Input` as current in the plain variant and `Password` in the masked one.

---

### 5.4 Form

> Several questions, one at a time. 1–10 questions.

**Default title:** the calling client's name. **Body:** intro text — it also becomes the quoted subject of the
form-level note.

**Progress.** The surface MUST show how far through the batch the person is, and MUST expose it as `Step <N> of
<M>` with a percentage to assistive technology. **The current step counts as complete**, so the indication
reads as full while the person is on the last step.

There is also a textual counter reading `<N> of <M>`.

Progress indication is **decorative** — not clickable, never focusable, and there is no way to jump between
steps.

**Question area** (the scrolling region): the question text, selectable and wrapping; the per-question note
control (§3.9) attached to it; and the answer control — option rows (§3.13) for a choice step, or a single text
field (§3.14) for a text step. **Text steps never show an "Other" row** — the field already is free input.

**Actions, by position:**

| Step | Secondary | Primary |
|---|---|---|
| First | `Cancel` | `Next` |
| Middle | `Back` | `Next` |
| Last | `Back` (or `Cancel` if the form has exactly one question) | `Done` |

**Hints:** `↑↓ navigate` · `Space select` · `⏎ next` (`⏎ done` on the last step) · the three tool hints.

**Navigation:**

- `→` and the primary control advance; both are **inert while the current question is unanswered**.
- `←` and the secondary control go back. **Every previously entered answer is preserved** in both directions;
  nothing is ever cleared by moving between steps.
- Step changes are **instantaneous** — there is no transition between questions. Focus lands on the new step's
  first answer element shortly after, and the question area scrolls back to the top of the list.
- Because forward movement requires a valid answer, a submitted form is normally complete.

**Validity per step type:**

| Step | Valid when |
|---|---|
| Single-select | Exactly one option selected, or "Other" selected with non-empty text |
| Multi-select | At least one option selected, or "Other" selected with non-empty text |
| Text | The field is non-empty (a single space counts) |

**What comes back:** one answer per answered question, labelled with the caller's own key, plus how many were
answered. A single-select step yields one string; a multi-select step a list in list order with any typed text
appended last; a text step the typed string. **A question never answered is reported as nothing at all**, not
as an empty answer. Per-question notes and one form-level note are delivered alongside, each keyed to its
question.

**Edge cases:**

- A one-question form still renders the full chrome: `1 of 1`, `Cancel` and `Done`.
- Cancelling mid-form **discards every answer silently** — but any notes still travel back. ⚠️ There is no
  confirmation prompt.
- Snoozing or asking differently from inside a form discards all answers.
- ⚠️ No review step, no skip, no optional questions, no inline validation message explaining why the primary
  control is disabled (§10.14).

---

### 5.5 Notify

> An announcement. No question, no waiting, no controls.

**Not suppressed** by a quiet period or by away mode, and it may appear on top of an open interactive surface.
It floats above other windows unconditionally and **appears without stealing keyboard focus**.

**Contents:** the report control and project badge; an identity cue; a title clamped to one line; and the
message in a scrolling region.

There is no header block, no tool strip, no hint strip, and no action controls.

**Default title:** `Notice`.

**Lifetime:** it closes itself after a fixed period (§9). There is no countdown, no pause-on-hover, and no
close control. **Escape closes it early** — the only key it responds to, working from the first frame because
notifications never trigger a cooldown.

**Anchor:** the person's saved preference only; a per-call anchor is ignored.

⚠️ The message renders as **literal characters** — no formatting, no clickable links (§10.3).
⚠️ Nothing specifies what happens when two notifications arrive at once (§10.5).
⚠️ A long message scrolls, but the lifetime is rarely enough to read it.

---

### 5.6 Response preview

> A last look at what is about to be sent. Read-only.

Shown right after any interactive surface is answered, **only when the person has enabled the review-before-send
preference**, and **never** after a snooze.

Structurally identical to the notification, with one behavioural difference: **its identity cue MUST NOT read
as an alert.** A preview is informational; a notification is an announcement, and the two must not be confused.

**Title:** `Response Preview`.
**Body:** the exact outgoing text — either the compact structured payload, or a plain-language rendering of it
when the humanised-responses preference is on.

Nothing the person does can alter or stop the response. It closes itself after the same fixed period; Escape
closes it early. It can be moved. The report control opens the issue page directly.

If the preview cannot be shown for any reason, the answer is still delivered — it is purely advisory.

⚠️ A fixed lifetime with no countdown, no pause and no scroll indication defeats the surface's own purpose for
any response longer than a line (§10.15).

---

### 5.7 Value tweak

> Numbers, tuned live against the person's real files, while they watch the result change.

Unlike the others, the answer here is not a decision — it is a *feel*. The person drags a control and their own
application updates. Everything about the surface serves that loop.

**Title:** always the calling client's name. ⚠️ A supplied title has no effect (§10.16).
**Body:** the agent's explanation of what is being tuned.

#### Session toolbar

- **Detected-stack badge** (conditional): reads `Framework detected: <name>` — one of Svelte, React, Vue, CSS,
  Vanilla. **Exactly one badge is shown** even when the values live in several kinds of file. It is
  informational only and can be wrong for a mixed project.
- **`Replay animations`** (conditional — only when a stack is detected). Default **on**. Tooltip: `Trigger
  animation replay after changes (requires browser hook)`. When on, the page being tuned re-runs its animations
  after each change **if it is set up to do so**. ⚠️ Nothing shows whether it is — the control looks identical
  either way and a failure is silent.
- **`Show edits`** (always present). Default **off**. Tooltip: `Toggle debug console`. Opens and closes the
  edit console. **Closing it also forgets the last edit**, so reopening starts empty.

#### Parameter list

One card per tunable number, in exactly the order supplied, up to 20.

Cards are grouped under a heading when the caller supplies an element or selector hint. **Grouping merges only
consecutive parameters sharing the same hint** — the same hint reappearing later produces a second heading.

#### Parameter card

Carries a **label** (its tooltip names the file and line the value came from), a **slider**, a **step
indication**, a **numeric readout with a unit**, and a **settings control**.

Required states: **default**, **focused**, **errored**, and **settings open**.

**Errored** shows the message `File changed externally`, disables the numeric field, makes the slider inert,
and causes arrow-key adjustment to be ignored.

**Settings open** replaces the slider area and MUST make clear that the slider is temporarily unavailable.

#### Slider

- Pressing the **track** jumps the value to that position, and the press continues as a drag from there.
- Pressing the **handle** begins a relative drag with no jump.
- Dragging horizontally moves the value proportionally: traversing the full track covers the full range.
- **Precision is vertical distance, not a modifier key.** The value's travel rate falls off continuously with
  how far the pointer has moved away from the row it was pressed on — roughly half speed at a short distance
  and a quarter at three times that — with no steps or thresholds. Moving back toward the row restores full
  speed. *This is the best idea in the surface: fine control with no key to remember.*
- Values clamp hard at the working bounds; there is no rubber-banding.
- Every dragged value is **snapped to the step** before it is applied.
- ⚠️ Hovering produces no feedback at all — no handle change, no value tooltip.

#### Step indication

Shows how coarse or fine the steps are along the track. **When ticks would be too dense to read, the count is
repeatedly halved until they are legible** — so a 0–500 range stepping by 1 shows a readable subset, not 501
hairlines. Fewer than two ticks draws nothing.

⚠️ Ticks reflect the step only. They never mark the current value, the original value, or zero, which makes
signed ranges hard to read.

#### Numeric readout

- Click to edit. Return commits: unparseable text reverts silently; a parsed number is clamped and applied.
- The number updates live while dragging or arrowing.
- **Precision is inferred from the source text**: no decimal point in the original → a rounded whole number;
  otherwise the larger of (decimals in the original) and (decimals in the step).
- Values written back **keep the file's own formatting** — the embedded unit suffix, the decimal count, and a
  leading-dot style such as `.5` all survive.
- ⚠️ The field carries no chrome, so **its editability is not discoverable**.

#### Per-card settings

Opened by the settings control. Offers a **revert** action and **`Min` / `Max`** fields.

- Revert writes the value back to what it was when the surface opened, clears the card's error if that write
  succeeds, and closes. Tooltip: `Reset to original value`.
- `Min` is accepted only if strictly less than the current max; `Max` only if strictly greater than the current
  min. ⚠️ **A rejected value snaps back silently with no explanation.**
- The adjusted range is **session-only and per card**: it rescales the slider, re-derives the ticks and
  re-clamps input, but never changes the current value and is never reported back. ⚠️

#### Live writing

Every change reaches the file **shortly after the person stops moving that value** (§9), so a continuous drag
produces one update per pause rather than one per movement. Moving one value never holds up another. Small
shifts elsewhere on the same line do not break a value's connection to its card, and when several tuned values
sit on one line, changing one never corrupts the others.

A write **fails and errors the card** when the expected text is no longer there, the file cannot be read or
written, or the target lies outside the declared project folder. ⚠️ **All three collapse to the single message
`File changed externally`**, so the person cannot tell which happened.

- ⚠️ There is **no difference between "queued" and "written"** and no success confirmation. The console is the
  only positive signal, and it is off by default.
- ⚠️ **Cancelling does not roll back writes already made** (§10.17) — the most surprising behaviour in the
  product.

#### Edit console

A separate panel beside the surface, shown only while `Show edits` is on. It appears immediately in its empty
state and populates after the first successful write.

- **Populated:** a header reading `<file name>:<line number>`, then the edited line with **two lines of context
  either side**. The edited line and the changed number within it MUST both be distinguishable from context.
  Context lines are truncated past a limit; **the edited line is never truncated** — it scrolls.
- **Empty:** the message `Move a slider to see changes`.

It sits on the **far side from the surface's own anchor** — a right-anchored surface gets its console on the
left, otherwise on the right. It is not independently movable or resizable, shares the surface's stacking
level, and follows it.

Content is not selectable and has no click target.

⚠️ It shows only the **single latest edit**, never a history, despite being labelled "Show edits".

#### Footer

**Hints:** `↑↓ navigate` · `←→ adjust` · `⏎ save` or `⏎ cancel` · `Esc cancel` · the three tool hints.

**The action set changes with state** — the moment any value differs from where it started, and back again if
every value returns:

| State | Actions | Return hint |
|---|---|---|
| No changes | A single primary `Cancel` | `⏎ cancel` |
| Changes made | `Revert All` · `Tell Agent` · primary `Save to File` | `⏎ save` |

| Action | Does |
|---|---|
| **`Save to File`** | Flushes every pending write, closes, and reports the final numbers with a marker meaning *the files already contain these; there is nothing to apply* |
| **`Tell Agent`** | Cancels pending writes, rewrites every value back to its opening value, closes, and reports the chosen numbers with a marker meaning *the files are untouched; you apply these* |
| **`Revert All`** | Rewrites every value back to its opening value, restores every readout, clears the error on every card whose reset succeeded, empties the console, and **leaves the surface open**. Everything now matches its start, so the footer collapses back to `Cancel`. |
| **`Cancel`** | Closes with no answer. ⚠️ Writes already made remain on disk. |

**Keyboard:** `↑`/`↓` move the focused card (with no card focused, `↑` jumps to the last and `↓` to the first);
`←`/`→` step the focused value; both are suppressed while typing.

⚠️ Three input methods clamp and snap differently (§10.18).
⚠️ There is **no per-card changed marker**; with 20 cards the person cannot see which they moved.

---

### 5.8 Layout sketch editor

> A screen layout, proposed by the agent, dragged into shape by the person.

This surface deliberately breaks the model above. It is a **workspace**, not a question.

#### Window behaviour

- It **is resizable**, down to a minimum, by dragging near any edge or corner, with cursor feedback naming the
  direction.
- It is moved by dragging **the header region only** — the body and footer do not move it.
- It is modal and **exclusive**: only one session may exist. A second request is refused with `An interactive
  layout session is already running. Complete or cancel it first.` A request with no desktop session is refused
  with `Interactive layout editor requires a desktop environment (unavailable over SSH/CI).`

#### Header

The report control (§3.1), a title with an optional description, and a **grid-size indication** reading
`<columns>×<rows>`.

Default title `Layout Sketch`. ⚠️ No project badge appears here (§10.6).

#### Tool rail

- **Undo / redo.** Tooltips `Undo (⌘Z)` and `Redo (⌘⇧Z)`. Each is disabled when there is nothing to do. Undo
  history is capped (§9) and the oldest step is discarded silently. **Making any new change after undoing
  clears the redo history.**
- **`Add`** — opens the add-block dialog.
- **A stash drop target** — only during a drag.
- **The stash tray** — only when something is stashed.

⚠️ The rail does not scroll, so many stash entries can overflow it.

#### Canvas

A fixed grid of **3–20 columns by 3–20 rows**, set when the session opens and **not changeable from inside the
editor**.

- **Cells are always square.** The grid scales to fit the available area and is centred in it; leftover space
  stays blank.
- **The canvas never scrolls** — it always scales.

Layer order, back to front: grid → role tints → blocks (containers before nested) → alignment guides →
annotation pins. **The hovered block is raised above its neighbours.**

Clicking an **empty** cell opens the add-block dialog targeted at it. Clicking a covered cell does nothing at
the canvas level.

#### Block

**Blocks show their number, not their label.** The label is reachable by hover tooltip, by renaming, in the
stash entry, and in every textual output.

**Numbering is hierarchical:** top-level blocks are `1`, `2`, `3`… in reading order; a block nested inside
block 2 is `2:1`; one nested inside that is `2:1:1`, to unlimited depth.

**Four independent semantic dimensions** must each be readable at a glance and must not be confusable with one
another:

| Dimension | Values | Meaning |
|---|---|---|
| **Content kind** | text, image, video, avatar, button, input, list, chart, map, nav, form | What kind of content lives there |
| **Role** | header, sidebar, canvas, footer, toolbar, panel | Which structural family it belongs to |
| **Importance** | primary, secondary, tertiary | How visually dominant it should read |
| **Elevation** | 0–3 | How far it floats above the surface |

An unrecognised role produces no role indication at all rather than a fallback.

**Required states:** default, **hovered**, **promoted** (see below), **dragging**, **nested**, **renaming**,
**read-only**. Read-only removes the resize affordance, dragging, double-click renaming and the context menu;
hover highlighting still occurs.

**A nested block MUST remain distinguishable from its container** and MUST NOT obscure the container's own
extent.

**Direct manipulation:**

- **Move** — press and drag anywhere on the block; a small movement threshold starts it. A live indication
  shows the destination as `x: <column>, y: <row>` (zero-based). Release snaps to the nearest whole cell,
  clamped fully inside the grid.
- **Resize** — drag the resize affordance; a smaller movement threshold starts it. A live indication shows
  `<width>×<height>` in whole cells. Clamped to at least one cell and at most the space remaining to the grid's
  far edges.
- **Rename** — double-click. Return commits (ignored if empty); Escape reverts. Placeholder `Label`.
- **Context menu** — right-click. `Duplicate` creates a copy offset one cell right and down, clamped, labelled
  `<label> Copy`, keeping the colour but **losing** content kind, role, importance, elevation and flow
  direction. `Delete` removes it immediately with **no confirmation**; nested blocks are **not** deleted. Both
  are undoable.
- **Nesting is inferred purely from geometric containment** — the smallest containing block wins. Dragging a
  container moves its children by the same cell delta; dragging a child does not move the container. Resizing a
  block so it no longer contains a former child **instantly reclassifies that child as top-level**, changing
  its treatment and its number.
- **Promotion** — holding a modifier while the pointer sits over two or more stacked blocks promotes the next
  one to the top of the hover order, wrapping. A promoted block behaves exactly as a hovered one. ⚠️
  Completely undiscoverable (§10.20).

**Stashing.** Dragging a block so its snapped destination falls **past the bottom row or before the first
column** removes it from the grid and parks it in the stash. **The opposite edges only clamp.** ⚠️ The
asymmetry is never explained.

Two drop hints appear the moment a drag begins and vanish when it ends: one over the canvas reading `Drop to
stash`, one in the rail reading `Drop here`. **Neither is a pointer target** — the decision is made from the
drag's computed destination, not from where the pointer is released, so both highlight from the same condition.

**Stash tray.** Headed `Stash`, one entry per stashed block showing its label and its colour. Clicking an entry
restores the block **at its original position and size**, with **no collision check** — it can land on top of
something. A stashed container takes its children with it, but restoring the container restores **only the
container**. A block reappearing by any route is dropped from the tray automatically.

⚠️ **Blocks left in the stash are silently discarded on Accept**, and reported as removed. The person is never
warned.

#### Content-kind inference

When no content kind is supplied, one is guessed from the block's label by **case-insensitive substring match,
evaluated in a fixed order, first match wins**:

`image` ← image, photo, hero, banner, thumbnail, logo · `video` ← video, player · `avatar` ← avatar, profile
pic · `button` ← button, cta, action · `input` ← input, search, field · `list` ← list, feed, items · `chart` ←
chart, graph, stats, analytics · `map` ← map, location · `nav` ← nav, menu, tabs, breadcrumb · `form` ← form,
signup, login, register, contact

An explicit kind always beats the guess. **Renaming re-runs the inference**, so a rename can make an indication
appear, change or vanish. Because matching is substring-based and ordered, "Hero Menu" resolves to *image* and
"Sitemap" to *map*.

Elevation is guessed the same way when not supplied: modal/dialog/overlay → 3, popover/floating → 2, card → 1,
everything else → 0.

#### Alignment guides

Shown only while a block is being dragged or has been promoted. A guide appears where the active block's edge
coincides **exactly** with another block's corresponding edge. Matching is exact grid-coordinate equality —
there is no proximity tolerance and no magnetism, because blocks already snap to whole cells.

⚠️ Guides currently reflect the block's **committed** edges rather than its live destination, so they never
update during the one gesture they exist for (§10.21).

#### Annotations

Caller-supplied only — **the person can neither create, edit nor delete them.**

Each is a numbered pin attached to a grid cell, with a leader to that cell, plus a numbered legend below the
canvas. **Legend text is single-line and truncated.**

A pin whose cell falls inside a block being dragged **follows that block**, and its stored coordinate is
rewritten on release. **Ownership is the first block in list order** whose extent contains the cell — not the
topmost or the smallest. A pin in no block never moves. Annotations belonging to a stashed block **stay behind,
orphaned.**

⚠️ A pin at the first column and row sits mostly outside the canvas. The legend does not scroll and squeezes
the canvas as it grows.

#### Device frames

Optional decorative chrome — **browser**, **phone** or **tablet** — wrapping the canvas so proportions read in
context. **Nothing in a frame responds to input**, and the frame cannot be changed from inside the editor.
Frame chrome consumes space, so cells get smaller.

The browser frame shows a mock address placeholder `https://`; the phone frame shows a fixed clock `9:41`
(never the real time) and no battery, signal or notch; the tablet frame carries no chrome at all.

The canvas drop hint re-anchors to the bottom of the framed unit rather than the raw canvas.

#### Add-block dialog

Heading `Add Block` · a field with the placeholder `Block label` · `Cancel` and `Add`, with `Add` as the
default action. Return confirms, Escape cancels.

`Add` is **disabled while the field is empty** and guarded on activation, so an empty label can never create a
block. ⚠️ **Whitespace-only text is accepted** and produces a block with a blank-looking label.

The new block is always **one cell**, coloured by the next entry in a fixed rotation, with no content kind,
role, importance or elevation.

The target cell is the clicked cell, or — when triggered from the rail — the **first free cell in reading
order**; if the grid is fully covered it falls back to the first cell, **producing an overlap with no warning**.

#### Footer

Two hint lines:

```
Drag to move · Resize from corner · Double-click to rename
⌘Z Undo · ⌘⇧Z Redo · ⌘D Duplicate · ⌫ Delete
```

Then `Cancel` and the primary `Accept`.

⚠️ **Duplicate and Delete are advertised but not bound** — they exist only in the context menu (§10.22).

**Keyboard, window-wide:** `Escape` cancels · `Return` accepts (which means it also fires while a label is
being typed unless the field consumes it first) · `⌘Z` undo · `⌘⇧Z` redo · standard editing in text fields.

⚠️ **There is no selection model at all** — no click-to-select, no selected state, no multi-select, no marquee,
no way to act on several blocks at once. Everything is hover plus a per-block context menu. And **the canvas is
entirely unreachable by keyboard** (§10.23).

#### What accepting produces

Accepting resolves as **kept as proposed** when the final layout is identical to what was proposed, and as
**changed by the user** otherwise — in which case a plain-language change list comes with it:

```
Added "<label>" at (<x>,<y>) size <w>×<h>
Moved "<label>" from (<x>,<y>) to (<x>,<y>)
Resized "<label>" from <w>×<h> to <w>×<h>
Renamed "<old>" to "<new>"
Removed "<label>"
```

One block can produce several lines. Move, resize and rename all use the block's **final** label. Colour, role,
content kind, importance and elevation changes are never reported, because the editor offers no way to change
them.

Three representations come back alongside the layout:

**1. Prose description**

```
Layout: 12 columns × 8 rows
- "Header" spans full width at top (cols 1–12, rows 1–1)
  - "Logo" on the left (cols 1–2, rows 1–1) [nested inside "Header"]
```

Spatial phrases in evaluation order: `spans full width at top` · `spans full width at bottom` · `spans full
width` · then any combination of `on the left`, `on the right`, `at the top`, `at the bottom` joined by `, ` ·
falling back to `in the center area`. Ranges are 1-based inclusive. A brief mode instead emits `- "Header" at
(0,0) size 12×1` with zero-based coordinates. An empty layout emits `No blocks defined.`

**2. Character diagram**

A grid aligned by character position — it therefore MUST be read in a fixed-width context — with unoccupied
cells holding a single `.` and a legend mapping each abbreviation to its label (`H=Header`, sorted
alphabetically). Horizontally adjacent cells of the same block have the separator between them removed, so a
wide block reads as one bar. Abbreviations are the uppercased first character of the label if unused, else the
first two, else the first character plus an incrementing number from 2; `.` is reserved. **Where blocks
overlap, the smaller block is the one shown.**

**3. Static image**

⚠️ The exported image does **not** currently reproduce what the person edited — different proportions, inverted
treatment, labels instead of numbers, and a legend outside the stated bounds (§10.24).

---

## 6. The caller surface

What the agent can ask for, and exactly how each option changes what the person experiences.

### 6.1 The four capabilities

| Capability | Produces | Waits for the person |
|---|---|---|
| **ask** | One of: confirm, pick, text, form | Yes |
| **notify** | The notification popup | No |
| **tweak** | The value tuning surface | Yes |
| **propose layout** | The sketch editor | Yes |

### 6.2 Options shared by every surface

| Option | Meaning | Effect | Default | Limits |
|---|---|---|---|---|
| `body` | The question or message | The header body (§3.3). Formatted per §3.4 — except on the notification. Escaped newlines become real ones, which trips the presentation switch and renders it as prose. | required | 1–1000 chars |
| `title` | The headline | Wraps; the transient popups clamp it to one line. | Per surface: `Confirmation` · client name · `Input` · client name · `Notice` · `Response Preview` · client name · `Layout Sketch` | ≤ 80 chars |
| `position` | Which anchor the surface takes | `left` · `right` · `center`. Also decides the note pane's side and the resize anchor. **Never applied to the two transient popups.** | The person's saved preference; falls back to centre | one of left / center / right |
| `project_path` | Which project this is about | The project badge, showing only the final segment with the full path as its tooltip. Omitting it removes the badge. Also the Project line in a filed report. | Cached from the first call in the session | absolute path |

Three more arrive from the launching environment rather than per call:

| Option | Effect |
|---|---|
| **Calling client name** | Used as the title when the caller supplies none; appears in a filed report's Environment section and beside every history entry. Default `MCP`. ⚠️ Documented as *prefixing* supplied titles but does not (§10.25). |
| **Colour scheme** | Selects one of the available palettes. Unrecognised values fall back to the default. Behaviour, copy and the caller surface are unchanged. |
| **Presentation style** | Selects a layout style (§7). Unrecognised names print the available list and fall back to the default style. |

### 6.3 Confirm

| Option | Effect | Default | Limits |
|---|---|---|---|
| `yes` | The primary control's label; it also carries the Return indication | `Yes` | ≤ 20 chars |
| `no` | The secondary control's label; no Return indication | `No` | ≤ 20 chars |

### 6.4 Pick

| Option | Effect | Default | Limits |
|---|---|---|---|
| `choices` | One row per entry, in order, above the "Other" row | required | **2–20**, each 1–100 chars |
| `descriptions` | A secondary line under the matching label. Index-aligned; an empty string renders no line; a short list is padded; extras are ignored. | none | each ≤ 200 chars |
| `multi` | Switches to multi-select: indicator form changes, the surface's identity cue changes, the accessibility description changes, and toggling changes from replace to accumulate. Adds **no** counter and no select-all. | `false` | — |
| `other` | Appends the free-text "Other" row. Set `false` **only** for genuinely closed lists. | `true` | — |
| `default` | Preselects that row and starts focus on it, so `Done` is live immediately. A value matching no option preselects nothing. | none | must match an option exactly |

**Rejection rule.** An option phrased as "All of the above", "Select all", "Everything" or "None of the above"
is refused **before any surface appears**, with: `Do not include "<that option>" style options. If the user
should be able to select multiple answers, set multi: true instead.`

### 6.5 Text

| Option | Effect | Default | Limits |
|---|---|---|---|
| `default` | The field opens containing this text, **pre-selected**. A long value scrolls inside the field rather than widening the surface. | empty | any string |
| `hidden` | Masks the input and changes the surface's identity cue. No reveal control. | `false` | — |

### 6.6 Form

| Option | Effect | Default | Limits |
|---|---|---|---|
| `questions` | One step each, in order. Sets the progress denominator. | required | **1–10** |
| `…[].id` | Never displayed; the key the answer and any note are filed under | required | 1–50 chars |
| `…[].question` | The step's prompt, selectable and wrapping. Also quoted in that question's note subject. | required | 1–500 chars |
| `…[].type` | `choice` → option rows (plus the "Other" row by default). `text` → a single field, and no "Other" row. | `choice` | choice / text |
| `…[].options` | One row each, in order | required for choice | **2–10**, each 1–100 chars |
| `…[].descriptions` | A secondary line under the matching label | none | each ≤ 200 chars |
| `…[].multi` | Multi-select for that step; that step's answer becomes a list | `false` | choice only |
| `…[].other` | Appends the "Other" row to that step | `true` | choice only |
| `…[].placeholder` | Ghost text in the empty field | `Enter your answer...` | text only, ≤ 200 chars |
| `…[].hidden` | Masks that step's field | `false` | text only |

The same "all of the above" rejection rule applies per step.

### 6.7 Notify

| Option | Effect | Default |
|---|---|---|
| `sound` | Requests a sound. Gated by §4.9 — since the notification sound preference is **off by default**, asking for one often produces silence. Changes nothing visible. | `true` |

The notification ignores a per-call `position`.

### 6.8 Value tweak

| Option | Effect | Default | Limits |
|---|---|---|---|
| `parameters` | One card each, in order | required | **1–20** |
| `…[].label` | The card's name; its tooltip names the file and line | required | 1–100 chars |
| `…[].element` | A group heading above the card. Consecutive cards sharing it merge under one heading. | none | ≤ 100 chars |
| `…[].unit` | Shown beside the readout. Auto-detected for stylesheet and pattern addressing. | auto, else blank | ≤ 10 chars |
| `…[].min` / `…[].max` | The slider's ends, the clamps, and the starting contents of the settings fields | required | min must be below max |
| `…[].step` | Tick spacing, the arrow-key increment, the drag snap, and the minimum decimals shown. Omitted → derived as one hundredth of the range rounded to a nice 1/2/5/10 × power of ten (0–500 → 5; 0–48 → 0.5). | auto | must be positive |
| `…[].current` | Positions the handle, seeds the readout, and is what "revert" writes back. With pattern addressing it also disambiguates which match this card controls. | resolved for stylesheet addressing | must equal the real value |
| `…[].id` | Never displayed; the key in the reported answer. Omitted → derived from the label. **Two entries resolving to the same key prevent the surface from opening at all.** | derived | 1–50 chars, unique |
| `…[].file` | Appears in the label's tooltip and the console header. Its type, pooled across all parameters, decides the stack badge and whether the replay control appears. | required | absolute, or relative to the project |

**Three ways to address a value**, exactly one of which must be complete:

| Style | Options | Notes |
|---|---|---|
| **Direct** | `line` · `column` · `expectedText` | Lines and columns count from 1. The source text drives the readout's number formatting. If it no longer matches at write time, the card errors. |
| **Stylesheet** | `selector` + `property`, optionally `index` or `fn` | Resolves before the surface opens and supplies the unit and group heading automatically. `index` picks one value out of a multi-value declaration; `fn` targets a named function's argument. |
| **Pattern** | `search` (one placeholder marking the number) + `current` | Auto-detects the unit from what follows the placeholder. |

**Refusals — nothing opens at all:** a location that cannot be resolved; two parameters resolving to the same
spot; two sharing an identifier; a pattern matching several places that the supplied current value cannot
single out (the agent is told to be more specific). Two cards MAY legitimately target the identical pattern in
the same file if their starting values differ.

⚠️ `title` is accepted here but has no effect (§10.16).

### 6.9 Propose layout

| Option | Effect | Default | Limits |
|---|---|---|---|
| `width` / `height` | Grid columns and rows, shown in the size indication. Cells stay square, so a wide grid in a short window shrinks every cell. | 12 / 8 | 3–20, clamped; ignored when a template is given |
| `template` | Overrides both. `compact` 6×4 (2–4 blocks) · `standard` 12×8 (default, up to 12) · `spacious` 16×10 (up to 20) · `detailed` 20×16 (up to 30) · `mobile` 4×12, which **also switches on the phone frame** unless one is named. | none | one of the five |
| `description` | A secondary line under the title; omitting it collapses the header | none | ≤ 200 chars |
| `blocks` | One editable block each, numbered in reading order | empty grid | coordinates are **not** clamped on load, so out-of-grid values render off-grid |
| `…[].label` | The hover tooltip, the rename seed, the change-list name, and the seed for the content-kind and elevation guesses | required | 1–50 chars |
| `…[].x` / `y` / `w` / `h` | Zero-based top-left cell plus spans. A block fully inside another is automatically nested. | required | x,y ≥ 0; w,h ≥ 1 |
| `…[].color` | The block's identity colour, also used for its stash entry | auto from a fixed rotation by list position | 6-digit hex, with or without a leading hash; unparseable → the first rotation entry |
| `…[].content` | The content kind; beats the label guess | guessed from the label | text / image / video / avatar / button / input / list / chart / map / nav / form |
| `…[].role` | The structural family, and — when importance is unset — the visual weight: `canvas` → primary; `header`, `sidebar` → secondary; `toolbar`, `panel`, `footer` → tertiary | none | header / sidebar / canvas / footer / toolbar / panel |
| `…[].importance` | How dominant the block reads | from role, else secondary | primary / secondary / tertiary |
| `…[].elevation` | How far it floats | guessed from the label | 0–3, clamped |
| `…[].flowDirection` | Which way content inside it flows | none | row / column |
| `structure` | A nested tree describing the layout by direction, gaps, sizing and priority instead of coordinates. **Takes precedence over `blocks`.** It is turned into ordinary blocks before the editor opens — the person only ever drags plain blocks and never sees or re-edits the nesting. | none | per node: id 1–50 chars; optional label ≤ 50 chars falling back to the id; direction row/column (column when unstated); gap 0–10 cells; priority a non-negative integer defaulting to 1; size a whole number of cells, or `hug` (one cell), or `fill` (a priority-weighted share of what is left) |
| `frame` | Device chrome | none, except `mobile` implies phone | browser / phone / tablet |
| `annotations` | Numbered pins plus the legend. The person cannot create, edit or delete them. | none | per entry: non-negative column and row, text 1–100 chars |

---

## 7. Presentation styles

The interface separates **what a surface is** from **how it is drawn**. A *presentation style* owns appearance
and arrangement, and nothing else.

### 7.1 The conformance contract

A style **MUST NOT** change: the keyboard map, shortcut suppression, Escape unwinding, the Return law, the
focus order law, the outcome model, the note matrix, availability rules, the cooldown, the caller surface, or
any user-visible string except those listed as style-specific in §7.2.

A style **MUST** supply, for each surface it defines: the arrangement, the palette, and its own per-surface
minimum sizes.

A style **MAY** define only some surfaces. **Any surface a style does not define falls back to the default
style's arrangement *and* its metrics.** This is a deliberate contract, not an omission — someone running a
partial style will see the undefined surfaces in the default arrangement, visibly unlike the rest of that
session.

Selecting a style installs that style's preferred palette automatically, but an **explicitly requested palette
always wins**, because the palette is resolved after the style.

### 7.2 What a style may legitimately change

Beyond pure appearance, a style may vary these, and they are the only copy it may touch:

| Element | Notes |
|---|---|
| **A type label naming the surface kind** | A style may show one or omit it. Where shown, the strings are `CONFIRM` · `INPUT` · `SECRET` · `PICK` · `PICK-MULTI` · `NOTIFY` · `PREVIEW` · `FORM <NN>/<NN>` (both numbers zero-padded). |
| **An ordinal beside each option** | Zero-padded to two digits. **Decorative only** — not a click target, and **no digit key selects an option.** |
| **A selection status line** | `select one` on a single-select list (it never changes) · `select any` on a multi-select list while nothing is chosen · `<N> selected` once at least one is, counting checked options plus the "Other" row when selected. Updates live on every toggle. |
| **The form's progress form** | Segmented or continuous; with or without a separate `<N> of <M>` counter. The `Step <N> of <M>` accessibility label is **not** optional. |
| **Text-field placeholders** | A style may add one where the default style has none. Note that fallbacks differ between styles and are **different strings** — `Type your answer…` (one ellipsis character) versus `Enter your answer...` (three periods). |
| **Transient-popup identity** | However it is expressed, a **preview MUST NOT read as an alert** (§5.6). |

**Shared controls are one element across all styles.** The option row, the "Other" row, the action controls and
the text field have one anatomy and one state model everywhere. A style changes their appearance, their minimum
size and the space around them — **never their internal structure or behaviour.**

The keyboard hint strip's **contents** are style-independent (§3.10).

---

## 8. Copy inventory

Every user-visible string. Exact, including punctuation and ellipsis style.

### 8.1 Shared

| Where | String |
|---|---|
| Report control | `Report` |
| Report tooltip | `Report a bug or suggestion` |
| Tool strip | `Snooze` · `Feedback` · `Ask differently` |
| Snooze prompt | `Ask me again in:` |
| Snooze durations | `1m` · `5m` · `15m` · `30m` · `1h` |
| Ask-differently menu | `Confirmation` · `Single Select` · `Multi Select` · `Text Input` · `Password` · `Wizard Form` |
| Note pane captions | `NOTE ON THIS DIALOG` · `NOTE ON THIS FORM` · `NOTE ON THIS QUESTION` |
| Note subject fallback | `(this question)` |
| Note editor label | `YOUR NOTE` |
| Note pane actions | `Clear` · `Close` |
| Note pane tooltips | `Close pane (Esc)` · `Close pane (note is preserved)` |
| Per-question note tooltips | `Add a note for the agent` · `Edit note` |
| "Other" row | `Other` · placeholder `Type your answer...` |
| Form text placeholder default | `Enter your answer...` |

### 8.2 Per surface

| Surface | Strings |
|---|---|
| **Confirm** | Title `Confirmation` · actions `No` / `Yes` · hints `⏎ confirm`, `Esc cancel` |
| **Pick** | Actions `Cancel` / `Done` · hints `↑↓ navigate`, `Space select`, `⏎ done` · a11y `Select one option. Use arrow keys to navigate, Space to select.` / `Select one or more options. Use arrow keys to navigate, Space to select.` |
| **Text** | Title `Input` · actions `Cancel` / `Submit` · hints `⏎ submit`, `Esc cancel` |
| **Form** | Actions `Cancel` / `Back` / `Next` / `Done` · counter `<N> of <M>` · hints `↑↓ navigate`, `Space select`, `⏎ next` / `⏎ done` · a11y `Step <N> of <M>`, `<P> percent complete` |
| **Notify** | Title `Notice` |
| **Preview** | Title `Response Preview` |
| **Value tweak** | `Framework detected: <name>` · `Replay animations` · tooltip `Trigger animation replay after changes (requires browser hook)` · `Show edits` · tooltip `Toggle debug console` · `File changed externally` · tooltip `Slider settings` · `Min` · `Max` · tooltip `Reset to original value` · `Move a slider to see changes` · actions `Revert All` / `Tell Agent` / `Save to File` / `Cancel` · hints `↑↓ navigate`, `←→ adjust`, `⏎ save` / `⏎ cancel`, `Esc cancel` |
| **Report flow** | `Report Issue` · `Describe the problem below.` · `What happened?` · `Briefly describe the issue...` · `⏎ next` · `Cancel` · `Next →` · `Save Screenshot?` · `Can we save a screenshot of this dialog to your clipboard? You can paste it directly into the GitHub issue with ⌘V.` · `⏎ copy & open` · `Skip` · `Yes, Copy Screenshot` |
| **Sketch** | Title `Layout Sketch` · `Add` · tooltips `Undo (⌘Z)`, `Redo (⌘⇧Z)` · `Stash` · `Drop here` · `Drop to stash` · `Add Block` · `Block label` · `Cancel` / `Add` · `Duplicate` / `Delete` · rename placeholder `Label` · live indications `x: <column>, y: <row>` and `<width>×<height>` · footer `Drag to move · Resize from corner · Double-click to rename` and `⌘Z Undo · ⌘⇧Z Redo · ⌘D Duplicate · ⌫ Delete` · actions `Cancel` / `Accept` · frame chrome `https://` and `9:41` |
| **Style-specific** | Type labels `CONFIRM` / `INPUT` / `SECRET` / `PICK` / `PICK-MULTI` / `NOTIFY` / `PREVIEW` / `FORM <NN>/<NN>` · status `select one` / `select any` / `<N> selected` · placeholders `Type your answer…` / `••••••••` |

### 8.3 Text the agent receives — never shown on screen

| Situation | Text |
|---|---|
| Quiet period running | `Snooze active. Wait <N> seconds before re-asking.` (+ ` <M> dialogs missed so far.` when applicable) |
| Snooze chosen in-surface | `Set a timer for <N> minute(s) and re-ask this question when it fires.` |
| Away mode | `The user has enabled Away (AFK) mode in Consult User MCP, so no dialog will be shown. Proceed autonomously with a reasonable default and note the open question in your final response. Do not fall back to other interactive question tools.` |
| Snoozed (humanised) | `The user snoozed. Wait <N> seconds, then retry the exact same question.` |
| Cancelled (humanised) | `The user cancelled. Proceed with a reasonable default.` |
| Note (humanised) | `The user added a note: "<note>".` |
| Form answered (humanised) | `The user answered: <id>: <value>, … (<completed>/<total> completed)` and `Notes by question: <id>: "<note>", …` |
| Re-ask requested | `The user wants this question re-asked as a step-by-step wizard (type: form).` and equivalents for the other five shapes |
| Layout session busy | `An interactive layout session is already running. Complete or cancel it first.` |
| No desktop session | `Interactive layout editor requires a desktop environment (unavailable over SSH/CI).` |
| Rejected option phrasing | `Do not include "<option>" style options. If the user should be able to select multiple answers, set multi: true instead.` |

### 8.4 Demonstration state

A demonstration mode opens the note pane, or the snooze tray, automatically a short moment after a surface
appears, with the surface already sized for it. This is a **real presentation state a rebuild must support** — a
surface that opens with a pane already expanded — not merely a test hook.

---

## 9. Functional timings and limits

These change what happens, not how anything looks.

| Value | What |
|---|---|
| **2.0s** | Opening cooldown. Adjustable from 0.1s to 3.0s in 0.1s increments, or off entirely. |
| **4.0s** | Notification and response-preview lifetime. Fixed; not pausable, extendable or cancellable except by Escape. |
| **10 minutes** | A request with no answer is abandoned. |
| **~150ms** | How long after the person stops moving a tweak value before it reaches the file. Per value, independent. |
| **~0.10s** | Focus lands after a surface appears, or after the report flow closes. Deliberately not instant. |
| **~0.15s** | Focus lands after a form step advances. |
| **~0.30s** | Demonstration mode auto-reveals a pane or tray. |
| **50** | Sketch editor undo history depth. The oldest step is discarded silently. |
| **1, 5, 15, 30, 60 minutes** | The offered snooze durations. |
| **72 characters** | How much of a report description becomes the issue title. |
| **2 lines** | Context shown either side of an edited line in the tweak console. |

Content limits are in §6. Structural limits: 2–20 options on a pick; 1–10 form questions with 2–10 options
each; 1–20 tweak parameters; a 3–20 by 3–20 sketch grid.

---

## 10. Known defects and open decisions

Places where the current behaviour is contradictory, incomplete, or surprising. A rebuild must decide each one
deliberately. Recommendations are recommendations, not requirements.

**10.2 — Confirm and Text cannot scroll.** Both lack a scroll region, so a body past the height cap is clipped
rather than reachable. *Recommend:* give both the same internal scroll region as the other surfaces, keeping
the header, tool strip and footer pinned.

**10.3 — Notifications render no formatting.** The one surface where a link would be most useful, and where the
person has four seconds to act on it, renders links as literal text. *Recommend:* apply the same inline
formatting as every other surface.

**10.4 — The hint strip lies.** It advertises `F feedback` on a text surface where `F` types a letter, shows
all three tool hints while a caret sits in any field, and stays at full strength during the cooldown when six
keys are inert. The documented workaround — the modifier chord — appears nowhere on screen. *Recommend:* make
the strip reflect live availability. A suppressed hint MUST be visibly de-emphasised; during the cooldown every
hint is; and while a caret is in any field the feedback hint MUST **swap to the modifier chord**, so the
working shortcut is always the one displayed.

**10.5 — Concurrency and multi-display are unspecified.** Nothing describes two notifications arriving at once,
so they occupy the same place and the first is invisible. And every surface is placed on one primary display
regardless of where the person is working, with no rule for a remembered position on a display that is gone.
*Recommend:* notifications **queue** — a second waits for the first to close, then appears in the same place
with its own lifetime — but never queue behind an interactive surface. Place every surface on the display that
currently contains the pointer, and discard a remembered position that falls entirely outside every attached
display.

**10.6 — The sketch editor has no project badge.** Every other surface shows one. *Recommend:* add it.

**10.7 — Snooze durations are pointer-only.** The tray opens with a key and then cannot be operated with one.
*Recommend:* put the durations in the Tab ring while the tray is expanded, let arrow keys move between them and
Space or Return pick, and return focus to the Snooze control on collapse.

**10.8 — The destructive action variant is unreachable.** It exists but no caller can request it, so a
destructive confirmation is indistinguishable from a harmless one. *Recommend:* expose it as a confirm option.

**10.9 — The "Other" row behaves inconsistently.** It uses a weaker selected treatment than ordinary rows and
has no hover or pressed feedback. *Recommend:* unify it with the ordinary row; its inner field keeps its own
focus treatment layered on top.

**10.10 — The report control behaves three ways.** Two-step flow on interactive surfaces; immediate browser on
the transient popups; immediate browser with a different pre-fill in the sketch editor. Nothing distinguishes
them. *Recommend:* keep the divergence — a four-second popup genuinely cannot host a two-step flow — but make
it predictable with a distinct tooltip, `Report a bug (opens in browser)`.

**10.11 — Snooze and ask-differently silently destroy typed work.** Both discard the answer *and* any drafted
note with no warning. *Recommend:* when a non-empty draft exists, confirm first — `Discard your note?` with
`Keep editing` and `Discard and snooze` / `Discard and re-ask`.

**10.12 — Multi-select has no counter and no bounds.** No indication of how many are chosen, no select-all or
clear-all, no way for a caller to require a minimum or maximum. *Recommend:* adopt the status line from §7.2
into the default style, and add caller-side bounds with the disabled control explained per 10.14.

**10.13 — Masked input cannot be verified.** No reveal control, no caps-lock warning. Someone who mistypes a
long secret finds out later. *Recommend:* add a reveal control that toggles the mask on press and reverts when
the surface loses focus.

**10.14 — A disabled primary control never explains itself.** On the pick surface and every form step it is
dead, Return does nothing, and forward navigation is blocked with no message anywhere in the product.
*Recommend:* one line of helper text near the answer region — `Select an option to continue` · `Select at least
one option to continue` · `Type an answer to continue` · `Type your custom answer to continue`. It appears
**only after the person's first interaction with the region**, never on open, so a freshly opened surface is
not pre-scolded.

**10.15 — The response preview defeats itself.** A fixed lifetime with no countdown, no pause, no scroll
indication, and no early dismissal except Escape. *Recommend:* pause while the pointer is over it; show
remaining time; let a click anywhere on the body close it.

**10.16 — The tweak surface ignores `title`.** The option is accepted and has no effect. *Recommend:* wire it,
or drop it from the caller surface.

**10.17 — Cancelling the tweak surface leaves every write on disk.** Escape, Cancel, snooze and ask-differently
all close without reverting the writes made during the session. This is the single most surprising behaviour in
the product. *Recommend:* Escape and Cancel revert every write before closing, matching the near-universal
mental model that cancelling undoes; snooze and ask-differently do the same; only `Save to File` leaves them.
Additionally add a **per-card changed marker** whenever a value differs from where it opened, and a **written
indicator** distinguishing pending from landed.

**10.18 — Three input methods clamp and snap differently.** Dragging snaps to the step and clamps to the
widened range; arrow keys snap but clamp to the *caller's* range; typed entry clamps to the widened range but
does **not** snap. The same card can hold a value the arrow keys cannot reach. *Recommend:* one rule for all
three — clamp to the card's current working range, then snap to the nearest step. The per-card range override
replaces the caller's bounds for every input method for the rest of the session.

**10.20 — Block promotion is undiscoverable.** Holding a modifier reaches buried blocks, but it is in no hint
line, has no tooltip, and nothing indicates that more blocks lie underneath. *Recommend:* add it to the footer
hints and indicate the stack when the pointer sits over two or more blocks.

**10.21 — Alignment guides are stale during the drag.** They reflect the block's committed edges, so they never
update while it moves — a "where you used to be aligned" indicator shown during the one gesture where that is
least useful. *Recommend:* evaluate them against the live snapped destination every frame, keeping
exact-equality matching, and draw each matching guide once regardless of how many neighbours match.

**10.22 — The sketch footer advertises two shortcuts that do not exist.** `⌘D Duplicate` and `⌫ Delete` are in
the hint line but only reachable from the context menu. *Recommend:* bind both, matching the menu actions
exactly and both undoable. If they cannot be bound, remove them from the hint line — never advertise a shortcut
that does nothing.

**10.23 — The sketch canvas has no selection model and no keyboard access.** No click-to-select, no selected
state, no multi-select, no way to act on several blocks at once — and no way to reach, move, resize, rename or
delete a block without a pointer. *Recommend:* decide selection deliberately rather than by omission, and give
the canvas focus and arrow-key movement at minimum.

**10.24 — The exported image does not reproduce the canvas.** Different proportions (the export does not keep
cells square), inverted treatment, labels instead of numbers, and a legend outside the stated bounds. The
artifact does not look like what the person approved. *Recommend:* derive the export the same way the canvas
does, show both the number and the label, and size the image to include the full legend.

**10.25 — The documented client-name prefix is not rendered.** The caller contract says the client name is
prefixed to titles; it is not — it only ever appears as a fallback when no title is supplied. *Recommend:*
correct the contract to match the behaviour.

**10.26 — The focus indicator is delegated and undefined.** Focus is the only thing distinguishing "this
control will react to Space or Return" from "this control is idle", and it is currently drawn entirely by the
host system, with nothing specified. On any other platform nothing would be drawn — and focused-but-unselected
option rows rely on it completely. *Recommend:* define it as a product requirement: visible against every
surface state in every palette, never replacing or suppressing the selected treatment, and drawn so a row can
read as focused-and-selected simultaneously.

**10.29 — Timeout is invisible.** A request is abandoned after ten minutes with no countdown, no warning, and
no stated behaviour at the moment it expires — including what happens to in-flight file writes in the tweak
surface. *Recommend:* decide the expiry behaviour explicitly and, at minimum, warn near the end.

**10.30 — Two divergent implementations of the pick surface exist.** One shows no selection indicators at all
(selection carried by the row's own treatment alone), has no tool strip, no note pane and no ask-differently
control, caps its list at a fixed height, and shows one hint line reading `↑↓ navigate • Space select • Enter
done` or `↑↓ navigate • Enter confirm`. *Recommend:* pick one canonical behaviour — the one specified in §5.2 —
and bring the other to it.

---

### Not carried over from the full specification

These entries in `UI-SPECIFICATION.md` are purely visual and have no behavioural content, so they are out of
scope here: **10.1** (no light palette), **10.19** (an element ignoring the palette), **10.27** (right-to-left
mirroring), **10.28** (text zoom and dynamic type). They still need deciding — they simply belong to the
document that has colours in it.
