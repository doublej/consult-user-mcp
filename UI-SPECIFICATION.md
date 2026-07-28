# Consult User MCP — User Interface Specification

**Scope:** every surface the person sees — the seven dialog surfaces and the layout sketch editor.
**Status:** descriptive of the shipping interface, with reconciliations and open decisions marked.

---

## 0. How to read this

This document specifies **what the interface is and does**, not how to build it. It is written so that a
designer and an engineer who have never seen the product can recreate every surface on any platform, in any
language, with any rendering technology, and arrive at something a current user would recognise as the same
product.

**It deliberately contains no** framework names, platform APIs, architectural patterns, storage or transport
mechanics, file layouts, or code identifiers. Where the current implementation makes a choice that is
invisible to the person using it, that choice is absent here on purpose — it is the rebuilder's to make.

**It deliberately does contain** exact dimensions, colours, timings, copy strings, keyboard bindings and
state rules. These are not implementation details; they are the interface.

### Conformance language

| Word | Meaning |
|---|---|
| **MUST** | Required. A build without it is not this product. |
| **SHOULD** | Strongly expected. Deviating needs a reason. |
| **MAY** | Genuinely optional. |
| ⚠️ | A known defect or contradiction in the current interface. §10 carries the full list and a recommendation for each. |

### Units

All dimensions are **layout units (`u`)**. One unit is one point of the interface's own coordinate space and
scales with the display's pixel density. Radii, spacing, type sizes and stroke weights all scale together.

> The current implementation states dialog metrics in points and sketch-editor metrics in pixels. **They are
> the same unit.** A 120u tool rail and a 120u pane column MUST render identically.

### Colour notation

Opaque colours are written as hex (`#598CFF`). Translucent colours are written as `RGB r,g,b at N%`.

### Two audiences, two vocabularies

- **The person** — the human being interrupted. Everything in §2–§6 is about them.
- **The calling agent** — the AI assistant that requested the interruption. §7 is the surface it drives.
  Text the agent receives is never shown on screen and is collected separately in §9.3.

---

## 1. What this interface is

An AI assistant working on the person's behalf sometimes needs a decision, a secret, a preference, or a
judgement call it cannot make alone. This interface is the channel for that: a small floating card that
appears over whatever the person is doing, asks exactly one thing, and gets out of the way.

The whole design follows from one tension:

> **The interruption must be cheap to answer and cheap to refuse.**

Every structural decision serves that. The card is small and always in the same place, so it costs nothing to
locate. It is entirely keyboard-driven, so answering never requires reaching for the pointer. It opens inert
for two seconds, so a keystroke in flight cannot answer it by accident. And it offers three ways out that are
not "answer" and not "cancel" — postpone it, annotate it, or reject the *shape* of the question — so the
person is never forced to choose between a bad answer and no answer.

### 1.1 The eight surfaces

| # | Surface | Asks for | Blocks the agent |
|---|---|---|---|
| 1 | **Confirm** | A yes or a no | Yes |
| 2 | **Pick** | One option from a list, or several | Yes |
| 3 | **Text** | A typed line, optionally masked | Yes |
| 4 | **Form** | Several questions, one screen at a time | Yes |
| 5 | **Notify** | Nothing — it announces | No |
| 6 | **Response preview** | Nothing — it shows what is about to be sent | No |
| 7 | **Value tweak** | Numbers, tuned live against real files | Yes |
| 8 | **Layout sketch** | A screen layout, dragged into shape | Yes |

Surfaces 1–4 and 7 are **interactive**: they share one shell, one keyboard model, one outcome model, and the
three escape hatches. Surfaces 5–6 are **transient popups**: same visual family, no controls, self-dismissing.
Surface 8 is a **workspace**: its own window model, resizable, with undo.

### 1.2 The interruption contract

An interactive surface is shown only when all of these hold:

1. No quiet period ("snooze") is running.
2. Away mode is off.
3. No other interactive surface is already on screen.

If any fails, **nothing is drawn** and the agent is told what to do instead (§5.7). Notifications are exempt
from 1 and 2 and MAY appear on top of an open dialog.

---

## 2. Foundations

### 2.1 Colour

Colour is defined by **role**, never by literal. Every surface MUST express every colour it uses as one of
these roles, and every role MUST exist in every palette. No surface may use a colour that only works in one
palette.

| Role | Used for |
|---|---|
| `window` | The card's own fill |
| `surface` | Raised elements on the card: choice rows, chips, pills, the tool strip band |
| `surface-hover` | Pointer over a raised element |
| `surface-pressed` | Pointer held down on a raised element; also "selected" for tool chips |
| `field` | The inside of a text input; also the inline-code highlight |
| `border` | Every hairline outline |
| `text-primary` | Titles, choice labels, values, button labels on secondary buttons |
| `text-secondary` | Body copy, descriptions, tool-strip labels |
| `text-muted` | Hints, badges, placeholders, disabled labels |
| `accent` | Every interactive signal: primary button, focus, selection, links, active state |
| `accent-pressed` | Primary button held down |
| `positive` | Success signalling |
| `negative` | Destructive actions and the report control's hover state |

#### Palette: **Midnight** (default)

| Role | Value |
|---|---|
| `window` | `#1A1A1F` at 98% opacity |
| `surface` | `#24242A` |
| `surface-hover` | `#2E2E38` |
| `surface-pressed` | `#383847` |
| `field` | `#29292E` |
| `border` | `#595959` |
| `text-primary` | `#FFFFFF` |
| `text-secondary` | white at 75% |
| `text-muted` | white at 50% |
| `accent` | `#598CFF` |
| `accent-pressed` | `#4073E6` |
| `positive` | `#4CD98C` |
| `negative` | `#F25966` |

#### Palette: **Sunset** (warm alternative)

| Role | Value |
|---|---|
| `window` | `#1F140F` at 98% opacity |
| `surface` | `#2E1F1A` |
| `surface-hover` | `#3D291F` |
| `surface-pressed` | `#4D3324` |
| `field` | `#241A14` |
| `border` | `#664D40` |
| `text-primary` | `#FFF5EB` |
| `text-secondary` | `#D9BFA6` |
| `text-muted` | `#9E8570` |
| `accent` | `#FF8C40` |
| `accent-pressed` | `#E67326` |
| `positive` | `#F2BF4D` (gold) |
| `negative` | `#F2594D` |

Both palettes are dark. ⚠️ There is no light palette; the host system's light appearance is ignored on every
surface except the sketch editor. See §10.1.

#### Accent tint ladder

Accent is used at reduced opacity to signal state without shouting. These steps are canonical:

| Opacity | Where |
|---|---|
| 5% | Edited code line in the tweak console |
| 8% | Note-pane subject card fill |
| 10% | Detected-stack badge fill; "Show edits" active fill |
| 12% | Report pill hover fill (uses `negative`) |
| 15% | Header icon medallion; active tool chip; selected "Other" card; edited-number chip |
| 18% | Compact-popup icon medallion; per-question note button with a note |
| 20% | Destructive button fill at rest |
| 25% | Selected choice card fill; note subject card border |
| 30% | Destructive button hover; report pill hover border |
| 35% | Text-selection highlight |
| 40% | Destructive button pressed |
| 60% | Hint-chip border; note-editor border |

### 2.2 Typography

One ramp. Anything off it is legacy and MUST NOT be used for new elements.

| Size | Weights in use | Applied to |
|---|---|---|
| **24u** | semibold | Header medallion glyph |
| **18u** | bold | Dialog title; sketch editor title |
| **15u** | semibold / medium / regular | Primary button label (semibold), secondary button label (medium), text-field text and placeholder (regular), compact-popup title (bold) |
| **13u** | regular / semibold | Body copy, note editor text, sketch description (regular); snooze chip label, compact-popup medallion glyph (semibold) |
| **12u** | regular / medium | Choice description (regular); tool-strip labels, snooze prompt, step counter, tweak card label, hover tooltip (medium) |
| **11u** | regular / medium / semibold / bold | Tweak units, error text, group headings, console header, range fields; note-pane caption (bold, uppercase, 1.4u tracking) |
| **10u** | regular / medium / semibold | Hint labels (regular); hint key chips, project badge, report pill, stash chips (medium); section labels uppercase (semibold) |
| **9u** | medium | Utility-row glyphs |

Permitted exceptions, for optical reasons only: **14u semibold** for choice-card labels and the note-pane
subject; **17u** for the alternative style's title.

Additional rules:
- Inline code renders one step smaller than its surrounding text, in a monospaced face, on a `field`-coloured
  highlight.
- Body copy sets its lines **1.45×** its own size apart.
- The dialog title is tracked about **1% tight**.
- Monospaced faces are used for: the tweak numeric readout, tweak group headings, the console header and code
  lines, tweak range fields, and — in the alternative style — the kicker, ordinal gutter and status line.

### 2.3 Spacing

Layout spacing MUST use: **4 · 8 · 12 · 16 · 20 · 28**.
Values of **2 · 3 · 6 · 10** are permitted only *inside* a control's own padding.

Canonical applications:

| Value | Where |
|---|---|
| 28 | Above the header medallion |
| 20 | Card side padding for header, content, tool strip and footer; footer vertical padding is 16 |
| 16 | Below the medallion; footer vertical padding; note-pane side padding |
| 12 | Utility-row inset; between tool chips; below the header block; tool-strip vertical padding is 8 |
| 10 | Between the two action buttons |
| 8 | Between choice cards; between hint pairs; between hint row and button row; card shadow gutter |
| 4 | Title to body; label to description |

### 2.4 Radii

| Radius | Applied to |
|---|---|
| **16u** | The card itself; the report overlay's inner card |
| **12u** | Action buttons (and their focus ring); the tweak console panel |
| **10u** | Choice cards, text fields, the note subject card |
| **8u** | Tool chips, snooze chips, the note editor, small outline buttons |
| **6u** | Tweak parameter cards, tooltips, the stack badge, sketch blocks |
| **4u** | Multi-select checkbox; the tweak settings overlay |
| **2u** | Slider track; the edited-number highlight chip |
| **1.5u** | Cooldown progress bar ends |
| capsule | Project badge, report pill, hint key chips, grid-size pill |

### 2.5 Borders, shadows, opacity

- **1u** is the default hairline: secondary buttons, chips, badges, cards, the note editor.
- **2u** marks *selected* on a choice card and *focused* on a text field.
- **0.5u** is used only in dense contexts: tweak card outlines, grid lines, the console panel border.
- **3u** is a vertical accent rail (note subject card).

| Opacity | Meaning |
|---|---|
| 50% | A disabled control's fill; muted label |
| 40% | A disabled "Clear" button; a control during the opening cooldown (label at 50%) |
| 70% | An errored tweak card |
| 30% | Content dimmed behind an inline overlay |

Shadows:
- Every card carries a soft drop shadow; the **8u gutter** between the painted card and the window edge exists
  so it is never clipped.
- The report overlay's inner card: black at 35%, 20u blur, offset 10u down.
- The tweak console panel: black at 30%, 12u blur, offset 4u down.

### 2.6 Motion

| Duration | Curve | Applied to |
|---|---|---|
| **0.12s** | — | Hover feedback (in practice an immediate repaint) |
| **0.15s** | ease-out | Card-level micro-transitions; scrolling a focused item to centre; stash drop-target highlight (ease-in-out) |
| **0.20s** | ease-out | Every pane slide, tray expand, overlay fade, and every window resize |

| Delay | Event |
|---|---|
| **0.10s** | Focus lands after a surface appears, or after an overlay closes |
| **0.15s** | Focus lands after a step transition |
| **0.25s** | Focus lands after a region expands |
| **0.30s** | Demonstration mode auto-reveals a pane or tray |

Rules:
- Direct manipulation (dragging a window, a slider, a sketch block; resizing) tracks the pointer **1:1 with no
  easing**. Snapping happens on release, not during.
- The cooldown progress bar fills smoothly and continuously with no visible stepping.
- **Reduced motion:** when the host system requests reduced motion, every slide, fade and expand becomes an
  instant change. Layout and end state are identical; only the transition is removed. Window resize still
  occurs; the cooldown bar still fills.

### 2.7 Focus and selection are separate channels

This is a load-bearing rule. A choice card can be **focused and unselected**, **selected and unfocused**, or
both at once, and all four combinations MUST be visually distinguishable.

- **Selection** changes fill and border: accent at 25% fill, border thickens to 2u accent, indicator fills.
- **Focus** draws a ring *outside* the control's own outline, following that control's corner radius.

⚠️ The current interface delegates the focus ring entirely to the host system and specifies no colour,
thickness or offset. On any other platform nothing would be drawn. **A rebuild MUST define it as a product
token.** Recommended: a **3u ring in `accent` at 60% opacity, offset 2u outside the control's outline**,
following the control's own radius (12u on buttons, 10u on choice cards and fields, 8u on chips, capsule on
pills), drawn *on top of* the selected treatment so both read at once. Focus MUST NOT be signalled by a fill
change alone.

### 2.8 Iconography

Each surface is identified by one glyph in its header medallion. The medallion is a **56×56 circle filled with
its glyph's colour at 15% opacity**, containing the glyph at **24u semibold** in the full colour. Compact
popups use a **28×28 circle at 18%** with a **13u semibold** glyph.

| Glyph | Surface |
|---|---|
| Question mark | Confirm |
| Bulleted list | Pick, single-select |
| Checklist | Pick, multi-select |
| Text cursor | Text, plain |
| Padlock | Text, masked |
| Numbered list | Form |
| Horizontal sliders | Value tweak |
| Bell | Notify |
| Eye | Response preview |
| Ladybug | Report overlay, step 1 (drawn in `negative`) |
| Clipboard | Report overlay, step 2 |

Control glyphs: clock-with-circular-arrow (snooze), speech bubble outline/filled (feedback), two crossing
arrows (ask differently), folder (project badge), ladybug (report pill), code brackets (show edits), gear
(slider settings), counter-clockwise arrow (revert).

---

## 3. The window model

### 3.1 Card anatomy

Every surface is a **borderless floating card**: 16u corners, no title bar, no window controls, no resize
handles, a real drop shadow, and an 8u transparent gutter between the painted card and the window's own edge.

Regions, top to bottom:

