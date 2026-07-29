# Consult User MCP — Behavioural Specification

**This document is self-sufficient.** It describes what the product does, what the person can do, and what the
calling agent gets back. It is the complete brief for building a presentation style from nothing. It does not
describe, reference, or imply any existing implementation.

---

## 0. What this is

### 0.1 The three tiers

Every requirement in this document carries one of three weights. **Read the tier before you read the
requirement** — it decides whether you are being told an answer or asked for one.

| Tier | Means | If you change it |
|---|---|---|
| **LAW** | An invariant. It is what makes this product this product. | You have built something else. |
| **CAPABILITY** | The person must be able to do this thing. **How it is presented is yours to decide.** | You have broken the product. |
| **DEFAULT** | One workable answer, supplied so you are never blocked. | Nothing. Replace it freely. |

Unmarked prose is context — the reasoning behind a nearby requirement. It binds nothing.

**LAW is deliberately narrow.** It covers what a key does, what comes back, what is refused, and what the
calling agent is told. It covers almost nothing you can see. If a rule is not marked LAW, you may satisfy it
any way you like.

### 0.2 What this document does not specify

Not as an omission — as a decision. These are yours:

- **Colour, type, dimension, spacing, weight, opacity, border, shadow, motion.** Nothing here constrains them.
- **Arrangement.** Nothing here says which region sits where, what is aligned to what, or how wide anything is.
- **Decomposition.** Nothing here says what is a discrete element and what is not. Where this document names
  two things separately, that is because they have two different jobs — not because they must be drawn as two
  things, in that order, in that relationship. Merge them, split them, or invent a third thing that does both.
- **Grouping.** Nothing here says which capabilities are collected together, or whether they are collected at
  all. Three capabilities described in three subsections may be one control, one gesture, one menu, or three
  separate elements in three different places.
- **Idiom.** Nothing here says a choice is a list, an action is a button, a note is a panel, a hint is a line
  of text, or progress is a bar. Those are all one answer each, and none of them is required.
- **Persistence of an element.** Where this document says a capability must be *reachable*, that is not the
  same as *visible at all times*. Revealed on demand, on hover, on a key, on focus, or through a mode are all
  valid, provided the person can discover it (§3.8).

### 0.3 How to read this if you are designing a style

The failure mode this document is written to prevent is **transcription**: reading a list of capabilities as a
parts list and assembling them top to bottom in the order they appear here.

Section order here is explanatory. It is not visual order, focus order, or importance order. Focus order is
specified once and only once, in §4.5, and it is derived from *your* arrangement — not from this document's.

Two checks before you commit to a design:

1. **The scramble test.** If this document's section numbering were shuffled, would your design change? If yes,
   you have transcribed the document rather than designed from it.
2. **The residue test.** Name three things your design does that this document does not mention. If you cannot,
   you have not designed anything — you have compiled.

A style that ends up as a title above a body above a list above two buttons is not wrong. But it should be the
answer to a question you asked, not the shape of this file.

### 0.4 Conformance language

| Word | Meaning |
|---|---|
| **MUST** | Required at the stated tier. |
| **SHOULD** | Strongly expected. Deviating needs a reason you can state. |
| **MAY** | Genuinely optional. |
| ⚠️ | A known defect or open decision. §10 carries the full list; each needs deciding, not inheriting. |

### 0.5 Two audiences

- **The person** — the human being interrupted. §1–§5 are about them.
- **The calling agent** — the AI assistant that requested the interruption. §6 is the surface it drives, and
  §8.2 is the text it receives. That text is never shown on screen and is **LAW** in full: it is a contract
  with software, not copy.

---

## 1. What the interface is

An AI assistant working on the person's behalf sometimes needs a decision, a secret, a preference, or a
judgement call it cannot make alone. This interface is the channel for that: something appears over whatever
the person is doing, asks exactly one thing, and gets out of the way.

Every requirement below follows from one tension:

> **The interruption must be cheap to answer and cheap to refuse.**

- It appears predictably, so locating it costs nothing.
- It is entirely keyboard-driven, so answering never requires the pointer.
- It opens inert, so a keystroke already in flight cannot answer it by accident.
- It offers three exits that are neither "answer" nor "cancel" — postpone it, annotate it, or reject the
  *shape* of the question — so the person is never forced to choose between a bad answer and no answer.

Those four sentences are the product. Everything after this is detail in service of them.

### 1.1 The eight surfaces

**LAW** — these eight exist, and each asks for what it says here.

| # | Surface | Asks for | Blocks the agent |
|---|---|---|---|
| 1 | **Confirm** | A yes or a no | Yes |
| 2 | **Pick** | One option from a set, or several | Yes |
| 3 | **Text** | A typed answer, optionally masked | Yes |
| 4 | **Form** | Several questions, one at a time | Yes |
| 5 | **Notify** | Nothing — it announces | No |
| 6 | **Response preview** | Nothing — it shows what is about to be sent | No |
| 7 | **Value tweak** | Numbers, tuned live against real files | Yes |
| 8 | **Layout sketch** | A screen layout, dragged into shape | Yes |

Surfaces 1–4 and 7 are **interactive**: one keyboard model, one outcome model, the three exits. Surfaces 5–6
are **transient**: no controls, self-dismissing. Surface 8 is a **workspace**: resizable, with undo.

**CAPABILITY** — before acting, the person must be able to tell **which kind of thing they are looking at**. In
particular: a **masked** text surface MUST be tellable from a plain one *before* they type, and a
**multi-select** set MUST be tellable from a single-select one *before* they choose. Getting either wrong costs
them real work.

*How you signal it is unspecified.* A label, a shape, a colour, a different arrangement entirely, an icon, the
absence of something — all valid. It need not be the same mechanism for both, and it need not be a distinct
element.

### 1.2 The interruption contract

**LAW** — an interactive surface is shown only when all three hold:

1. No quiet period ("snooze") is running.
2. Away mode is off.
3. No other interactive surface is already on screen.

If any fails, **nothing is drawn** and the agent is told what to do instead (§4.7). Notifications are exempt
from 1 and 2, and MAY appear on top of an open interactive surface.

---

## 2. The window model

### 2.1 The surface is its own frame

**LAW** — every surface provides its own frame: no host-system title bar, no close or minimise controls, and —
for everything except the layout sketch editor — no resize handle. The person cannot resize an interactive
surface.

Consequence worth stating: there is no borrowed chrome to lean on. Whatever tells the person this thing is
closable, movable, or theirs to dismiss, you are drawing.

### 2.2 The sizing law

**LAW.** The most consequential structural rule in the product.

> **A surface is measured once, when it appears. Its width is then fixed for the rest of its life. Only its
> height reflows.**

The reason is directly observable: if width were recomputed from wrapped text, text would rewrap, which would
change the measured width, which would rewrap the text. It would oscillate. So it does not.

- On appearance the surface is exactly as wide as its content needs, floored at a minimum you choose per
  surface and capped so it always fits the screen; and exactly as tall as that content is once wrapped to that
  width, floored at a minimum you choose and capped at a fraction of the usable screen height.
- Height reflows freely whenever content changes.
- Width changes for exactly one reason: **something attaching or detaching beside the surface** — see §3.6 —
  and then by exactly that thing's fixed extent. If your style never attaches anything beside the surface,
  width never changes at all.
- **The same request MUST always produce the same size.** Nothing about the dimensions may depend on what was
  shown before, or on the order in which content settles.
- Sub-unit changes are ignored. The surface does not twitch or re-anchor for them.

**DEFAULT** — the height cap for the two transient surfaces is noticeably lower than for interactive ones. They
are meant to be glanced at, not read.

*Practical warning, not a requirement:* anything you attach with a flexible extent will make the measured width
vary run to run, which violates the fourth rule above. Give attachable things a deterministic extent.

### 2.3 Overflow

**LAW** — when content exceeds the height cap the surface stops growing, and the content the person is working
*in* scrolls internally rather than being clipped.

| Surface | What must stay reachable when it overflows |
|---|---|
| Pick | Every option |
| Form | The current question and its answer control |
| Value tweak | Every parameter |
| Notify | The whole message |
| Response preview | The whole body |
| Confirm | ⚠️ currently clipped — see §10.2 |
| Text | ⚠️ currently clipped — see §10.2 |

**CAPABILITY** — while that content scrolls, the person MUST still be able to identify the question, reach the
tools (§3.5–§3.7) and reach the actions (§3.9). *Whether that means pinning regions, a scrolling container
inside a fixed frame, an overlay, or something else is unspecified.*

### 2.4 Anchoring

**LAW** — a surface is placed once, on appearance, against one of three horizontal anchors — **left**,
**centre** or **right** — offset from the top of the usable screen area. The offset is yours.

**LAW** — under any resize the **top edge is fixed**: the surface grows and shrinks downward. Horizontally, a
left-anchored surface keeps its left edge, a right-anchored surface its right edge, a centred surface its
centre.

**LAW** — if your style attaches anything beside the surface (§3.6), it opens **away from the wall the surface
is against**:

| Anchor | Attaches on |
|---|---|
| Left | Right |
| Right | Left |
| Centre | Whichever side has more room |
| Indeterminate | Right |

**LAW** — the two transient surfaces read the person's saved anchor preference only. A per-call anchor is
accepted by the caller contract and never applied to them.

⚠️ Multi-display behaviour is unspecified — §10.5.

### 2.5 Moving

**LAW:**

- Pressing and dragging the surface's **inert area** moves it; it stays where it is dropped.
- Pressing **anything interactive** activates that thing and **never** moves the surface.
- Clicking an inactive surface brings it forward and gives it keyboard focus first, *then* delivers the click.

*Which areas are inert is a consequence of your arrangement, not a specification. The rule is that the two sets
never overlap: nothing is both a drag handle and a control.*

### 2.6 Stacking

**LAW:**

- Interactive surfaces float above other applications by default, following a person-level preference. When it
  is off they behave as ordinary windows.
- Notifications float **unconditionally** and appear **without stealing keyboard focus**.
- Anything the value-tweak surface shows outside its own frame (§5.7) shares that surface's stacking level
  exactly and follows it when it moves or resizes.

---

## 3. What every interactive surface must let the person do

**This section is a list of capabilities, not a list of components.**

