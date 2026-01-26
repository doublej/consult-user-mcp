# Bug: Multiple Choice Last Option Cut Off

**Ticket:** consult-fe8
**Priority:** P1
**Component:** dialog-cli / ChooseDialog

## Issue
When displaying a multiple choice dialog with many options (5+), the last option is partially hidden behind the bottom toolbar containing:
- Snooze / Feedback buttons
- Keyboard hints (navigate, select, done, snooze, feedback)

## Expected Behavior
All choice options should be fully visible and scrollable, with proper padding/margin to account for the fixed bottom toolbar.

## Actual Behavior
The last option ("All of them" in screenshot) is clipped - only the top portion visible, text overlaps with toolbar.

## Reproduction
1. Call `ask_multiple_choice` with 6+ choices including descriptions
2. Observe last option is cut off

## Screenshot
See: choice-cutoff-screenshot.png (if saved)

## Likely Fix
In `ChooseDialog.swift` or `DialogComponents.swift`:
- Add bottom padding to ScrollView equal to toolbar height
- Or use `.safeAreaInset(edge: .bottom)` modifier
