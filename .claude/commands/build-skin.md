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

<blindfold>
This session is launched with a deny-list that blocks every rendering of the product's current appearance. That
is deliberate: the point is a visual language derived from behaviour and direction, uncontaminated by what
exists.

Treat the blindfold as a rule, not just a wall:

- Do not read, search, reconstruct, or ask about the current appearance. If a tool call is denied, that is the
  system working. Move on — never route around it with a different tool, a shell command, or git history.
- Two files you *may* open carry values you must not use. `Theme/Theme.swift` and `Components/` are blocked
  precisely because of this; their API is reproduced in `<chassis_api>` below so you never need them. If you
  somehow see a colour, size, or radius from the existing UI, discard it.
- Never run a dialog without `DIALOG_SKIN` set to your own skin's id. The default renders the current UI.
- Do not open the built app's other windows, the docs site, or any image in the repo.

If you catch yourself reasoning from "how it probably looks today", stop. The contract is the only input.
</blindfold>

<the_contract>
Read `UI-BEHAVIOUR-SPECIFICATION.md` in full before writing anything. It is the complete behavioural contract
for eight surfaces and it is deliberately free of visual design.

How to read it:

- Everything it states is **binding**. Behaviour, states, sequence, keyboard model, outcome model and copy are
  invariant across skins — §7 is explicit about what a skin may and may not change.
- Everywhere it says a thing MUST be *distinguishable*, *distinct*, or *not read as* something else, it is
  handing you a design problem. Those are the requirements you are being paid to answer. Collect them first.
- §10 lists behavioural defects in the current build. You inherit the behaviour, not the defects — where a
  defect is a *visual* failure (10.4, 10.9, 10.26 especially), fix it in your skin rather than reproducing it.
- Where it is silent on appearance, you decide. Silence is permission, not an omission.

Build a decision list before you build anything: every "MUST be distinguishable" in the contract, and the
channel you will use to answer it. Two requirements answered by the same channel is a bug — the contract calls
this out for focus vs selection (§2.7 in its numbering, §3.13 here) and it generalises.
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
  sizing law and §9 limits govern what these must satisfy.
- Supply `preferredTheme` returning your own palette. An explicitly requested theme still wins over it.

The modal lifecycle, response building, keyboard routing, snooze, feedback pane, report flow and project badge
are owned by the chassis. You do not reimplement them and you must not change their behaviour.
</what_you_are_building>

<chassis_api>
Reproduced here so you never need to open the blocked files.

`ThemeProtocol` members you must supply. **The names are legacy and carry no design intent** — read them as
neutral slots and fill them from your own direction. `accentBlue` need not be blue.

```
name
windowBackground · cardBackground · cardHover · cardSelected
textPrimary · textSecondary · textMuted
accentBlue · accentBlueDark · accentGreen · accentRed
border · inputBackground
cornerRadius · buttonRadius · cardRadius
```

Shared focusable controls. They own their keyboard handling and focus ring, and they repaint from the active
theme:

```
FocusableButton(title:isPrimary:isDestructive:isDisabled:showReturnHint:action:)
FocusableTextField(placeholder:isSecure:text:onSubmit:focusTrigger:)
FocusableChoiceCard(title:subtitle:isSelected:isMultiSelect:onTap:)
```

**This is the one place your freedom is bounded.** These three draw their own internal anatomy — a choice card
decides for itself how selection and focus read. Two options, and you must choose deliberately and say which:

1. **Reuse them.** Your palette and radii flow in through the theme; their internal structure does not change.
   Cheapest, and keyboard behaviour is correct for free.
2. **Write your own.** Full control over anatomy — but you inherit responsibility for focus rings, key
   handling, hit targets and the focus/selection separation the contract requires. Only worth it if your
   direction genuinely cannot be expressed through the theme.
</chassis_api>

<constraints>
- Touch only `Skins/<YourName>/` and the single registry line. Do not modify the chassis, the existing skins,
  the models, the services, the server, or the Windows tree.
- Do not change any behaviour, keyboard binding, outcome shape, or copy string. §7 and §8 of the contract are
  the boundary. If your direction seems to require breaking one, it does not — find another expression.
- **`tweak` is the expensive one.** It is legitimate to leave it falling through, and the contract expects
  skins to do exactly that. Decide explicitly and say which you chose; do not drift into it by accident.
- No new dependencies.
- Build with `bun run dev` and restart the tray app. Never bare `swift build` — it compiles without updating
  what actually runs.
- At most 3 subagents, and only for genuinely parallel surface work.
</constraints>

<build_and_see>
This is visual work, so looking at it is the job, not a check at the end.

- Drive surfaces from the fixtures in `test-cases/cases/` — 65 of them, covering the shapes that break layouts:
  tiny bodies, unbreakable paths, twenty options, long descriptions, panes already open. Run them with your
  skin id set.
- Look at every surface you build, at more than one fixture, before moving to the next. A surface that has only
  been compiled has not been built.
- Exercise the states the contract names as required: focused-and-unselected, selected-and-unfocused, disabled
  primary, cooldown, note pane open, snooze tray expanded, an overflowing list.
- Verify the sizing law holds: the same request produces the same size twice, and opening the note pane is the
  only thing that changes width.
</build_and_see>

<done_when>
Every kind you chose to implement renders correctly across its fixtures, every "MUST be distinguishable" on
your decision list is answered by a distinct channel, and the skin reads as one system rather than seven
separately-solved screens.
</done_when>

<report>
Keep the write-up short — a page at most. High effort belongs in the work, not the summary.

Cover: the direction in a sentence and how it shows up; your decision list with the channel chosen for each;
which chassis option you took and why; what `tweak` does; what you deliberately left out. Then the file paths.

State what you saw, not what you expect to work. If a surface is unverified, say so plainly rather than
hedging. Do not narrate corrections you made along the way.
</report>