```
┌─────────────────────────────────────────┐
│  [Report]                    [ project] │  ← utility row      (12u inset)
│                                         │
│                  ( ◉ )                  │  ← header medallion (28u above)
│                 Title                   │     title           (16u below medallion)
│              body copy…                 │     body            (4u below title)
│                                         │
│  ┌───────────────────────────────────┐  │  ← content region   (20u sides)
│  │  the surface's own body           │  │     scrolls if it can outgrow the cap
│  └───────────────────────────────────┘  │
│                                         │
│▓ Snooze   Feedback   Ask differently  ▓ │  ← tool strip       (full-bleed band)
│                                         │
│   ⏎ submit  Esc cancel  S snooze  …     │  ← hint strip
│  ┌──────────────┐ ┌──────────────────┐  │  ← action buttons   (48u tall)
│  │    Cancel    │ │     Submit ⏎     │  │
│  └──────────────┘ └──────────────────┘  │
└─────────────────────────────────────────┘
```

The tool strip is the only region that is **full-bleed** — its `surface`-coloured band touches both card
edges. Everything else respects the 20u side gutter.

### 3.2 The sizing law

This is the single most consequential structural rule in the product.

> **A card is measured once, when it appears. Its width is then frozen for the rest of its life. Only its
> height reflows.**

The reason is directly visible: if width were recomputed from wrapped text, text would rewrap, which would
change the measured width, which would rewrap the text. The card would oscillate. So it does not.

**On appearance:**

- **Width** = the content's natural width, floored at the surface's minimum, capped at *screen width − 80u*.
- **Height** = the content's height once wrapped to that width, floored at 300u, capped at **85%** of the
  usable screen height (**45%** for the two compact popups).
- The window is 16u larger than the card in each dimension (the 8u gutter on each side).

**Afterwards:**

- Height reflows freely whenever content changes and animates over 0.20s ease-out.
- Width changes for exactly one reason: the note pane attaching or detaching, which changes it by exactly the
  pane's fixed width.
- The same request MUST always produce a card of exactly the same size. Nothing about its dimensions may
  depend on what was shown before it.
- The card ignores content changes smaller than one unit — it does not twitch or re-anchor below that
  threshold.

**Minimum widths and heights** are per surface and per presentation style — see §8.3.

**Overflow.** When content exceeds the height cap, the card stops growing and one designated region scrolls
internally. The header, tool strip and footer never scroll away.

| Surface | Scrolling region |
|---|---|
| Pick | The choice list |
| Form | The question area |
| Value tweak | The parameter list |
| Notify | The message |
| Response preview | The body |
| **Confirm** | ⚠️ **none — a long body is clipped** |
| **Text** | ⚠️ **none — a long prompt is clipped** |

⚠️ See §10.2. Both SHOULD gain the same internal scroll region.

### 3.3 Placement and anchoring

Interactive surfaces are placed once, on appearance:

- **Vertically:** the card's top edge sits **80u below the top of the usable screen area** (the screen minus
  any always-present system chrome).
- **Horizontally:** `left` → 40u in from the left edge · `right` → 40u in from the right edge · `center` →
  horizontally centred.

**Anchoring under resize:** the **top edge is always fixed** — the card grows and shrinks downward. Horizontally,
a left-placed card keeps its left edge, a right-placed card keeps its right edge, a centred card keeps its
centre.

Placement also decides **which side the note pane opens on** — always away from the wall the card is against:

| Card position | Note pane side |
|---|---|
| Left | Right |
| Right | Left |
| Centre | Whichever side has more room (compare card centre to screen centre) |
| Indeterminate | Right |

Compact popups (notify, response preview) read the person's **saved placement preference only**; a per-call
position is accepted by the caller contract but never applied to them. They fall back to the right edge when
no preference can be read.

⚠️ **Multi-display is unspecified** — every surface is placed on one primary display regardless of where the
person is working. See §10.5.

### 3.4 Dragging

Pressing and dragging the card's **empty background** moves the window, and it stays wherever it is dropped.

Pressing any **control** — an action button, a choice row, a text field, the note editor and its scroll area,
a slider, the parameter list, a tool chip — activates that control and never moves the window.

Clicking an inactive card brings it to the front and gives it keyboard focus first, then delivers the click.

### 3.5 Stacking

Interactive surfaces float above other applications by default (a person-level preference, on by default; when
off they behave as ordinary windows). Notifications float **unconditionally** and appear without stealing
keyboard focus from whatever the person was doing.

The tweak console panel shares the tweak pane's stacking level exactly.

---

## 4. Shared chrome

Everything in this section appears on more than one surface and MUST behave identically wherever it appears.

### 4.1 Utility row

Runs across the very top of every surface, inset 12u from the top and both sides. A flexible gap pushes its two
items to opposite ends.

**Report pill** (left). Ladybug glyph at 9u medium + the word `Report` at 10u medium, in `text-muted`, padded
7u/3u, in a capsule outlined 1u in `border` at 40%, transparent fill.
- Hover: glyph, label and outline turn `negative`; fill becomes `negative` at 12%, outline at 30%.
- Tooltip: `Report a bug or suggestion`.
- Behaviour differs by surface — see §4.13.

**Project badge** (right, only when a project path is supplied). Filled-folder glyph at 9u + the **final path
segment only** at 10u medium, single line, **middle-truncated**, in `text-muted`, padded 8u/4u, on a
`surface` capsule outlined 1u in `border` at 50%. Sized to content; never stretched.
- Tooltip: the full path.
- Omitted entirely when no path is known, leaving the report pill alone in the row.

⚠️ The sketch editor renders no project badge. See §10.6.

### 4.2 Header

Medallion (§2.8) → title → body.

**Title.** 18u bold, `text-primary`, **horizontally centred**, wraps to unlimited lines, never truncates.

**Body.** 13u, `text-secondary`, 4u below the title, **selectable and copyable**, ideal wrap width **380u** but
allowed to stretch to the card width.

**The alignment rule.** Body copy is **centred when it is a single block** and **left-aligned the moment it
contains a line break**. This makes one-line questions read as headlines and multi-paragraph or list-like text
read as prose. It applies to every surface's body.

### 4.3 Inline text formatting

Agent-supplied prose renders with a small fixed set of inline formats. Markers are consumed and never shown
literally.

| Written as | Renders as |
|---|---|
| `**bold**` | Bold |
| `*italic*` | Italic (single asterisks not adjacent to another asterisk) |
| `` `code` `` | Monospaced, one type step smaller, on a `field`-coloured highlight |
| `[label](url)` | `accent`-coloured clickable text showing only the label; opens in the default browser |

Everything else renders literally. **Block-level formatting is not interpreted** — headings, bullet lists,
block quotes, fenced blocks and tables appear as raw characters. A malformed link stays literal. Formats are
applied in the order links → bold → italic → code.

Escaped newline and tab sequences in the incoming text are converted to real line breaks and tabs before
display — which means a body written with escaped newlines flips to left alignment.

**Where formatting applies:** the body of every *interactive* surface, the form's question text, and the note
pane's quoted subject card.
**Where it does not:** ⚠️ the notification body and the response-preview body render exactly the characters
supplied. See §10.3.

### 4.4 Tool strip

A full-bleed `surface`-coloured band between the content and the footer, padded 20u/8u, holding three
left-aligned chips 12u apart with empty space after them.

Each chip: a 12u glyph + a 12u medium label 6u apart, padded 12u/6u, 8u radius, transparent at rest.

| Chip | Glyph | Rest | Hover | Active |
|---|---|---|---|---|
| `Snooze` | clock + arrow | `text-secondary` | `surface-hover` fill | `accent` label on `accent` at 15% |
| `Feedback` | speech bubble — **outline when no note, filled once one exists** | `text-secondary` | `surface-hover` fill | never enters an active state |
| `Ask differently` | two crossing arrows | `text-secondary` | `accent` label on `surface-hover` fill | — |

Only **Snooze** shows an active state. The **only** signal that a note exists is the bubble glyph switching
from outline to filled.

⚠️ Asymmetry: the `S` key **only opens** the snooze tray; it never closes it. Clicking the chip **toggles** it.
Escape collapses it.

### 4.5 Snooze tray

Expands directly above the tool strip, inside the same band, padded 20u/12u.

- Prompt: `Ask me again in:` at 12u medium, `text-secondary`, left-aligned, 8u above the chip row.
- Five duration chips 8u apart, each **48×36u**, 8u radius, `surface` fill, 1u `border`, label 13u semibold in
  `text-primary`.
- Hover: fill becomes solid `accent`, label turns white.

Durations: **`1m` · `5m` · `15m` · `30m` · `1h`**.

Choosing one closes the surface immediately and starts a **global quiet period** of that length (§5.7).

⚠️ The chips are pointer-only on some surfaces — a keyboard user can open the tray and then be unable to pick.
See §10.7.

### 4.6 Ask-differently menu

A compact floating list anchored about 20u in from the card's left edge and 50u up from its bottom, sized to
its longest entry. Entries highlight under the pointer; Up/Down move the highlight, Return chooses, Escape
dismisses with no effect. It overlays the card and never resizes it.

Six entries, fixed order:

`Confirmation` · `Single Select` · `Multi Select` · `Text Input` · `Password` · `Wizard Form`

The entry matching the surface currently on screen is **check-marked and disabled**, so there is always
exactly one checked row and the person can always see which shape they are in.

Choosing an entry closes the surface immediately and asks the agent to re-pose the same question in that
shape. **Any in-progress answer and any drafted note are discarded** (§5.8).

### 4.7 Note pane

A side pane where the person writes a free-text remark that travels back *alongside* the answer.

**Width is exactly 360u and never flexes.** Opening it widens the whole window by that amount; closing it
narrows it back. It never stretches, never shrinks, and its content never spills past the card's rounded
corners. A 1u divider in `border` at 50% separates it from the card. Fill is `surface`.

**Header** (padded 16u sides, 14u top, 10u bottom): a speech-bubble glyph at 11u semibold in `accent`, then the
caption in **UPPERCASE at 11u bold `accent` with 1.4u tracking**, then a **22×22** circular close button on the
far right holding an ✕ at 11u semibold in `text-muted` on a `surface-hover` fill at 50%.

**Subject card** (conditional): a 3u `accent` vertical rail, then the text being annotated at 14u semibold in
`text-primary`, left-aligned, inside a 10u-radius box filled `accent` at 8% with a 25% `accent` border. Capped
at **3 lines / 80u** with tail truncation.

**Editor section:** the label `YOUR NOTE` in uppercase at 10u semibold `text-muted`, then a multi-line editor —
minimum **180u tall**, 8u radius, `field` fill, 1u border at 60%, 10u inner inset, 13u text, `accent` caret,
undo supported, its own scrollbar appearing only when needed.

**Footer** (16u sides, 12u vertical): `Clear` on the left, `Close` on the right, both 12u medium
`text-secondary` in an 8u-radius 1u-outlined pill padded 12u/6u.

**Caption and subject by context:**

| Opened from | Caption | Subject card |
|---|---|---|
| A single-question surface | `NOTE ON THIS DIALOG` | **Hidden** — the question is already visible right beside it |
| A form's Feedback chip | `NOTE ON THIS FORM` | The form's intro text; **hidden if there is none** |
| A form's per-question bubble | `NOTE ON THIS QUESTION` | **Always shown** — the question's own text; falls back to the literal `(this question)` if that text cannot be resolved |

**Behaviour:**

- The editor **holds the caret from the first frame of the opening animation**, so a key pressed while the pane
  is still sliding is typed into the note, not treated as a shortcut.
- `Clear` empties the draft in place; it is **disabled and dimmed to 40%** while the draft is empty.
- `Close`, the ✕, Escape, or re-triggering the same target all close the pane and **preserve the draft**.
  Reopening restores it and re-focuses the editor.
- Triggering a *different* note target while open **swaps the pane's contents** rather than closing it.
- A **whitespace-only draft counts as empty** everywhere: the chip stays outlined, `Clear` stays disabled, and
  nothing is delivered.
- Tooltips: ✕ → `Close pane (Esc)`; footer button → `Close pane (note is preserved)`.

### 4.8 Per-question note button

Only in the form. A **28×28 circular button** with a solid speech-bubble glyph at 14u semibold, sitting 8u to
the right of the question text and top-aligned with its first line. It never shrinks and never moves as the
question wraps.

| State | Treatment | Tooltip |
|---|---|---|
| No note | `text-muted` glyph on `text-muted` fill at 6% | `Add a note for the agent` |
| Hovered | same glyph, fill rises to 15% | — |
| Has a note | `accent` glyph on `accent` fill at 18%, plus a 1u `accent` ring at 90% | `Edit note` |

The glyph is **always** the solid bubble — state is carried by colour and ring, never by swapping the icon.

### 4.9 Keyboard hint strip

A single non-wrapping row of key/label pairs 8u apart, 4u vertical padding, sitting 8u above the button row.

Each pair: a **key chip** — the key name at 10u medium in a rounded face, `text-secondary`, padded 4u/2u, in a
capsule filled `surface` and outlined 1u in `border` at 60% — followed 3u later by the **label** at 10u regular
in `text-muted`, always one line.

Contents by surface (the three tool hints `S snooze` · `F feedback` · `A ask differently` always trail):

| Surface | Leading hints |
|---|---|
| Confirm | `⏎ confirm` · `Esc cancel` |
| Pick | `↑↓ navigate` · `Space select` · `⏎ done` |
| Text | `⏎ submit` · `Esc cancel` |
| Form | `↑↓ navigate` · `Space select` · `⏎ next` (`⏎ done` on the last step) |
| Value tweak | `↑↓ navigate` · `←→ adjust` · `⏎ save` or `⏎ cancel` · `Esc cancel` |
| Report overlay | step 1 `⏎ next` · step 2 `⏎ copy & open` |

The strip is what forces the card's minimum width — it must fit on one line.

⚠️ The strip is static and advertises shortcuts that are currently suppressed. See §10.4.

### 4.10 Action buttons

A row of one to three buttons, 10u apart, that together fill the card width — each stretches to an **equal
share** regardless of label length. Every button is **48u tall** with a **12u radius**. Labels are centred at
15u and **truncate with an ellipsis** inside a 12u inner inset rather than wrapping or widening the card.

