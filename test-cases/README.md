# Dialog Visual Testing

Automated screenshot capture and verification for consult-user-mcp dialogs.

## Quick Start

Run it in the container. This suite spawns a real dialog per fixture — on your
own machine that means eighty windows taking the screen and the keyboard for
several minutes, and any focus change mid-run silently corrupts the result.

```bash
bun run test:container                       # everything
SUITES=visual bun run test:container         # just this suite
```

Screenshots come back in `../container/out/screenshots/`.
See `../container/README.md` for setup and knobs.

On the host anyway — for a single fixture you are iterating on, and only when
nobody is using the machine:

```bash
./test-runner.sh confirm       # a category, not the whole set
```

Screenshots saved to `screenshots/<timestamp>/`. The runner exits non-zero when
it captured fewer shots than fixtures, or when OCR could not read the words that
should be on a shot — which is how a photograph of the wrong window shows up as
a failure instead of a green run.

## Structure

```
test-cases/
  test-runner.sh        # Captures screenshots of all test cases
  verify-checklist.md   # What to check in each screenshot
  cases/
    confirm/            # Confirmation dialogs
    choose/             # Multiple choice dialogs
    text-input/         # Text input dialogs
    questions/          # Multi-question wizard
    notify/             # Notification panes
    tweak/              # Value adjustment pane
    sketch/             # Layout editor (propose_layout)
```

## Options

```bash
# Test with themes
DIALOG_THEME=sunset ./test-runner.sh
DIALOG_THEME=midnight ./test-runner.sh

# Slower render (if dialogs aren't captured)
RENDER_DELAY=2.0 ./test-runner.sh

# Debug mode (shows window detection info)
DEBUG=1 ./test-runner.sh
```

## Troubleshooting

**Screenshots capture the wrong window:**
The runner asks for the window owned by the process it just spawned, so a
stale dialog can no longer be photographed in place of the real one — a miss
is reported as a miss. If shots are still missing:
1. Run with `DEBUG=1`; on a miss the finder lists every window it saw
2. Increase delay: `RENDER_DELAY=2.0` (the container uses 1.5 — its compositor
   maps a new window more slowly than bare metal)
3. Grant Screen Recording in System Settings › Privacy & Security. In the
   container this is pre-granted by `prep.sh`; a failure there means the grant,
   not the layout.

**No screenshots captured:**
- Check that DialogCLI builds: `cd dialog-cli && swift build -c release`
- Grant accessibility permissions if prompted

## Adding Test Cases

Create a JSON file in the appropriate `cases/` subdirectory matching the request model:

| Directory | CLI Command | Model |
|-----------|-------------|-------|
| confirm/ | `confirm` | `{body, title, confirmLabel, cancelLabel, position, projectPath}` |
| choose/ | `choose` | `{body, choices, descriptions, allowMultiple, defaultSelection, position, projectPath}` |
| text-input/ | `textInput` | `{body, title, defaultValue, hidden, position, projectPath}` |
| questions/ | `questions` | `{questions[{id, question, type, options, multiSelect, placeholder}], mode, position, projectPath}` |
| notify/ | `notify` | `{body, title, sound}` |
| tweak/ | `tweak` | `{body, parameters[{id, label, file, line, column, expectedText, current, min, max, step, unit}]}` |
| sketch/ | `proposeLayout` | `{title, description, width, height, blocks[{label, x, y, w, h}]}` |

Optional visual test key:

- `testPane`: `"snooze"` or `"feedback"` to auto-open that pane before screenshot capture

## Keystroke Injection (interaction tests)

`DIALOG_TEST_KEYS` injects synthesized keystrokes through the app's own
event queue — same dispatch path as real typing (including the
`DialogKeyRouter` monitor), no Accessibility permission needed.

Semicolon-separated tokens, executed in order:

| Token | Meaning |
|-------|---------|
| `d<seconds>` | wait (e.g. `d1.5`) |
| `p<millis>` | pause between typed characters (default 0 = burst) |
| `t:<text>` | type text, one key event per character |
| `c:<char>` | ⌘-chord (e.g. `c:f`) |
| `left` `right` `up` `down` `esc` `return` `tab` `space` | special keys |
| `+<key>` | shift form of a special key, e.g. `+tab` |

Example — regression test for the feedback-pane focus race (typed text
must arrive complete, no snooze panel toggle):

```bash
DIALOG_TEST_KEYS="d1.5;p0;t:fsorry use safari;d1.0;esc;d0.4;return" \
  ./dialog-cli/.build/debug/DialogCLI confirm '{"body":"race test"}'
# expect: {"feedbackText":"sorry use safari", ...}
```

`keyboard-tests.sh` runs the whole keyboard contract as an asserting suite:
burst typing versus the hotkeys, the feedback-pane focus race, arrows while a
field is being edited, Space on the pick surface, the Other field, the Escape
ladder, and expired-dialog inertness. It spawns real dialogs and takes the
keyboard, so run it in the container:

```bash
SUITES=keyboard bun run test:container
```

## Known Issues

See `visual-bugs/` for documented regressions (e.g., choice cutoff with 6+ options).
