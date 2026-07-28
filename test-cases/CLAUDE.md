# Test Cases

## What this is

JSON fixtures for every dialog type, plus a screenshot runner. Two consumers, which is the thing worth knowing: the visual test runner **and** the Tray App's debug menu both read from `cases/`.

## Mental model

```
cases/<type>/<name>.json    a raw dialog request, exactly as the CLI receives it
test-runner.sh              iterates cases/, spawns each dialog, screenshots it
capture-dialog.swift        the screenshot helper
verify-checklist.md         what a human should look for per dialog type
screenshots/<timestamp>/    output (gitignored)
```

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
- **A new dialog type needs three things:** a `cases/<type>/` directory with at least one fixture, an entry in the `test-runner.sh` command mapping, and a debug-menu item. Miss the mapping and the runner skips the whole type without reporting anything.
- **Fixtures cover shapes, not just happy paths.** The value of `long-body`, `unbreakable-path`, `many-many-options`, `unbalanced` is that they break layout. Keep adding the ugly ones — window sizing is the most fragile thing in the dialog CLI.
- Some fixtures have companion setup files (a `.css` for tweak cases) that the runner copies into place. Keep them beside the JSON.

## Common change patterns

**Reproducing a layout bug** → add a fixture that triggers it before fixing. `visual-bugs/` collects known-bad renders.

**Adding a fixture** → drop the JSON in the right `cases/` directory. Nothing to register for an existing type.

## Verification

```bash
bun run test:visual                    # from repo root
./test-runner.sh                       # from here; screenshots to screenshots/<timestamp>/
```

Then read `verify-checklist.md` against the output. The runner captures; it does not assert.

## Related context

- `verify-checklist.md` — per-dialog-type review checklist
- `../dialog-cli/CLAUDE.md` — what consumes these fixtures
- `../macos-app/CLAUDE.md` — the debug menu
- `.claude/rules/dialog-parity.md`