| Variant | Fill | Label | Border | Hover | Pressed |
|---|---|---|---|---|---|
| **Primary** | solid `accent` | white, 15u semibold | none | `accent` blended 10% toward white | `accent-pressed` |
| **Secondary** | `surface` | `text-primary`, 15u medium | 1u `border` | `surface-hover` | `surface-pressed` |
| **Destructive** | `negative` at 20% | `negative`, 15u medium | none | 30% | 40% |
| **Disabled** | `surface` at 50% | `text-muted` | — | none | none |

Rules:
- The primary button appends **` ⏎`** to its own label — but **only while enabled**. A disabled primary drops
  the suffix, so the affordance never promises a key that will not work.
- A disabled button is **not focusable and is skipped by Tab**, not focused-and-inert.
- Activation requires press *and* release inside the same button; dragging out cancels it.
- The pointer becomes a pointing hand over any button.
- Ordering is always **secondary first, primary last** (Cancel/Back on the left, Confirm/Done/Submit/Next on
  the right).

The **destructive** variant exists in the system but ⚠️ no surface uses it and no caller can request it, so a
"delete 47 files" confirmation looks identical to a harmless one. See §10.8.

### 4.11 Text field

The shared single-line input, used for text answers, masked answers, the "Other" custom answer and the report
description.

**48u tall**, 10u radius, `field` fill, text inset 14u each side and vertically centred, text at 15u
`text-primary`, placeholder at 15u `text-muted` at 90%.

| State | Treatment |
|---|---|
| Rest | 1u `border` |
| Focused | **2u `accent`** border; `text-primary` caret; selection highlighted with `accent` at 35% |
| Masked | Renders bullets instead of characters |
| Overflow | Text scrolls horizontally; the field never grows |

- Clicking anywhere in the field, including its padding, places the caret.
- A prefilled value opens **with its text selected**, so the first keystroke replaces it. This is required
  behaviour, not a host-platform accident.
- Standard cut / copy / paste / select-all are available.
- No length limit is enforced and no trimming is applied on submit.

### 4.12 Choice card

The selectable row used by the pick surface and by every choice step of the form.

Rounded rectangle, **10u radius**, full list width, **minimum 48u tall**.

- **Label** 16u from the left: 14u semibold `text-primary`, wraps to unlimited lines, never truncates.
- **Description** (optional) directly beneath with a 4u gap: 12u regular `text-secondary`, wraps.
- Label and description are one block, vertically centred.
- **Selection indicator** 24×24, pinned 16u from the right edge, vertically centred, 12u from the text column.
  The text column is therefore *card width − 68u*.
- Natural height = label height + 24u, plus (description height + 4u) when present, floored at 48u.

| State | Fill | Border |
|---|---|---|
| Default | `surface` | 1u `border` |
| Hover | `surface-hover` | 1u `border` |
| Pressed | `surface-pressed` | 1u `border` |
| **Selected** | `accent` at 25% | **2u `accent`** |
| Focused | unchanged | unchanged — the ring is drawn outside (§2.7) |

There is no disabled state; every listed option is always selectable.

Cards always stretch to the full list width — a one-character label still produces a full-width card. Long
labels wrap and grow the card, producing a deliberately uneven stack.

⚠️ The card **label and description are drawn text and cannot be selected or copied.** Only body/prompt text
and form question text are selectable.

#### Selection indicator

| Mode | Unselected | Selected |
|---|---|---|
| **Single** | 24u circle drawn as a 2u ring in `border` | `accent` ring + a solid **12u** `accent` centre dot |
| **Multi** | 24u rounded square (4u corners) drawn as a 2u outline in `border` | Solid `accent` fill + a white checkmark stroked 2u with round caps and joins, spanning ~10u |

The indicator is not a separate click target — the whole card is. State changes repaint immediately: no
check-draw animation, no bounce.

The shape is the **only** cue distinguishing one-of from many-of, besides the header glyph.

#### The "Other" card

Appended as the **last item** of every choice list unless the caller explicitly turns it off. Present by
default.

- Top row: the fixed label `Other` at 14u semibold on the left, a flexible gap, the same selection indicator on
  the right.
- 6u gap, then an inline text field spanning the card's inner width, minimum 36u tall.
- Placeholder: `Type your answer...`
- Card padding 16u sides, 10u vertical.

Behaviour:
- Clicking anywhere on the card selects it **and** puts the caret in its field.
- Typing any character auto-selects the card.
- In single-select, selecting it clears every other selection, and selecting any listed option clears it (the
  typed text stays visible but is no longer the answer).
- In multi-select it toggles independently and combines freely.
- **Selected-but-empty counts as unanswered** — the primary button stays disabled unless other options are also
  checked.
- The word `Other` is **never** returned as the answer. Only the typed text is.
- Text is **not trimmed** before being judged non-empty, so a single space counts as an answer.

⚠️ The "Other" card currently uses a 15% selected tint (vs 25%) and has no hover or pressed treatment, unlike
every ordinary card. See §10.9.

### 4.13 Report an issue

**On an interactive surface**, the report pill first captures a picture of the card as it currently looks, then
covers it with a two-step overlay: a **black scrim at 55%** with a smaller card floating on top, inset 16u,
16u radius, `window` fill, shadow black at 35% / 20u blur / 10u down. While it is up the surface beneath is
dimmed and inert, and every key except Escape goes to the overlay.

**Step 1 — describe.**
- Header: `negative`-tinted ladybug medallion; title `Report Issue`; body `Describe the problem below.`
- Field group: label `What happened?` at 12u medium `text-secondary`, 6u above a 48u text field with the
  placeholder `Briefly describe the issue...`
- Footer: hint `⏎ next`, buttons `Cancel` (secondary) and `Next →` (primary).
- `Next →` is **disabled while the description is empty or whitespace-only**, and Return does nothing.
- The description is trimmed before use.

**Step 2 — screenshot consent.**
- Header: `accent`-tinted clipboard medallion; title `Save Screenshot?`; body `Can we save a screenshot of this
  dialog to your clipboard? You can paste it directly into the GitHub issue with ⌘V.`
- Footer: hint `⏎ copy & open`, buttons `Skip` (secondary) and `Yes, Copy Screenshot` (primary).
- Both always enabled.

**Transitions.** The overlay cross-fades over 0.20s ease-out. Step 1 → 2 slides the outgoing card left while
fading and the incoming card in from the right, 0.20s ease-out. Escape closes the overlay and *only* the
overlay; focus returns to the surface 0.10s later.

**The outcome** is that the default browser opens a pre-filled issue page. That page *is* the confirmation —
there is no in-app success message. The body carries, in order: a Description section with the typed text; a
section naming the request kind and reproducing it in a monospaced block; an Environment section listing the
project and the client; a Screenshot placeholder line if consent was given; and a credit line. The title is the
first 72 characters of the description. The issue is pre-labelled as a bug.

**On other surfaces the pill behaves differently:**

| Surface | Behaviour |
|---|---|
| Confirm, Pick, Text, Form, Value tweak | Two-step overlay, screenshot offered |
| Notify, Response preview | **Opens the issue page immediately** — no overlay, no description, no screenshot |
| Layout sketch | **Opens the issue page immediately**, seeded with a `Layout editor: ` title prefix and an Environment section naming the layout editor |

⚠️ Nothing on screen distinguishes these. See §10.10.

---

## 5. The interaction model

These laws apply to every interactive surface. They are the reason the product feels like one thing.

### 5.1 The complete keyboard map

| Key | Does | Active when |
|---|---|---|
| `Return` | The surface's primary action | Always, unless a rule below overrides |
| `Escape` | Unwinds exactly one layer (§5.3) | Always |
| `Space` | Toggles the focused choice card, or presses the focused button | Not while a caret is in a text field |
| `↑` / `↓` | Move focus between **content** elements, wrapping at both ends | Not while typing |
| `←` / `→` | Form: previous / next step. Value tweak: decrease / increase the focused value by one step | Not while typing |
| `Tab` / `Shift+Tab` | Cycle focus through **everything**, including buttons | Always |
| `S` | Opens the snooze tray | §5.2 |
| `F` | Opens the note pane | §5.2 |
| `A` | Opens the ask-differently menu | §5.2 |
| `Modifier+F` | Opens the note pane **regardless of focus** | Always |
| Cut / copy / paste / select-all | Standard editing | In any text field |

Modifier keys are written with the host platform's own glyphs; the binding is the platform's primary modifier
plus the named key.

**Arrow keys never reach the action buttons.** Buttons are reachable by Tab alone. This is deliberate — it
keeps arrow navigation inside the answer, where it belongs.

### 5.2 The shortcut suppression law

Plain single-letter shortcuts (`S`, `F`, `A`) are **suppressed** in three situations:

1. While a caret sits in **any** text field, including the note editor and including the note pane's opening
   animation.
2. While the note pane is open.
3. During the opening cooldown.

In all three the letter is typed literally. **The modifier-chorded feedback shortcut survives all three** — it
exists precisely because a bare `F` is unreachable on a text surface.

`Return`, `Tab`, the arrow keys and modifier chords always route to the surface. `Return` has one exception:
inside the note editor it inserts a newline.

### 5.3 The Escape unwinding law

Escape peels back **exactly one layer per press**, in this fixed order. It never skips a layer and never closes
two at once.

```
1. Report overlay open?      → close the overlay          (the surface is untouched)
2. Note pane open?           → close the pane             (the draft is preserved)
3. Snooze tray expanded?     → collapse the tray          (nothing is snoozed)
4. otherwise                 → cancel the surface
```

### 5.4 The Return law

Return first attempts the surface's **primary action**. If the primary action is unavailable because the
current answer is incomplete, the key **falls through to the focused control** — so a focused Back button
activates and a focused text field receives it. When nothing is focused, the key is consumed and nothing
happens.

### 5.5 The focus order law

- Focus order is **top-to-bottom by on-screen position**; within a row it is **left to right**. It wraps.
- It follows *visual* position, not creation order. Controls that appear or disappear join or leave the ring
  in their on-screen position.
- Disabled controls are skipped entirely.
- On appearance, focus lands on the **first content element — never a button** — 0.10s later. After a form step
  advances, 0.15s later. After an overlay closes, 0.10s later.
- The **confirm surface registers no content elements**, so nothing is focused on open and no ring is visible
  until the person presses Tab. `↑`/`↓` do nothing there. Return still confirms, because the primary action is
  bound at the surface level rather than to a focused control. This is deliberate: focusing the confirm button
  on open would let a stray Space answer the question the instant the cooldown ends.

### 5.6 The opening cooldown

For the first **2.0 seconds** after an interactive surface appears (adjustable from 0.1s to 3.0s, and
switchable off entirely):

- Every action button renders at **40% background opacity with its label at 50%**.
- A **3u-tall progress bar with 1.5u rounded ends** fills left to right along the bottom inside of each
  button — inset 8u from each side, 6u above the button's bottom edge, **white at 70%** on the primary button
  and **`accent` at 60%** elsewhere. It fills smoothly and continuously.
- Clicks are swallowed. `Return`, `Escape`, `Space`, `S`, `F` and `A` all do nothing.
- **Typing is never blocked.**

Escape is blocked at two independent levels during the cooldown, so it is inert even when the report overlay is
open. Nothing on screen indicates the block beyond the dimmed buttons and their filling bar.

Notifications and the response preview **never** trigger a cooldown, so Escape works on them from the first
frame.

The purpose is narrow and worth stating: a card appears over whatever the person was doing, and a keystroke
already in flight must not be able to answer it.

### 5.7 Availability

**Quiet period (snooze).** Global, not per surface. While one runs:
- No interactive surface is drawn at all. Each suppressed request is counted.
- Sounds are muted (a preference, on by default).
- Notifications still appear.
- Suppressed requests are **not** written to the interaction history.
- An expired period is cleared the next time a surface is requested.

**Away mode.** Suppresses every interactive surface entirely; the agent is told to proceed on its own defaults.
Notifications are unaffected.

**One at a time.** Only one interactive surface can exist. A second request while one is open resolves to the
open surface's outcome — no second window appears. Notifications are exempt.

**Timeout.** An unanswered request is abandoned after **10 minutes**. ⚠️ Nothing on screen counts down, warns,
or explains what happens at that moment.

### 5.8 The outcome model

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

⚠️ Snooze and ask-differently silently throw away typed work. See §10.11.

### 5.9 Sound

A short sound MAY play as a surface appears. It is gated three ways and the caller can only ever *ask*, never
force:

1. The caller asked for sound.
2. The person's preference for that category is on — **questions make sound by default, notifications do not**.
3. No quiet period is muting sounds.

Four options, one global preference: **`subtle`** (default — a short dry tick), **`pop`** (a soft percussive
pop), **`chime`** (a glassy bell), **`none`**.

⚠️ The notification's sound currently plays *after* the popup is already on screen, so it trails the appearance
rather than announcing it. It SHOULD play as the window comes forward.

### 5.10 History

Every surface the person **answered or cancelled** appears in the interaction history, with its time, the
asking client, a summary of the question, and the answer (multiple selections joined with `, `). Suppressed
(snoozed) requests never do. A multi-question entry is summarised by its first question, with the answers on one
line as `key: value; key: value`.

---

## 6. The surfaces

### 6.1 Confirm

> One yes-or-no question. The simplest surface, and the only one with no invalid state.

**Header glyph:** question mark. **Default title:** `Confirmation`.

**Body:** the question, per §4.2.

**Footer:** exactly two buttons — the decline (secondary) on the left, the confirm (primary) on the right.
Default labels `No` and `Yes`; both are caller-supplied and cap at 20 characters. Over-long labels truncate;
the button does not grow and the card does not widen.

**Hints:** `⏎ confirm` · `Esc cancel` · the three tool hints.

**Key behaviours:**
- The primary button is **never disabled**; Return always confirms once the cooldown has elapsed.
- Confirming reports *yes*. Declining reports *no* — and, with a note drafted, the note travels with it, making
  it a redirection rather than a cancel.
- Nothing is focused on open (§5.5).

**Edge cases:**
- A one-character body still honours the 420×300u minimum, so the card looks mostly empty.
- A very long title wraps over several centred lines and pushes everything down; there is no truncation rule
  and no scroll region, so it can push the buttons past the height cap. ⚠️
- A raw URL or file path renders as-is and is not clickable — only bracketed links are.

---

### 6.2 Pick

