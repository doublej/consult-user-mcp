---
description: Build the entire visual layer from scratch — every pixel, no shipped UI components — from the behaviour contract and a stated visual direction.
---

<role>
You are building the complete rendering layer for a product whose interface you have never seen, from a written
behaviour contract and a stated visual direction. You are not restyling, not translating a mockup, and not
writing a skin that leans on shared components. **Every pixel on screen is yours.** If you did not write it, it
must not be drawn.
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

<why_this_replaces_build_skin>
The previous attempt used `/build-skin`, which scoped the work to the skin seam and told the agent that the
container's furniture — report control, project badge, note pane — was "palette only", and that the shipped
prose renderer had to be reused. Those components are most of the pixels on a body-heavy surface. The result
was a careful palette swap on somebody else's layout, and it was correctly rejected.

**`UI-RENDERING-BOUNDARY.md` is the correction. Read it in full before writing anything.** It moves the seam,
lists exactly what you keep and what you write, and carries the behaviour embedded in each component you are
replacing. Everything below assumes you have read it.
</why_this_replaces_build_skin>

<blindfold>
This session is launched with a deny-list that blocks every rendering of the product's current appearance. That
is deliberate: the point is a visual language derived from behaviour and direction, uncontaminated by what
exists. **Writing a component fresh never requires reading the one it replaces** — everything a replacement must
preserve is behaviour, and behaviour is specified.

Treat the blindfold as a rule, not just a wall:

- Do not read, search, reconstruct, or ask about the current appearance. If a tool call is denied, that is the
  system working. Move on — never route around it with a different tool, a shell command, or git history.
- **The deny-list is not airtight and you must not lean on it.** `Theme/`, `Components/`, `Dialogs/` and the
  existing skins hold the current appearance. If you find yourself about to open one, the answer is in
  `UI-BEHAVIOUR-SPECIFICATION.md` or in `UI-RENDERING-BOUNDARY.md` §4 — go read that instead.
- `Services/` and `Models/` are **not** blocked and you will need them: the key router, the focus manager, the
  cooldown gate, the request and response models. Read those freely. They hold no pixels.
- Never run a dialog without `DIALOG_SKIN` set to your own id. The default renders the current UI.
- Screenshot only the window id returned by `test-cases/capture-dialog.swift`, never the screen or another
  window. Do not open the built app's other windows, the docs site, or any image in the repo.
- Build output quotes source from files you must not read. Filter it — print only error headlines from your own
  paths. Write the filter into a script rather than reading raw build logs.

If you catch yourself reasoning from "how it probably looks today", stop.
</blindfold>

<preflight>
1. Read `UI-RENDERING-BOUNDARY.md`, then `UI-BEHAVIOUR-SPECIFICATION.md` in full. The behaviour spec is long;
   read it in two passes rather than skimming one.
2. Pick your layer's name and confirm `dialog-cli/Sources/DialogCLI/Skins/<YourName>/` is empty —
   `find … -type f` and `git ls-files …`. A stub may exist from an earlier attempt. **Say in your first message
   which folder you are building in and whether it was empty.** If it has contents, stop and ask.
3. Confirm the repo is clean. Commit anything outstanding first.
</preflight>

<the_hardest_requirement>
This is the requirement the previous attempt failed, and it failed it while following every other instruction
correctly. Read it twice.

**The behaviour contract's ordering rules do not add up to a layout — but they feel like they do.** Read
§2.3's "identify the question, reach the tools, reach the actions", §3.9's "decline and retreat before commit",
§3.8's keyboard discovery, §3.5–§3.7's three exits, and you will derive: kind label, title, body, divider, tool
chips, buttons at the bottom right, hints beneath. That is the conventional dialog. It is what already exists.
Deriving it from the contract feels like rigour and produces a recolour.

The contract now says this against itself — §0.2 lists arrangement, decomposition, grouping and idiom as
deliberately unspecified, and §0.3 gives you the scramble test and the residue test. Run both. But the pull is
strong enough that the contract disclaiming it is not sufficient; the thesis below is.

So: **commit to a structural thesis before you write a line of view code, and write it down.**

A structural thesis is a claim about *geometry* — where things are and how the surface is built — that a
reader could not have guessed from the contract. "Amber accent, rounded sans, tight spacing" is not one. These
are:

- the answer region is *enclosed*, and the enclosure is the brand mark at surface scale;
- everything hangs off a fixed mono gutter that carries every key and ordinal, with no cards and no button row;
- the agent's words occupy a fixed rail and the person's answer owns the rest of the frame, full-bleed;
- the surface is a single continuous column with no dividers at all, separated only by weight and measure.

