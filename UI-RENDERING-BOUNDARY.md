# The rendering boundary

**Companion to `UI-BEHAVIOUR-SPECIFICATION.md`.** That document says what the interface *does*. This one says
which code is allowed to *draw*, and what a from-scratch rendering layer has to carry over when it replaces the
shipped one.

---

## 0. Why this document exists

A previous attempt built a new visual language as a skin, using the shipped chassis for everything the skin
seam did not cover. The result was a recolour, and it was a recolour for a structural reason worth stating
plainly:

> **On a body-heavy surface, the shared components are most of the pixels.** `MarkdownText` renders nearly all
> the visible text on a confirm surface. `DialogContainer` renders the report control, the project badge, the
> note pane and the report overlay. Reuse those and the new "visual language" is a palette swap on somebody
> else's layout, no matter how much care goes into the parts that remain.

The old skin brief made this worse by describing those components as immovable — "drawn by container, palette
only" — which guaranteed the outcome it warned against.

**The correction is not "try harder inside the seam." It is to move the seam.** A rendering layer owns every
pixel or it owns none of them.

---

## 1. The one architectural rule

> **Register at the skin seam. Own the entire view tree beneath it.**

`DialogManager` calls `createSkinnedWindow(kind, position:) { skin in skin.confirmView(spec) }`. The view that
comes back **is the whole window content.** Nothing above it draws. That is enough room to own everything —
including the container — while leaving the lifecycle, the response shape and the history untouched, which is
what §7.2 of the behaviour spec requires of any presentation style.

Three consequences:

1. **Rewrite means "write fresh," not "edit."** The shipped components stay on disk, untouched and still used
   by the other styles. The new layer simply refers to none of them. The diff stays additive and nothing else
   regresses.
2. **A partial rewrite is worse than no rewrite.** `DialogSkin` defaults every member to falling through to the
   shipped style, which is a good scaffold while building and a trap at the end: a surface left falling through
   renders in the *old* layout, and a component left imported drags the old anatomy into a new one. Both must
   be gone before the work is done.
3. **The blindfold survives.** Writing fresh does not require reading what exists. Everything a replacement has
   to preserve is behaviour, and behaviour is specified — in `UI-BEHAVIOUR-SPECIFICATION.md` and in §4 below.

---

## 2. The seam

### 2.1 Behaviour — keep, call, never redraw

These hold no pixels. Read them, call them, do not reimplement them.

| Concern | Where it lives | What it gives you |
|---|---|---|
| Lifecycle per dialog kind | `Services/DialogManager+*.swift` | Request decode, snooze check, spec build, window creation, modal loop, response build, history append |
| The registration seam | `Skins/DialogSkin.swift`, `Skins/SkinRegistry.swift` | `DialogKind`, the spec structs, `SkinWindowMetrics`, one line to become selectable |
| Keyboard routing policy | `Services/DialogKeyRouter.swift` | The §4.1 key map, §4.2 suppression, §4.3 unwinding, §4.4 Return law |
| Focus ring machinery | `FocusManager` | `registerContent` / `registerButton` / `unregister` / `focus` / `focusFirst` / `focusLast` / `focusNext` / `focusPrevious`. It manages the ring; **it draws nothing** |
| The input gate | `CooldownManager` | `isCoolingDown` — the §4.6 block itself |
| Request / response shapes | `Models/` | `QuestionItem`, `QuestionAnswer`, `QuestionType`, `QuestionOption`, `DialogPosition`, `TweakParameter` |
| Persistence | settings, snooze state, interaction history | §4.7 availability, §4.10 history |
| Issue-URL construction | `GitHubReporter` | The §3.12 outcome — the pre-filled page. **Not** the two-step flow that precedes it |

**Do not modify any of them.** If a rendering need seems to require changing one, it does not — the need is
being expressed at the wrong layer.

### 2.2 Rendering — write fresh, import nothing

Everything below currently draws. A new rendering layer must supply its own and reference none of these
symbols.

| What | Currently | You write |
|---|---|---|
| Palette, radii, type tokens | `Theme/`, `ThemeProtocol` | Your own tokens. Conform to `ThemeProtocol` **only** because `preferredTheme` is how a palette reaches anything you did not write — and once you write everything, it reaches nothing. Treat it as vestigial |
| The chassis wrapper | `DialogContainer` | Your own container — §4 below is its full contract |
| Tool strip, snooze tray, shape menu | `DialogToolbar` | Yours |
| Action control | `FocusableButton` | Yours |
| Single-line input | `FocusableTextField` | Yours |
| Option row | `FocusableChoiceCard` | Yours |
| Internal scroll region | `AutoSizingScrollView` | Yours |
| Agent prose renderer | `MarkdownText` | Yours — §4.6 below |
| Selectable plain text | `SelectableText` | Yours |
| Note pane | inside the container | Yours — §3.6 of the behaviour spec, in full |
| Report control + two-step flow | inside the container | Yours — §3.12, in full |
| Project badge | inside the container | Yours — §3.2 |
| Concrete dialog views | `Dialogs/`, `Skins/Classic/`, `Skins/Alt/` | Yours, all seven kinds |