> One option from a list, or several. 2–20 options.

**Header glyph:** bulleted list (single) or checklist (multi). **Default title:** the calling client's name.

**Body:** the question, per §4.2.

**Content:** a vertical stack of choice cards (§4.12) 8u apart, inset 20u, with 4u above the first and 8u below
the last. The **"Other" card is always the final item** when present. The list is the scrolling region.

**Footer:** `Cancel` (secondary) and `Done` (primary).

**Hints:** `↑↓ navigate` · `Space select` · `⏎ done` · the three tool hints.

**Validity:**
- Nothing selected → `Done` is **disabled**, drops its `⏎` suffix, and Return does nothing.
- "Other" selected but empty → counts as nothing selected.
- A preselected default opens already selected with focus on it, so `Done` is live on the first frame.

**Selection semantics:**

| | Single | Multi |
|---|---|---|
| Clicking a listed option | Replaces the selection; clears "Other" | Toggles independently; leaves everything else |
| Clicking the selected option | Deselects it, leaving the question unanswered | Deselects it |
| The returned answer | One string, or the typed custom text | A list in list order, with any typed custom text **appended last** |

**Accessibility description:** multi → `Select one or more options. Use arrow keys to navigate, Space to
select.` · single → `Select one option. Use arrow keys to navigate, Space to select.`

**Edge cases:**
- Focus moving to a card scrolls it to the **vertical centre** of the list over 0.15s ease-out.
- Fewer than 2 or more than 20 options is refused before any window appears.
- Options phrased as "All of the above", "Select all", "Everything" or "None of the above" are **rejected
  outright** — the caller is told to use multi-select instead (§7.4).
- Duplicate option strings produce two identical cards distinguished only by position; a default matching more
  than one silently picks the first. ⚠️
- A default that matches no option preselects nothing.
- ⚠️ There is no selection counter in multi-select, no select-all/clear-all, and no way to express a minimum or
  maximum selection count. See §10.12.

---

### 6.3 Text

> One typed line. Optionally masked.

**Header glyph:** text cursor, or **padlock when masked**. **Default title:** `Input`.

**Body:** the prompt, per §4.2. Because there is no in-field hint, **all guidance must live here**.

**Content:** exactly one text field (§4.11), 20u inset, fixed 48u tall, 12u above the tool strip.

**Footer:** `Cancel` (secondary) and `Submit` (primary).

**Hints:** `⏎ submit` · `Esc cancel` · the three tool hints.

**Key behaviours:**
- The field **takes focus automatically 0.10s after the card appears** — the person can type immediately.
- Return submits; a newline can never be inserted. The field is strictly single-line, and pasting multi-line
  text yields one line.
- **The field is always in a submittable state.** `Submit` is never disabled and an empty submit returns an
  empty string. There is no validation, no length limit, no required-field concept and no error state.
- ⚠️ **No placeholder is rendered**, even though the shared field supports one and the form's text steps use
  one. An empty prefill gives a completely blank box.
- A prefilled value opens **pre-selected**, so the first keystroke replaces it.
- Long values scroll horizontally inside the fixed field; the card never widens to fit them.

**Masked variant.** Identical in every respect except the padlock glyph and bullet-rendered characters.
⚠️ **No reveal control, no caps-lock warning, no strength meter** — someone who mistypes a long secret cannot
verify it before submitting. A prefilled secret is indistinguishable from typed input. See §10.13.

The ask-differently menu disables `Text Input` in the plain variant and `Password` in the masked one.

---

### 6.4 Form

> Several questions, one screen at a time. 1–10 questions.

**Header glyph:** numbered list. **Default title:** the calling client's name.
**Body:** intro text, per §4.2 — it also becomes the subject card of the form-level note.

**Progress strip.** Directly under the header, inset 20u, 8u below it. One equal-width pill per question, 6u
apart, filling the width. **Completed and current pills:** solid `accent`, 6u tall, no outline. **Upcoming
pills:** `surface` fill, 4u tall, 1u outline in `border` at 50%. Reserved height 6u.

Pills are **decorative** — not clickable, never focusable, no way to jump between steps. The **current step
counts as filled**, so the strip is full while the person is on the last step.
Screen-reader label `Step <N> of <M>`, value `<P> percent complete`.

**Step counter.** Directly under the strip: `<N> of <M>` at 12u medium `text-muted`, centred, 8u below the
strip and 16u above the question.

**Question area** (the scrolling region), inset 20u, 6u above and 8u below:
- The question text at 15u semibold, selectable, wrapping to unlimited lines.
- The per-question note button (§4.8) 8u to its right, top-aligned with the first line.
- The answer control: a stack of choice cards (§4.12) for a choice step, or a single text field (§4.11) for a
  text step. Text steps never show an "Other" card — the field already is free input.

**Footer buttons, by position:**

| Step | Left (secondary) | Right (primary) |
|---|---|---|
| First | `Cancel` | `Next` |
| Middle | `Back` | `Next` |
| Last | `Back` (or `Cancel` if the form has exactly one question) | `Done` |

**Hints:** `↑↓ navigate` · `Space select` · `⏎ next` (`⏎ done` on the last step) · the three tool hints.

**Navigation:**
- `→` and the primary button advance; both are **inert while the current question is unanswered**.
- `←` and the secondary button go back. **Every previously entered answer is preserved** in both directions;
  nothing is ever cleared by moving between steps.
- Step changes are **instantaneous** — no slide, no cross-fade. Focus lands on the new step's first answer
  element 0.15s later and the question area scrolls back to the first option over 0.15s ease-out.
- Because forward movement requires a valid answer, a submitted form is normally complete.

**Validity per step type:**

| Step | Valid when |
|---|---|
| Single-select | Exactly one option selected, or "Other" selected with non-empty text |
| Multi-select | At least one option selected, or "Other" selected with non-empty text |
| Text | The field is non-empty (a single space counts) |

**What comes back:** one answer per answered question, labelled with the caller's own key, plus how many were
answered. A single-select step yields one string, a multi-select step a list in list order with any typed text
appended last, a text step the typed string. A question never answered is reported as **nothing at all**, not
as an empty answer. Per-question notes and one form-level note are delivered alongside, each keyed to its
question.

**Edge cases:**
- A one-question form still renders the full chrome: one pill, `1 of 1`, `Cancel` and `Done`.
- Cancelling mid-form **discards every answer silently** — but any notes still travel back. ⚠️ There is no
  confirmation prompt.
- Snoozing or asking differently from inside a form discards all answers.
- ⚠️ There is **no review or summary step**, no way to skip a question, no way to mark one optional, and no
  inline validation message explaining why the primary button is disabled. See §10.14.

---

### 6.5 Notify

> An announcement. No question, no waiting, no buttons.

**Not suppressed** by a quiet period or by away mode, and it may appear on top of an open interactive surface.
It floats above other windows unconditionally and **appears without stealing keyboard focus**.

**Anatomy** — a compact card with a fixed **360u content column**, padded 20u sides / 12u top / 16u bottom, 12u
between rows:

1. Utility row (report pill, project badge).
2. **Identity row:** a 28×28 circle filled `accent` at 18% containing a bell glyph at 13u semibold, then 10u to
   its right the title at 15u bold `text-primary`, **limited to one line and truncated with an ellipsis**.
3. **Message row:** the body at 13u `text-secondary`, left-aligned, inside a scrolling region.

There is no medallion-and-centred-title header block, no tool strip, no hint strip, and no buttons.

**Sizing:** minimum 360×120u; maximum height **45%** of the usable screen (much shorter than the 85% cap).
Placement follows the person's saved preference only.

**Lifetime:** it closes itself after exactly **4.0 seconds**. There is no countdown, no pause-on-hover, and no
close control. **Escape closes it early** — that is the only key it responds to, and it works from the first
frame because notifications never trigger a cooldown.

**Default title:** `Notice`.

⚠️ The message is rendered as **literal characters** — no formatting, no clickable links (§10.3).
⚠️ Nothing specifies what happens when two notifications arrive at once (§10.5).
⚠️ A long message can grow to the cap and scroll, but four seconds is rarely enough to read it.

---

### 6.6 Response preview

> A last look at what is about to be sent. Read-only.

Shown right after any interactive surface is answered, **only when the person has enabled the review-before-send
preference**, and never after a snooze.

Structurally identical to the notification, with two differences: the medallion holds an **eye glyph at 13u
semibold on `text-secondary` at 18%** (not `accent`, so a preview never reads as an alert), and the body is the
outgoing response text.

**Title:** `Response Preview`.
**Body:** the exact outgoing text — either the compact structured payload, or a plain-language rendering of it
when the humanised-responses preference is on.

Nothing the person does can alter or stop the response. It closes itself after 4.0 seconds; Escape closes it
early. It can be dragged. The report pill opens the issue page directly.

If the preview cannot be shown for any reason, the answer is still delivered — it is purely advisory.

⚠️ Four seconds with no countdown, no pause and no scroll indicator defeats the surface's own purpose for any
response longer than a line. See §10.15.

---

### 6.7 Value tweak

> Numbers, tuned live against the person's real files, while they watch the result change.

This surface is unlike the others: the answer is not a decision, it is a *feel*. The person drags a slider and
their own app updates. Everything about it serves that loop.

**Header glyph:** horizontal sliders. **Title:** always the calling client's name — ⚠️ a supplied title has no
effect (§10.16). **Body:** the agent's explanation of what is being tuned.

#### Session toolbar

A centred row directly under the header, items 8u apart, 20u side padding, 8u below.

- **Detected-stack badge** (conditional): a 10u semibold glyph in the stack's brand colour + `Framework
  detected: <name>` at 11u medium `text-muted`, in a 6u-radius pill filled with the brand colour at 10% and
  outlined 0.5u at 30%, padded 10u/5u.
  Brand colours: Svelte `#FF3E00` · React `#61DAFB` · Vue `#42B883` · CSS `#0099DB` · Vanilla `#F3D950`.
  Exactly one badge is shown even when the values live in several kinds of file; it is informational only and
  can be wrong for a mixed project.
- **`Replay animations` checkbox** (conditional — only when a stack is detected): a 12u check-in-square,
  `accent` when on and `text-muted` when off, label at 11u medium. Default **on**.
  Tooltip: `Trigger animation replay after changes (requires browser hook)`.
  When on, the page being tuned re-runs its animations after each change **if it is set up to do so**. Nothing
  in the pane shows whether it is — the checkbox looks identical either way and a failure is silent. ⚠️
- **`Show edits` toggle** (always present): a 10u code-brackets glyph + 11u medium text, padded 8u/4u, 4u
  radius. Inactive: `text-muted` on transparent. Active: `accent` on `accent` at 10%. Default **off**.
  Tooltip: `Toggle debug console`.

#### Parameter list

A vertically scrolling column, 20u sides, 4u top, 8u bottom, groups 12u apart, cards within a group 4u apart.

**Group heading** (only when the caller supplies an element or selector hint): that text in **uppercase, 11u
semibold monospaced, `text-muted`**, 4u left inset, 6u above the group's first card. Grouping only merges
**consecutive** parameters sharing the same hint; the same hint reappearing later produces a second heading.

Order is exactly the order supplied. Up to 20 parameters.

#### Parameter card

A 6u-radius rectangle filled `surface` at 50%, outlined 0.5u in `border` at 50%, padded 10u/8u. Its three
columns are top-aligned, 8u apart:

| Column | Contents |
|---|---|
| **Label** | 12u regular `text-secondary`, **min 60u / max 120u wide**, wraps. Hovering shows the file and line the value was read from. |
| **Slider** | The scrub slider at 18u tall, a 2u gap, then the tick strip at 4u. Replaced by the settings overlay when open. |
| **Value** | **Fixed 110u**, right-aligned, items 4u apart: the numeric field (56u), the unit slot (24u), the gear button. |

The value column never changes width, so **every readout on every card lines up**.

| State | Treatment |
|---|---|
| Default | 0.5u border at 50% |
| Focused | Border thickens to **1.5u `accent`** |
| **Errored** | A `negative` warning triangle at 10u + `File changed externally` at 11u above the row; `negative` border at 50%; the whole card at **70% opacity**; numeric field disabled and muted; slider greyed and inert; arrow keys ignored |
| Settings open | Slider and ticks dim to **30%**; the gear turns `accent` and rotates 45° |

#### Scrub slider

- **Track:** 4u tall, 2u radius, white at 10%, inset 7u from each end so the thumb never overhangs.
- **Fill:** from the left end to the thumb, `accent` at 60%.
- **Thumb:** a **14u white circle** outlined 0.5u in black at 15%. Hit target is the thumb radius plus 4u (11u).
- **Control height:** 18u. The cursor over it is an open hand.

Behaviour:
- Pressing the **track** jumps the value to that position, and the press continues as a drag from there.
- Pressing the **thumb** begins a relative drag with no jump.
- Dragging horizontally moves the value proportionally: the full track width covers the full range.
- **Precision is vertical distance, not a modifier key.** The value's travel rate falls off with how far the
  pointer has moved away from the row it was pressed on: **half speed at 40u away, a quarter at 120u**. It
  changes continuously with no steps or thresholds, and moving back toward the row restores full speed. This is
  the single best idea in the surface — fine control without a key to remember.
- Values clamp hard at the working bounds; no rubber-banding.
- Every dragged value is **snapped to the step** before it is applied.
- Disabled: fill grey at 30%, thumb grey at 50%, all input ignored.
- ⚠️ Hovering the slider produces no visual change at all — no thumb growth, no value tooltip.

#### Tick marks

A row of **1u-wide, 4u-tall bars in `text-muted` at 40%**, evenly distributed across the slider width with the
first and last flush to the ends, 2u below the slider.

One tick per step across the range. **If the spacing would be tighter than 10u, the count is repeatedly halved
until it is at least 10u** — so a 0–500 range with a step of 1 shows a readable subset, not 501 hairlines.
Fewer than two ticks draws nothing, but the 4u strip still reserves its height.

⚠️ Ticks reflect the step only. They never mark the current value, the original value, or zero, which makes
signed ranges hard to read.

#### Numeric readout

A right-aligned monospaced number at **12u medium in `accent`** in a **borderless 56u field**, with a
`text-muted` 11u unit suffix in a fixed 24u slot beside it.