Pick one, state it in your first message, and let it decide the seven surfaces. **If your layout can be
described as "label, title, body, divider, chips, buttons bottom-right, hints", you have not done the work** —
regardless of how good the palette is.

State the thesis to the user and get agreement **before** building surface two.
</the_hardest_requirement>

<the_contract>
`UI-BEHAVIOUR-SPECIFICATION.md` is the complete behavioural contract for eight surfaces and it is deliberately
free of visual design.

- **Read the tier before the requirement** (§0.1). **LAW** is invariant — keyboard model, outcome model, what
  the agent receives. **CAPABILITY** means the person must be able to do a thing and the form is yours.
  **DEFAULT** is one workable answer you may replace outright, including on-screen copy (§8.1). §7.2 is the
  boundary.
- §3 is capabilities, not components. Two entries may be one element; one may be three; some need no persistent
  representation at all.
- Everywhere it says a thing MUST be *distinguishable*, *distinct*, or *not read as* something else, it is
  handing you a design problem. Collect those first.
- §7.5 lists what a style **may** add that the default has not: a label naming the surface kind, an ordinal
  beside each option, a count of what is chosen, a text-surface placeholder — and then "anything else". Free
  identity; use it.
- §10 lists defects. You inherit the behaviour, not the defects. **Fix every visual one** — 10.2, 10.3, 10.4,
  10.9, 10.10, 10.12, 10.13, 10.14, 10.15, 10.26 are all reachable now that you own the whole layer, where a
  skin could only reach some of them. Say which you fixed and how.
- Where it is silent on appearance, you decide. Silence is permission.

**Build a decision list before you build anything:** every "MUST be distinguishable" in the contract, and the
distinct channel you will use to answer it. Two requirements answered by the same channel is a bug — the
contract calls this out for focus versus selection (§3.10) and it generalises. Put the list in your report.
</the_contract>

<what_you_are_building>
A complete rendering layer, registered at the skin seam and owning everything beneath it.

- Lives in `dialog-cli/Sources/DialogCLI/Skins/<YourName>/`.
- Conforms to `DialogSkin` (`Skins/DialogSkin.swift`, `Skins/SkinRegistry.swift` — pure API, no visuals). One
  line in `SkinRegistry.entries`.
- Seven kinds: `confirm`, `choose`, `textInput`, `questions`, `tweak`, `notify`, `preview`. Each has a spec
  struct carrying request data plus prebuilt callbacks. You supply a view; you never touch the lifecycle.
- **Plus everything the old brief said was the chassis's:** your own container, your own tool strip and snooze
  tray and shape menu, your own note pane, your own report control and two-step flow, your own project badge,
  your own prose renderer, your own scroll region, your own focusable button, row and field.
- `metrics(for:)` — per-kind minimum width, minimum height, max height ratio, satisfying §2.2 and §9.
- `preferredTheme` is vestigial once you draw everything; supply it anyway so nothing you missed goes unstyled.

**Every protocol member defaults to falling through to the shipped style.** That is a good scaffold while
building and a trap at the end: a member left falling through renders the old layout. `tweak` is the one
legitimate exception — leaving it falling through is explicitly supported by §7.3, and it is expensive. Decide
it deliberately, say which you chose, and do not drift into it by accident.
</what_you_are_building>

<build_and_see>
This is visual work, so looking at it is the job, not a check at the end.

```bash
cd dialog-cli && swift build
DIALOG_SKIN=<yours> .build/debug/DialogCLI confirm "$(cat ../test-cases/cases/confirm/basic.json)"
```

`bun run dev` only updates the *installed* app; it does not affect this loop.

**Show the user the first surface as soon as it renders, with your structural thesis stated in words beside
it.** A wrong direction is cheapest to correct at surface one. Then stop and wait for agreement.

### Known-costly details

- **`fittingSize` measures twice.** Any control whose width is not a pure function of its content needs an
  explicit width. Measure labels with `NSFont` yourself. See `UI-RENDERING-BOUNDARY.md` §5.1.
- **The cooldown swallows input for ~2s.** Lead every key script with `d2.4`.
- **Snooze is global and persisted** to `~/Library/Application Support/ConsultUserMCP/settings.json` under
  `snoozeUntil`. A stray snooze makes every capture silently return nothing. Back the file up before a run and
  restore it after.
- **`capture-dialog.swift` recompiles on every invocation**, which takes longer than some of the states you are
  trying to catch. Compile it once with `swiftc -O` and call the binary.
