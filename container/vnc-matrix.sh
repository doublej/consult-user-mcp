#!/bin/bash
# Interactive test matrix driven over Tart's VNC.
#
# Each scenario:
#   1. writes interact-request.json on the host (shared into the VM)
#   2. WatchPaths-triggered LaunchAgent inside the VM spawns DialogCLI
#   3. host waits for interact-ready, drives VNC keystrokes
#   4. host waits for interact-done, reads interact-result.json
#   5. assertions are jq expressions on the JSON
#
# `vnc-drive.sh` was the single-case proof; this is the matrix.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$HERE/out"
LOG="$OUT/matrix.log"
SCENARIO_IDX=0
# Per-scenario paths are computed in spawn() — virtiofs caches file
# contents aggressively, so overwriting one path gives the guest stale
# reads. Unique filenames per scenario force a fresh open() each time.

VNC_URL=$(grep -oE "vnc://:[a-z0-9-]+@127\.0\.0\.1:[0-9]+" /tmp/tart-tahoe-consult.log | head -1)
PASS=$(echo "$VNC_URL" | sed -E 's|vnc://:([^@]+)@.*|\1|')
PORT=$(echo "$VNC_URL" | sed -E 's|.*:([0-9]+)$|\1|')

PASS_CT=0
FAIL_CT=0
SKIPS=()
FAILS=()

vnc() {
    timeout 30 uvx --quiet --from vncdotool vncdo \
        -s "127.0.0.1::$PORT" -p "$PASS" --delay 90 "$@" 2>>"$LOG"
    return 0  # reactor cleanup throws — non-fatal
}