Each entry states a thing the person must be able to accomplish and the rules that govern it once they do.
None of them states what to draw. Two entries may be one element. One entry may be three. An entry may have no
persistent representation at all as long as it is discoverable (§3.8).

Where an entry lists **DEFAULT** copy, that copy is a starting vocabulary — see §8.1.

### 3.1 Report a problem

**CAPABILITY** — from **every** surface, including read-only ones, the person can report that something is
wrong **without answering the question first**. A surface too broken to answer is exactly when this matters.

**DEFAULT** — labelled `Report`, described as `Report a bug or suggestion`.

The flow it starts is §3.12. Its behaviour differs by surface — see the table there.

### 3.2 Know which project this is about

**CAPABILITY** — when the caller supplies a project path, the person can tell which project the question
concerns; the **full** path is available to them somehow; and when no path is supplied, **nothing about the
project is shown at all** rather than a placeholder or an empty slot.

**DEFAULT** — show the final path segment, with the full path on hover.

⚠️ The layout sketch editor currently shows no project identity at all (§10.6).

### 3.3 Read the question

**LAW** — every surface carries a title, and most carry a body.

- **Title** wraps to as many lines as needed and never truncates — except on the two transient surfaces, where
  it is clamped and truncated.
- **Body** MUST be selectable and copyable.

**LAW — the presentation-switch rule.** A body with no line break and a body containing one MUST be presented
**differently**. The trigger is the presence of a line break, **not** the length. A one-line question is a
headline; multi-paragraph or list-like text is a passage. This applies to every surface's body.

*How the two differ is entirely yours — size, weight, measure, alignment, spacing, structure, or something with
no typographic component at all. The requirement is that the person can tell a statement from a passage before
reading it.*

### 3.4 Inline text formatting

**LAW** — agent-supplied prose supports exactly this set. **Markers are consumed and never shown literally.**

| Written as | Renders as |
|---|---|
| `**bold**` | Bold |
| `*italic*` | Italic (single asterisks not adjacent to another asterisk) |
| `` `code` `` | A distinct code treatment |
| `[label](url)` | Clickable text showing only the label; opens in the default browser |

**LAW** — everything else renders literally. Block-level formatting is **not** interpreted: headings, bullet
lists, block quotes, fenced blocks and tables appear as raw characters. A malformed link stays literal.
Formats are applied in the order links → bold → italic → code.

**LAW** — escaped newline and tab sequences in incoming text are converted to real ones before display. A body
written with escaped newlines therefore trips §3.3's presentation switch and is presented as prose.

**Applies to:** the body of every interactive surface, the form's question text, and the quoted subject of an
annotation. **Does not apply to:** ⚠️ the notification and response-preview bodies (§10.3).

*What "a distinct code treatment" looks like is unspecified.*

### 3.5 Postpone the question

**CAPABILITY** — the person can decline to deal with this *now* without answering and without cancelling, by
choosing how long to be left alone.

**LAW** — choosing a duration closes the surface immediately and starts a **global** quiet period of that
length (§4.7). Any typed answer and any drafted annotation are discarded (§4.8). ⚠️ §10.11.

**DEFAULT** — five durations, offered as `1m` · `5m` · `15m` · `30m` · `1h`, under the prompt `Ask me again
in:`. The set of durations is DEFAULT; that it is a small fixed set is CAPABILITY.

**LAW** — every offered duration MUST be reachable by keyboard. ⚠️ Currently some are not (§10.7).

### 3.6 Annotate the question

**CAPABILITY** — the person can write free text that travels back to the agent **alongside** whatever else
happens. This is the single most important of the three exits: it is how someone says "wrong question" without
having to say "no".

**LAW — an annotation is never a redirect.** It never replaces an answer. See the note matrix in §4.8 for
exactly which outcomes carry it.

**LAW — annotation targets.** There are three, and each carries a different subject:

| Opened from | Annotates | Subject shown |
|---|---|---|
| A single-question surface | That question | **No** — the question is already in front of them |
| A form, at form level | The whole form | The form's intro text; **omitted if there is none** |
| A form, at question level | That question | **Always** — that question's own text, falling back to `(this question)` |

**LAW — editing behaviour:**

- The editor **holds the caret from the first frame it begins to appear**, so a key pressed while it is still
  arriving is typed into the annotation rather than treated as a shortcut.
- Clearing the draft is possible, and is **unavailable while the draft is empty**.
- Dismissing it by any route — a close action, Escape, or re-triggering the same target — **preserves the
  draft**. Returning restores it and re-focuses the editor.
- Triggering a **different** target while it is open **swaps its contents** rather than dismissing it.
- A **whitespace-only draft counts as empty everywhere**: nothing is delivered, clearing stays unavailable, and
  §3.7's has-annotation signal stays in its empty state.