---

## 3. What was previously misdescribed

For anyone comparing against the old skin brief, these four statements in it are now void:

| Old brief said | Correct |
|---|---|
| "Report control — drawn by container — **No**, palette only" | Yours. §3.1 and §3.12 |
| "Project badge — drawn by container — **No**, palette only" | Yours. §3.2 |
| "Note pane — drawn by container — **No**, palette only" | Yours. §3.6 |
| "Use `MarkdownText` for every agent-supplied body — rolling your own breaks selectability and marker consumption" | Write your own that *does not* break them. §4.6 below is the contract it has to meet |

The old brief was right about one thing and it still holds: **the shared controls are most of the pixels.** It
drew the wrong conclusion from it.

---

## 4. Rewrite contracts

Behaviour currently embedded in the components being replaced. Losing any of it is a regression even if the new
version looks better.

### 4.1 The container

- **Installs the key router** on appear and tears it down on close. This is the single riskiest seam in the
  whole job: the router is a service you keep, but *its installation currently happens inside the component you
  are replacing*. Find the install/teardown API in `Services/DialogKeyRouter.swift` and reproduce the calls
  exactly. A container that forgets this produces a surface with no keyboard at all.
- **Owns the Escape stack** (§4.3): report flow → note pane → snooze tray → cancel. Exactly one layer per
  press, never two.
- **Gates on the cooldown** (§4.6): clicks swallowed, `Return` `Escape` `Space` `S` `F` `A` inert, **typing
  never blocked**. Escape is blocked at two independent levels, so it is inert even with the report flow open.
- **Vends the equivalent of `FeedbackController`** to the content: current note target, open-a-target, does-a-
  target-have-a-note, and the expanded-tool state that Escape collapses.
- **Holds the note draft** and exposes it for reading on submit. Whitespace-only counts as empty everywhere.
- **Applies the anchor** (§2.4): the pane opens away from the wall the surface is against.

### 4.2 The option row

- `acceptsFirstResponder` and `canBecomeKeyView` return true; **false when disabled**, so Tab skips it (§3.9).
- Registers with `FocusManager.registerContent` on `viewDidMoveToWindow`, unregisters when the window goes.
- Handles `Space` in `keyDown`. **Never installs its own `NSEvent` monitor** — arrows and Tab are routed.
- Draws its own focus indicator on `becomeFirstResponder` / `resignFirstResponder`. §10.26 makes defining this
  explicitly a requirement, not a nicety.
- Selection and focus on **separate channels** (§3.10). All four combinations legible.
- Indicator **form** differs between single and multi select — it is the only thing besides the surface's own
  identity cue telling the person whether they may pick more than one.
- The whole row is the target; the indicator is not a separate one.
- Labels wrap, never truncate. Rows do not shrink to fit short labels.

### 4.3 The action control

- Four variants, mutually distinguishable: primary, secondary, destructive, disabled (§3.9).
- The primary indicates that Return activates it — **and drops that indication when disabled**.
- Disabled is not focusable and is skipped by Tab.
- Press *and* release on the same control; dragging off cancels.
- Labels truncate. The control never grows and the surface never widens to fit one.
- **Its width must be a pure function of its content** — measure the label yourself and set it explicitly. See
  §5.1.

### 4.4 The text field

- States: rest, focused, masked, overflowing (§3.11).
- Clicking anywhere in the field places the caret, not only on the glyphs.
- A prefilled value opens **with its text selected**. Required behaviour, not a platform accident.
- Long content scrolls inside; the field never grows and the surface never widens.
- Cut / copy / paste / select-all work. No length limit, no trim on submit.
- Strictly single-line: pasting multi-line text yields one line.
- A masked field must not reveal the real characters in any state.

### 4.5 The scroll region

- Exactly **one** designated region per surface scrolls (§2.3). Header, tool strip and footer never scroll away.
- It must size to its content up to the cap and only then scroll — and it must do so **without breaking the
  two-pass measurement** in §5.1.
- Focus moving to a row scrolls that row to the centre of the list (§5.2).

### 4.6 The prose renderer

This is the component whose replacement is most often skipped, and the one that owns the most pixels.

- **Selectable and copyable** (§3.3).
- Consumes inline markers, never shows them literally (§3.4): `**bold**`, `*italic*` (single asterisks not
  adjacent to another asterisk), `` `code` `` as a distinct treatment, `[label](url)` showing only the label and
  opening in the default browser.
- **Applied in the order links → bold → italic → code.**
- **Block-level formatting is not interpreted** — headings, bullets, block quotes, fenced blocks and tables
  render as raw characters. A malformed link stays literal.
- Escaped newline and tab sequences become real ones **before** display — which means such a body trips the
  §3.3 presentation switch and renders as prose.
