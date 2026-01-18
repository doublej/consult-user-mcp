# Dialog Visual Verification Checklist

Use this checklist when reviewing screenshots from `test-runner.sh`.

---

## General (All Dialogs)

- [ ] Dialog renders without clipping or overflow
- [ ] Text is readable and properly wrapped
- [ ] Dialog is positioned correctly (center by default)
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

---

## Text Input Dialogs

### `text-input/basic.json`
- [ ] Title "Project Setup" in toolbar
- [ ] Prompt text visible
- [ ] Text field present and empty
- [ ] Text field has focus indicator

### `text-input/password.json`
- [ ] Title "API Configuration" displayed
- [ ] Text field shows password masking indicator
- [ ] Input would be hidden (bullets/dots when typing)

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
