---
description: Build a complete new dialog skin from the behaviour contract alone, blind to the existing UI.
---

<role>
You are designing and building a complete visual language for a product whose interface you have never seen,
working from a written behaviour contract and a stated visual direction. You are not translating a mockup and
you are not restyling something — you are answering, with your own decisions, every question the contract
deliberately leaves open.
</role>

<visual_direction>
$ARGUMENTS
</visual_direction>

If `<visual_direction>` is empty, stop and ask for it in one sentence. Do not invent one.

If it names a file or a design-handoff archive, unpack it to your scratchpad and read it before anything else.
A handoff usually contains two kinds of document and they are not equal:

- A **decision sheet** ("pick one from each row") is a menu of options that may never have been answered. It is
  not the direction.
- A **resolved system** ("locked system: …", a logo-construction page, exported assets) carries the picks that
  were actually made. That is the direction. Where the two disagree, the resolved system wins.

Read the exported assets too — an `.svg` mark tells you the final geometry and which element owns the accent.
A handoff may quote values from the current `Theme.swift`. Those are the appearance you are blind to. Take the
*system* (which hue, which ground, which face, which element carries the accent) and discard any literal value
it attributes to today's build.

<blindfold>
This session is launched with a deny-list that blocks every rendering of the product's current appearance. That
is deliberate: the point is a visual language derived from behaviour and direction, uncontaminated by what
exists.

Treat the blindfold as a rule, not just a wall:

- Do not read, search, reconstruct, or ask about the current appearance. If a tool call is denied, that is the
  system working. Move on — never route around it with a different tool, a shell command, or git history.
- **The deny-list is not airtight and you must not lean on it.** `Theme/`, `Components/`, `Dialogs/` and the
  existing skins hold the current appearance. `<chassis_api>` below reproduces every declaration you need from
  them, with types. If you find yourself about to grep one of those paths, the answer is already in this brief —
  go read it again. If a value from the existing UI reaches you anyway, discard it.
- Never run a dialog without `DIALOG_SKIN` set to your own skin's id. The default renders the current UI.
- Screenshot only the window id returned by `test-cases/capture-dialog.swift`, never the screen or another
  window. Do not open the built app's other windows, the docs site, or any image in the repo.

If you catch yourself reasoning from "how it probably looks today", stop. The contract is the only input.
</blindfold>

<preflight>
Before writing anything:

1. Pick your skin's name and confirm `dialog-cli/Sources/DialogCLI/Skins/<YourName>/` is empty —
   `find … -type f` and `git ls-files …`. A stub directory may exist from an earlier attempt. **Say in your
   first message to the user what folder you are building in and whether it was empty.** If it has contents,
   stop and ask before touching them.
2. Confirm the repo is clean (`git status`). Commit anything outstanding first.
</preflight>

<the_contract>
Read `UI-BEHAVIOUR-SPECIFICATION.md` in full before writing anything. It is the complete behavioural contract
for eight surfaces and it is deliberately free of visual design. It is long; read it in two passes rather than
skimming one.

How to read it:

- **Read the tier before the requirement** (§0.1). **LAW** is invariant — keyboard model, outcome model, what
  the agent receives. **CAPABILITY** means the person must be able to do a thing and *the form is yours*.
  **DEFAULT** is one workable answer you may replace outright. §0.2 lists what the contract deliberately does
  not specify — arrangement, decomposition, grouping, idiom — and that list is the size of your freedom.
- §3 is a list of **capabilities, not components**. Two entries may be one element; one entry may be three.
  Assembling it top to bottom in the order written is the failure mode §0.3 exists to prevent — run both
  checks there before you commit to a design.
- Everywhere it says a thing MUST be *distinguishable*, *distinct*, or *not read as* something else, it is
  handing you a design problem. Those are the requirements you are being paid to answer. Collect them first.
- §7.5 lists things a style **may** add that the default has not: a label naming the surface kind, an ordinal
  beside each option, a count of what is chosen, a placeholder on the text surface. It ends with "anything
  else" — the list is examples, not permission.
- §10 lists behavioural defects in the current build. You inherit the behaviour, not the defects — where a
  defect is a *visual* failure (10.4, 10.9, 10.12, 10.14, 10.26 especially), fix it in your skin rather than
  reproducing it.