- **Fonts:** you may not add SPM resources, so a direction naming a webfont has to be substituted from what
  macOS ships. Preserve the *system* — scale, weight discipline, the sans/mono split — substitute the faces,
  and say plainly which you substituted.
- The shell restricts pipes and some filters. Write multi-step shell into a script file and run it with `zsh`.

### The state harness — already built, do not rewrite it

It lives at `test-cases/skin-states/`. Add rows to it; leave the driver alone.

- `states.tsv` — `name ⇥ fixtureDir ⇥ fixtureCase ⇥ settleDelay ⇥ DIALOG_TEST_PANE ⇥ DIALOG_TEST_KEYS ⇥ projectPath ⇥ imageCount`
- `capture-states.sh [name-filter]` — renders each row off-display, writes `shots/<name>.png`, a
  `<name>.layout.json` report, and an `index.html` contact sheet.
- `bun run test:layout` — the same render plus the rules that fail a build. Your work is not done until this
  passes for your skin.

It renders each state off-display and reads the view tree directly, so nothing appears and nothing takes the
keyboard. Replacing it with a `screencapture` loop takes the display hostage and photographs whatever window
is frontmost — this project has already shipped that bug once and spent months looking at the wrong dialog.

- `DIALOG_TEST_PANE=snooze|feedback` opens a pane on appear — §8.4 demonstration state, a real presentation
  state, not just a test hook.
- `DIALOG_TEST_KEYS` — semicolon-separated, documented at the top of `Services/TestKeyDriver.swift`:
  `d<seconds>` wait · `p<millis>` typing pause · `t:<text>` type · `c:<char>` ⌘-chord ·
  `left`/`right`/`up`/`down`/`esc`/`return`/`tab`/`space` · `+<key>` shift form.

Fixture directory → CLI command: `confirm`→`confirm`, `choose`→`choose`, `text-input`→`textInput`,
`questions`→`questions`, `notify`→`notify`. `preview` accepts `{"body":"…"}` but has no shared fixture
directory — keep its fixtures beside the manifest rather than adding to the shared corpus.

The manifest must cover, at minimum: every fixture that breaks layout (tiny bodies, long bodies, unbreakable
paths, twenty options, long descriptions, unbalanced); both halves of the §3.3 presentation switch; masked
versus plain; single versus multi select; **all four focus × selection combinations**; disabled and enabled
primary; the cooldown (shoot at ~0.7s); the note pane on left and right anchors; the snooze tray expanded; a
drafted note showing the has-note indicator; report flow step 1; each form step including a text step; and both
transient popups.

**Read the PNGs back with the Read tool. A state you have not looked at is not built.**

Then verify the sizing law directly: shoot the same fixture twice, confirm identical dimensions, and confirm
the note pane is the only thing that changes width.
</build_and_see>

<constraints>
- Touch only `Skins/<YourName>/`, the single `SkinRegistry.entries` line, and `test-cases/skin-states/`.
- Do not modify the chassis, the existing skins, the models, the services, the server, or the Windows tree.
  Leaving them untouched is what keeps the other styles working and the diff additive.
- Do not change any behaviour, keyboard binding, outcome shape, or copy string. §7 and §8 of the behaviour spec
  are the boundary. If your direction seems to require breaking one, it does not — find another expression.
- No new dependencies, no new SPM resources.
- Commit after each surface lands and renders, not in one batch at the end.
- At most 3 subagents, and only for genuinely parallel surface work. A subagent inherits none of your blindfold
  reasoning — give it the decision list, the structural thesis, and `UI-RENDERING-BOUNDARY.md` explicitly.
</constraints>

<done_when>
- The acceptance checks in `UI-RENDERING-BOUNDARY.md` §6 pass, including the grep for leaked shipped symbols.
- Every "MUST be distinguishable" on your decision list is answered by a **distinct** channel.
- Every state in the manifest has been captured and looked at.
- The seven surfaces read as one system rather than seven separately-solved screens.
- For every surface, the answer to *"which visible element here did I not draw?"* is **none**.
</done_when>

<report>
Keep it short — a page at most. High effort belongs in the work.

Cover: **the structural thesis in a sentence and how it shows up on each surface**; your decision list with the
channel chosen for each; which §10 defects you fixed and how; any face you substituted; what `tweak` does; what
you deliberately left out. Then the file paths and the path to the contact sheet.

State what you saw, not what you expect to work. If a surface or a state is unverified, say so plainly rather
than hedging. Do not narrate corrections you made along the way.
</report>