# spawn <command> <body-json>
# Each scenario gets a fresh request filename to bypass virtiofs caching.
spawn() {
    local cmd="$1"; local body="$2"
    SCENARIO_IDX=$((SCENARIO_IDX+1))
    REQ="$OUT/interact-request-$SCENARIO_IDX.json"
    RES="$OUT/interact-result-$SCENARIO_IDX.json"
    ERR="$OUT/interact-result-$SCENARIO_IDX.err"
    READY="$OUT/interact-ready-$SCENARIO_IDX"
    DONE="$OUT/interact-done-$SCENARIO_IDX"

    /opt/homebrew/bin/jq -n --arg c "$cmd" --argjson b "$body" \
        '{command:$c, body:$b}' > "$REQ"
    sync

    tart exec tahoe-consult bash -c "
        launchctl bootout gui/501/dev.consult-mcp.spawn 2>/dev/null
        pkill -9 -f DialogCLI 2>/dev/null
        # Script Editor / other GUI apps left running from earlier
        # osascript debug calls steal focus from DialogCLI. Nuke them.
        pkill -9 'Script Editor' 2>/dev/null
        sleep 0.4
        echo $SCENARIO_IDX > /Users/admin/.consult-mcp-spawn/spawn.idx
        launchctl bootstrap gui/501 /Users/admin/Library/LaunchAgents/dev.consult-mcp.spawn.plist
    " >/dev/null 2>&1
    local i
    for i in $(seq 1 25); do
        [ -f "$READY" ] && break
        sleep 0.3
    done
    [ -f "$READY" ] || { echo "  FAIL: dialog never opened (no READY marker)"; return 1; }

    # Click on the dialog window center to focus it. Without this any
    # other app currently in the foreground (often a leftover Script
    # Editor file picker) eats our keystrokes.
    local coords
    coords=$(tart exec tahoe-consult bash -c "/usr/bin/swift -e '
import Cocoa
let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String:Any]]
for w in info {
    let o = w[kCGWindowOwnerName as String] as? String ?? \"\"
    if o == \"DialogCLI\" {
        let b = w[kCGWindowBounds as String] as? [String:Double] ?? [:]
        // Top-left interior — guaranteed empty space, no buttons in
        // any dialog layout.
        let cx = Int(b[\"X\", default: 0] + 20)
        let cy = Int(b[\"Y\", default: 0] + 6)
        print(\"\\(cx) \\(cy)\")
        break
    }
}' 2>/dev/null")
    if [ -n "$coords" ]; then
        vnc move $coords click 1 >/dev/null 2>&1
        sleep 0.4
    fi
    return 0
}

# Wait for the dialog to exit and JSON to land.
collect() {
    local i
    for i in $(seq 1 40); do
        [ -f "$DONE" ] && return 0
        sleep 0.3
    done
    echo "  FAIL: dialog never exited (no DONE marker)"
    return 1
}

# assert <jq-expression> <expected-string>
assert() {
    local expr="$1"; local want="$2"
    local got
    got=$(/opt/homebrew/bin/jq -r "$expr" "$RES" 2>/dev/null)
    if [ "$got" = "$want" ]; then
        echo "    ✓ $expr = $want"
        return 0
    else
        echo "    ✗ $expr = $got (wanted: $want)"
        return 1
    fi
}

# scenario <name> <runner-fn>
scenario() {
    local name="$1"; shift
    echo ""
    echo "── $name ──"
    if "$@"; then
        PASS_CT=$((PASS_CT+1))
        echo "  PASS"
    else
        FAIL_CT=$((FAIL_CT+1))
        FAILS+=("$name")
        echo "  FAIL"
    fi
}

# ─────────────────────────────────────────────────────────────────────────
# Scenarios
# ─────────────────────────────────────────────────────────────────────────

s_confirm_basic_with_feedback() {
    spawn confirm '{
        "body":"Apply this migration to production now?",
        "title":"Database Migration",
        "confirmLabel":"Apply","cancelLabel":"Cancel","position":"center"
    }' || return 1
    sleep 0.6
    vnc key f;                                  sleep 1.5
    vnc type "automated note from matrix";      sleep 0.7
    vnc key esc;                                sleep 0.7
    vnc key enter
    collect || return 1
    local ok=0
    assert '.confirmed' 'true' || ok=1
    assert '.feedbackText' 'automated note from matrix' || ok=1
    assert '.cancelled' 'false' || ok=1
    return $ok
}

s_confirm_empty_no_feedback() {
    spawn confirm '{
        "body":"Just confirm with no annotation.",
        "title":"Plain","confirmLabel":"OK","cancelLabel":"Nope","position":"center"
    }' || return 1
    sleep 0.6
    vnc key enter
    collect || return 1
    local ok=0
    assert '.confirmed' 'true' || ok=1
    assert '.feedbackText' 'null' || ok=1
    return $ok
}

s_confirm_cancel_rescued_by_feedback() {
    spawn confirm '{
        "body":"You will leave a note instead of confirming.",
        "title":"Cancel-with-note","confirmLabel":"Apply","cancelLabel":"Cancel","position":"center"
    }' || return 1
    sleep 0.6
    vnc key f;                          sleep 1.5
    vnc type "rescue note on cancel";   sleep 0.7
    vnc key esc;                        sleep 0.7
    vnc key esc
    collect || return 1
    local ok=0
    assert '.feedbackText' 'rescue note on cancel' || ok=1
    assert '.cancelled' 'false' || ok=1
    return $ok
}

s_confirm_reopen_pane_after_close() {
    spawn confirm '{
        "body":"Reopen pane and keep typing.",
        "title":"Reopen","confirmLabel":"OK","cancelLabel":"Cancel","position":"center"
    }' || return 1
    sleep 0.6
    vnc key f;                  sleep 1.4
    vnc type "first";           sleep 0.6
    vnc key esc;                sleep 0.9
    vnc key f;                  sleep 1.4
    vnc type " second";         sleep 0.6
    vnc key esc;                sleep 0.6
    vnc key enter
    collect || return 1
    assert '.feedbackText' 'first second'
}

s_text_input_answer_only() {
    # Plain text-input round-trip (no pane). Sanity check that
    # spawning + typing + enter works for non-confirm dialogs.
    spawn textInput '{
        "body":"What should the rollback commit message be?",
        "title":"Rollback","defaultValue":"","hidden":false,"position":"center"
    }' || return 1
    sleep 0.6
    # vncdotool's keysym map sends ":" as the un-shifted ";" on US layout
    # in this VM; avoid shifted punctuation in expected output.
    vnc type "revert rollback bad commit";           sleep 0.6
    vnc key enter
    collect || return 1
    assert '.answer' 'revert rollback bad commit'
}

