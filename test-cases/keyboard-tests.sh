#!/bin/bash
# Keyboard interaction tests for the Dialog CLI.
#
# Each case spawns a real dialog, injects keystrokes through DIALOG_TEST_KEYS
# (the app's own event queue — same dispatch path as real typing, including
# the DialogKeyRouter monitor), and asserts on the JSON response. The point
# is the typing-vs-hotkey contract: characters typed into a focused text
# field must NEVER trigger the s/f/a dialog hotkeys or lose characters, and
# an expired dialog must swallow everything except close.
#
# Burst mode (`p0`) types with zero inter-key delay, which races faster than
# any human — the regression harness for the focus-race bugs (96323a3,
# cd78201, b1594f5, 30c5773).
#
# Usage:  bash test-cases/keyboard-tests.sh
# Env:    DIALOG_CLI    path to the binary (default: dialog-cli/.build/release/DialogCLI,
#                       falling back to debug)
#         KEYBOARD_SKIN skin the suite runs under (default: caret — the New
#                       Interface; the classic sanity block runs regardless)
#
# Runs in ~1 min. Needs an Aqua session (windows must actually map) and jq.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(dirname "$HERE")"
CASES="$HERE/cases"

CLI="${DIALOG_CLI:-}"
if [ -z "$CLI" ]; then
    for c in "$REPO/dialog-cli/.build/release/DialogCLI" "$REPO/dialog-cli/.build/debug/DialogCLI"; do
        [ -x "$c" ] && CLI="$c" && break
    done
fi
if [ -z "$CLI" ] || [ ! -x "$CLI" ]; then
    echo "ERROR: DialogCLI binary not found — build dialog-cli first" >&2
    exit 1
fi

command -v jq >/dev/null || { echo "ERROR: jq required" >&2; exit 1; }

# The suite targets the New Interface (Caret) by default; every dialog in
# the main sections is spawned with this skin.
SKIN="${KEYBOARD_SKIN:-caret}"

MAX_WAIT=30   # seconds per dialog before the watchdog kills it
PASS=0
FAIL=0
FAILED_NAMES=()

# Spawn a dialog with injected keys, print its JSON response.
# run_dialog <cmd> <fixture> <keys> [ENV=VAL ...]
run_dialog() {
    local cmd="$1" fixture="$2" keys="$3"
    shift 3
    local outfile pid waited
    outfile="$(mktemp)"
    env DIALOG_SKIN="$SKIN" "$@" DIALOG_TEST_KEYS="$keys" "$CLI" "$cmd" "$(cat "$fixture")" \
        >"$outfile" 2>/dev/null &
    pid=$!
    waited=0
    while kill -0 "$pid" 2>/dev/null && [ "$waited" -lt "$MAX_WAIT" ]; do
        sleep 1
        waited=$((waited + 1))
    done
    if kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null
        echo '{"harness":"watchdog-timeout"}'
    else
        wait "$pid" 2>/dev/null
        cat "$outfile"
    fi
    rm -f "$outfile"
}

# assert <name> <response-json> <jq-predicate>
#
# A dialog the watchdog had to kill answered nothing, so it cannot satisfy
# anything — but plenty of these predicates are of the form "no snooze
# happened", and an empty response satisfies those by accident. That is not a
# hypothetical: a container run where not one keystroke reached a dialog
# reported ten passes. A timeout fails here before the predicate is consulted.
assert() {
    local name="$1" json="$2" predicate="$3"
    if echo "$json" | jq -e 'has("harness")' >/dev/null 2>&1; then
        echo "  FAIL  $name"
        echo "        the dialog never answered: $(echo "$json" | head -c 120)"
        FAIL=$((FAIL + 1))
        FAILED_NAMES+=("$name")
        return
    fi
    if echo "$json" | jq -e "$predicate" >/dev/null 2>&1; then
        echo "  PASS  $name"
        PASS=$((PASS + 1))
    else
        echo "  FAIL  $name"
        echo "        predicate: $predicate"
        echo "        response:  $(echo "$json" | head -c 400)"
        FAIL=$((FAIL + 1))
        FAILED_NAMES+=("$name")
    fi
}

echo "==> Dialog CLI: $CLI"
echo "==> Skin: $SKIN"
echo ""

