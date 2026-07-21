# Dialog Visual Testing

Automated screenshot capture and verification for consult-user-mcp dialogs.

## Quick Start

```bash
chmod +x test-runner.sh
./test-runner.sh
```

Screenshots saved to `screenshots/<timestamp>/`.

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

**Screenshots capture wrong window (terminal instead of dialog):**
1. Run with `DEBUG=1` to see window detection output
2. Increase delay: `RENDER_DELAY=2.0`
3. Ensure Screen Recording permission is granted in System Settings > Privacy & Security
4. The script looks for windows with "dialog" in the owner name

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
| `left` `right` `up` `down` `esc` `return` `tab` | special keys |

Example — regression test for the feedback-pane focus race (typed text
must arrive complete, no snooze panel toggle):

```bash
DIALOG_TEST_KEYS="d1.5;p0;t:fsorry use safari;d1.0;esc;d0.4;return" \
  ./dialog-cli/.build/debug/DialogCLI confirm '{"body":"race test"}'
# expect: {"feedbackText":"sorry use safari", ...}
```

## Known Issues

See `visual-bugs/` for documented regressions (e.g., choice cutoff with 6+ options).
