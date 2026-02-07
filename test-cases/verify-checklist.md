# Dialog Visual Verification Checklist

Use this checklist when reviewing screenshots from `test-runner.sh`.

---

## General (All Dialogs)

- [ ] Dialog renders without clipping or overflow
- [ ] Text is readable and properly wrapped
- [ ] Dialog is positioned correctly (left by default)
- [ ] Window shadow and border render properly
- [ ] Theme colors are consistent (if testing themed)
- [ ] No visual artifacts or rendering glitches

---

## Confirm Dialogs

### `confirm/basic.json`
- [ ] Title "Confirmation" displayed in toolbar
- [ ] Body text fully visible
- [ ] Yes/No buttons present and properly styled
- [ ] Primary button (Yes) visually distinct

### `confirm/custom-labels.json`
- [ ] Custom title "Delete Files" displayed
- [ ] Long body text wraps correctly
- [ ] Custom labels "Delete All" / "Keep Files" render
- [ ] Destructive action styling (if applicable)

### `confirm/with-project.json`
- [ ] Project badge visible in top-right corner
- [ ] Badge shows folder icon and project name ("my-app")
- [ ] Badge has tooltip showing full path on hover
- [ ] Badge styling is subtle (muted colors, capsule shape)

### `confirm/pane-snooze.json`
- [ ] Snooze pane is expanded
- [ ] Duration chips (`1m`, `5m`, `15m`, `30m`, `1h`) are visible
- [ ] No overlap between snooze pane and footer buttons

### `confirm/pane-feedback.json`
- [ ] Feedback pane is expanded
- [ ] Feedback input field and Send button are visible
- [ ] No clipping in toolbar expanded state

---

## Choose Dialogs

### `choose/single-select.json`
- [ ] Body question visible
- [ ] 3 choices displayed as cards
- [ ] No selection indicator (single-select, none pre-selected)
- [ ] Keyboard hints show navigation instructions

### `choose/multi-select.json`
- [ ] Multi-select indicator present (checkboxes or similar)
- [ ] 4 choices all visible
- [ ] Selection state toggleable visually

### `choose/with-descriptions.json`
- [ ] Choice labels prominent
- [ ] Descriptions visible below labels
- [ ] Description text styled differently (lighter/smaller)

### `choose/many-options.json` (Regression Test)
- [ ] **CRITICAL**: All 6 options fully visible
- [ ] Last option "All of them" not cut off
- [ ] ScrollView properly accounts for bottom toolbar
- [ ] No overlap between choices and keyboard hints

### `choose/pane-snooze.json`
- [ ] Snooze pane opens with choice list still intact above
- [ ] Pane does not obscure selected/default option state

### `choose/pane-feedback.json`
- [ ] Feedback pane opens with input + Send button
- [ ] Toolbar expansion does not break list scroll sizing

### `choose/multi-select-pane-snooze.json`
- [ ] Multi-select checkboxes visible with snooze pane open
- [ ] Descriptions render below each option label
- [ ] Snooze pane does not obscure choices or descriptions

### `choose/multi-select-pane-feedback.json`
- [ ] Multi-select checkboxes visible with feedback pane open
- [ ] Descriptions render below each option label
- [ ] Feedback input + Send button visible without clipping

---

## Text Input Dialogs

### `text-input/basic.json`
- [ ] Title "Project Setup" displayed
- [ ] Prompt text visible
- [ ] Text field present and empty
- [ ] Text field has focus indicator
- [ ] Snooze/Feedback toolbar present
- [ ] Keyboard hints show submit, cancel, snooze, feedback

### `text-input/password.json`
- [ ] Title "API Configuration" displayed
- [ ] Text field shows password masking (NSSecureTextField)
- [ ] Input would be hidden (bullets/dots when typing)

### `text-input/markdown.json`
- [ ] **Bold text** renders with heavier weight
- [ ] *Italic text* renders with italic style
- [ ] `Inline code` renders with monospace font and background
- [ ] [Links](url) render as clickable blue text
- [ ] All markdown elements render correctly together

### `text-input/pane-snooze.json`
- [ ] Snooze pane expands below input field
- [ ] Input field remains visible and not overlapped

### `text-input/pane-feedback.json`
- [ ] Feedback pane expands with editable input + Send
- [ ] Toolbar and footer maintain spacing/alignment

---

## Questions Dialogs