- Where it is silent on appearance, you decide. Silence is permission, not an omission.

Build a decision list before you build anything: every "MUST be distinguishable" in the contract, and the
channel you will use to answer it. Two requirements answered by the same channel is a bug — the contract calls
this out for focus vs selection (§3.10) and it generalises. Put the list in your report.
</the_contract>

<what_you_are_building>
A skin: a complete visual implementation of the dialog set, registered alongside the existing ones and selected
at runtime.

- Live in `dialog-cli/Sources/DialogCLI/Skins/<YourName>/`.
- Conform to `DialogSkin` (read `Skins/DialogSkin.swift` and `Skins/SkinRegistry.swift` — both are pure API,
  no visuals). Add one line to `SkinRegistry.entries`.
- Seven kinds: `confirm`, `choose`, `textInput`, `questions`, `tweak`, `notify`, `preview`. Each has a spec
  struct carrying request data plus prebuilt callbacks. You supply a view; you never touch the lifecycle.
- **Every protocol member has a default that falls through to the existing skin**, so a half-finished skin
  compiles and runs. Build one surface at a time and keep it runnable throughout.
- Supply `metrics(for:)` — per-kind minimum width, minimum height, max height ratio. The contract's §2.2
  sizing law and §9 limits govern what these must satisfy. A kind you leave falling through must return the
  default skin's metrics for that kind, or it will be sized for a layout it is not using.
- Supply `preferredTheme` returning your own palette. An explicitly requested theme still wins over it.
</what_you_are_building>

<chassis_api>
Reproduced here so you never need to open the blocked files. Everything below is declaration only.

### Where your view lands

`DialogManager` calls `createSkinnedWindow(kind, position:) { skin in skin.confirmView(spec) }`. **Your view is
the entire window content.** There is no outer frame to inherit; if you do not paint a ground, nothing does.

### ThemeProtocol — you implement this

Colours are `NSColor`. Radii are `CGFloat`. **The names are legacy and carry no design intent** — read them as
neutral slots and fill them from your own direction. `accentBlue` need not be blue; `accentGreen` is just a
fourth slot.

```swift
protocol ThemeProtocol {
    var name: String { get }
    var windowBackground: NSColor { get }
    var cardBackground: NSColor { get }
    var cardHover: NSColor { get }
    var cardSelected: NSColor { get }
    var textPrimary: NSColor { get }
    var textSecondary: NSColor { get }
    var textMuted: NSColor { get }
    var accentBlue: NSColor { get }
    var accentBlueDark: NSColor { get }
    var accentGreen: NSColor { get }
    var accentRed: NSColor { get }
    var border: NSColor { get }
    var inputBackground: NSColor { get }
    var cornerRadius: CGFloat { get }
    var buttonRadius: CGFloat { get }
    var cardRadius: CGFloat { get }
}
```

`Theme.Colors.<member>` returns the active theme's value as a SwiftUI `Color`. Every shared AppKit control reads
it, which is how your palette reaches them.

### DialogContainer — wrap every interactive surface in this

```swift
DialogContainer(
    bindings: DialogKeyBindings = DialogKeyBindings(),
    currentDialogType: String = "",              // "confirm" | "choose" | "textInput" | "questions" | "tweak"
    dialogPosition: DialogPosition = .center,
    contentMinWidth: CGFloat = 420,
    globalFeedbackSubject: FeedbackSubject,
    onAskDifferently: ((String) -> Void)? = nil,
    feedbackBindingForQuestion: ((String) -> Binding<String>)? = nil,
    @ViewBuilder content: @escaping (FeedbackController) -> Content
)

struct DialogKeyBindings {
    var canSubmit: () -> Bool = { false }
    var onSubmit: () -> Void = {}
    var onCancel: () -> Void = {}
    var onArrowLeft:  (() -> Bool)? = nil
    var onArrowRight: (() -> Bool)? = nil
    var onArrowUp:    (() -> Bool)? = nil
    var onArrowDown:  (() -> Bool)? = nil
    var onTab: ((NSEvent.ModifierFlags) -> Bool)? = nil
}

enum FeedbackTarget: Equatable { case global; case question(id: String) }
struct FeedbackSubject { enum Kind { case question, dialog, form }; let kind: Kind; let text: String? }

struct FeedbackController {
    let currentTarget: FeedbackTarget?
    let openFeedback: (FeedbackTarget) -> Void
    let hasFeedback: (FeedbackTarget) -> Bool
    let expandedTool: Binding<DialogToolbar.ToolbarTool?>   // enum ToolbarTool { case snooze }
}
```

