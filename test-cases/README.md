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
```

## Options

```bash
# Test with themes
DIALOG_THEME=sunset ./test-runner.sh
DIALOG_THEME=midnight ./test-runner.sh

# Slower render for complex dialogs
RENDER_DELAY=1.5 ./test-runner.sh
```

## Adding Test Cases

Create a JSON file in the appropriate `cases/` subdirectory matching the request model:

| Directory | CLI Command | Model |
|-----------|-------------|-------|
| confirm/ | `confirm` | `{body, title, confirmLabel, cancelLabel, position}` |
| choose/ | `choose` | `{body, choices, descriptions?, allowMultiple, defaultSelection?, position}` |
| text-input/ | `textInput` | `{body, title, defaultValue, hidden, position}` |
| questions/ | `questions` | `{questions[], mode, position}` |

## Known Issues

See `visual-bugs/` for documented regressions (e.g., choice cutoff with 6+ options).
