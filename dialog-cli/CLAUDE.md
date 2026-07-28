# Dialog CLI (macOS)

## What this is

The binary that actually shows a dialog. Spawned once per dialog by `mcp-server`, prints a JSON response on stdout, exits. It holds no state between invocations — everything persistent lives in `settings.json`, written by the Tray App.

Swift + SwiftUI + AppKit. ~8.9k LOC, the densest subtree in the repo.

## Mental model

Three layers, and most bugs come from confusing them.

**`Services/DialogManager+*.swift` — lifecycle.** One extension per dialog type. Checks snooze, builds a spec, asks the active [[Skin]] for a view, creates the window, runs the modal loop, builds the response, appends history. Owns everything that is not pixels.

**`Skins/` — appearance.** A [[Skin]] is a complete visual implementation of the dialog set. `classic` wraps the original views; `alt` is an independent one. Skins receive a spec (request data + prebuilt callbacks) and return an `AnyView`. They also declare window metrics. Every `DialogSkin` member defaults to falling through to `ClassicSkin`, so a partial skin still runs. See `Sources/DialogCLI/Skins/README.md`.

**`Components/DialogContainer.swift` — behaviour.** The chassis every dialog wraps itself in: key router, feedback pane, snooze panel, report overlay, project badge. A skin changes layout; it does not reimplement this.

## Important invariants

- **Arrow-key and Tab navigation only work through `FocusManager`-registered `NSView`s.** `FocusableButton`, `FocusableTextField`, and `FocusableChoiceCard` are `NSViewRepresentable` for this reason. A pure-SwiftUI replacement silently loses keyboard navigation — it will look fine and be unusable.
- **Window width comes from `NSHostingView.fittingSize`,** measured in a two-pass layout in `createAutoSizedWindow`. Any pane must have a deterministic width, or the window resizes differently run to run. `AltActionBar` measures its own button labels for exactly this reason.
- **`Cooldown` swallows input for the first ~2s.** Intentional — it stops a keystroke aimed at the editor from answering the dialog. It also means automated key injection with a short delay appears to do nothing.
- **Feedback is an annotation, not an answer.** `feedbackText` arrives *alongside* the answer. The draft lives in `DialogContainer` and is read on submit via `DialogManager.globalFeedbackBinding`.
- **Snooze is checked before any window is created,** at the top of each `DialogManager+*` method. A snoozed call must never flash a window.
- **All AppKit widgets read the global `Theme`.** That is how a skin's `preferredTheme` restyles them for free — and why hardcoding a colour in a widget breaks every theme at once.

## Common change patterns

**Restyling a dialog** → edit the skin, not `DialogManager`.

**Adding a dialog type** → `DialogKind` case, spec struct, `DialogSkin` protocol method, `ClassicSkin` implementation, `Main.swift` command switch, request/response models. Then the wider checklist in `.claude/rules/dialog-parity.md`.

**Adding a skin** → one type under `Skins/<Name>/`, one line in `SkinRegistry.entries`. Implement only what you have reskinned.

**Changing keyboard behaviour** → `Services/DialogKeyRouter.swift`. Every dialog runs the same pipeline; do not add ad-hoc `NSEvent` monitors in a view.

## Verification

```bash
swift build                                   # from dialog-cli/
DIALOG_SKIN=alt .build/debug/DialogCLI confirm "$(cat ../test-cases/cases/confirm/basic.json)"
DIALOG_TEST_KEYS="d3.0;esc" .build/debug/DialogCLI confirm '...'   # scripted keys
```

`DIALOG_TEST_KEYS` injects keystrokes — format documented at the top of `Services/TestKeyDriver.swift`. Use a delay past the cooldown (`d3.0`) or the keys are swallowed. `DIALOG_TEST_PANE=snooze|feedback` opens a pane on appear.

A local build does **not** change the installed app. Use `bun run dev` from the repo root for that.

## Related context

- `Sources/DialogCLI/Skins/README.md` — the skin seam in detail
- `../GLOSSARY.md` — Skin vs Theme, Dialog vs Pane, Feedback vs note
- `.claude/rules/dialog-parity.md` — everything a new dialog type touches
- `../test-cases/CLAUDE.md` — fixtures and the screenshot runner
