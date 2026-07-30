# Test Cases

## What this is

JSON fixtures for every dialog type, plus two harnesses over them. Two consumers of the fixtures, which is the thing worth knowing: the harnesses **and** the Tray App's debug menu all read from `cases/`.

The two harnesses answer different questions, and the second one is the one that fails a build:

| | `test-runner.sh` | `layout-audit.sh` |
|---|---|---|
| Question | does it look right? | does it fit? |
| Method | spawns real dialogs, `screencapture`, OCR | renders off-screen, measures the view tree and the bitmap |
| Verdict | word presence, margin strips | overflow, overlap, text-fit, escapes |
| Takes the keyboard | yes — one dialog per case, on screen | no — windows are parked off-display |
| Exit code | capture failures only | fails on any layout violation |

## Mental model

```
cases/<type>/<name>.json    a raw dialog request, exactly as the CLI receives it
test-runner.sh              iterates cases/, spawns each dialog, screenshots it
capture-dialog.swift        the screenshot helper
verify-checklist.md         what a human should look for per dialog type
screenshots/<timestamp>/    output (gitignored)

layout-audit.sh             the asserting harness — render every state, then check
skin-states/states.tsv      the state manifest: fixture + settle + pane + key script
skin-states/render/         off-screen renderer (main.swift) and the probe (probe.swift)
skin-states/check-layout.ts the rules; turns probe output into pass/fail
skin-states/waivers.json    known-bad states, each with a reason and an issue id
skin-states/audit/<skin>/   output: <state>.png beside <state>.layout.json (gitignored)
```

A **state** is a fixture plus how to drive it: which pane is open, what keys to
type, how long to settle. That is why `states.tsv` has more rows than `cases/`
has files — one fixture shot four ways is four states.

A fixture is not a wrapper format — it is the literal JSON argument passed to the [[Dialog CLI]]. That is why the same file works for both the runner and the debug menu.

Directory names are the *test-case* names, not CLI commands. `test-runner.sh` maps between them around line 88:

| Directory | CLI command |
|---|---|
| `confirm/` | `confirm` |
| `choose/` | `choose` |
| `text-input/` | `textInput` |
| `questions/` | `questions` |
| `notify/` | `notify` |
| `tweak/` | `tweak` |
| `sketch/` | (Sketch CLI) |

## Important invariants

- **The debug menu loads from here.** Never hardcode dialog JSON in `macos-app/Sources/AppDelegate.swift`. A fixture added here is the way to get a dialog into the debug menu.
- **A new dialog type needs four things:** a `cases/<type>/` directory with at least one fixture, an entry in the `test-runner.sh` command mapping, a `makeWindow` case in `skin-states/render/main.swift`, and a debug-menu item. Miss the mapping and the runner skips the whole type without reporting anything; miss the `makeWindow` case and the audit reports `unknown kind` and moves on.
- **A fixture is not a state.** Adding JSON to `cases/` gets it into the debug menu and the screenshot runner. It does *not* get it into the layout audit — that needs a row in `skin-states/states.tsv`. A fixture with no row is never measured.
- **Fixtures cover shapes, not just happy paths.** The value of `long-body`, `unbreakable-tokens`, `forty-options`, `wide-glyphs`, `unbalanced` is that they break layout. Keep adding the ugly ones — window sizing is the most fragile thing in the dialog CLI.
- **The skin is pinned, not inherited.** Both harnesses default to `caret`, the New Interface. Before that was true, every visual run silently exercised only the classic chassis, and the skin people had actually switched on was the one nothing tested.
- Some fixtures have companion setup files (a `.css` for tweak cases) that the runner copies into place. Keep them beside the JSON.

## What the audit can and cannot see

Worth knowing before trusting a green run, and before writing a rule:

- **`fittingSize` can never report overflow on its own.** `createAutoSizedWindow` *sizes the window from* `fittingSize`, so the two agree by construction. Overflow only means something once the window is clamped at the height cap. The rule is kept because that clamped case is real, not because it fires often.
- **SwiftUI `Text` is invisible to the view walk.** It is drawn into the hosting view's layer, not into a child `NSView`. Only the `NSViewRepresentable` widgets — `CaretTarget`, `CaretNoteEditor`, the `Focusable*` family — can be measured. A clipped SwiftUI label is caught by its *consequences* (an overlap, a box that stopped fitting), not directly.
- **Overlap between interactive views is the highest-signal rule.** It is what catches a note pane opening across the footer: nothing is clipped, the geometry stays self-consistent, and two things a person can click simply land on the same pixels.
- **The pixel probe derives the background from the image**, so it works on any skin and theme without being told the palette. It cannot see a collision — pixels do not record what drew them.
- **The rules are calibrated for caret and only caret.** Telling a row scrolled out of a list from a control the layout pushed outside the window has no general answer. Caret lays an oversized list out at full height and hangs the scroll view outside the surface, which is what the probe keys on; classic keeps it inside and clips at the layer with a translucent footer over the top. Run the audit against classic or bracket and every long-list state fails while looking perfectly correct in the screenshot — 14 and 8 respectively. That is why `SKINS` defaults to caret. Tracked in cum-6ql.
- **There is no `edge-ink` rule**, though the probe still measures it. It produced zero true positives across two skins and a wall of false ones. A rule nobody can trust is worse than no rule.

## Common change patterns

**Reproducing a layout bug** → add a fixture that triggers it *and* a `states.tsv` row, then run the audit and confirm it fails before fixing. `visual-bugs/` collects known-bad renders.

**Adding a fixture** → drop the JSON in the right `cases/` directory for the debug menu and the screenshot runner; add a `states.tsv` row to get it measured.

**A bug you are not fixing today** → add it to `waivers.json` with the rules it trips, a reason, and the issue id. A waiver that stops matching fails the run, so the fix gets noticed rather than quietly widening the waiver list.

## Verification

```bash
bun run test:layout                        # assert: caret, every state
SKINS="caret classic" bun run test:layout  # more than one — expect noise, see below
bun run test:visual                    # capture + OCR, on screen, caret by default
bun run test:keyboard                  # typing-vs-hotkey contract
```

From here: `./layout-audit.sh [name-filter]`, `./test-runner.sh`, `bash keyboard-tests.sh`.

The audit prints a `FAIL`/`WAIVED`/`STALE` line per state and exits non-zero. The screenshot runner captures; read `verify-checklist.md` against its output.

## Related context

- `verify-checklist.md` — per-dialog-type review checklist
- `../dialog-cli/CLAUDE.md` — what consumes these fixtures
- `../macos-app/CLAUDE.md` — the debug menu
- `.claude/rules/dialog-parity.md`