- Click to edit. Return commits: unparseable text reverts silently; a parsed number is clamped and applied.
- The number updates live while dragging or arrowing.
- **Precision is inferred from the source text**: no decimal point in the original → a rounded whole number;
  otherwise the larger of (decimals in the original) and (decimals in the step).
- Values written back **keep the file's own formatting** — the embedded unit suffix, the decimal count, and a
  leading-dot style such as `.5` all survive.
- ⚠️ The field has no border and no background, so **its editability is not discoverable**.

#### Per-card settings overlay

Opened by the gear; replaces that card's slider area. A compact right-aligned strip — revert button, `Min`
field, `Max` field, 8u apart — on a solid `surface` fill, 4u radius, 0.5u border at 50%, padded 8u/4u.

- Revert: a counter-clockwise arrow at 10u medium `text-muted`. Tooltip `Reset to original value`. Writes the
  value back to what it was when the pane opened, clears the card's error if that write succeeds, and closes
  the overlay.
- Range fields: a 10u medium `text-muted` caption 3u left of an 11u medium monospaced right-aligned field, 44u
  wide, `text-secondary`, no visible box. Return commits. `Min` is accepted only if strictly less than the
  current max; `Max` only if strictly greater than the current min. **A rejected value snaps back silently with
  no explanation.** ⚠️
- Slides in from the right with a fade, ~0.2s ease-in-out; the gear rotates 0°→45°.

The adjusted range is **session-only and per card**: it rescales the slider, re-derives the ticks and re-clamps
input, but never changes the current value and is never reported back. ⚠️

#### Live writing

Every change reaches the file about **150ms after the person stops moving that value**, so a continuous drag
produces one update per pause rather than one per pixel. Moving one value never holds up another. Small shifts
elsewhere on the same line do not break a value's connection to its card, and when several tuned values sit on
one line, changing one never corrupts the others.

A write **fails and errors the card** when the expected text is no longer there, the file cannot be read or
written, or the target lies outside the declared project folder. All three collapse to the single message
`File changed externally`. ⚠️

- There is **no visual difference between "queued" and "written"** and no success tick. The console panel is
  the only positive confirmation, and it is off by default. ⚠️
- ⚠️ **Cancelling does not roll back writes already made.** See §10.17 — this is the most surprising behaviour
  in the product.

#### Edit console panel

A separate floating panel beside the pane, **270u wide** (260u of content), 12u radius, 0.5u border at 30%,
`field` fill, its own shadow. Its height always matches the pane's exactly.

It sits on the **far side from the pane's screen position** — a right-placed pane gets its console on the left,
otherwise the console sits on the right — with an 8u gap. It shares the pane's stacking level, is not
independently movable or resizable, and repositions instantly when the pane moves.

**Populated view:**
- Header strip: `surface` band padded 12u/8u with a 10u document glyph and `filename:linenumber` at 11u
  semibold monospaced `text-secondary`, clipped to one line.
- Code block: **five lines** — two before, the edited line, two after — with 8u vertical padding.
- Each line: a 32u right-aligned line-number gutter at 10u monospaced `text-muted` at 60%, 8u of trailing
  space, then the content at 10u monospaced. Row padding 4u/1u.
- Context lines: `text-muted`, transparent row, **truncated with a trailing ellipsis past 60 characters**.
- **Edited line:** `text-primary` on a row tinted `accent` at 5%. The changed number itself is drawn `accent`,
  semibold, on a 2u-radius `accent` chip at 15% that bleeds 1u beyond the glyphs. The edited line is never
  truncated — it scrolls.

**Empty view:** vertically centred, a 20u slider-below-rectangle glyph in `text-muted` at 40%, an 8u gap, then
`Move a slider to see changes` at 11u in `text-muted` at 60%.

Content is not selectable and has no click target. It appears and disappears instantly — no slide, no fade.

⚠️ It shows only the **single latest edit**, never a history, despite being labelled "Show edits". Closing it
also forgets that edit, so reopening starts empty.

#### Footer

**Hints:** `↑↓ navigate` · `←→ adjust` · `⏎ save` or `⏎ cancel` · `Esc cancel` · the three tool hints. Seven
hints on one line are what force this surface's 460u minimum width.

**The button set changes with state** — the moment any value differs from where it started, and back again if
every value returns:

| State | Buttons | Return hint |
|---|---|---|
| No changes | A single primary `Cancel` | `⏎ cancel` |
| Changes made | `Revert All` · `Tell Agent` · primary `Save to File` | `⏎ save` |

| Button | Does |
|---|---|
| **`Save to File`** | Flushes every pending write, closes, and reports the final numbers with a marker meaning *the files already contain these; there is nothing to apply* |
| **`Tell Agent`** | Cancels pending writes, rewrites every value back to its opening value, closes, and reports the chosen numbers with a marker meaning *the files are untouched; you apply these* |
| **`Revert All`** | Rewrites every value back to its opening value, restores every readout, clears the error on every card whose reset succeeded, empties the console, and **leaves the pane open**. Everything now matches its start, so the footer collapses back to the single `Cancel`. |
| **`Cancel`** | Closes with no answer. ⚠️ Writes already made remain on disk. |

**Keyboard:** `↑`/`↓` move the focused card (with no card focused, `↑` jumps to the last and `↓` to the first);
`←`/`→` step the focused value; both are suppressed while typing.

⚠️ Three input methods clamp and snap differently — see §10.18.
⚠️ There is **no per-card changed marker**; with 20 cards the person cannot see at a glance which they moved.

---

### 6.8 Layout sketch editor

> A screen layout, proposed by the agent, dragged into shape by the person.

This surface breaks the dialog window model deliberately. It is a **workspace**, not a question: resizable,
undoable, and sized for sustained direct manipulation.

#### Window

- Opens at **700 × 500u**; **cannot be resized below 500 × 400u**.
- Horizontally **centred**; top edge 80u below the top of the usable screen area.
- Borderless card, **12u radius** (not 16u), drop shadow, 8u content inset, clipped to its rounded shape.
- **Resizable** by dragging within **8u of any edge or corner** — side edges show a directional resize cursor,
  corners a crosshair. Left and top edges resize anchored to the opposite edge.
- Draggable **by the header region only** — the body and footer do not move the window.
- Modal and **exclusive**: only one session may exist. A second request is refused with `An interactive layout
  session is already running. Complete or cancel it first.` A request with no desktop session is refused with
  `Interactive layout editor requires a desktop environment (unavailable over SSH/CI)`.
- Region padding — header: 20u sides, 20u top, 12u bottom. Body: 20u sides, tool rail and canvas 12u apart.
  Footer: 20u sides, 12u top, 20u bottom.

#### Header

Report pill (§4.1) · a left-aligned two-line stack (title 18u bold `text-primary`, optional description 13u
`text-secondary`, 4u apart) · flexible gap · a **grid-size pill** reading `<columns>×<rows>` with a true
multiplication sign, at 12u `text-muted`, padded 8u/4u, capsule.

Default title `Layout Sketch`. ⚠️ The grid-size pill uses a hard-coded dark grey capsule that does not follow
the palette (§10.19). ⚠️ No project badge appears here (§10.6).

#### Tool rail

A fixed **120u-wide** column, items 8u apart, top-aligned.

- **Undo / redo**: two equal icon buttons 4u apart, each 32u tall, 6u radius, `surface` fill, 13u medium glyph.
  Enabled → `text-secondary`; disabled → `text-muted`. Tooltips `Undo (⌘Z)` and `Redo (⌘⇧Z)`.
- **`Add` tile**: full rail width, **52u tall**, 8u radius, `surface` fill with a 1u border; a 16u plus glyph
  above the word `Add` at 10u medium, `text-secondary`.
- **Rail drop target** — only during a drag (see below).
- **Stash tray** — only when something is stashed.

Undo history is capped at **50 steps**; the oldest is discarded silently. Making any new change after undoing
clears the redo history. ⚠️ The rail does not scroll, so many stash chips can overflow it.

#### Canvas

A **white card**, 6u radius, 8u inner padding — white in **both** palettes, so blocks always sit on paper.

- **Grid lines** at every column and row boundary including the outer edges: pale blue `#C7E0FA`, 0.5u.
- **Cells are always square**: size = min(available width ÷ columns, available height ÷ rows). The grid is
  centred in the available area; leftover space stays blank. **The canvas never scrolls — it always scales to
  fit.**
- Columns and rows are **3–20 each** and are **fixed for the session** — the person cannot change them.

Layer order, bottom to top: grid lines → role tints → blocks (containers first, nested after) → alignment
guides → annotation pins. The hovered block is raised above its neighbours.

Clicking an **empty** cell opens the add-block dialog pre-targeted at it. Clicking a covered cell does nothing
at the canvas level.

#### Block

A rounded rectangle, **6u radius**, in the block's own colour, whose four visual dimensions each carry meaning.

**Anatomy:**
- Fill and border, per importance.
- A **wireframe glyph** inside, inset 6u, at **30% opacity** in the block's colour.
- A **number badge** at the top-left: the block's hierarchical number in white 11u bold, on the block colour at
  85%, padded 5u/2u, 4u radius, offset 3u from the corner.
- Optional **flow arrow** immediately right of the badge: a right arrow for row flow, a down arrow for column
  flow, 11u bold in the block colour at 70%.
- A **resize grip** at the bottom-right: three parallel diagonal strokes, each 1.5u thick, spaced 3.5u, in the
  block colour at 50% (100% while resizing), in a 14×14u hit area.
- A drop shadow per elevation.

**Block labels are never drawn on the block face** — only the number. The label is reachable by hover tooltip,
by renaming, in the stash chip, and in every textual output.

**Numbering is hierarchical:** top-level blocks are `1`, `2`, `3`… in reading order; a block nested inside
block 2 is `2:1`; one nested inside that is `2:1:1`, to unlimited depth.

**The four semantic dimensions:**

| Importance | Fill | Border |
|---|---|---|
| Primary | 35% | 2.5u solid |
| Secondary | 25% | 1.5u solid |
| Tertiary | 12% | 0.5u dashed (4 on / 3 off) |

| Elevation | Shadow |
|---|---|
| 0 | none |
| 1 | black 10%, 2u blur, 1u down |
| 2 | black 15%, 6u blur, 3u down |
| 3 | black 20%, 12u blur, 6u down |

| Role | Tint painted under the block (no inset, no radius) |
|---|---|
| header, footer | RGB 160,140,120 at 5% |
| sidebar, toolbar | RGB 120,140,170 at 5% |
| canvas, panel | RGB 128,128,128 at 3% |

An unrecognised role produces no tint at all. Tints overlap additively.

**Other states:**

| State | Treatment |
|---|---|
| Hover | Border thickens to 2.5u; a label tooltip appears centred over the block; the block is raised |
| Promoted (see below) | Rendered exactly as hovered |
| Dragging | Fill jumps to 50%, border 2.5u; the block follows the pointer; the hover tooltip is suppressed |
| **Nested** | Fill forced to 35%, border always dashed 4/3, inset a further 2u per side so the parent's edge stays visible |
| Renaming | The badge and arrow are replaced by an inline field |
| Read-only | No grip, no drag, no double-click, no context menu; hover highlight still occurs |

**Geometry:** a block occupies (span × cell size) in each axis, drawn **1u inside its cell footprint per side**
(3u when nested).

**Direct manipulation:**
- **Move** — press and drag anywhere on the block; **4u of movement** starts it. A tooltip shows `x: <column>,
  y: <row>` (zero-based). Release snaps to the nearest whole cell, clamped fully inside the grid.
- **Resize** — drag the bottom-right grip; **2u of movement** starts it. A tooltip shows `<width>×<height>` in
  whole cells. Clamped to at least 1×1 and at most the space remaining to the grid's right/bottom edge.
- **Rename** — double-click. Return commits (ignored if empty); Escape reverts. Placeholder `Label`.
- **Context menu** — right-click. `Duplicate` (a copy offset one cell right and down, clamped, labelled
  `<label> Copy`, keeping the colour but losing content kind, role, importance, elevation and flow) and
  `Delete` (immediate, no confirmation; nested blocks are **not** deleted). Both undoable.
- **Nesting is inferred purely from geometric containment** — the smallest containing block wins. Dragging a
  parent moves its children by the same cell delta; dragging a child does not move the parent. Resizing a block
  so it no longer contains a former child instantly reclassifies that child as top-level, changing its border,
  inset and number.
- **Option-cycling** — holding the modifier while the pointer sits over two or more stacked blocks promotes the
  next one to the top of the hover order, wrapping. ⚠️ Completely undiscoverable (§10.20).

**Stashing.** Dragging a block so its snapped destination falls **past the bottom row or left of column 0**
removes it from the grid and parks it in the stash. The top and right edges only clamp. ⚠️ The asymmetry is
never explained.

Two hints appear the moment a drag begins and vanish when it ends. Neither is itself a pointer target — the
decision is made from the drag's computed destination, not from where the pointer is released.

| Hint | Anatomy | Armed | Highlighted |
|---|---|---|---|
| **Canvas bottom** | Tray-with-down-arrow glyph + `Drop to stash` at 12u medium, 8u vertical padding, full width, 6u radius, inset 8u from the canvas (or frame) edge | `surface` at 70%, `text-secondary` | Orange at 60%, white text |
| **Rail** | Same glyph + `Drop here` at 11u medium, 10u vertical padding, full rail width, 8u radius, dashed 1.5u border (5 on / 3 off) | `surface` at 40%, neutral dashed border | Orange at 60%, solid orange border, white text |

Both crossfade between armed and highlighted over **150ms ease-in-out**; appearance and disappearance are
instant. Both highlight from the same condition, so pushing a block off the bottom also lights the rail hint.

**Stash tray.** In the rail, only when something is stashed. An 8u-radius `surface` card, 8u padding, 1u border
at 50%, headed `Stash` in uppercase 10u semibold `text-muted`. One chip per stashed block, 4u apart: an 8u
filled circle in the block's colour, a 4u gap, the label at 10u medium `text-primary`, on a 5u-radius chip
filled `surface-hover` at 60%, padded 6u/4u, full rail width, single line, truncated.

Clicking a chip restores the block **at its original position and size** — with no collision check, so it can
land on top of something. A stashed parent takes its children with it, but restoring the parent restores only
the parent. A block reappearing by any route is dropped from the tray automatically.