s_text_input_f_shortcut_swallowed_by_textfield() {
    # KNOWN BUG: on textInput dialogs the dialog's NSTextField is first
    # responder. Pressing 'f' types an 'f' into that field instead of
    # opening the feedback pane. We pin this as a regression sentinel:
    # if the dialog ever DOES open the pane on 'f' here, the test will
    # fail and force us to update the plan.
    spawn textInput '{
        "body":"Verifies that f-shortcut is currently swallowed.",
        "title":"f-swallow","defaultValue":"","hidden":false,"position":"center"
    }' || return 1
    sleep 0.6
    vnc key f;                          sleep 1.0
    vnc key enter                                   # submit whatever's in the field
    collect || return 1
    # Expect: the dialog sees 'f' as character input — answer contains it.
    # No feedbackText because the pane never opened.
    local ok=0
    assert '.answer' 'f' || ok=1
    assert '.feedbackText' 'null' || ok=1
    return $ok
}

s_wizard_global_feedback() {
    # Form path: open global feedback pane, type, close, select choice
    # (space or enter on the focused card), advance, repeat.
    #
    # In a wizard no text field is focused, so 'f' SHOULD open the pane.
    spawn questions '{
        "title":"Per-question",
        "body":"two-question form",
        "questions":[
            {"id":"a","question":"Pick A:","type":"choice","options":[
                {"label":"Alpha","description":""},
                {"label":"Bravo","description":""}],"multiSelect":false},
            {"id":"b","question":"Pick B:","type":"choice","options":[
                {"label":"Charlie","description":""},
                {"label":"Delta","description":""}],"multiSelect":false}
        ],
        "mode":"wizard","position":"center"
    }' || return 1
    sleep 0.8
    vnc key f;                          sleep 1.5
    vnc type "global form note";        sleep 0.7
    vnc key esc;                        sleep 0.8
    vnc key enter;                      sleep 0.8   # select focused choice (Alpha), advance
    vnc key enter;                      sleep 0.8   # select focused choice (Charlie), advance
    vnc key enter                                    # final "Done"
    collect || return 1
    local ok=0
    assert '.feedbackText' 'global form note' || ok=1
    assert '.answer.a' 'Alpha' || ok=1
    assert '.answer.b' 'Charlie' || ok=1
    return $ok
}

# ─────────────────────────────────────────────────────────────────────────
# Run
# ─────────────────────────────────────────────────────────────────────────

mkdir -p "$OUT"
: > "$LOG"

echo "VNC: 127.0.0.1::$PORT"
echo "Output: $OUT/interact-result-N.json"
echo "Log:    $LOG"

# Warm up the VNC connection — the first vncdo invocation after VM idle
# loses its keystroke to connection handshake latency. A no-op pause
# establishes the session so the first real scenario's 'f' actually fires.
vnc pause 0.2 >/dev/null 2>&1
echo

scenario "confirm: basic + feedback"            s_confirm_basic_with_feedback
scenario "confirm: empty (no feedback)"         s_confirm_empty_no_feedback
scenario "confirm: cancel rescued by feedback"  s_confirm_cancel_rescued_by_feedback
scenario "confirm: reopen pane after close"     s_confirm_reopen_pane_after_close
scenario "text-input: answer round-trip"        s_text_input_answer_only
scenario "text-input: f shortcut swallowed"     s_text_input_f_shortcut_swallowed_by_textfield
# ⌘F chord coverage is deferred: vncdotool's `super-f` chord drops the
# modifier through Tart's VNC layer, so the matrix can't drive it.
# Verify the P8 fix by hand in the running app or via a follow-up tap
# inside the VM (osascript inside the guest, frontmost dialog).
scenario "wizard: global feedback"              s_wizard_global_feedback

echo
echo "═════════════════════════════════════════"
echo "PASS: $PASS_CT     FAIL: $FAIL_CT"
if [ ${#FAILS[@]} -gt 0 ]; then
    printf '  fail: %s\n' "${FAILS[@]}"
fi
echo "═════════════════════════════════════════"
[ "$FAIL_CT" -eq 0 ]