### `questions/wizard-basic.json`
- [ ] Wizard mode: shows one question at a time
- [ ] Question text visible
- [ ] Options displayed as selectable cards
- [ ] Navigation (Next/Previous) present
- [ ] Step indicator visible (1/2, etc.)

### `questions/accordion-basic.json`
- [ ] Accordion mode: all sections visible
- [ ] Sections expandable/collapsible
- [ ] Current section expanded
- [ ] Other sections collapsed showing summary
- [ ] Multi-select question shows checkbox indicators

### `questions/pane-snooze.json`
- [ ] Snooze pane visible in questions flow
- [ ] Question list and footer remain readable

### `questions/pane-feedback.json`
- [ ] Feedback pane visible in questions flow
- [ ] No layout jump causing question content clipping

---

## Notify Dialogs

### `notify/basic.json`
- [ ] Notification icon + title visible
- [ ] Body text wraps correctly
- [ ] Window auto-closes after display timeout
- [ ] Project badge visible in top-right corner

### `notify/long-message.json`
- [ ] Long body text wraps without clipping
- [ ] Title remains single-line and readable
- [ ] Project badge visible in top-right corner

### `notify/silent.json`
- [ ] Notification renders normally with `sound=false`
- [ ] No crash or missing UI state when silent
- [ ] No project badge (no projectPath provided)

---

## Theme-Specific Checks

### Midnight Theme (`DIALOG_THEME=midnight`)
- [ ] Dark background color
- [ ] Light text with good contrast
- [ ] Accent colors appropriate for dark mode
- [ ] No "bright flashes" on elements

### Sunset Theme (`DIALOG_THEME=sunset`)
- [ ] Warm color palette
- [ ] Good text contrast
- [ ] Consistent accent usage

---

## Accessibility

### Reduce Motion (`System Preferences > Accessibility > Display`)

The dialog system respects macOS "Reduce motion" setting via `@Environment(\.accessibilityReduceMotion)`.

**Components that respect reduce motion:**
- `ConfirmDialog.swift` - toolbar expand/collapse animations
- `TextInputDialog.swift` - toolbar expand/collapse animations
- `DialogToolbar.swift` - snooze/feedback panel transitions
- `AccordionDialog.swift` - section expand/collapse, option selection, button interactions

**When reduce motion is enabled:**
- State changes happen immediately (no `withAnimation`)
- Transitions use `.identity` instead of `.opacity` or `.move`
- No visual glitches or jarring effects

**Testing reduce motion:**
```bash
# Check current setting
defaults read com.apple.universalaccess reduceMotion

# Enable reduce motion
defaults write com.apple.universalaccess reduceMotion -bool true

# Disable reduce motion
defaults write com.apple.universalaccess reduceMotion -bool false

# Run test dialogs and verify no animations play
./test-cases/test-runner.sh
```

**Verification checklist:**
- [ ] Toolbar panels appear/disappear instantly (no slide)
- [ ] Accordion sections expand/collapse without animation
- [ ] Button hover states change immediately
- [ ] No motion sickness triggers

---

## Interaction Testing

Visual screenshots don't capture interaction behavior. Test these manually:

### Click Reliability (ChoiceCard)
- [ ] Single clicks reliably select choice options
- [ ] No need for double-clicking to register selection
- [ ] Mouse drag within card still triggers selection on release
- [ ] Mouse drag outside card does not trigger selection

### Button Cooldown
- [ ] Rapid clicks on buttons don't trigger multiple actions
- [ ] Visual feedback shows button is temporarily disabled after click

---

## Known Issues

### Choice Cutoff Bug (001-choice-cutoff.md)
**Status**: May be present in 6+ option dialogs

If `choose/many-options.json` shows the last option cut off:
1. Document with screenshot
2. Issue is in ChooseDialog.swift ScrollView bottom padding
3. Verify fix by checking last option is fully visible

---

## Running Tests

```bash
# Default theme
./test-cases/test-runner.sh

# With theme
DIALOG_THEME=sunset ./test-cases/test-runner.sh
DIALOG_THEME=midnight ./test-cases/test-runner.sh

# Slower render (for complex dialogs)
RENDER_DELAY=1.5 ./test-cases/test-runner.sh
```

## Screenshot Location

Screenshots are saved to: `test-cases/screenshots/<timestamp>/`

File naming: `<category>_<case-name>.png`
- `confirm_basic.png`
- `choose_many-options.png`
- etc.