⚠️ **Blocks left in the stash are silently discarded on Accept**, and reported as removed. The person is never
warned.

#### Wireframe glyph vocabulary

Eleven abstract content signatures, all drawn at **30% opacity in the block's colour, inset 6u**. Counts scale
with the block's live size within the stated caps.

| Kind | Signature |
|---|---|
| **text** | 2–4 stacked rounded bars; bar height max(3u, 12% of block height), gaps max(2u, 8%); the last bar 60% width, the rest full |
| **image** | A corner-to-corner cross plus a centred photo glyph at 25% of the shorter side |
| **video** | A solid centred play triangle at 40% of the shorter side |
| **avatar** | An outlined circle (1.5u) at 50% of the shorter side with a person glyph at 45% of that circle |
| **button** | One outlined pill (1.5u), fully rounded, width min(70% of block width, 100u), height min(40% of block height, 24u) |
| **input** | A bottom baseline rule 1.5u thick with a 14u caret bar at its left end |
| **list** | 2–5 rows, each a filled circle plus a rounded bar; row height max(3u, 10%), gaps max(2u, 6%) |
| **chart** | 3–5 bottom-aligned bars (one per 16u of width), 4u gaps, heights cycling 60/90/40/75/50% |
| **map** | Full-width and full-height crosshair at 0.75u plus a centred pin glyph at 25% of the shorter side |
| **nav** | 2–4 filled pills side by side (one per 30u of width), 4u gaps, height min(40% of block height, 18u) |
| **form** | 1–3 stacked outlined field rectangles at the top, then a filled submit pill 50% of block width, min(15% of height, 18u) tall |

**Inference from the label** is a case-insensitive substring match evaluated in a fixed order, first match
wins:

`image` ← image, photo, hero, banner, thumbnail, logo · `video` ← video, player · `avatar` ← avatar, profile
pic · `button` ← button, cta, action · `input` ← input, search, field · `list` ← list, feed, items · `chart` ←
chart, graph, stats, analytics · `map` ← map, location · `nav` ← nav, menu, tabs, breadcrumb · `form` ← form,
signup, login, register, contact

An explicit kind always beats the guess. **Renaming re-runs the inference**, so a rename can make a glyph
appear, change or vanish. Because matching is substring-based and ordered, "Hero Menu" gets the image glyph and
"Sitemap" gets the map glyph.

#### Alignment guides

Thin **cyan lines at 40% opacity, 0.5u thick**, spanning the full grid width or height, shown only while a
block is being dragged or has been promoted.

A vertical guide appears at a column boundary when the active block's left or right edge sits there **and**
another block's left or right edge does too; likewise horizontally. Matching is **exact grid-coordinate
equality** — there is no proximity tolerance and no magnetism, because blocks already snap to whole cells.

⚠️ Guides are currently drawn from the block's **committed** edges, not its live destination, so they never
update during the one gesture they exist for. See §10.21.

#### Annotations

Caller-supplied only — the person can neither create, edit nor delete them.

- **Pin:** a solid orange **20u circle** whose centre sits exactly on the top-left corner of the target cell,
  containing the 1-based ordinal in white 11u bold, with a **1u orange leader line at 40%** running to the
  cell's centre. Drawn above blocks and guides.
- **Legend:** a card below the canvas (and below any device frame), 8u padding, 6u radius, one row per
  annotation 2u apart. Each row: a solid orange **16u circle** with the ordinal in white 9u bold, a 6u gap,
  then the text at 11u `text-secondary`, **single line, truncated**.

A pin whose coordinate falls inside a block being dragged **follows that block frame-for-frame**, and its
stored coordinate is rewritten on release. Ownership is the **first block in list order** whose rectangle
contains the coordinate — not the topmost or smallest. A pin in no block never moves. Annotations belonging to
a stashed block **stay behind, orphaned**.

⚠️ A pin at column 0 / row 0 sits three-quarters outside the canvas. The legend does not scroll and squeezes
the canvas as it grows.

#### Device frames

Decorative chrome wrapping the canvas. Nothing in a frame responds to input, and the frame cannot be changed
from inside the editor. Frame padding reduces the space left for the grid, so cells get smaller.

| Frame | Anatomy |
|---|---|
| **Browser** | A title bar padded 8u/10u on a 12%-white fill: three 10u traffic-light dots 6u apart at 70% opacity, then a centred address pill — 20u tall, 4u radius, 15%-white fill — holding the placeholder `https://` at 10u in mid grey. The whole assembly clipped to 8u with a 1u border at 25% white. |
| **Phone** | A status strip padded 12u/4u on an 8%-white fill holding the fixed clock `9:41` at 10u semibold in mid grey (never the real time). A **6u bezel** of near-black, clipped to **20u** with a **2u** border at 30% white — the thickest of the three. No battery, signal or notch. |
| **Tablet** | A uniform **8u bezel**, clipped to **14u** with a 1.5u border at 25% white. No status strip, no controls — visually only a rounder, thicker border than no frame. |

The mid-drag stash hint re-anchors to the bottom of the framed unit rather than the raw canvas.

#### Add-block dialog

A small modal panel **280u wide**, 20u padding, 16u between its three rows, centred over the editor and dimming
it.

Heading `Add Block` · a single-line field with the placeholder `Block label` · a footer row with `Cancel` on
the left and `Add` on the right as the default action.

`Add` is **disabled while the field is empty** and guarded on click, so an empty label can never create a
block. **Whitespace-only text is accepted** and produces a block with a blank-looking label. Return confirms,
Escape cancels.

The new block is always **1×1** at the target cell, coloured by the next entry in the palette rotation (by
current block count), with no content kind, role, importance or elevation.

The target cell is the clicked cell, or — when triggered from the rail — the **first free cell scanning
row-major**; if the grid is fully covered it falls back to the top-left cell, producing an overlap with no
warning.

#### Footer

Two stacked hint lines 3u apart, each 10u and clamped to one line (the second at 70% of `text-muted`'s
opacity), then `Cancel` (**110×44u**) and the primary `Accept` (**130×44u**) 12u apart, both 12u radius with
15u labels.

```
Drag to move · Resize from corner · Double-click to rename
⌘Z Undo · ⌘⇧Z Redo · ⌘D Duplicate · ⌫ Delete
```

The primary button renders as `Accept  ⏎` (two spaces then the glyph).

⚠️ **Duplicate and Delete are advertised but not bound** — they exist only in the context menu (§10.22).

**Keyboard, window-wide:** `Escape` cancels · `Return` accepts (which means it also fires while a label is
being typed unless the field consumes it first) · `⌘Z` undo · `⌘⇧Z` redo · standard editing shortcuts in text
fields.

⚠️ **There is no selection model at all** — no click-to-select, no selected styling, no multi-select, no
marquee, no shift-click, no way to act on several blocks at once. Everything is hover plus a per-block context
menu. And the canvas is **entirely unreachable by keyboard**. See §10.23.

#### Block colour palette

Assigned in order to any block without an explicit colour, cycling after twelve. Fallback for an unparseable
value is the first entry.

`#3B82F6` blue · `#10B981` emerald · `#F59E0B` amber · `#EF4444` red · `#8B5CF6` violet · `#EC4899` pink ·
`#06B6D4` cyan · `#F97316` orange · `#84CC16` lime · `#6366F1` indigo · `#14B8A6` teal · `#A855F7` purple

#### Grid presets

| Preset | Grid | Intended for |
|---|---|---|
| compact | 6 × 4 | 2–4 blocks |
| **standard** | **12 × 8** | the default, up to 12 blocks |
| spacious | 16 × 10 | dashboards, up to 20 blocks |
| detailed | 20 × 16 | high-fidelity wireframes, up to 30 blocks |
| mobile | 4 × 12 | a tall column — **also switches on the phone frame** unless one is named |

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

Three readable representations come back alongside the layout:

**1. Prose description**

```
Layout: 12 columns × 8 rows
- "Header" spans full width at top (cols 1–12, rows 1–1)
  - "Logo" on the left (cols 1–2, rows 1–1) [nested inside "Header"]
```

Spatial phrases in evaluation order: `spans full width at top` · `spans full width at bottom` · `spans full
width` · then any combination of `on the left`, `on the right`, `at the top`, `at the bottom` joined by `, ` ·
falling back to `in the center area`. Ranges are 1-based inclusive with an en-dash. A brief mode instead emits
`- "Header" at (0,0) size 12×1` with zero-based coordinates. An empty layout emits `No blocks defined.`

**2. Box-drawing diagram**

A monospaced grid, cells five characters wide separated by pipes, unoccupied cells holding a single `.`, with a
legend line mapping each abbreviation to its label (`H=Header`, sorted alphabetically, joined by two spaces).
Horizontally adjacent cells of the same block have the pipe between them replaced by a space, so a wide block
reads as one bar. Abbreviations are the uppercased first character of the label if unused, else the first two,
else the first character plus an incrementing number from 2; `.` is reserved. Where blocks overlap, **the
smaller block is the one shown**.

**3. Static image**

⚠️ The exported image does **not** currently match what the person edited — different background, different
grid-line colour, non-square cells, labels instead of numbers, and a legend drawn outside the stated bounds.
See §10.24.

---

## 7. The caller surface

What the agent can ask for, and exactly how each option changes what the person sees.

### 7.1 The four capabilities

| Capability | Produces | Waits for the person |
|---|---|---|
| **ask** | One of: confirm, pick, text, form | Yes |
| **notify** | The notification popup | No |
| **tweak** | The value tuning pane | Yes |
| **propose layout** | The sketch editor | Yes |

### 7.2 Options shared by every surface

| Option | Meaning | Effect on screen | Default | Limits |
|---|---|---|---|---|
| `body` | The question or message | The header body (§4.2). Formatted per §4.3 — except on the notification. Escaped newlines become real ones, which flips alignment to left. | required | 1–1000 chars |
| `title` | The headline | 18u bold centred, wraps. Compact popups clamp it to one line. | Per surface: `Confirmation` · client name · `Input` · client name · `Notice` · `Response Preview` · client name · `Layout Sketch` | ≤ 80 chars |
| `position` | Where the card sits | `left` 40u in from the left · `right` 40u in from the right · `center` centred. Also decides the note pane's side and the resize anchor. **Never applied to the two compact popups.** | The person's saved preference (itself defaulting to left); falls back to centre | one of left / center / right |
| `project_path` | Which project this is about | The project badge (§4.1), showing only the final segment, with the full path as its tooltip. Omitting it removes the badge. Also the Project line in a filed report. | Cached from the first call in the session | absolute path |

Two more arrive from the launching environment rather than per call:

| Option | Effect |
|---|---|
| **Calling client name** | Used as the title when the caller supplies none; appears in a filed report's Environment section and beside every history entry. Default `MCP`. ⚠️ It is documented as *prefixing* supplied titles but does not — see §10.25. |
| **Colour scheme** | Selects Midnight or Sunset (§2.1). Unrecognised values fall back to Midnight. Layout, sizes and copy are unchanged. |
| **Presentation style** | Selects a layout style (§8). Unrecognised names print the available list and fall back to Standard. |

### 7.3 Confirm

| Option | Effect | Default | Limits |
|---|---|---|---|
| `yes` | The primary (right) button's label; ` ⏎` is always appended | `Yes` | ≤ 20 chars |
| `no` | The secondary (left) button's label; no glyph appended | `No` | ≤ 20 chars |

### 7.4 Pick

| Option | Effect | Default | Limits |
|---|---|---|---|
| `choices` | One card per entry, in order, above the "Other" card | required | **2–20** entries, each 1–100 chars |
| `descriptions` | A 12u secondary line under the matching label, growing that card. Index-aligned; an empty string renders no line; a short list is padded; extras are ignored. | none | each ≤ 200 chars |
| `multi` | Swaps every radio for a checkbox, swaps the header glyph, changes the accessibility description, and changes toggling from replace to accumulate. Adds **no** counter and no select-all. | `false` | — |
| `other` | Appends the free-text "Other" card. Set `false` **only** for genuinely closed lists. | `true` | — |
| `default` | Preselects that card and starts focus on it, so `Done` is live immediately. A value matching no option preselects nothing. | none | must match an option exactly |

**Rejection rule.** An option phrased as "All of the above", "Select all", "Everything" or "None of the above"
is refused **before any window appears**, with: `Do not include "<that option>" style options. If the user
should be able to select multiple answers, set multi: true instead.`

### 7.5 Text

| Option | Effect | Default | Limits |
|---|---|---|---|
| `default` | The field opens containing this text, **pre-selected**. A long value scrolls inside the fixed field rather than widening the card. | empty | any string |
| `hidden` | Renders bullets and swaps the medallion glyph to a padlock. No reveal control. | `false` | — |

### 7.6 Form

| Option | Effect | Default | Limits |
|---|---|---|---|
| `questions` | One step each, in order. Sets the pill count and the `of M` denominator. | required | **1–10** |
| `…[].id` | Never displayed; it is the key the answer and any note are filed under. | required | 1–50 chars |
| `…[].question` | 15u semibold, selectable, wrapping. Also quoted in that question's note subject card. | required | 1–500 chars |
| `…[].type` | `choice` → option cards (plus the "Other" card by default). `text` → a single field, and no "Other" card. | `choice` | choice / text |
| `…[].options` | One card each, in order | required for choice | **2–10**, each 1–100 chars |
| `…[].descriptions` | A secondary line under the matching label | none | each ≤ 200 chars |
| `…[].multi` | Checkboxes for that step; that step's answer becomes a list | `false` | choice only |
| `…[].other` | Appends the "Other" card to that step | `true` | choice only |
| `…[].placeholder` | Ghost text in the empty field | `Enter your answer...` | text only, ≤ 200 chars |
| `…[].hidden` | Masks that step's field | `false` | text only |

The same "all of the above" rejection rule applies per step.

### 7.7 Notify

| Option | Effect | Default |
|---|---|---|
| `sound` | Requests a sound. Gated by §5.9 — since the notification sound preference is **off by default**, asking for one often produces silence. Changes nothing visual. | `true` |

The notification ignores a per-call `position`.

### 7.8 Value tweak

