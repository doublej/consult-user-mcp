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
    questions/          # Multi-question wizard/accordion
    notify/             # Notification panes
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

Optional visual test key:

- `testPane`: `"snooze"` or `"feedback"` to auto-open that pane before screenshot capture

## Known Issues

See `visual-bugs/` for documented regressions (e.g., choice cutoff with 6+ options).