Reading the note draft on submit — a whitespace-only draft counts as empty (§4.8):

```swift
DialogManager.shared.globalFeedbackBinding?.wrappedValue   // Binding<String>?
```

### What the container draws, and what you draw

This is the part that decides whether you have built a new visual language or recoloured an old one. **Read it
before you plan a single surface.**

| Element | Drawn by | Can you restyle it? |
|---|---|---|
| Report control (top of every surface) | container | **No** — palette only |
| Project badge | container | **No** — palette only |
| Report flow overlay (two steps) | container | **No** — palette only |
| Note pane (the side pane) | container | **No** — palette only |
| Key router install, Escape unwinding, cooldown | container | No, and must not |
| Outer clip to `Theme.cornerRadius` | container | Radius only |
| **Ground / background** | **you** | It paints none |
| **Tool strip** (`Snooze` · `Feedback` · `Ask differently`) | **you** | **Yes** — see below |
| Header, body, option list, fields, progress, hints, actions | **you** | Yes |

The container renders the report control and project badge in a strip **above** your content, not overlaid on
it — do not reserve a horizontal gutter for them.

### The tool strip is yours if you want it

The container hands your content a `FeedbackController` and expects the content to render the strip. The
shipped component is:

```swift
DialogToolbar(
    expandedTool: controller.expandedTool,
    currentDialogType: "confirm",
    hasFeedback: controller.hasFeedback(.global),
    onSnooze: spec.onSnooze,                                  // (Int) -> Void, minutes
    onOpenFeedback: { controller.openFeedback(.global) },
    onAskDifferently: spec.onAskDifferently                   // (String) -> Void
)
```

It also owns the expanded snooze tray and the ask-differently menu. **You may replace it with your own view
that calls the identical callbacks.** Appearance is not behaviour, and the contract does not require these
three capabilities to be grouped, or to be persistent, at all. If you do replace it, you must still satisfy
§3.5 (a small fixed set of durations, every one keyboard-reachable per §10.7), §3.6 (including the
has-annotation signal, which is the only warning that unsent work exists) and §3.7 (six shapes, the current
one marked and unavailable).

### The three focusable controls

```swift
FocusableButton(title: String, isPrimary: Bool = false, isDestructive: Bool = false,
                isDisabled: Bool = false, showReturnHint: Bool = false, action: @escaping () -> Void)

FocusableTextField(placeholder: String = "", isSecure: Bool = false, text: Binding<String>,
                   onSubmit: (() -> Void)? = nil, focusTrigger: Binding<Bool> = .constant(false))

FocusableChoiceCard(title: String, subtitle: String?, isSelected: Bool,
                    isMultiSelect: Bool, onTap: () -> Void)
```

They are `NSViewRepresentable`s registered with `FocusManager`, which is the only reason arrow-key and Tab
navigation work. They draw their own internal anatomy — a choice card decides for itself how selection and
focus read — and they repaint from the active theme.

**This is where the assignment is usually lost.** These three plus the container's own controls are most of the
pixels on screen. Reuse them all and you will ship the existing arrangement in a new palette, which is not what
was asked for. Choose deliberately, say which you chose, and expect to justify it:

1. **Reuse.** Cheapest, keyboard correct for free, and honestly a recolour. Legitimate only if your direction
   really is a palette-and-type direction.
2. **Write your own.** Register them yourself and you own the anatomy — including the focus indicator §10.26
   says a rebuild MUST define explicitly. This is the default expectation for a fresh visual language.

If you write your own, this is the whole API you need:

```swift
FocusManager.shared.registerContent(_ view: NSView)   // arrow-navigable: option rows, fields
FocusManager.shared.registerButton(_ view: NSView)    // Tab-only: action controls
FocusManager.shared.unregister(_ view: NSView)        // on removeFromSuperview
FocusManager.shared.focus(_ view: NSView)
FocusManager.shared.focusFirst() / focusLast() / focusNext() / focusPrevious()
```