- The link colour is now yours. The shipped one is a hardcoded blue that will fight any palette.

Where it applies: the body of every interactive surface, the form's question text, and a note pane's quoted
subject. Where it does not: the notification and response-preview bodies (§3.4, §10.3) — decide that one
deliberately and say which way you went.

### 4.7 The report flow

Now yours end to end, except the URL construction.

- Captures a picture of the surface as it currently looks, then covers it. The surface beneath is inert and
  every key except Escape goes to the flow.
- Step 1 `Report Issue` / `Describe the problem below.` / field `What happened?` / placeholder `Briefly describe
  the issue...` / `Cancel` and `Next →` / hint `⏎ next`. `Next →` disabled while the description is empty or
  whitespace-only, and Return does nothing. The description is trimmed before use.
- Step 2 `Save Screenshot?` / the consent body verbatim from §8.1 / `Skip` and `Yes, Copy Screenshot` / hint
  `⏎ copy & open`. Both always enabled.
- Escape closes the flow and only the flow.
- If the picture cannot be captured the flow still completes; only the clipboard copy is skipped.
- On the transient popups and the sketch editor it opens the browser immediately instead — §10.10 recommends
  keeping that divergence but making it predictable with the tooltip `Report a bug (opens in browser)`.

---

## 5. The two seams that break silently

### 5.1 The sizing law

`NSHostingView.fittingSize` measures the content twice. §2.2 requires the same request to produce the same size
every time.

> **Any control whose intrinsic width is not a pure function of its content must be given an explicit width.**

Measure action-control labels with `NSFont` and set `.frame(width:)`. A control that negotiates its own width
against its parent will measure differently on the two passes and the window will size differently run to run.

Verify it directly: shoot the same fixture twice and confirm identical dimensions. Then confirm the note pane
is the only thing that changes width, and by exactly its own fixed amount.

### 5.2 The cooldown

`CooldownManager` publishes nothing and exposes no duration. §4.6 nonetheless requires a **visible indication
of how much time remains**.

Poll `isCoolingDown` for the state. For the length, read `buttonCooldownDuration` from
`~/Library/Application Support/ConsultUserMCP/settings.json` (§9: 2.0s default, 0.1–3.0s, or off). Let
`isCoolingDown` win when the two disagree, so the indication never outlives the block it describes.

The cooldown is armed a beat *after* the view appears — allow a few frames before concluding it is switched off.

---

## 6. Acceptance

The work is not a recolour when all of these hold.

**Mechanical.** From `dialog-cli/`:

```bash
# No shipped rendering symbol appears anywhere in the new layer.
grep -rnE 'DialogContainer|DialogToolbar|FocusableButton|FocusableTextField|FocusableChoiceCard|AutoSizingScrollView|MarkdownText|SelectableText|Theme\.Colors|ClassicSkin|AltSkin' Sources/DialogCLI/Skins/<Name>/
```

Two allowed hits and no others: `ClassicSkin.metrics(for: .tweak)`, if `tweak` is left falling through, and the
`SkinRegistry.entries` line. Everything else is a leak.

**Structural.** Every `DialogSkin` member is implemented, or `tweak` alone is not and that is stated as a
decision (§7.3 permits exactly that, and warns the undefined surface will look visibly unlike the rest).

**From §7.4 — requirements on any style, including this one.** All four are currently unmet across the product,
so a new layer is where they get met, not inherited:

- A **light palette exists**, and every requirement in the behaviour spec holds in it identically.
- **No hardcoded colour anywhere.** One element ignoring the active palette breaks every other palette at once —
  which also means a hit from the shipped theme is evidence of a leak, not of styling working.
- **Right-to-left mirroring decided deliberately.** §4.5 and §3.9 are stated in reading order and therefore
  mirror; nothing else in the spec does automatically.
- **Text scaling handled.** §2.2's measure-once law still has to floor, cap and reflow correctly when a surface
  is built at one text size and rendered at another.

**From §3.8 — what the person is told about the keyboard tracks live availability.** The spec calls this "a
requirement of any new style, not an option". Suppressed keys must read as unavailable; during the cooldown the
affected ones do; while a caret sits in any text field the single-letter shortcuts do, **and the annotation
shortcut presents as its modifier chord instead**, because that is the one that works.

**Visual.** Every state in the capture manifest has been shot **and looked at**, including all four
chosen × focused combinations, both halves of the §3.3 presentation switch, masked versus plain, unavailable
and available commit, the cooldown, anything attached beside the surface on both anchors, the postpone options
expanded, a drafted annotation showing its signal, report flow step 1, every form step, and both transient
surfaces.

**From §0.3 — run both tests on the finished thing, not only at the start.** The scramble test: if the spec's
section numbering were shuffled, would the design change? The residue test: name three things the design does
that the spec does not mention.

**The honest one.** For each surface, the answer to *"which visible element here did I not draw?"* is
**none** — the window's own rounded clip aside.
