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
assert() {
    local name="$1" json="$2" predicate="$3"
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

# ── 5. Classic sanity — the old chassis must not regress either ────────
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