Your `NSView` must return `true` from `acceptsFirstResponder` and `canBecomeKeyView`, register on
`viewDidMoveToWindow`, unregister when the window goes away, draw its own focus indicator in
`becomeFirstResponder` / `resignFirstResponder`, and handle `keyDown` for Space. Arrow and Tab keys are routed
by the chassis; do not add your own `NSEvent` monitors. Disabled controls must return `false` from
`canBecomeKeyView` so Tab skips them (§3.9).

### Other shared pieces you will want

```swift
AutoSizingScrollView { content }                     // the one internal scroll region per §2.3
MarkdownText(_ text: String, fontSize: CGFloat = 13,
             color: Color = …, alignment: NSTextAlignment = .center)   // §3.4 inline formats, selectable
SelectableText(_ text: String, fontSize: CGFloat = 13, weight: NSFont.Weight = .regular,
               color: Color = …, alignment: NSTextAlignment = .left)
CooldownManager.shared.isCoolingDown -> Bool         // NOT published; poll it if the view must react
```

Use `MarkdownText` for every agent-supplied body — it is what makes the body selectable (§3.3) and what
consumes the inline markers (§3.4). Rolling your own `Text` breaks both.

### Model types

```swift
enum DialogPosition: String { case left, center, right }
struct QuestionOption { let label: String; let description: String? }
enum QuestionType: String { case choice, text }
struct QuestionItem { let id, question: String; let type: QuestionType; let options: [QuestionOption]
                      let multiSelect, allowOther, hidden: Bool; let placeholder: String? }
enum QuestionAnswer { case choices(Set<Int>); case text(String)
                      var isEmpty: Bool; static func empty(for: QuestionItem) -> QuestionAnswer
                      static func toggling(choice:in:otherSelected:multiSelect:) -> (QuestionAnswer, Bool)
                      static func togglingOther(in:otherSelected:multiSelect:) -> (QuestionAnswer, Bool) }
```

`QuestionFormState` (an `ObservableObject`) holds the form's answers and note drafts and vends bindings:
`bindingForAnswer(_:)`, `bindingForText(_:)`, `bindingForOtherSelected(_:)`, `bindingForOtherText(_:)`,
`bindingForFeedback(_:)`, `hasFeedback(_:)`, `isAnswered(_:)`.
</chassis_api>

<layout_gotchas>
Hard-won; each one costs a rebuild cycle to rediscover.

- **Window width comes from `NSHostingView.fittingSize`** in a two-pass layout. §2.2 requires the same request
  to produce the same size twice, so **any control whose intrinsic width is not a pure function of its content
  must be given an explicit width.** Measure action-control labels yourself with `NSFont` and set
  `.frame(width:)`; do not let the shared button negotiate. Its intrinsic label font is larger than you will
  guess — measure at ~15pt semibold and add generous padding, or labels truncate.
- `FocusableButton` does not honour a `.frame(height:)`; it sizes itself.
- **The cooldown swallows input for ~2s.** Injected keystrokes before then do nothing — always lead a key
  script with `d2.4`.
- Snooze is checked before any window is created, and it is **global and persisted** to
  `~/Library/Application Support/ConsultUserMCP/settings.json` under `snoozeUntil`. A stray snooze makes every
  later capture silently return nothing. Back that file up before a capture run and restore it after.
- Fonts: the skin may not add SPM resources, so a direction naming a webfont (Manrope, DM Mono, Instrument
  Sans…) has to be substituted from what macOS ships. Preserve the *system* — scale, weight discipline, the
  sans/mono split — substitute the faces, and say plainly in your report which you substituted.
</layout_gotchas>

<constraints>
- Touch only `Skins/<YourName>/`, the single `SkinRegistry.entries` line, and `test-cases/skin-states/` for the
  capture harness. Do not modify the chassis, the existing skins, the models, the services, the server, or the
  Windows tree.
- Do not change any behaviour, keyboard binding, or outcome shape. §7.2 of the contract is the boundary, and
  §8.2 and §8.3 are exact. If your direction seems to require breaking one, it does not — find another
  expression.
- On-screen copy (§8.1) is **DEFAULT, not law** — you may replace it where the meaning survives. Caller-supplied
  strings — titles, bodies, questions, option text, confirm's action labels — are never yours.