| Option | Effect | Default | Limits |
|---|---|---|---|
| `parameters` | One card each, in order | required | **1–20** |
| `…[].label` | The 12u left-hand text; wraps within 60–120u | required | 1–100 chars |
| `…[].element` | An uppercase monospaced group heading above the card. Consecutive cards sharing it merge under one heading. | none | ≤ 100 chars |
| `…[].unit` | Fills the fixed 24u slot beside the readout. Auto-detected for stylesheet and pattern addressing. | auto, else blank | ≤ 10 chars |
| `…[].min` / `…[].max` | The slider's ends, the clamps, and the starting contents of the settings overlay's fields | required | min must be below max |
| `…[].step` | Tick spacing, the arrow-key increment, the drag snap, and the minimum decimals shown. Omitted → derived as one hundredth of the range rounded to a nice 1/2/5/10 × power of ten (0–500 → 5; 0–48 → 0.5). | auto | must be positive |
| `…[].current` | Positions the thumb, seeds the readout, and is what "revert" writes back. With pattern addressing it also disambiguates which match this card controls. | resolved for stylesheet addressing | must equal the real value |
| `…[].id` | Never displayed; the key in the reported answer. Omitted → derived from the label. **Two entries resolving to the same key prevent the pane from opening at all.** | derived | 1–50 chars, unique |
| `…[].file` | Appears in the label's hover tooltip and the console header. Its type, pooled across all parameters, decides the stack badge and whether the replay checkbox appears. | required | absolute, or relative to the project |

**Three ways to address a value**, exactly one of which must be complete:

| Style | Options | Notes |
|---|---|---|
| **Direct** | `line` · `column` · `expectedText` | Lines and columns count from 1. The source text drives the readout's number formatting. If it no longer matches at write time, the card errors. |
| **Stylesheet** | `selector` + `property`, optionally `index` or `fn` | Resolves before the pane opens and supplies the unit and group heading automatically. `index` picks one value out of a multi-value declaration; `fn` targets a named function's argument. |
| **Pattern** | `search` (one placeholder marking the number) + `current` | Auto-detects the unit from what follows the placeholder. |

**Refusals — nothing opens at all:** a location that cannot be resolved; two parameters resolving to the same
spot; two sharing an identifier; a pattern matching several places that the supplied current value cannot
single out (the agent is told to be more specific). Two sliders may legitimately target the identical pattern
in the same file if their starting values differ — two blur radii of 8 and 10 in one stylesheet, for example.

⚠️ `title` is accepted here but has no effect (§10.16).

### 7.9 Propose layout

| Option | Effect | Default | Limits |
|---|---|---|---|
| `width` / `height` | Grid columns and rows. Shown verbatim in the size pill. Cells stay square, so a wide grid on a short window shrinks every cell. | 12 / 8 | 3–20, clamped; ignored when a template is given |
| `template` | Overrides both (§6.8 preset table). `mobile` also switches on the phone frame unless one is named. | none | compact / standard / spacious / detailed / mobile |
| `description` | A 13u secondary line under the title; omitting it collapses the header to one line | none | ≤ 200 chars |
| `blocks` | One editable tile each, numbered by reading order | empty grid | coordinates are **not** clamped on load, so out-of-grid values render off-grid |
| `…[].label` | The hover tooltip, the rename seed, the change-list name, and the seed for the glyph and shadow guesses | required | 1–50 chars |
| `…[].x` / `y` / `w` / `h` | Zero-based top-left cell plus spans. A block fully inside another is automatically nested. | required | x,y ≥ 0; w,h ≥ 1 |
| `…[].color` | Fill, border, badge, glyph and stash-chip dot | auto from the palette by list position | 6-digit hex, with or without a leading hash; unparseable → blue |
| `…[].content` | The wireframe glyph; beats the label guess | guessed from the label | text / image / video / avatar / button / input / list / chart / map / nav / form |
| `…[].role` | The tint, and — when importance is unset — the visual weight: `canvas` → primary; `header`, `sidebar` → secondary; `toolbar`, `panel`, `footer` → tertiary | none | header / sidebar / canvas / footer / toolbar / panel |
| `…[].importance` | Fill opacity and border weight | from role, else secondary | primary / secondary / tertiary |
| `…[].elevation` | The drop shadow | guessed from the label — modal/dialog/overlay → 3, popover/floating → 2, card → 1, else 0 | 0–3, clamped |
| `…[].flowDirection` | The arrow beside the number badge | none | row / column |
| `structure` | A nested tree describing the layout by direction, gaps, sizing and priority instead of coordinates. **Takes precedence over `blocks`.** It is turned into ordinary rectangles before the editor opens — the person only ever drags plain blocks and never sees or re-edits the nesting. | none | per node: id 1–50 chars; optional label ≤ 50 chars falling back to the id; direction row/column (column when unstated); gap 0–10 cells; priority a non-negative integer defaulting to 1; size a whole number of cells, or `hug` (one cell), or `fill` (a priority-weighted share of what is left) |
| `frame` | Device chrome (§6.8) | none, except `mobile` implies phone | browser / phone / tablet |
| `annotations` | Numbered pins plus the legend. The person cannot create, edit or delete them. | none | per entry: non-negative column and row, text 1–100 chars |

---

## 8. Presentation styles

The interface separates **what a surface is** from **how it is drawn**. A *presentation style* owns layout and
appearance and nothing else — every behaviour in §5, every outcome in §5.8, every copy string in §9, and the
whole caller surface in §7 are invariant across styles.

### 8.1 The conformance contract

A style **MUST NOT** change: the keyboard map, shortcut suppression, Escape unwinding, the outcome model, the
note matrix, availability rules, the cooldown, or any user-visible string except those listed as
style-specific in §8.4.

A style **MUST** supply, for each surface it defines: the arrangement, the palette, and a full row of the
minimum-metrics table (§8.3).

A style **MAY** define only some surfaces. **Any surface a style does not define falls back to the Standard
style's arrangement *and* its metrics.** This is a deliberate contract, not an omission — a person running the
Alternative style today sees the value-tweak pane in the Standard arrangement, visibly unlike every other
surface in that session.

Selecting a style installs that style's preferred palette automatically, but an **explicitly requested palette
always wins**, because the palette is resolved after the style.

### 8.2 The two shipping styles

| | **Standard** | **Alternative** |
|---|---|---|
| Header | Centred medallion, centred title | Left-aligned **kicker** (an uppercase monospaced type label) above a left-aligned title — no medallion |
| Accent rail | none | A rail down the card's left edge — a gradient from full accent to 15% on interactive surfaces, flat solid on compact popups |
| Option list | Cards only | Cards preceded by a **numbered ordinal gutter** |
| Selection feedback | Indicator + fill + border | Same controls, plus a live **status line** |
| Form progress | Segmented pills + a separate `N of M` counter | One continuous rule; the step count folded into the kicker |
| Text field | No placeholder on the text surface | Always a placeholder |
| Action bar | Buttons stretched to fill the width | Buttons **right-aligned**, sized to their labels |

Note that the shared controls — the choice card, the "Other" card, the buttons, the text field — are **one
element in both styles**. A style changes their palette, their minimum height and the space around them; it
never changes their internal anatomy.

### 8.3 Minimum metrics

| Surface | Standard | Alternative |
|---|---|---|
| Confirm | 420 × 300 | 440 × 260 |
| Pick (single / multi) | 420 × 300 | 460 × 280 |
| Text / masked | 420 × 300 | 440 × 260 |
| Form | 460 × 300 | 480 × 300 |
| Value tweak | 460 × 300 | *(falls back to Standard)* |
| Notify | 360 × 120 | 390 × 110 |
| Response preview | 360 × 120 | 390 × 110 |

Height cap: **85%** of the usable screen on every interactive surface, **45%** on both compact popups — in both
styles.

### 8.4 Alternative style specifics

**Kicker.** Uppercase, 10u semibold monospaced, **1.4u tracking**, in `accent`, clamped to one line. It is the
only thing identifying the surface kind in this style, so the strings matter:

`CONFIRM` · `INPUT` · `SECRET` · `PICK` · `PICK-MULTI` · `NOTIFY` · `PREVIEW` · `FORM <NN>/<NN>` (both numbers
zero-padded, e.g. `FORM 02/04`).

**Ordinal gutter.** Every option row is preceded by a fixed-width gutter holding the option's 1-based position
**zero-padded to two digits** (`01`, `02`, … `10`), at 10u medium monospaced in `text-muted`, right-aligned in
an **18u** column, 10u from the card, top-aligned 16u down so it lines up with the label's first line. The
"Other" card takes the next ordinal. **The gutter is decorative** — not a click target, and no digit key selects
an option.

**Status line.** Between the header and the option list: 10u medium monospaced `text-muted`, left-aligned,
padded 22u each side, 12u above and 6u below. Copy: `select one` on a single-select list (it never changes) ·
`select any` on a multi-select list while nothing is chosen · `<N> selected` once at least one is, counting
checked options plus the "Other" card when selected. It updates live on every toggle.

**Form progress.** One continuous rule 2u tall spanning the content width (22u each side, 12u below the header,
14u above the question): an unfilled track in `border` at 50%, overlaid from the left by a filled bar in
`accent` whose width is current ÷ total. The current step counts as filled. Screen-reader label `Step <N> of
<M>`. There is no separate counter line.

**Placeholders.** The single-line field always carries one: `Type your answer…` (a single ellipsis character)
in plain mode, `••••••••` (eight bullets) in masked mode. A form text step with no supplied placeholder falls
back to `Type your answer…` here, whereas the Standard style falls back to `Enter your answer...` (three
periods). **These are different strings.**

**Compact popups.** The 3u rail and the kicker share one colour, and it differs by kind: the notification uses
`accent`; the response preview uses `text-secondary`, so a preview never reads as an alert. The title clamps to
**two** lines here (one in Standard) and the project badge sits at the right end of the kicker row rather than
in its own utility row.

**Metrics:**

| | Standard | Alternative |
|---|---|---|
| Header padding | 20u sides | **22u** sides, 18u top, 8u between kicker / title / body |
| Ideal wrap width | 380u | **400u** |
| Text field height | 48u | **44u** |
| Choice card min height / gap | 48u / 8u | **46u / 6u** |
| Action button height | 48u | **42u** |
| Action button width | equal share of the row | right-aligned, **max(96u, label + 32u)**, 12u apart, ≥ 12u before the first |
| Action bar padding | 20u / 16u | 22u / 14u |
| Divider above the action bar | none | 1u at 45% of `border` |
| Compact popup column | 360u, padded 20u / 12u / 16u, 12u row gaps | **380u**, padded 16u / 14u, 10u row gaps |

In the action bar the **hint strip has the lowest layout priority** — on a narrow window the hints compress and
truncate before any button shrinks.

The hint strip's *contents* are identical in both styles (§4.9) — hints are style-independent.

---

## 9. Copy inventory

Every user-visible string, in one place. Strings are exact, including punctuation and ellipsis style.

### 9.1 Shared chrome

| Where | String |
|---|---|
| Report pill | `Report` |
| Report pill tooltip | `Report a bug or suggestion` |
| Tool strip | `Snooze` · `Feedback` · `Ask differently` |
| Snooze prompt | `Ask me again in:` |
| Snooze durations | `1m` · `5m` · `15m` · `30m` · `1h` |
| Ask-differently menu | `Confirmation` · `Single Select` · `Multi Select` · `Text Input` · `Password` · `Wizard Form` |
| Note pane captions | `NOTE ON THIS DIALOG` · `NOTE ON THIS FORM` · `NOTE ON THIS QUESTION` |
| Note pane subject fallback | `(this question)` |
| Note pane editor label | `YOUR NOTE` |
| Note pane buttons | `Clear` · `Close` |
| Note pane tooltips | `Close pane (Esc)` · `Close pane (note is preserved)` |
| Per-question note tooltips | `Add a note for the agent` · `Edit note` |
| "Other" card | `Other` · placeholder `Type your answer...` |
| Form text placeholder default | `Enter your answer...` |

### 9.2 Per surface

| Surface | Strings |
|---|---|
| **Confirm** | Title `Confirmation` · buttons `No` / `Yes` · hints `⏎ confirm`, `Esc cancel` |
| **Pick** | Buttons `Cancel` / `Done` · hints `↑↓ navigate`, `Space select`, `⏎ done` · a11y `Select one option. Use arrow keys to navigate, Space to select.` / `Select one or more options. Use arrow keys to navigate, Space to select.` |
| **Text** | Title `Input` · buttons `Cancel` / `Submit` · hints `⏎ submit`, `Esc cancel` |
| **Form** | Buttons `Cancel` / `Back` / `Next` / `Done` · counter `<N> of <M>` · hints `↑↓ navigate`, `Space select`, `⏎ next` / `⏎ done` · a11y `Step <N> of <M>`, `<P> percent complete` |
| **Notify** | Title `Notice` |
| **Preview** | Title `Response Preview` |
| **Value tweak** | `Framework detected: <name>` · `Replay animations` · tooltip `Trigger animation replay after changes (requires browser hook)` · `Show edits` · tooltip `Toggle debug console` · `File changed externally` · tooltip `Slider settings` · `Min` · `Max` · tooltip `Reset to original value` · `Move a slider to see changes` · buttons `Revert All` / `Tell Agent` / `Save to File` / `Cancel` · hints `↑↓ navigate`, `←→ adjust`, `⏎ save` / `⏎ cancel`, `Esc cancel` |
| **Report overlay** | `Report Issue` · `Describe the problem below.` · `What happened?` · `Briefly describe the issue...` · `⏎ next` · `Cancel` · `Next →` · `Save Screenshot?` · `Can we save a screenshot of this dialog to your clipboard? You can paste it directly into the GitHub issue with ⌘V.` · `⏎ copy & open` · `Skip` · `Yes, Copy Screenshot` |
| **Sketch** | Title `Layout Sketch` · `Add` · tooltips `Undo (⌘Z)`, `Redo (⌘⇧Z)` · `Stash` · `Drop here` · `Drop to stash` · `Add Block` · `Block label` · `Cancel` / `Add` · `Duplicate` / `Delete` · rename placeholder `Label` · tooltips `x: <column>, y: <row>` and `<width>×<height>` · footer `Drag to move · Resize from corner · Double-click to rename` and `⌘Z Undo · ⌘⇧Z Redo · ⌘D Duplicate · ⌫ Delete` · buttons `Cancel` / `Accept` · frame chrome `https://` and `9:41` |
| **Alternative style** | Kickers `CONFIRM` / `INPUT` / `SECRET` / `PICK` / `PICK-MULTI` / `NOTIFY` / `PREVIEW` / `FORM <NN>/<NN>` · status `select one` / `select any` / `<N> selected` · placeholders `Type your answer…` / `••••••••` |