# ── 1. Burst-typing into a text field must not trigger hotkeys ─────────
# The text is saturated with the hotkey letters s, f, a. Any hotkey firing
# steals characters (snooze panel, feedback pane, ask-differently menu)
# and the answer comes back mangled or the response carries hotkey state.
echo "== typing-vs-hotkeys =="
TYPED="safari for fast assets"
resp="$(run_dialog textInput "$CASES/text-input/keyboard-empty.json" \
    "d2.5;p0;t:${TYPED};d0.5;return")"
assert "textInput burst typing arrives complete" "$resp" \
    ".answer == \"$TYPED\""
assert "textInput burst typing triggers no snooze" "$resp" \
    '(.snoozed // false) == false'

resp="$(run_dialog textInput "$CASES/text-input/password.json" \
    "d2.5;p0;t:sfa123sfa;d0.5;return")"
assert "hidden textInput burst typing arrives complete" "$resp" \
    '.answer == "sfa123sfa"'

resp="$(run_dialog questions "$CASES/questions/wizard-single-text.json" \
    "d2.5;p0;t:assess for safety;d0.5;return")"
assert "wizard text question burst typing arrives complete" "$resp" \
    'tostring | contains("assess for safety")'

# ── 2. Feedback-pane focus race (regression: 96323a3 … 30c5773) ────────
# `f` opens the pane; the rest of the burst must land in the editor even
# though focus is still in flight. Then esc closes the pane, return answers.
echo "== feedback-pane race =="
resp="$(run_dialog confirm "$CASES/confirm/basic.json" \
    "d2.5;p0;t:fsorry use safari;d1.0;esc;d0.4;return")"
assert "feedback text arrives complete after f-burst" "$resp" \
    '.feedbackText == "sorry use safari"'

# ── 3. Hotkeys still work when NOT editing text ────────────────────────
echo "== hotkeys when idle =="
resp="$(run_dialog confirm "$CASES/confirm/basic.json" \
    "d2.5;t:f;d0.8;p0;t:hello;d0.5;esc;d0.4;return")"
assert "f hotkey opens feedback pane when idle" "$resp" \
    '.feedbackText == "hello"'

resp="$(run_dialog confirm "$CASES/confirm/basic.json" "d2.5;return")"
assert "return submits confirm when idle" "$resp" \
    '.confirmed == true'

# ── 4. Expired dialog is inert ─────────────────────────────────────────
# MCP_DIALOG_TIMEOUT_MS=1000 expires the dialog before the keys arrive.
# Everything must be swallowed except Esc/Return, which close it as a
# dismissal — never as an answer.
echo "== expired state =="
resp="$(run_dialog confirm "$CASES/confirm/basic.json" \
    "d3.0;t:sfa;d0.3;return" MCP_DIALOG_TIMEOUT_MS=1000)"
assert "expired dialog returns no answer on return" "$resp" \
    '(.confirmed // false) == false and (.answer // null) == null'
assert "expired dialog typing triggers no snooze" "$resp" \
    '(.snoozed // false) == false'

resp="$(run_dialog confirm "$CASES/confirm/basic.json" \
    "d3.0;t:hello;d0.3;esc" MCP_DIALOG_TIMEOUT_MS=1000)"
assert "expired dialog closes on esc without answering" "$resp" \
    '(.confirmed // false) == false and (.answer // null) == null'

resp="$(run_dialog textInput "$CASES/text-input/keyboard-empty.json" \
    "d3.0;p0;t:into the void;d0.3;return" MCP_DIALOG_TIMEOUT_MS=1000)"
assert "expired textInput swallows typed answer" "$resp" \
    '(.answer // null) == null'

# ── 5. Arrows belong to the caret while text is being edited ───────────
# On caret this was a data-loss bug rather than a nuisance: the wizard bound
# the left arrow straight to retreat(), which cancels on the first step, so
# pressing left to fix a typo threw the answer and the dialog away. Nothing
# could see it — before this block the suite pressed no arrow key at all.
echo "== arrows while typing =="
resp="$(run_dialog questions "$CASES/questions/wizard-single-text.json" \
    "d2.5;p0;t:staging;d0.4;left;left;d0.4;return")"
assert "wizard: left arrow while typing does not cancel" "$resp" \
    '(.cancelled // false) == false'
assert "wizard: left arrow while typing keeps the answer" "$resp" \
    'tostring | contains("staging")'

resp="$(run_dialog textInput "$CASES/text-input/keyboard-empty.json" \
    "d2.5;p0;t:release;d0.4;left;left;left;d0.4;return")"
assert "textInput: arrows while typing do not disturb the answer" "$resp" \
    '.answer == "release"'