- **`tweak` is the expensive one.** It is legitimate to leave it falling through, and the contract expects
  skins to do exactly that. Decide explicitly and say which you chose; do not drift into it by accident.
- No new dependencies, no new SPM resources.
- Commit after each surface lands and renders, not in one batch at the end.
- At most 3 subagents, and only for genuinely parallel surface work. A subagent inherits none of your blindfold
  reasoning — give it the decision list and the chassis boundary explicitly.
</constraints>

<build_and_see>
This is visual work, so looking at it is the job, not a check at the end.

Iterate with `swift build` from `dialog-cli/` and run `.build/debug/DialogCLI` directly — that is what the
capture harness drives, and it is fast. Use `bun run dev` only when you want the *installed* app updated;
it does not affect the loop below.

```bash
cd dialog-cli && swift build
DIALOG_SKIN=<yours> .build/debug/DialogCLI confirm "$(cat ../test-cases/cases/confirm/basic.json)"
```

**Show the user the first surface as soon as it renders**, before building the rest. Send the PNG with
`SendUserFile`. A direction that is wrong is cheapest to correct at surface one, and the chassis boundary above
is exactly the kind of thing they will spot instantly and you cannot.

Note: the shell here restricts pipes and some filters. Write multi-step shell into a script file in your
scratchpad and run it with `zsh <path>` rather than fighting one-liners.

### The state harness — required, not optional

You must be able to screenshot **every** state, not just the default one, and re-shoot them all after a change.
Build it at `test-cases/skin-states/` before the second surface:

- `states.tsv` — one row per state: `name ⇥ fixtureDir ⇥ fixtureCase ⇥ settleDelay ⇥ DIALOG_TEST_PANE ⇥ DIALOG_TEST_KEYS`
- `capture-states.sh [name-filter]` — iterates the manifest, shoots each, writes `shots/<name>.png` and an
  `index.html` contact sheet.

Per state the recipe is: launch the CLI backgrounded with `DIALOG_SKIN` set → `sleep <settleDelay>` →
`swift test-cases/capture-dialog.swift` to get the window id → `screencapture -o -x -l<id>` → kill the process.

The two hooks that drive states:

- `DIALOG_TEST_PANE=snooze|feedback` — opens a pane on appear (this is §8.4 demonstration state, a real
  presentation state, not just a test hook).
- `DIALOG_TEST_KEYS` — semicolon-separated script, documented at the top of `Services/TestKeyDriver.swift`:
  `d<seconds>` wait · `p<millis>` typing pause · `t:<text>` type · `c:<char>` ⌘-chord · `left`/`right`/`up`/
  `down`/`esc`/`return`/`tab`. Always lead with `d2.4` to clear the cooldown.

Fixture directory → CLI command: `confirm`→`confirm`, `choose`→`choose`, `text-input`→`textInput`,
`questions`→`questions`, `notify`→`notify`.

The manifest must cover, at minimum: every fixture that breaks layout (tiny bodies, long bodies, unbreakable
paths, twenty options, long descriptions, unbalanced); both halves of the §3.3 presentation switch; masked vs
plain; single vs multi select; **all four focus × selection combinations**; disabled primary and enabled
primary; the cooldown (shoot at ~0.7s); note pane open on left and right anchors; snooze tray expanded; a
drafted note showing the has-note indicator; report flow step 1; each form step including a text step; and both
transient popups.

Read the PNGs back with the Read tool. A state you have not looked at is not built.

Finally, verify the sizing law directly: shoot the same fixture twice and confirm identical dimensions, and
confirm the note pane is the only thing that changes width.
</build_and_see>

<done_when>
Every kind you chose to implement renders correctly across its fixtures, every "MUST be distinguishable" on
your decision list is answered by a distinct channel, every state in the manifest has been captured and looked
at, and the skin reads as one system rather than seven separately-solved screens.
</done_when>

<report>
Keep the write-up short — a page at most. High effort belongs in the work, not the summary.

Cover: the direction in a sentence and how it shows up; your decision list with the channel chosen for each;
which chassis option you took and **which elements remain the chassis's** so the reader knows the ceiling; any
face you substituted; what `tweak` does; what you deliberately left out. Then the file paths and the path to
the contact sheet.

State what you saw, not what you expect to work. If a surface or a state is unverified, say so plainly rather
than hedging. Do not narrate corrections you made along the way.
</report>