### 9.3 Text the agent receives — never shown on screen

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

### 9.4 Presentation states used for capture and demonstration

A demonstration mode opens the note pane, or the snooze tray, automatically **0.30s** after a surface appears,
with the window already sized for it. This is a real presentation state a rebuild must support — a surface that
opens with a pane already expanded — not merely a test hook.

---

## 10. Known defects and open decisions

Each of these is a place where the current interface is contradictory, incomplete, or surprising. A rebuild
must decide each one deliberately. Recommendations are given; they are recommendations, not requirements.

**10.1 — No light palette.** Both palettes are dark and the host system's light appearance is ignored
everywhere except the sketch editor. *Recommend:* either declare dark-only as an intentional decision and say
the system setting is deliberately ignored, or specify a full light token set. If specifying one, use `window`
`#FFFFFF` · `surface` `#F2F2F7` · `surface-hover` `#E6E6F0` · `surface-pressed` `#D9D9E6` · `field` `#EBEBF0` ·
`border` `#CCCCD1` · `text-primary` `#000000` · `text-secondary` `#4D4D4D` · `text-muted` `#808080` · `accent`
`#007AFF` · `accent-pressed` `#0066D9`, with every accent tint keeping its opacity. Note that the sketch
editor's existing light palette disagrees on the muted role (`#666666`); reconcile to `#808080`.

**10.2 — Confirm and Text cannot scroll.** Both lack a scroll region, so a body past the height cap is clipped.
*Recommend:* give both the same internal scroll region as the other surfaces, keeping the header top, the tool
strip and the footer pinned.

**10.3 — Notification renders no formatting.** The one surface where a link would be most useful, and where the
person has four seconds to act on it, is the one that renders links as literal text. *Recommend:* apply the
same inline formatting as every other surface.

**10.4 — The hint strip lies.** It shows `F feedback` on a text surface where `F` types a letter, shows all
three tool hints while a caret sits in any field, and stays at full strength during the cooldown when six keys
are inert. The documented workaround — the modifier chord — appears nowhere on screen. *Recommend:* make the
strip reflect live availability. A suppressed hint renders at 40% opacity with its chip border dropped to 30%;
during the cooldown every hint dims; while a caret is in any field the three tool hints dim and the feedback
chip **swaps to the modifier chord**, so the working shortcut is always the one displayed.

**10.5 — Concurrency and multi-display are unspecified.** Nothing describes two notifications arriving at once,
so they occupy the same position and the first is invisible. And every surface is placed on one primary display
regardless of where the person is working, with no rule for a remembered position on a display that is no
longer attached. *Recommend:* notifications **queue** — a second waits for the first to close, then appears in
the same place with its own timer — but never queue behind an interactive dialog. Place every surface on the
display that currently contains the pointer, using that display's usable area for the 40u inset, the 80u top
offset and the height cap. Discard a remembered position that falls entirely outside every attached display.

**10.6 — The sketch editor has no project badge.** Every other surface shows one. *Recommend:* add it, left of
the grid-size pill, same styling, same tooltip.

**10.7 — Snooze durations are pointer-only.** The tray opens with a key and then cannot be operated with one.
*Recommend:* put the five chips in the Tab ring while the tray is expanded, let `←`/`→` move between them and
Space or Return pick, and return focus to the Snooze chip on collapse.

**10.8 — The destructive button variant is unreachable.** It exists in the system but no caller can request it,
so a destructive confirmation looks identical to a harmless one. *Recommend:* expose it as a confirm option.

**10.9 — The "Other" card is inconsistent.** 15% selected tint against every other card's 25%, and no hover or
pressed treatment. *Recommend:* unify to the ordinary card's treatment; its inner field keeps its own focus
border layered on top.

**10.10 — The report pill behaves three ways.** Two-step overlay on interactive surfaces; immediate browser on
the compact popups; immediate browser with a different pre-fill in the sketch editor. Nothing on screen
distinguishes them. *Recommend:* keep the divergence — a four-second popup genuinely cannot host a two-step
flow — but make it predictable with a distinct tooltip, `Report a bug (opens in browser)`.

**10.11 — Snooze and ask-differently silently destroy typed work.** Both discard the answer *and* any drafted
note with no warning. *Recommend:* when a non-empty draft exists, confirm first — `Discard your note?` with
`Keep editing` and `Discard and snooze` / `Discard and re-ask`.

**10.12 — Multi-select has no counter and no bounds.** No "2 selected" indicator, no select-all or clear-all,
and no way for a caller to require a minimum or maximum number of selections. *Recommend:* adopt the
Alternative style's status line (§8.4) into the Standard style, and add caller-side min/max with the disabled
button explained by the helper line from 10.14.

**10.13 — Masked input cannot be verified.** No reveal control, no caps-lock warning. Someone who mistypes a
long secret finds out later. *Recommend:* add a reveal control — an eye glyph at 13u in `text-muted`, 16u in
from the field's right edge, toggling the mask on press and reverting to masked when the surface loses focus.

**10.14 — A disabled primary button never explains itself.** On the pick surface and every form step the button
is dead, Return does nothing, and forward navigation is blocked with no message anywhere in the product.
*Recommend:* one line of helper text 8u below the answer region, left-aligned, 12u regular `text-muted`:
`Select an option to continue` · `Select at least one option to continue` · `Type an answer to continue` ·
`Type your custom answer to continue`. It appears **only after the person's first interaction with the
region**, never on open, so a freshly opened surface is not pre-scolded.

**10.15 — The response preview defeats itself.** Four seconds, no countdown, no pause, no scroll indicator, no
early dismissal except Escape. *Recommend:* pause the timer while the pointer is over the card; draw a 2u
progress bar along the bottom inside edge in `text-muted` at 40% draining left to right; let a click anywhere on
the body close it.

**10.16 — The tweak pane ignores `title`.** The option is accepted and has no effect; the pane always titles
itself with the client name. *Recommend:* wire it, or drop it from the caller surface.

**10.17 — Cancelling the tweak pane leaves every write on disk.** Escape, Cancel, snooze and ask-differently
all close without reverting the writes made during the session. This is the single most surprising behaviour in
the product. *Recommend:* Escape and Cancel revert every write before closing, matching the near-universal
mental model that cancelling undoes. Snooze and ask-differently do the same. Only `Save to File` leaves them.
Additionally add a **per-card changed marker** — a 3u `accent` rail down the card's left edge whenever its
value differs from where it opened — and a **written indicator**: a 4u `accent` dot left of the readout at 40%
while a write is pending, 100% for 600ms after it lands.

**10.18 — Three input methods clamp and snap differently.** Dragging snaps to the step and clamps to the
widened range; arrow keys snap but clamp to the *caller's* range; typed entry clamps to the widened range but
does **not** snap. The same card can hold a value the arrow keys cannot reach. *Recommend:* one rule for all
three — clamp to the card's current working range, then snap to the nearest step. The per-card range override
replaces the caller's bounds for every input method for the rest of the session.

**10.19 — The grid-size pill ignores the palette.** *Recommend:* draw it with `surface` and `text-muted` like
every other pill.

**10.20 — Option-cycling is undiscoverable.** Holding a modifier reaches buried blocks, but it is in no hint
line, has no tooltip, and there is no affordance showing that more blocks lie underneath. *Recommend:* add it
to the footer hints and show a small stacked-count badge when the pointer sits over two or more blocks.

**10.21 — Alignment guides are stale during the drag.** They reflect the block's committed edges, so they never
update while it moves — a "where you used to be aligned" indicator shown during the one gesture where that is
least useful. *Recommend:* evaluate them against the live snapped destination every frame. Keep exact-equality
matching (blocks already snap to cells) and draw each matching line once regardless of how many neighbours
match.

**10.22 — The sketch footer advertises two shortcuts that do not exist.** `⌘D Duplicate` and `⌫ Delete` are in
the hint line but only reachable from the context menu. *Recommend:* bind both, matching the menu actions
exactly and both undoable. If they cannot be bound, remove them from the hint line — never advertise a shortcut
that does nothing.

**10.23 — The sketch canvas has no selection model and no keyboard access.** No click-to-select, no selected
styling, no multi-select, no marquee, no way to act on several blocks at once — and no way to reach, move,
resize, rename or delete a block without a pointer. *Recommend:* decide selection deliberately rather than by
omission, and give the canvas a focus ring and arrow-key movement at minimum.

**10.24 — The exported image does not match the canvas.** On screen: square cells, a white canvas, pale blue
grid lines, numbered badges. Exported: a fixed 800 × 600 area with **non-square** cells, a near-black backdrop,
grey grid lines, labels instead of numbers, and a legend drawn below the stated bounds. The artifact does not
look like what the person approved. *Recommend:* derive cell size the same way (`min(800 ÷ columns, 600 ÷
rows)`, grid centred), use the white canvas with the same pale blue lines, show **both** the number badge and
the label, and compute the image height as grid + frame padding + the full legend so nothing is clipped.

**10.25 — The documented client-name prefix is not rendered.** The caller contract says the client name is
prefixed to titles; it is not — it only ever appears as a fallback when no title is supplied. *Recommend:*
correct the contract to match the rendering.

**10.26 — Accessibility is thin.** Roles and labels exist; nothing else does. The smallest text in the product
is 10u in `text-muted` — white at 50% on `#1A1A1F` — used for hint labels and the project badge, which is
exactly the text a first-time person most needs and is below common contrast minimums. *Recommend:* set a
contrast floor of **4.5:1 at or below 13u** and **3:1 above it**, in every palette. Raise `text-muted` to white
at **62%** wherever it carries text at 10u or 11u, keeping 50% only for decorative glyphs.

**10.27 — No right-to-left support.** *Recommend:* mirror the whole layout — the utility row swaps ends, the
note pane's side rule inverts, the tool strip becomes right-aligned, the two-button footer keeps primary-last
(which becomes leftmost), and the hint strip reverses order. **Never** mirror the return-key glyph or the
progress-bar fill direction.

**10.28 — No text-zoom or dynamic-type story.** Every dimension is fixed. *Recommend:* decide whether the type
ramp scales with a system text-size setting and, if so, which minimum widths float with it.

**10.29 — Timeout is invisible.** A request is abandoned after 10 minutes with no countdown, no warning, and no
stated behaviour at the moment it expires — including what happens to in-flight file writes in the tweak pane.
*Recommend:* decide the expiry behaviour explicitly and, at minimum, show a warning in the last 30 seconds.

**10.30 — Two divergent implementations of the pick surface exist.** One shows no selection indicators at all
(selection carried by border and tint alone), has no tool strip, no note pane and no ask-differently control,
caps its list at a fixed height, and shows one hint line reading `↑↓ navigate • Space select • Enter done` or
`↑↓ navigate • Enter confirm`. *Recommend:* pick one canonical behaviour — the one specified in §6.2 — and
bring the other to it.

---

## Appendix A — Metrics quick reference

| Element | Size |
|---|---|
| Card corner radius | 16u (sketch editor: 12u) |
| Shadow gutter | 8u per side (window is 16u larger than the card each way) |
| Header medallion | 56×56, glyph 24u semibold, fill at 15% |
| Compact medallion | 28×28, glyph 13u semibold, fill at 18% |
| Action button | 48u tall, 12u radius, 10u apart |
| Text field | 48u tall, 10u radius, 14u text inset |
| Choice card | ≥ 48u tall, 10u radius, 8u apart, 16u label inset, 16u indicator inset |
| Selection indicator | 24×24 (single-select inner dot 12u) |
| Snooze chip | 48×36, 8u radius |
| Note pane | **exactly 360u wide**, editor ≥ 180u tall, subject capped at 3 lines / 80u |
| Note pane close button | 22×22, glyph 11u |
| Per-question note button | 28×28, glyph 14u |
| Tool chip | 12u glyph + 12u label 6u apart, padded 12u/6u, 8u radius |
| Hint key chip | 10u medium, padded 4u/2u, capsule, 1u border at 60%; label 3u to its right |
| Project badge | glyph 9u + label 10u medium, padded 8u/4u, capsule |
| Report pill | glyph 9u + label 10u medium, padded 7u/3u, capsule, border at 40% |
| Cooldown bar | 3u tall, 1.5u radius, inset 8u each side, 6u above the button's bottom |
| Body ideal wrap width | 380u (Alternative: 400u) |
| Tweak value column | 110u fixed (number 56u, unit 24u), card label 60–120u |
| Tweak slider | track 4u tall / 2u radius / inset 7u; thumb 14u; control 18u tall; ticks 1×4u, ≥ 10u apart |
| Tweak console panel | 270u wide (260u content), 12u radius, 8u from the pane |
| Sketch tool rail | **exactly 120u wide**, 12u from the canvas |
| Sketch undo/redo | 32u tall, 6u radius, 4u apart |
| Sketch Add tile | 52u tall, 8u radius |
| Sketch block | 6u radius, inset 1u per side (nested 3u), grip 14×14 |
| Sketch footer buttons | Cancel 110×44, Accept 130×44, 12u apart |
| Add-block dialog | 280u wide, 20u padding, 16u row spacing |
| Screen placement | 40u from the left or right edge, 80u below the top of the usable area |
| Maximum width | screen width − 80u |
| Maximum height | 85% of the usable screen (45% for compact popups) |

## Appendix B — Timing quick reference

| Value | What |
|---|---|
| 0.10s | Focus lands after a surface appears, or an overlay closes |
| 0.12s | Hover feedback |
| 0.15s | Card micro-transitions; scroll-to-centre; focus after a step change; stash hint crossfade |
| 0.20s | Every pane, tray, overlay and window resize |
| 0.25s | Focus after a region expands |
| 0.30s | Demonstration-mode auto-reveal |
| 150ms | A tweak value reaches the file after movement stops |
| 2.0s | Opening cooldown (0.1–3.0s adjustable, or off) |
| 4.0s | Notification and response-preview lifetime |
| 10 min | A request is abandoned |
| 50 | Sketch undo history depth |