# ── 6. Space — the key a pick surface is answered with ─────────────────
# Untestable until the driver learned to press it, so all three of the
# skins' independent Space implementations were unguarded by anything.
echo "== space activates =="
resp="$(run_dialog choose "$CASES/choose/single-select.json" \
    "d2.6;down;d0.3;space;d0.5;return")"
assert "choose single: down then space selects the second option" "$resp" \
    '.answer == "Option Beta"'

resp="$(run_dialog choose "$CASES/choose/multi-select.json" \
    "d2.6;space;d0.3;down;d0.2;down;d0.3;space;d0.5;return")"
assert "choose multi: space toggles two options" "$resp" \
    '(.answer | type) == "array" and (.answer | length) == 2'

# ── 7. The Other field is a text field inside the option ring ──────────
# Exactly the typing-vs-hotkey shape the suite exists for, on the one
# surface the suite never used to spawn.
echo "== choose Other field =="
resp="$(run_dialog choose "$CASES/choose/single-select-other.json" \
    "d2.6;down;down;down;d0.3;space;d0.6;p0;t:fast safe store;d0.5;return")"
assert "choose Other: burst typing arrives complete" "$resp" \
    '.answer == "fast safe store"'
assert "choose Other: burst typing triggers no snooze" "$resp" \
    '(.snoozed // false) == false'

# A form rebuilds its Other field on every step. When "give this field the
# caret" was a plain flag rather than a question's name, the flag set on step 1
# was still set when step 2's field appeared: it took the caret unasked, and
# Space — the key that picks an option — was typed into it as a space.
echo "== form Other field does not follow the step =="
resp="$(run_dialog questions "$CASES/questions/wizard-with-other.json" \
    "d2.6;down;down;down;d0.3;space;d0.6;p0;t:rust;d0.6;return;d1.0;space;d0.5;return;d0.8;p0;t:demo;d0.5;return")"
assert "form Other: step 1 takes the typed answer" "$resp" \
    '.answer.language == "rust"'
assert "form Other: step 2 Space picks an option, not a space" "$resp" \
    '.answer.features == ["Auth"]'
assert "form Other: step 3 still takes text" "$resp" \
    '.answer.name == "demo"'

# ── 8. The Escape ladder peels one layer per press ─────────────────────
echo "== escape ladder =="
resp="$(run_dialog confirm "$CASES/confirm/basic.json" "d2.5;esc")"
assert "esc on a live dialog cancels it" "$resp" \
    '.cancelled == true'

resp="$(run_dialog confirm "$CASES/confirm/basic.json" \
    "d2.5;esc;d0.5;return" DIALOG_TEST_PANE=snooze)"
assert "esc closes the snooze tray without cancelling" "$resp" \
    '(.cancelled // false) == false and (.snoozed // false) == false'

# ── 9. The hotkeys must also fire when they are supposed to ────────────
# The suite proved s and a stay quiet while typing and never once proved
# they work at all, so "the hotkey stopped working" was a green run.
echo "== hotkeys fire when idle =="
resp="$(run_dialog confirm "$CASES/confirm/basic.json" "d2.5;t:s;d0.8;esc;d0.4;return")"
assert "s opens the snooze tray when idle" "$resp" \
    '(.cancelled // false) == false'

resp="$(run_dialog confirm "$CASES/confirm/basic.json" "d2.5;c:f;d0.8;p0;t:chord;d0.5;esc;d0.4;return")"
assert "cmd-f opens the feedback pane" "$resp" \
    '.feedbackText == "chord"'

# ── 10. Classic sanity — the old chassis must not regress either ───────
echo "== classic sanity =="
resp="$(run_dialog textInput "$CASES/text-input/keyboard-empty.json" \
    "d2.5;p0;t:${TYPED};d0.5;return" DIALOG_SKIN=classic)"
assert "classic: burst typing arrives complete" "$resp" \
    ".answer == \"$TYPED\""

resp="$(run_dialog confirm "$CASES/confirm/basic.json" \
    "d3.0;t:sfa;d0.3;return" DIALOG_SKIN=classic MCP_DIALOG_TIMEOUT_MS=1000)"
assert "classic: expired dialog returns no answer" "$resp" \
    '(.confirmed // false) == false and (.answer // null) == null'

echo ""
echo "==> $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
    printf '    failed: %s\n' "${FAILED_NAMES[@]}"
    exit 1
fi