- The editor supports undo and accepts newlines (§4.2's Return exception).

**CAPABILITY — the person must be able to tell, without opening it, that an annotation exists.** This is the
only signal that unsent work is pending.

**DEFAULT** — captions `NOTE ON THIS DIALOG` · `NOTE ON THIS FORM` · `NOTE ON THIS QUESTION`, editor labelled
`YOUR NOTE`, actions `Clear` and `Close`.

*Whether this is a panel beside the surface, an overlay, a sheet, an expansion, a mode, or a second window is
unspecified.* If it attaches beside the surface, §2.2 and §2.4 apply: fixed extent, opening away from the
anchored wall. If it does not, neither applies.

### 3.7 Reject the shape of the question

**CAPABILITY** — the person can tell the agent *"this is the wrong kind of question"* and name the kind they
want instead, without answering.

**LAW** — six shapes, in this order:

`Confirmation` · `Single Select` · `Multi Select` · `Text Input` · `Password` · `Wizard Form`

**LAW** — the shape currently on screen is **marked as current and unavailable**, so there is always exactly
one such entry and the person can always tell which shape they are in.

**LAW** — choosing one closes the surface immediately and asks the agent to re-pose the same question in that
shape. Any in-progress answer and any drafted annotation are discarded (§4.8). ⚠️ §10.11.

**LAW** — arrow keys move between entries, Return chooses, Escape dismisses with no effect. Dismissing without
choosing leaves the surface exactly as it was.

### 3.8 Discover what the keyboard does

**CAPABILITY** — the person MUST be able to find out what keys are available **without guessing and without
documentation**. The product is keyboard-first; an undiscoverable shortcut does not exist.

**LAW** — the minimum that must be conveyable, per surface:

| Surface | Must convey |
|---|---|
| Confirm | Return confirms · Escape cancels |
| Pick | Arrows navigate · Space selects · Return completes |
| Text | Return submits · Escape cancels |
| Form | Arrows navigate · Space selects · Return advances (completes on the last step) |
| Value tweak | Arrows navigate · Left/right adjust · Return saves or cancels · Escape cancels |
| Report flow | Return advances (step 1) · Return copies and opens (step 2) |
| All interactive | The three exits of §3.5–§3.7 |

**LAW** — what is conveyed MUST reflect what is **actually available right now**. Advertising a suppressed key
is worse than advertising nothing, because it teaches the person a key that will fail them. ⚠️ This is
currently violated (§10.4) and its resolution is a requirement of any new style, not an option.

Specifically: during the cooldown (§4.6) the affected keys MUST read as unavailable; while a caret sits in any
text field the single-letter shortcuts MUST read as unavailable and the annotation shortcut MUST present as its
modifier chord instead, because that is the one that works.

**DEFAULT** — a persistent line of `key action` pairs. *This is one answer. Contextual reveal, hover, an
overlay on a held modifier, per-control adornment, a legend, or a help mode are all valid, provided the person
can find them without being told they exist.*

### 3.9 Commit, decline, and go back

**CAPABILITY** — every surface offers between one and three ways out, drawn from: **commit** (confirm, submit,
done, next, save, accept), **decline** (cancel, no), and **retreat** (back). Which of these a given surface
offers is stated per surface in §5.

**LAW — four semantic variants exist and MUST be tellable apart:** primary, secondary, destructive, disabled.

**LAW:**

- **In focus order, decline and retreat come before commit.** This determines what Tab reaches first and is
  muscle memory. *Where they sit spatially is yours; focus order is derived from your arrangement per §4.5, so
  if you place them unusually you must still make Tab reach them in this relative order.*
- The commit action MUST indicate that Return activates it — **but only while it is available.** An unavailable
  commit MUST drop that indication, so the affordance never promises a key that will not work.
- An **unavailable action is not focusable and is skipped by Tab.** Never focused-and-inert.
- Activation requires press *and* release on the same target; dragging off cancels it.
- Labels that do not fit are truncated. **An action never grows and the surface never widens to fit a label.**

⚠️ The **destructive** variant exists but no caller can request it, so a "delete 47 files" confirmation is
indistinguishable from a harmless one (§10.8).

### 3.10 Choose from a set

**CAPABILITY** — used by the pick surface and by every choice step of a form. The person can see the available
options, see which are currently chosen, change what is chosen, and — when free text is permitted — supply an
answer that is not on offer.

**LAW — states.** Each option has: default, hover, pressed, **chosen**, **focused**. There is **no unavailable
state** — every offered option is always choosable.

**LAW — chosen and focused are separate channels.** An option can be focused-and-unchosen, chosen-and-unfocused,
or both. **All four combinations MUST be distinguishable.** Focus MUST NOT be signalled by the same channel
choice uses.

⚠️ Focus is the only thing separating "this will react to Space" from "this is idle", and it is currently
delegated to the host system and specified nowhere. **Any new style MUST define it explicitly** (§10.26).

**LAW — single versus multi.**

| Mode | Choosing an option |
|---|---|
| **Single** | Replaces the choice |
| **Multi** | Toggles it independently |

**LAW** — the two modes MUST be distinguishable from each other *before the person chooses anything*. Besides
the surface's own identity cue (§1.1), this is the only thing telling them whether more than one is permitted.
State changes are immediate; there is no draw-in.

**LAW** — the whole option is the target. If your style draws a discrete chosen-marker, that marker is **not**
a separate target.

**LAW — content.** An option presents its label and, when the caller supplies one, its description. Long labels
**wrap rather than truncate**, so an uneven set is expected and correct; options do not shrink to fit short
labels.

⚠️ Option text cannot currently be selected or copied, while surface bodies and form questions can.

#### Free text within a set

**LAW** — unless the caller turns it off, the set also offers **free text**, and it is **always last**.

- **DEFAULT** — labelled `Other`, with the placeholder `Type your answer...`.
- Activating it both chooses it **and** places the caret in its field.
- Typing any character auto-chooses it.
- In single mode, choosing it clears every other choice, and choosing a listed option clears it — **the typed
  text stays visible but is no longer the answer.**
- In multi mode it toggles independently and combines freely.
- **Chosen-but-empty counts as unanswered.**
- The label is **never** returned. Only the typed text is.
- Text is **not trimmed** before being judged non-empty, so a single space counts as an answer.

⚠️ It currently behaves inconsistently with ordinary options (§10.9). It **SHOULD** carry the same state model
as any other option, with its field's own focus treatment layered on top.

### 3.11 Type an answer

**CAPABILITY** — used for text answers, masked answers, free text within a set, and the report description.

**LAW — states:** rest, **focused**, masked, overflowing.

**LAW:**

- Clicking anywhere in the field — not only on the text — places the caret.
- A prefilled value opens **with its text selected**, so the first keystroke replaces it. This is required
  behaviour, not a host-platform accident.
- Long content **scrolls within the field**; the field never grows and the surface never widens.
- Standard cut / copy / paste / select-all are available.
- No length limit is enforced and no trimming is applied on submit.
- A masked field renders substitute characters and MUST NOT reveal the real ones in any state.

⚠️ Masked input cannot be verified — no reveal, no caps-lock warning (§10.13).

### 3.12 The report flow

**LAW — on an interactive surface**, reporting captures a picture of the surface as it currently looks, then
covers it with a **two-step flow**. While the flow is up the surface beneath is inert, and every key except
Escape goes to the flow.

**Step 1 — describe.**
- **DEFAULT** — titled `Report Issue`, body `Describe the problem below.`, field labelled `What happened?` with
  placeholder `Briefly describe the issue...`, actions `Cancel` and `Next →`.
- **LAW** — advancing is **unavailable while the description is empty or whitespace-only**, and Return does
  nothing then. The description is trimmed before use.

**Step 2 — screenshot consent.**
- **DEFAULT** — titled `Save Screenshot?`, body `Can we save a screenshot of this dialog to your clipboard? You
  can paste it directly into the GitHub issue with ⌘V.`, actions `Skip` and `Yes, Copy Screenshot`.
- **LAW** — both are always available.

**LAW** — Escape closes the flow and **only** the flow. The surface underneath is untouched and regains focus.

**LAW — the outcome** is that the default browser opens a pre-filled issue page. **That page is the
confirmation**; there is no in-app success message. Its body carries, in order: a Description section with the
typed text; a section naming the request kind and reproducing it; an Environment section listing the project
and the client; a Screenshot placeholder line if consent was given; and a credit line. The title is the first
72 characters of the description. The issue is pre-labelled as a bug.

**LAW** — if the picture cannot be captured, the flow still completes; only the clipboard copy is skipped.

**LAW — behaviour by surface:**

| Surface | Behaviour |
|---|---|
| Confirm, Pick, Text, Form, Value tweak | Two-step flow, screenshot offered |
| Notify, Response preview | **Opens the issue page immediately** — no flow, no description, no screenshot |
| Layout sketch | **Opens the issue page immediately**, seeded with a `Layout editor: ` title prefix and an Environment section naming the layout editor |

⚠️ Nothing currently distinguishes these three (§10.10).

---

## 4. The interaction model

**This entire section is LAW.** It applies to every interactive surface and it is the reason the product feels
like one thing rather than eight. Nothing here is negotiable by a style.

### 4.1 The complete keyboard map

| Key | Does | Active when |
|---|---|---|
| `Return` | The surface's commit action | Always, unless a rule below overrides |
| `Escape` | Unwinds exactly one layer (§4.3) | Always |
| `Space` | Toggles the focused option, or activates the focused control | Not while a caret is in a text field |
| `↑` / `↓` | Move focus between **content** elements, wrapping at both ends | Not while typing |
| `←` / `→` | Form: previous / next step. Value tweak: decrease / increase the focused value by one step | Not while typing |
| `Tab` / `Shift+Tab` | Cycle focus through **everything**, including actions | Always |
| `S` | Postpone (§3.5) | §4.2 |
| `F` | Annotate (§3.6) | §4.2 |
| `A` | Reject the shape (§3.7) | §4.2 |
| `Modifier+F` | Annotate **regardless of focus** | Always |
| Cut / copy / paste / select-all | Standard editing | In any text field |

Modifier keys are written with the host platform's own glyphs; the binding is the platform's primary modifier
plus the named key.

**Arrow keys never reach the actions.** Those are reachable by Tab alone. This is deliberate — it keeps arrow
navigation inside the answer, where it belongs.

### 4.2 The shortcut suppression law

Plain single-letter shortcuts (`S`, `F`, `A`) are **suppressed** in three situations:

1. While a caret sits in **any** text field, including the annotation editor, and including while that editor
   is still arriving.
2. While the annotation editor is open.
3. During the opening cooldown.

In all three the letter is typed literally. **The modifier-chorded annotation shortcut survives all three** —
it exists precisely because a bare `F` is unreachable on a text surface.

`Return`, `Tab`, the arrow keys and modifier chords always route to the surface. `Return` has one exception:
inside the annotation editor it inserts a newline.

See §3.8: what the person is *told* about these keys must track this law live.

### 4.3 The Escape unwinding law

Escape peels back **exactly one layer per press**, in this fixed order. It never skips a layer and never closes
two at once.

```
1. Report flow open?          → close the flow                 (the surface is untouched)
2. Annotation editor open?    → close it                       (the draft is preserved)
3. Postpone options open?     → collapse them                  (nothing is postponed)
4. otherwise                  → cancel the surface
```

If your style presents any of layers 1–3 in a way that has no separate open/closed state, that layer simply
does not participate — but the relative order of the ones that remain MUST hold.

### 4.4 The Return law

Return first attempts the surface's **commit action**. If commit is unavailable because the answer is
incomplete, the key **falls through to the focused control** — so a focused retreat action activates and a
focused text field receives it. When nothing is focused, the key is consumed and nothing happens.

### 4.5 The focus order law

- Focus order follows **reading order** of *your* arrangement: top to bottom, and left to right within a row.
  It wraps.
- It follows **presented** order, not creation order. Things that appear or disappear join or leave the ring in
  their presented position.
- **Unavailable controls are skipped entirely.**
- On appearance, focus lands on the **first content element — never an action**. The same after a form step
  advances, and after the report flow closes. It lands shortly after, not instantly (§9).
- **The confirm surface registers no content elements**, so nothing is focused on open and no focus indicator
  is visible until the person presses Tab. `↑`/`↓` do nothing there. Return still confirms, because commit is
  bound at the surface level rather than to a focused control.

  This is deliberate: focusing the confirm action on open would let a stray Space answer the question the
  instant the cooldown ends.

§3.9's relative ordering constraint — decline and retreat before commit — is a constraint on this ring, and
therefore a constraint on your arrangement.

### 4.6 The opening cooldown

For a short period after an interactive surface appears (§9):

- Every action renders in a **damped, clearly-not-yet-ready state**, with a **visible indication of how much
  time remains**.
- Clicks are swallowed. `Return`, `Escape`, `Space`, `S`, `F` and `A` all do nothing.
- **Typing is never blocked.**

Escape is blocked at two independent levels during the cooldown, so it is inert even when the report flow is
open. Nothing indicates the block beyond the damped actions and the remaining-time indication.

The cooldown is adjustable and can be switched off entirely. When off, actions are live immediately and no
remaining-time indication is drawn.

**Transient surfaces never trigger a cooldown**, so Escape works on them from the first frame.

The purpose is narrow and worth stating: a surface appears over whatever the person was doing, and a keystroke
already in flight must not be able to answer it.

*The form of the damping and of the remaining-time indication is yours. That both exist is not.*

### 4.7 Availability

**Quiet period (postpone).** Global, not per surface. While one runs:

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
quiet period  >  re-ask request  >  annotation  >  cancellation  >  answer
```

**The annotation matrix** — which outcomes carry a drafted annotation:

| Outcome | Annotation | Reported as |
|---|---|---|
| Answer | **delivered alongside** | An answer, annotated |
| Decline / cancel **with** an annotation | **delivered** | A **redirection**, not a cancel — the agent reads it, adjusts, and continues |
| Decline / cancel **without** one | — | A plain cancel; the agent proceeds with a sensible default |
| Postpone | **discarded** | Duration and remaining wait only |
| Reject the shape | **discarded** | The requested shape only |
| Timeout | discarded | Nothing |

An annotation is **never a redirect**. It never replaces an answer, and dismissing the editor never discards
it. Whitespace-only annotations count as empty everywhere.

⚠️ Postpone and reject-the-shape silently throw away typed work (§10.11).

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
asking client, a summary of the question, and the answer (multiple choices joined with `, `). Suppressed
requests never do. A multi-question entry is summarised by its first question, with the answers on one line as
`key: value; key: value`.

---

## 5. The surfaces

Each entry states what the surface asks, what must be true of it, what comes back, and where it is currently
broken. **Where an entry names an action or a title, that is DEFAULT copy** (§8.1) — the requirement is that
the person can commit, decline, or retreat as listed in §3.9.

### 5.1 Confirm

> One yes-or-no question. The simplest surface, and the only one with no invalid state.

**DEFAULT title:** `Confirmation`. **Body:** the question, per §3.3.

**Ways out:** exactly two — decline (secondary) then commit (primary). **DEFAULT** labels `No` and `Yes`; both
are caller-supplied and frequently overridden, so neither is a fixed string you can design around.

**LAW:**

- Commit is **never unavailable**; Return always confirms once the cooldown has elapsed.
- Confirming reports *yes*. Declining reports *no* — and, with an annotation drafted, that annotation travels
  with it, making it a redirection rather than a cancel (§4.8).
- Nothing is focused on open (§4.5).

**Edge cases:**

- Over-long action labels truncate; the action does not grow and the surface does not widen.
- ⚠️ A very long title has no truncation rule and there is no scroll region, so it can push the actions past
  the height cap (§10.2).
- A raw URL or file path renders as-is and is not clickable — only bracketed links are (§3.4).

---

### 5.2 Pick

> One option from a set, or several. 2–20 options.

**DEFAULT title:** the calling client's name. **Body:** the question, per §3.3.

**Content:** the options of §3.10, in the order supplied, with free text **always last** when present. This is
the region that must survive overflow (§2.3).

**Ways out:** decline and commit. **DEFAULT** labels `Cancel` and `Done`.

**LAW — validity:**

- Nothing chosen → commit is **unavailable**, drops its Return indication, and Return does nothing.
- Free text chosen but empty → counts as nothing chosen.
- A preselected default opens **already chosen, with focus on it**, so commit is live on the first frame.

**LAW — semantics:**

| | Single | Multi |
|---|---|---|
| Choosing a listed option | Replaces the choice; clears free text | Toggles independently; leaves everything else |
| Choosing an already-chosen option | Deselects it, leaving the question unanswered | Deselects it |
| What comes back | One string, or the typed custom text | A list in the offered order, with any typed custom text **appended last** |

**LAW — accessibility description:** multi → `Select one or more options. Use arrow keys to navigate, Space to
select.` · single → `Select one option. Use arrow keys to navigate, Space to select.`

**Edge cases:**

- Focus moving to an option **brings it to the centre of the visible region**.
- Fewer than 2 or more than 20 options is refused before anything appears.
- Options phrased as "All of the above", "Select all", "Everything" or "None of the above" are **rejected
  outright** (§6.4).
- ⚠️ Duplicate option strings produce two indistinguishable entries; a default matching more than one silently
  picks the first.
- A default matching no option preselects nothing.
- ⚠️ No count of what is chosen, no select-all or clear-all, no way to require a minimum or maximum (§10.12).

---

### 5.3 Text

> One typed answer. Optionally masked.

**DEFAULT title:** `Input`. **Body:** the prompt, per §3.3. Because the field currently carries no hint, **all
guidance must live in the body.**

**Content:** exactly one text field (§3.11).

**Ways out:** decline and commit. **DEFAULT** labels `Cancel` and `Submit`.

**LAW:**

- The field **takes focus automatically shortly after the surface appears** — the person can type immediately.
- Return submits; a newline can never be inserted. The field is strictly single-line, and pasting multi-line
  text yields one line.
- **The field is always in a submittable state.** Commit is never unavailable and an empty submit returns an
  empty string. There is no validation, no length limit, no required-field concept and no error state.
- A prefilled value opens **pre-selected**, so the first keystroke replaces it.

⚠️ **No placeholder is rendered**, even though the shared field supports one and the form's text steps use one.
An empty prefill gives a completely blank box. A style **MAY** add one — see §7.2.

**Masked variant.** Identical in every respect except that it is identifiable as masked before typing, and
characters are substituted. ⚠️ §10.13.

**LAW** — the shape-rejection menu (§3.7) marks `Text Input` as current in the plain variant and `Password` in
the masked one.

---

### 5.4 Form

> Several questions, one at a time. 1–10 questions.

**DEFAULT title:** the calling client's name. **Body:** intro text — which also becomes the quoted subject of a
form-level annotation (§3.6).

**CAPABILITY — the person must always know how far through the batch they are.**

**LAW** — it MUST be exposed as `Step <N> of <M>` with a percentage to assistive technology. **The current step
counts as complete**, so the indication reads as full while they are on the last step. Whatever conveys it is
**decorative**: not a target, never focusable, and there is no way to jump between steps.

**DEFAULT** — a proportional indicator plus a textual `<N> of <M>` counter. *Segmented, continuous, numeric
only, positional, or something with no discrete indicator at all are all valid.*

**Content** (the region that must survive overflow, §2.3): the question text, selectable and wrapping; access
to that question's annotation (§3.6); and the answer control — the option set of §3.10 for a choice step, or a
single text field (§3.11) for a text step. **Text steps never offer free-text-within-a-set** — the field
already is free input.

**Ways out, by step:**

| Step | Decline / retreat | Commit |
|---|---|---|
| First | `Cancel` | `Next` |
| Middle | `Back` | `Next` |
| Last | `Back` (or `Cancel` if the form has exactly one question) | `Done` |

**LAW — navigation:**

- `→` and commit advance; both are **inert while the current question is unanswered**.
- `←` and retreat go back. **Every previously entered answer is preserved** in both directions; nothing is ever
  cleared by moving between steps.
- Step changes are **instantaneous** — there is no transition between questions. Focus lands on the new step's
  first answer element shortly after (§9), and the answer region returns to the top.
- Because forward movement requires a valid answer, a submitted form is normally complete.

**LAW — validity per step type:**

| Step | Valid when |
|---|---|
| Single-select | Exactly one option chosen, or free text chosen with non-empty content |
| Multi-select | At least one option chosen, or free text chosen with non-empty content |
| Text | The field is non-empty (a single space counts) |

**LAW — what comes back:** one answer per answered question, labelled with the caller's own key, plus how many
were answered. Single-select yields one string; multi-select a list in the offered order with any typed text
appended last; text the typed string. **A question never answered is reported as nothing at all**, not as an
empty answer. Per-question annotations and one form-level annotation are delivered alongside, each keyed to its
question.

**Edge cases:**

- A one-question form still renders the full chrome: `1 of 1`, decline and commit.
- Cancelling mid-form **discards every answer silently** — but annotations still travel back. ⚠️ There is no
  confirmation.
- Postponing or rejecting the shape from inside a form discards all answers (§10.11).
- ⚠️ No review step, no skip, no optional questions, and no explanation of why commit is unavailable (§10.14).

---

### 5.5 Notify

> An announcement. No question, no waiting, no way in.

**LAW:**

- **Not suppressed** by a quiet period or by away mode, and it may appear on top of an open interactive
  surface.
- It floats above other windows unconditionally and **appears without stealing keyboard focus**.
- It has no tools, no keyboard hints, and no actions. Reporting (§3.1) and project identity (§3.2) are still
  present.
- Its title is clamped to one line; its message must survive overflow (§2.3).
- **DEFAULT title:** `Notice`.
- **Lifetime:** it closes itself after a fixed period (§9). There is no countdown, no pause-on-hover, no close
  control. **Escape closes it early** — the only key it responds to, working from the first frame because
  transient surfaces never trigger a cooldown.
- **Anchor:** the person's saved preference only; a per-call anchor is ignored (§2.4).

⚠️ The message renders as **literal characters** — no formatting, no clickable links (§10.3).
⚠️ Nothing specifies what happens when two arrive at once (§10.5).
⚠️ A long message scrolls, but the lifetime is rarely enough to read it.

---

### 5.6 Response preview

> A last look at what is about to be sent. Read-only.

**LAW** — shown right after any interactive surface is answered, **only** when the person has enabled the
review-before-send preference, and **never** after a postpone.

**LAW** — it behaves as the notification does, with one difference that matters: **it MUST NOT read as an
alert.** A preview is informational; a notification is an announcement. Confusing the two makes the person
brace for a problem that is not there. *How you keep them apart is unspecified — but they MUST be
distinguishable at a glance, and it is the preview that must not borrow the alarming one.*

**DEFAULT title:** `Response Preview`.
**Body:** the exact outgoing text — either the compact structured payload, or a plain-language rendering of it
when the humanised-responses preference is on.

**LAW** — nothing the person does can alter or stop the response. It closes itself after the same fixed period;
Escape closes it early. It can be moved. Reporting opens the issue page directly (§3.12).

**LAW** — if the preview cannot be shown for any reason, the answer is still delivered. It is purely advisory.

⚠️ A fixed lifetime with no countdown, no pause and no scroll indication defeats the surface's own purpose for
any response longer than a line (§10.15).

---

### 5.7 Value tweak

> Numbers, tuned live against the person's real files, while they watch the result change.

Unlike the others, the answer here is not a decision — it is a *feel*. The person moves something and their own
application updates. Everything about this surface serves that loop, and anything that interrupts it is a bug
regardless of how it looks.

**DEFAULT title:** the calling client's name. ⚠️ A supplied title has no effect (§10.16).
**Body:** the agent's explanation of what is being tuned.

#### Session-level controls

**CAPABILITY** — three things must be conveyable or operable at session level:

- **Detected stack** (conditional): **DEFAULT** reads `Framework detected: <name>` — one of Svelte, React, Vue,
  CSS, Vanilla. **Exactly one is shown** even when the values live in several kinds of file. Informational
  only, and it can be wrong for a mixed project.
- **Animation replay** (conditional — only when a stack is detected). Default **on**. **DEFAULT** labelled
  `Replay animations`, described as `Trigger animation replay after changes (requires browser hook)`. When on,
  the page being tuned re-runs its animations after each change **if it is set up to do so**. ⚠️ Nothing shows
  whether it is — the control looks identical either way and a failure is silent.
- **Edit visibility** (always present). Default **off**. **DEFAULT** labelled `Show edits`, described as
  `Toggle debug console`. **LAW** — turning it off also **forgets the last edit**, so turning it back on starts
  empty.

#### The parameters

**LAW** — one per tunable number, in exactly the order supplied, up to 20.

**LAW** — parameters are grouped under a heading when the caller supplies an element or selector hint.
**Grouping merges only consecutive parameters sharing the same hint** — the same hint reappearing later
produces a second heading.

**Each parameter must present:** a label (whose file and line are available to the person somehow), an
adjustable control, an indication of how coarse the steps are, a numeric readout with its unit, and access to
its own settings.

**LAW — states:** default, focused, **errored**, settings-open.

- **Errored** shows `File changed externally`, makes the numeric field uneditable, makes the adjustable control
  inert, and causes arrow-key adjustment to be ignored.
- **Settings-open** MUST make clear that adjustment is temporarily unavailable.

⚠️ There is **no per-parameter changed marker**; with 20 of them the person cannot see which they moved
(§10.17).

#### The adjustable control

**LAW:**

- Pressing the **track** jumps the value to that position, and the press continues as a drag from there.
- Pressing the **handle** begins a relative drag with no jump.
- Dragging along the axis moves the value proportionally: traversing the full extent covers the full range.
- **Precision is perpendicular distance, not a modifier key.** The travel rate falls off continuously with how
  far the pointer has moved away from the axis it was pressed on — roughly half speed at a short distance and a
  quarter at three times that — with no steps or thresholds. Moving back restores full speed.

  *This is the best idea in the surface: fine control with no key to remember. Keep the behaviour even if you
  discard the slider idiom entirely.*
- Values clamp hard at the working bounds; there is no rubber-banding.
- Every dragged value is **snapped to the step** before it is applied.

⚠️ Hovering produces no feedback at all — no handle change, no value readout.

#### Step indication

**LAW** — it shows how coarse or fine the steps are. **When marks would be too dense to read, the count is
repeatedly halved until they are legible** — so a 0–500 range stepping by 1 shows a readable subset, not 501
hairlines. Fewer than two marks draws nothing.

⚠️ Marks reflect the step only. They never mark the current value, the original value, or zero, which makes
signed ranges hard to read.

#### Numeric readout

**LAW:**

- It is editable. Return commits: unparseable text reverts silently; a parsed number is clamped and applied.
- The number updates live while dragging or arrowing.
- **Precision is inferred from the source text**: no decimal point in the original → a rounded whole number;
  otherwise the larger of (decimals in the original) and (decimals in the step).
- Values written back **keep the file's own formatting** — the embedded unit suffix, the decimal count, and a
  leading-dot style such as `.5` all survive.

⚠️ **Its editability is not discoverable** — the field carries no affordance at all. Fix this in any new style.

#### Per-parameter settings

**LAW** — offers a **revert** action and **`Min` / `Max`** bounds.

- Revert writes the value back to what it was when the surface opened, clears that parameter's error if the
  write succeeds, and closes. **DEFAULT** description `Reset to original value`.
- `Min` is accepted only if strictly below the current max; `Max` only if strictly above the current min. ⚠️ A
  rejected value snaps back silently with no explanation.
- The adjusted range is **session-only and per parameter**: it rescales the control, re-derives the step marks
  and re-clamps input, but never changes the current value and is never reported back.

#### Live writing

**LAW** — every change reaches the file **shortly after the person stops moving that value** (§9), so a
continuous drag produces one update per pause rather than one per movement. Moving one value never holds up
another. Small shifts elsewhere on the same line do not break a value's connection to its parameter, and when
several tuned values sit on one line, changing one never corrupts the others.

**LAW** — a write fails and errors the parameter when the expected text is no longer there, the file cannot be
read or written, or the target lies outside the declared project folder. ⚠️ **All three collapse to
`File changed externally`**, so the person cannot tell which happened.

⚠️ There is **no difference between "queued" and "written"** and no success confirmation (§10.17).
⚠️ **Cancelling does not roll back writes already made** (§10.17) — the most surprising behaviour in the
product.

#### The edit log

**LAW** — shown only while edit visibility is on. It appears immediately in its empty state and populates after
the first successful write.

- **Populated:** identifies the file and line, then shows the edited line with **two lines of context either
  side**. The edited line and the changed number within it MUST both be distinguishable from context. Context
  lines are truncated past a limit; **the edited line is never truncated** — it scrolls.
- **Empty: DEFAULT** message `Move a slider to see changes`.
- It sits on the **far side from the surface's own anchor** — a right-anchored surface puts it on the left,
  otherwise on the right. It is not independently movable or resizable, shares the surface's stacking level
  (§2.6), and follows it.
- Its content is not selectable and has no target.

⚠️ It shows only the **single latest edit**, never a history, despite being labelled "Show edits".

#### Committing

**LAW — the ways out change with state**, the moment any value differs from where it started, and back again if
every value returns:

| State | Ways out | Return does |
|---|---|---|
| No changes | A single primary **cancel** | Cancel |
| Changes made | **revert-all** · **hand-back** · primary **save** | Save |

**DEFAULT** labels `Cancel` · `Revert All` · `Tell Agent` · `Save to File`.

| Action | Does |
|---|---|
| **Save** | Flushes every pending write, closes, and reports the final numbers with a marker meaning *the files already contain these; there is nothing to apply* |
| **Hand back** | Cancels pending writes, rewrites every value back to its opening value, closes, and reports the chosen numbers with a marker meaning *the files are untouched; you apply these* |
| **Revert all** | Rewrites every value back to its opening value, restores every readout, clears the error on every parameter whose reset succeeded, empties the edit log, and **leaves the surface open**. Everything now matches its start, so the ways out collapse back to a single cancel. |
| **Cancel** | Closes with no answer. ⚠️ Writes already made remain on disk (§10.17). |

**LAW — keyboard:** `↑`/`↓` move between parameters (with none focused, `↑` jumps to the last and `↓` to the
first); `←`/`→` step the focused value; both are suppressed while typing.

⚠️ Three input methods clamp and snap differently (§10.18).

---

### 5.8 Layout sketch editor

> A screen layout, proposed by the agent, dragged into shape by the person.

**This surface deliberately breaks the model above.** It is a workspace, not a question. Almost everything in
this subsection is mechanics — how direct manipulation resolves — rather than presentation, and the mechanics
are LAW because they are what the person is actually operating.

#### Window behaviour

**LAW:**

- It **is resizable**, down to a minimum, by dragging near any edge or corner, with cursor feedback naming the
  direction.
- It is moved by dragging **one designated region only** — not the whole background, and never the canvas.
- It is modal and **exclusive**: only one session may exist. A second request is refused with `An interactive
  layout session is already running. Complete or cancel it first.` A request with no desktop session is refused
  with `Interactive layout editor requires a desktop environment (unavailable over SSH/CI).`

#### What must be present

**CAPABILITY** — the person must be able to: report a problem (§3.1); read the title and its optional
description; know the grid's dimensions; undo and redo; add a block; see and restore stashed blocks; and commit
or cancel.

**DEFAULT** — title `Layout Sketch`; grid size shown as `<columns>×<rows>`; add labelled `Add`; undo and redo
described as `Undo (⌘Z)` and `Redo (⌘⇧Z)`; stash headed `Stash`.

**LAW** — undo and redo are each unavailable when there is nothing to do. Undo history is capped (§9) and the
oldest step is discarded silently. **Making any new change after undoing clears the redo history.**

⚠️ No project identity is shown here, unlike every other surface (§10.6).
⚠️ Wherever stashed blocks are listed, that listing must handle many entries. It currently overflows.

#### The canvas

**LAW:**

- A fixed grid of **3–20 columns by 3–20 rows**, set when the session opens and **not changeable from inside
  the editor**.
- **Cells are always square.** The grid scales to fit the available area and is centred in it; leftover space
  stays blank.
- **The canvas never scrolls — it always scales.**
- Layer order, back to front: grid → role indication → blocks (containers before nested) → alignment guides →
  annotation pins. **The hovered block is raised above its neighbours.**
- Clicking an **empty** cell opens the add-block flow targeted at it. Clicking a covered cell does nothing at
  the canvas level.

#### Blocks

**LAW — blocks show their number, not their label.** The label is reachable by hover, by renaming, in the stash
listing, and in every textual output.

**LAW — numbering is hierarchical:** top-level blocks are `1`, `2`, `3`… in reading order; a block nested
inside block 2 is `2:1`; one nested inside that is `2:1:1`, to unlimited depth.

**LAW — four independent semantic dimensions** must each be readable at a glance and must not be confusable
with one another:

| Dimension | Values | Meaning |
|---|---|---|
| **Content kind** | text, image, video, avatar, button, input, list, chart, map, nav, form | What kind of content lives there |
| **Role** | header, sidebar, canvas, footer, toolbar, panel | Which structural family it belongs to |
| **Importance** | primary, secondary, tertiary | How visually dominant it should read |
| **Elevation** | 0–3 | How far it floats above the surface |

Four orthogonal dimensions on one object is the hard problem in this surface. *Nothing specifies which channels
you spend on which.*

**LAW** — an unrecognised role produces **no role indication at all**, not a fallback.

**LAW — states:** default, hovered, **promoted**, dragging, nested, renaming, read-only. Read-only removes
resizing, dragging, rename and the context menu; hover highlighting still occurs.

**LAW** — a nested block MUST remain distinguishable from its container and MUST NOT obscure the container's
own extent.

#### Direct manipulation

**LAW:**

- **Move** — press and drag anywhere on the block; a small movement threshold starts it. A live indication
  shows the destination as `x: <column>, y: <row>` (zero-based). Release snaps to the nearest whole cell,
  clamped fully inside the grid.
- **Resize** — drag the resize affordance; a smaller movement threshold starts it. A live indication shows
  `<width>×<height>` in whole cells. Clamped to at least one cell and at most the space remaining to the grid's
  far edges.
- **Rename** — double-click. Return commits (ignored if empty); Escape reverts. **DEFAULT** placeholder
  `Label`.
- **Context menu** — right-click. **DEFAULT** entries `Duplicate` and `Delete`. Duplicate creates a copy offset
  one cell right and down, clamped, labelled `<label> Copy`, keeping the colour but **losing** content kind,
  role, importance, elevation and flow direction. Delete removes it immediately with **no confirmation**;
  nested blocks are **not** deleted. Both are undoable.
- **Nesting is inferred purely from geometric containment** — the smallest containing block wins. Dragging a
  container moves its children by the same cell delta; dragging a child does not move the container. Resizing a
  block so it no longer contains a former child **instantly reclassifies that child as top-level**, changing
  its treatment and its number.
- **Promotion** — holding a modifier while the pointer sits over two or more stacked blocks promotes the next
  one to the top of the hover order, wrapping. A promoted block behaves exactly as a hovered one. ⚠️ Completely
  undiscoverable (§10.20).

#### Stashing

**LAW** — dragging a block so its snapped destination falls **past the bottom row or before the first column**
removes it from the grid and parks it in the stash. **The opposite edges only clamp.** ⚠️ The asymmetry is
never explained.

**LAW** — two drop hints appear the moment a drag begins and vanish when it ends: one over the canvas, one at
the stash. **Neither is a pointer target** — the decision is made from the drag's computed destination, not
from where the pointer is released, so both are driven by the same condition. **DEFAULT** copy `Drop to stash`
and `Drop here`.

**LAW** — each stash entry shows its block's label and colour. Restoring puts the block back **at its original
position and size**, with **no collision check** — it can land on top of something. A stashed container takes
its children with it, but restoring the container restores **only the container**. A block reappearing by any
route leaves the stash automatically.

⚠️ **Blocks left in the stash are silently discarded on accept**, and reported as removed. The person is never
warned.

#### Content-kind inference

**LAW** — when no content kind is supplied, one is guessed from the block's label by **case-insensitive
substring match, evaluated in a fixed order, first match wins**:

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

**LAW** — shown only while a block is being dragged or has been promoted. A guide appears where the active
block's edge coincides **exactly** with another block's corresponding edge. Matching is exact grid-coordinate
equality — no proximity tolerance and no magnetism, because blocks already snap to whole cells.

⚠️ Guides currently reflect the block's **committed** edges rather than its live destination, so they never
update during the one gesture they exist for (§10.21).

#### Annotations

**LAW** — caller-supplied only. **The person can neither create, edit nor delete them.**

Each is a numbered pin attached to a grid cell, with a leader to that cell, plus a numbered legend. **Legend
text is single-line and truncated.**

**LAW** — a pin whose cell falls inside a block being dragged **follows that block**, and its stored coordinate
is rewritten on release. **Ownership is the first block in list order** whose extent contains the cell — not
the topmost or the smallest. A pin in no block never moves. Annotations belonging to a stashed block **stay
behind, orphaned.**

⚠️ A pin at the first column and row sits mostly outside the canvas. The legend does not scroll and squeezes
the canvas as it grows.

#### Device frames

**LAW** — optional decorative chrome — **browser**, **phone** or **tablet** — wrapping the canvas so
proportions read in context. **Nothing in a frame responds to input**, and the frame cannot be changed from
inside the editor. Frame chrome consumes space, so cells get smaller.

**DEFAULT** — the browser frame shows a mock address placeholder `https://`; the phone frame shows a fixed
clock `9:41` (never the real time) and no battery, signal or notch; the tablet frame carries no chrome at all.

**LAW** — the canvas drop hint re-anchors to the bottom of the framed unit rather than the raw canvas.

#### Adding a block

**DEFAULT** — headed `Add Block`, a field placeheld `Block label`, actions `Cancel` and `Add`, with add as the
default action. Return confirms, Escape cancels.

**LAW** — add is **unavailable while the field is empty** and guarded on activation, so an empty label can
never create a block. ⚠️ Whitespace-only text is accepted and produces a block with a blank-looking label.

**LAW** — the new block is always **one cell**, coloured by the next entry in a fixed rotation, with no content
kind, role, importance or elevation.

**LAW** — the target cell is the clicked cell, or — when triggered without one — the **first free cell in
reading order**; if the grid is fully covered it falls back to the first cell, **producing an overlap with no
warning**.

#### Committing

**Ways out:** decline and commit. **DEFAULT** labels `Cancel` and `Accept`.

**LAW — keyboard, window-wide:** `Escape` cancels · `Return` accepts (which means it also fires while a label
is being typed unless the field consumes it first) · `⌘Z` undo · `⌘⇧Z` redo · standard editing in text fields.

**CAPABILITY** — the direct-manipulation gestures and the keyboard shortcuts must be discoverable per §3.8.
**DEFAULT** — two hint lines reading `Drag to move · Resize from corner · Double-click to rename` and
`⌘Z Undo · ⌘⇧Z Redo · ⌘D Duplicate · ⌫ Delete`.

⚠️ **Duplicate and Delete are advertised but not bound** — they exist only in the context menu (§10.22). Never
advertise a shortcut that does nothing.
⚠️ **There is no selection model at all** — no click-to-select, no selected state, no multi-select, no marquee,
no way to act on several blocks at once. Everything is hover plus a per-block context menu. And **the canvas is
entirely unreachable by keyboard** (§10.23).

#### What accepting produces

**LAW** — accepting resolves as **kept as proposed** when the final layout is identical to what was proposed,
and as **changed by the user** otherwise — in which case a plain-language change list comes with it:

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

**LAW** — three representations come back alongside the layout:

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

**This entire section is LAW.** It is the API the calling agent drives, and a style changes nothing in it.

It is included because the options here decide what the person actually encounters — a style that has not read
§6 will design for cases that cannot occur and miss cases that will.

### 6.1 The four capabilities

| Capability | Produces | Waits for the person |
|---|---|---|
| **ask** | One of: confirm, pick, text, form | Yes |
| **notify** | The notification | No |
| **tweak** | The value tuning surface | Yes |
| **propose layout** | The sketch editor | Yes |

### 6.2 Options shared by every surface

| Option | Meaning | Effect | Default | Limits |
|---|---|---|---|---|
| `body` | The question or message | The body, per §3.3. Formatted per §3.4 — except on the notification. Escaped newlines become real ones, which trips the presentation switch and renders it as prose. | required | 1–1000 chars |
| `title` | The headline | Wraps; the transient surfaces clamp it to one line. | Per surface: `Confirmation` · client name · `Input` · client name · `Notice` · `Response Preview` · client name · `Layout Sketch` | ≤ 80 chars |
| `position` | Which anchor the surface takes | `left` · `right` · `center`. Also decides which side anything attached opens on, and the resize anchor. **Never applied to the two transient surfaces.** | The person's saved preference; falls back to centre | one of left / center / right |
| `project_path` | Which project this is about | Project identity per §3.2. Omitting it removes it entirely. Also the Project line in a filed report. | Cached from the first call in the session | absolute path |

Three more arrive from the launching environment rather than per call:

| Option | Effect |
|---|---|
| **Calling client name** | Used as the title when the caller supplies none; appears in a filed report's Environment section and beside every history entry. Default `MCP`. ⚠️ Documented as *prefixing* supplied titles but does not (§10.25). |
| **Colour scheme** | Selects one of the available palettes. Unrecognised values fall back to the default. Behaviour, copy and the caller surface are unchanged. |
| **Presentation style** | Selects a style (§7). Unrecognised names print the available list and fall back to the default. |

### 6.3 Confirm

| Option | Effect | Default | Limits |
|---|---|---|---|
| `yes` | The commit action's label; it also carries the Return indication | `Yes` | ≤ 20 chars |
| `no` | The decline action's label; no Return indication | `No` | ≤ 20 chars |

Both are routinely supplied. Design the confirm surface for arbitrary caller labels of up to 20 characters, not
for `Yes` and `No`.

### 6.4 Pick

| Option | Effect | Default | Limits |
|---|---|---|---|
| `choices` | One option per entry, in order, before the free-text entry | required | **2–20**, each 1–100 chars |
| `descriptions` | A secondary line under the matching label. Index-aligned; an empty string renders no line; a short list is padded; extras are ignored. | none | each ≤ 200 chars |
| `multi` | Switches to multi-select: the mode indication changes, the surface's identity cue changes, the accessibility description changes, and choosing changes from replace to accumulate. Adds **no** count and no select-all. | `false` | — |
| `other` | Appends the free-text entry. Set `false` **only** for genuinely closed sets. | `true` | — |
| `default` | Preselects that option and starts focus on it, so commit is live immediately. A value matching no option preselects nothing. | none | must match an option exactly |

**Rejection rule.** An option phrased as "All of the above", "Select all", "Everything" or "None of the above"
is refused **before anything appears**, with: `Do not include "<that option>" style options. If the user should
be able to select multiple answers, set multi: true instead.`

### 6.5 Text

| Option | Effect | Default | Limits |
|---|---|---|---|
| `default` | The field opens containing this text, **pre-selected**. A long value scrolls inside the field rather than widening the surface. | empty | any string |
| `hidden` | Masks the input and changes the surface's identity cue. No reveal control. | `false` | — |

### 6.6 Form

| Option | Effect | Default | Limits |
|---|---|---|---|
| `questions` | One step each, in order. Sets the progress denominator. | required | **1–10** |
| `…[].id` | Never displayed; the key the answer and any annotation are filed under | required | 1–50 chars |
| `…[].question` | The step's prompt, selectable and wrapping. Also quoted as that question's annotation subject. | required | 1–500 chars |
| `…[].type` | `choice` → an option set (with free text by default). `text` → a single field, and no free-text entry. | `choice` | choice / text |
| `…[].options` | One option each, in order | required for choice | **2–10**, each 1–100 chars |
| `…[].descriptions` | A secondary line under the matching label | none | each ≤ 200 chars |
| `…[].multi` | Multi-select for that step; that step's answer becomes a list | `false` | choice only |
| `…[].other` | Appends the free-text entry to that step | `true` | choice only |
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
| `parameters` | One per entry, in order | required | **1–20** |
| `…[].label` | Its name; its file and line are available to the person | required | 1–100 chars |
| `…[].element` | A group heading. Consecutive parameters sharing it merge under one heading. | none | ≤ 100 chars |
| `…[].unit` | Shown beside the readout. Auto-detected for stylesheet and pattern addressing. | auto, else blank | ≤ 10 chars |
| `…[].min` / `…[].max` | The range ends, the clamps, and the starting contents of the settings bounds | required | min must be below max |
| `…[].step` | Step-mark spacing, the arrow-key increment, the drag snap, and the minimum decimals shown. Omitted → derived as one hundredth of the range rounded to a nice 1/2/5/10 × power of ten (0–500 → 5; 0–48 → 0.5). | auto | must be positive |
| `…[].current` | Positions the control, seeds the readout, and is what revert writes back. With pattern addressing it also disambiguates which match this parameter controls. | resolved for stylesheet addressing | must equal the real value |
| `…[].id` | Never displayed; the key in the reported answer. Omitted → derived from the label. **Two entries resolving to the same key prevent the surface from opening at all.** | derived | 1–50 chars, unique |
| `…[].file` | Appears with the label and in the edit log. Its type, pooled across all parameters, decides the stack indication and whether the replay control appears. | required | absolute, or relative to the project |

**Three ways to address a value**, exactly one of which must be complete:

| Style | Options | Notes |
|---|---|---|
| **Direct** | `line` · `column` · `expectedText` | Lines and columns count from 1. The source text drives the readout's number formatting. If it no longer matches at write time, the parameter errors. |
| **Stylesheet** | `selector` + `property`, optionally `index` or `fn` | Resolves before the surface opens and supplies the unit and group heading automatically. `index` picks one value out of a multi-value declaration; `fn` targets a named function's argument. |
| **Pattern** | `search` (one placeholder marking the number) + `current` | Auto-detects the unit from what follows the placeholder. |

**Refusals — nothing opens at all:** a location that cannot be resolved; two parameters resolving to the same
spot; two sharing an identifier; a pattern matching several places that the supplied current value cannot
single out (the agent is told to be more specific). Two parameters MAY legitimately target the identical
pattern in the same file if their starting values differ.

⚠️ `title` is accepted here but has no effect (§10.16).

### 6.9 Propose layout

| Option | Effect | Default | Limits |
|---|---|---|---|
| `width` / `height` | Grid columns and rows. Cells stay square, so a wide grid in a short window shrinks every cell. | 12 / 8 | 3–20, clamped; ignored when a template is given |
| `template` | Overrides both. `compact` 6×4 (2–4 blocks) · `standard` 12×8 (default, up to 12) · `spacious` 16×10 (up to 20) · `detailed` 20×16 (up to 30) · `mobile` 4×12, which **also switches on the phone frame** unless one is named. | none | one of the five |
| `description` | A secondary line under the title; omitting it collapses whatever presents it | none | ≤ 200 chars |
| `blocks` | One editable block each, numbered in reading order | empty grid | coordinates are **not** clamped on load, so out-of-grid values render off-grid |
| `…[].label` | The hover text, the rename seed, the change-list name, and the seed for the content-kind and elevation guesses | required | 1–50 chars |
| `…[].x` / `y` / `w` / `h` | Zero-based top-left cell plus spans. A block fully inside another is automatically nested. | required | x,y ≥ 0; w,h ≥ 1 |
| `…[].color` | The block's identity colour, also used for its stash entry | auto from a fixed rotation by list position | 6-digit hex, with or without a leading hash; unparseable → the first rotation entry |
| `…[].content` | The content kind; beats the label guess | guessed from the label | text / image / video / avatar / button / input / list / chart / map / nav / form |
| `…[].role` | The structural family, and — when importance is unset — the visual weight: `canvas` → primary; `header`, `sidebar` → secondary; `toolbar`, `panel`, `footer` → tertiary | none | header / sidebar / canvas / footer / toolbar / panel |
| `…[].importance` | How dominant it reads | from role, else secondary | primary / secondary / tertiary |
| `…[].elevation` | How far it floats | guessed from the label | 0–3, clamped |
| `…[].flowDirection` | Which way content inside it flows | none | row / column |
| `structure` | A nested tree describing the layout by direction, gaps, sizing and priority instead of coordinates. **Takes precedence over `blocks`.** It is turned into ordinary blocks before the editor opens — the person only ever drags plain blocks and never sees or re-edits the nesting. | none | per node: id 1–50 chars; optional label ≤ 50 chars falling back to the id; direction row/column (column when unstated); gap 0–10 cells; priority a non-negative integer defaulting to 1; size a whole number of cells, or `hug` (one cell), or `fill` (a priority-weighted share of what is left) |
| `frame` | Device chrome | none, except `mobile` implies phone | browser / phone / tablet |
| `annotations` | Numbered pins plus the legend. The person cannot create, edit or delete them. | none | per entry: non-negative column and row, text 1–100 chars |

---

## 7. Presentation styles

The interface separates **what a surface is** from **how it is drawn**. A *presentation style* owns everything
in the second category.

### 7.1 What a style owns

**Everything not marked LAW.**

That includes, non-exhaustively: arrangement, decomposition, grouping, idiom, colour, type, dimension, spacing,
motion, which capabilities are persistent versus revealed, how many discrete elements exist, what is drawn at
all, and every string marked DEFAULT.

A style is not a re-skin of a fixed structure. It is an independent answer to §1–§5. Two conforming styles may
share no visual or structural vocabulary whatsoever and both be correct.

### 7.2 What a style must not change

- Every rule marked **LAW**, in full.
- Every capability marked **CAPABILITY** must remain accomplishable, though not in any particular form.
- The text of §8.2 — what the calling agent receives — exactly.
- The accessibility strings named in §8.3.

A style MUST supply, for each surface it defines: an arrangement, a palette, and its own per-surface minimum
sizes (§2.2).

### 7.3 Partial styles

A style **MAY** define only some surfaces. **Any surface it does not define falls back to the default style's
arrangement *and* its metrics.** This is a deliberate contract, not an omission — someone running a partial
style will see the undefined surfaces in the default arrangement, visibly unlike the rest of that session.

Selecting a style installs that style's preferred palette automatically, but an **explicitly requested palette
always wins**, because the palette is resolved after the style.

### 7.4 Requirements on any style, including the default

These are not currently met and are the responsibility of whoever builds next:

- **A light palette MUST exist.** Every requirement in this document holds in it identically.
- **Every element MUST take its colour from the active palette.** No hardcoded values anywhere; one element
  ignoring the palette breaks the whole thing in every other palette at once.
- **Right-to-left mirroring MUST be decided deliberately.** Every ordering rule in §4.5 and §3.9 is stated in
  reading order and therefore mirrors; nothing else in this document does automatically.
- **Text scaling MUST be handled.** §2.2's measure-once law means a surface built at one text size and rendered
  at another must still floor, cap and reflow correctly.

### 7.5 Additions a style may make

A style may add things this document does not describe, provided no LAW is broken. Some that are known to be
useful and are absent from the current default:

- **A label naming the surface kind.** Where shown, the strings are `CONFIRM` · `INPUT` · `SECRET` · `PICK` ·
  `PICK-MULTI` · `NOTIFY` · `PREVIEW` · `FORM <NN>/<NN>` (both numbers zero-padded).
- **An ordinal beside each option.** **Decorative only** — not a target, and **no digit key chooses an option**
  (§4.1 is the complete map).
- **A count of what is chosen.** `select one` on a single-select set · `select any` on a multi-select set while
  nothing is chosen · `<N> selected` once at least one is, counting chosen options plus the free-text entry
  when chosen. Updates live on every toggle. This also addresses §10.12.
- **A placeholder in the text surface's field**, which currently has none (§5.3).
- **Anything else.** This list is examples, not permission.

---

## 8. Copy

### 8.1 On-screen vocabulary — DEFAULT

Every string below is a **default**. It is here so nothing blocks you, and because consistent product voice is
worth something. A style **MAY** replace any of it, provided the meaning survives and §7.2 is respected.

Strings the **caller** supplies — action labels on confirm, titles, bodies, questions, option text — are not
here and are never yours to change.

| Where | String |
|---|---|
| Report | `Report` · `Report a bug or suggestion` |
| The three exits | `Snooze` · `Feedback` · `Ask differently` |
| Postpone prompt | `Ask me again in:` |
| Postpone durations | `1m` · `5m` · `15m` · `30m` · `1h` |
| Shape-rejection entries | `Confirmation` · `Single Select` · `Multi Select` · `Text Input` · `Password` · `Wizard Form` |
| Annotation captions | `NOTE ON THIS DIALOG` · `NOTE ON THIS FORM` · `NOTE ON THIS QUESTION` |
| Annotation subject fallback | `(this question)` |
| Annotation editor label | `YOUR NOTE` |
| Annotation actions | `Clear` · `Close` |
| Annotation descriptions | `Close pane (Esc)` · `Close pane (note is preserved)` |
| Per-question annotation | `Add a note for the agent` · `Edit note` |
| Free text within a set | `Other` · placeholder `Type your answer...` |
| Form text placeholder | `Enter your answer...` |
| Confirm | Title `Confirmation` · actions `No` / `Yes` |
| Pick | Actions `Cancel` / `Done` |
| Text | Title `Input` · actions `Cancel` / `Submit` |
| Form | Actions `Cancel` / `Back` / `Next` / `Done` · counter `<N> of <M>` |
| Notify | Title `Notice` |
| Preview | Title `Response Preview` |
| Value tweak | `Framework detected: <name>` · `Replay animations` · `Trigger animation replay after changes (requires browser hook)` · `Show edits` · `Toggle debug console` · `File changed externally` · `Slider settings` · `Min` · `Max` · `Reset to original value` · `Move a slider to see changes` · actions `Revert All` / `Tell Agent` / `Save to File` / `Cancel` |
| Report flow | `Report Issue` · `Describe the problem below.` · `What happened?` · `Briefly describe the issue...` · `Cancel` · `Next →` · `Save Screenshot?` · `Can we save a screenshot of this dialog to your clipboard? You can paste it directly into the GitHub issue with ⌘V.` · `Skip` · `Yes, Copy Screenshot` |
| Sketch | Title `Layout Sketch` · `Add` · `Undo (⌘Z)` · `Redo (⌘⇧Z)` · `Stash` · `Drop here` · `Drop to stash` · `Add Block` · `Block label` · `Cancel` / `Add` · `Duplicate` / `Delete` · rename placeholder `Label` · live indications `x: <column>, y: <row>` and `<width>×<height>` · hints `Drag to move · Resize from corner · Double-click to rename` and `⌘Z Undo · ⌘⇧Z Redo · ⌘D Duplicate · ⌫ Delete` · actions `Cancel` / `Accept` · frame chrome `https://` and `9:41` |

Keyboard hints (§3.8) have no default strings, because their form is not specified. What they must convey is.

### 8.2 Text the agent receives — LAW

Never shown on screen. Exact, including punctuation. This is a contract with software and a style changes none
of it.

| Situation | Text |
|---|---|
| Quiet period running | `Snooze active. Wait <N> seconds before re-asking.` (+ ` <M> dialogs missed so far.` when applicable) |
| Postponed in-surface | `Set a timer for <N> minute(s) and re-ask this question when it fires.` |
| Away mode | `The user has enabled Away (AFK) mode in Consult User MCP, so no dialog will be shown. Proceed autonomously with a reasonable default and note the open question in your final response. Do not fall back to other interactive question tools.` |
| Postponed (humanised) | `The user snoozed. Wait <N> seconds, then retry the exact same question.` |
| Cancelled (humanised) | `The user cancelled. Proceed with a reasonable default.` |
| Annotation (humanised) | `The user added a note: "<note>".` |
| Form answered (humanised) | `The user answered: <id>: <value>, … (<completed>/<total> completed)` and `Notes by question: <id>: "<note>", …` |
| Re-ask requested | `The user wants this question re-asked as a step-by-step wizard (type: form).` and equivalents for the other five shapes |
| Layout session busy | `An interactive layout session is already running. Complete or cancel it first.` |
| No desktop session | `Interactive layout editor requires a desktop environment (unavailable over SSH/CI).` |
| Rejected option phrasing | `Do not include "<option>" style options. If the user should be able to select multiple answers, set multi: true instead.` |

### 8.3 Accessibility strings — LAW

| Where | String |
|---|---|
| Pick, single | `Select one option. Use arrow keys to navigate, Space to select.` |
| Pick, multi | `Select one or more options. Use arrow keys to navigate, Space to select.` |
| Form progress | `Step <N> of <M>` and `<P> percent complete` |

### 8.4 Demonstration state

**LAW** — a demonstration mode reveals the annotation editor, or the postpone options, automatically a short
moment after a surface appears, with the surface already sized for it.

**This is a real presentation state a style must support** — a surface that opens with something already
revealed — not merely a test hook. If your style has no revealed/unrevealed distinction for these, the mode is
a no-op and that is fine; but the surface must not mis-size when it fires.

---

## 9. Functional timings and limits

**LAW.** These change what happens, not how anything looks.

| Value | What |
|---|---|
| **2.0s** | Opening cooldown. Adjustable from 0.1s to 3.0s in 0.1s increments, or off entirely. |
| **4.0s** | Notification and response-preview lifetime. Fixed; not pausable, extendable or cancellable except by Escape. |
| **10 minutes** | A request with no answer is abandoned. |
| **~150ms** | How long after the person stops moving a tweak value before it reaches the file. Per value, independent. |
| **~0.10s** | Focus lands after a surface appears, or after the report flow closes. Deliberately not instant. |
| **~0.15s** | Focus lands after a form step advances. |
| **~0.30s** | Demonstration mode reveals. |
| **50** | Sketch editor undo history depth. The oldest step is discarded silently. |
| **1, 5, 15, 30, 60 minutes** | The offered postpone durations. |
| **72 characters** | How much of a report description becomes the issue title. |
| **2 lines** | Context shown either side of an edited line in the tweak edit log. |

Content limits are in §6. Structural limits: 2–20 options on a pick; 1–10 form questions with 2–10 options
each; 1–20 tweak parameters; a 3–20 by 3–20 sketch grid.

---

## 10. Known defects and open decisions

Places where current behaviour is contradictory, incomplete, or surprising. **A style must decide each one
deliberately rather than inherit it.** Recommendations are recommendations.

**10.2 — Confirm and Text cannot scroll.** Both lack a scroll region, so a body past the height cap is clipped
rather than reachable. *Recommend:* give both the same overflow treatment as the other surfaces (§2.3).

**10.3 — Notifications render no formatting.** The one surface where a link would be most useful, and where the
person has four seconds to act on it, renders links as literal text. *Recommend:* apply §3.4 there too.

**10.4 — What the person is told about the keyboard is not true.** It advertises `F feedback` on a text surface
where `F` types a letter, shows all three exit shortcuts while a caret sits in any field, and stays at full
strength during the cooldown when six keys are inert. The documented workaround — the modifier chord — appears
nowhere. *Recommend:* track live availability, per §3.8, which states this as a requirement rather than a
suggestion.

**10.5 — Concurrency and multi-display are unspecified.** Nothing describes two notifications arriving at once,
so they occupy the same place and the first is invisible. And every surface is placed on one primary display
regardless of where the person is working, with no rule for a remembered position on a display that is gone.
*Recommend:* notifications **queue** — a second waits for the first to close, then appears in the same place
with its own lifetime — but never queue behind an interactive surface. Place every surface on the display that
currently contains the pointer, and discard a remembered position that falls entirely outside every attached
display.

**10.6 — The sketch editor shows no project identity.** Every other surface does. *Recommend:* add it.

**10.7 — Postpone durations are pointer-only.** They can be opened with a key and then not operated with one.
*Recommend:* put them in the Tab ring while revealed, let arrow keys move between them and Space or Return
choose, and return focus to where it came from on collapse.

**10.8 — The destructive action variant is unreachable.** It exists but no caller can request it, so a
destructive confirmation is indistinguishable from a harmless one. *Recommend:* expose it as a confirm option.

**10.9 — Free text within a set behaves inconsistently.** It uses a weaker chosen treatment than ordinary
options and has no hover or pressed feedback. *Recommend:* unify it, with its field's own focus treatment
layered on top.

**10.10 — Reporting behaves three ways.** Two-step flow on interactive surfaces; immediate browser on the
transient ones; immediate browser with a different pre-fill in the sketch editor. Nothing distinguishes them.
*Recommend:* keep the divergence — a four-second popup genuinely cannot host a two-step flow — but make it
predictable, e.g. a distinct description reading `Report a bug (opens in browser)`.

**10.11 — Postpone and shape-rejection silently destroy typed work.** Both discard the answer *and* any drafted
annotation with no warning. *Recommend:* when a non-empty draft exists, confirm first — `Discard your note?`
with `Keep editing` and `Discard and snooze` / `Discard and re-ask`.

**10.12 — Multi-select has no count and no bounds.** No indication of how many are chosen, no select-all or
clear-all, no way for a caller to require a minimum or maximum. *Recommend:* adopt the count from §7.5 into the
default style, and add caller-side bounds with the unavailable commit explained per 10.14.

**10.13 — Masked input cannot be verified.** No reveal, no caps-lock warning. Someone who mistypes a long
secret finds out later. *Recommend:* add a reveal that toggles the mask on press and reverts when the surface
loses focus.

**10.14 — An unavailable commit never explains itself.** On the pick surface and every form step it is dead,
Return does nothing, and forward navigation is blocked with no message anywhere in the product. *Recommend:*
one line of helper text near the answer — `Select an option to continue` · `Select at least one option to
continue` · `Type an answer to continue` · `Type your custom answer to continue` — appearing **only after the
person's first interaction with that region**, never on open, so a freshly opened surface is not pre-scolded.

**10.15 — The response preview defeats itself.** A fixed lifetime with no countdown, no pause, no scroll
indication, and no early dismissal except Escape. *Recommend:* pause while the pointer is over it; show
remaining time; let a click anywhere on the body close it.

**10.16 — The tweak surface ignores `title`.** Accepted, no effect. *Recommend:* wire it, or drop it from §6.8.

**10.17 — Cancelling the tweak surface leaves every write on disk.** Escape, cancel, postpone and
shape-rejection all close without reverting the writes made during the session. The single most surprising
behaviour in the product. *Recommend:* Escape and cancel revert every write before closing, matching the
near-universal mental model that cancelling undoes; postpone and shape-rejection do the same; only save leaves
them. Additionally add a **per-parameter changed marker** whenever a value differs from where it opened, and a
**written indicator** distinguishing pending from landed.

**10.18 — Three input methods clamp and snap differently.** Dragging snaps to the step and clamps to the
widened range; arrow keys snap but clamp to the *caller's* range; typed entry clamps to the widened range but
does **not** snap. The same parameter can hold a value the arrow keys cannot reach. *Recommend:* one rule for
all three — clamp to the current working range, then snap to the nearest step. The per-parameter range override
replaces the caller's bounds for every input method for the rest of the session.

**10.20 — Block promotion is undiscoverable.** Holding a modifier reaches buried blocks, but it is in no hint,
has no description, and nothing indicates that more blocks lie underneath. *Recommend:* surface it per §3.8 and
indicate the stack when the pointer sits over two or more blocks.

**10.21 — Alignment guides are stale during the drag.** They reflect committed edges, so they never update
while a block moves — a "where you used to be aligned" indicator shown during the one gesture where that is
least useful. *Recommend:* evaluate against the live snapped destination every frame, keeping exact-equality
matching, and draw each matching guide once regardless of how many neighbours match.

**10.22 — The sketch editor advertises two shortcuts that do not exist.** `⌘D Duplicate` and `⌫ Delete` are
shown but only reachable from the context menu. *Recommend:* bind both, matching the menu actions exactly and
both undoable. If they cannot be bound, stop advertising them — §3.8 makes this a requirement, not a
preference.

**10.23 — The sketch canvas has no selection model and no keyboard access.** No click-to-select, no selected
state, no multi-select, no way to act on several blocks at once — and no way to reach, move, resize, rename or
delete a block without a pointer. *Recommend:* decide selection deliberately rather than by omission, and give
the canvas focus and arrow-key movement at minimum.

**10.24 — The exported image does not reproduce the canvas.** Different proportions (the export does not keep
cells square), inverted treatment, labels instead of numbers, and a legend outside the stated bounds. The
artifact does not look like what the person approved. *Recommend:* derive the export the same way the canvas
does, show both the number and the label, and size the image to include the full legend.

**10.25 — The documented client-name prefix is not rendered.** §6.2 says the client name is prefixed to titles;
it is not — it only ever appears as a fallback when no title is supplied. *Recommend:* correct the contract to
match the behaviour.

**10.26 — The focus indicator is delegated and undefined.** Focus is the only thing distinguishing "this will
react to Space or Return" from "this is idle", and it is currently drawn entirely by the host system, with
nothing specified. On any other platform nothing would be drawn — and focused-but-unchosen options rely on it
completely. *Recommend, and §3.10 requires:* define it explicitly — visible against every surface state in
every palette, never replacing or suppressing the chosen treatment, and drawn so an option can read as
focused-and-chosen simultaneously.

**10.29 — Timeout is invisible.** A request is abandoned after ten minutes with no countdown, no warning, and
no stated behaviour at the moment it expires — including what happens to in-flight file writes in the tweak
surface. *Recommend:* decide the expiry behaviour explicitly and, at minimum, warn near the end.

**10.30 — Two divergent implementations of the pick surface exist.** One shows no chosen-indication at all
(carried by the option's own treatment alone), offers none of the three exits, caps its list at a fixed height,
and conveys one line of hints. *Recommend:* pick one canonical behaviour — the one specified in §5.2 — and
bring the other to it.

*(10.1, 10.19, 10.27 and 10.28 were purely visual defects in an earlier document. They are now stated as
positive requirements on every style, in §7.4.)*
