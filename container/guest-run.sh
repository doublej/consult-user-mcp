#!/bin/bash
# What the container actually runs. Executed inside the guest's Aqua session
# by the runner LaunchAgent, against the repo copy that was just synced in.
#
# This file lives in the repo on purpose. The provisioning step bakes only a
# five-line shim into the VM; everything that can change lives here and
# arrives with the code it tests. A harness edit takes effect on the next
# run, with no re-prep, and the guest can never execute a version of the
# suite that does not match the sources under it.
#
# Settings arrive in request.env through the shared folder — a LaunchAgent
# inherits no environment from whoever triggered it.
#
# Env (via request.env):
#   SUITES              which of: unit layout keyboard visual
#   EXPECT_FINGERPRINT  host-side hash of the sources; mismatch is fatal
#   DIALOG_SKIN/SKINS   skin under test
set -uo pipefail

WORK="$HOME/work/consult-user-mcp"
SHARE_OUT="/Volumes/My Shared Files/out"
LOG="$SHARE_OUT/run.log"
DONE="$SHARE_OUT/done"

exec > >(tee -a "$LOG") 2>&1

SUITES="${SUITES:-unit layout keyboard visual}"
export DIALOG_SKIN="${DIALOG_SKIN:-caret}"
export SKINS="${SKINS:-caret}"

eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
export PATH="$HOME/.bun/bin:$PATH"

echo "=============================================================="
echo "  container run — $(date)"
echo "  $(sw_vers -productName) $(sw_vers -productVersion) / $(uname -m)"
echo "  suites: $SUITES   skin: $DIALOG_SKIN"
echo "=============================================================="

finish() {
    echo "$1" > "$DONE"
    echo ""
    echo "==> $1"
    exit "${2:-0}"
}

cd "$WORK" || finish "FAIL: repo not synced to $WORK" 1

# ── the share must have handed over the sources the host meant ────────
# VirtioFS caches aggressively on a long-lived VM: the rsync above can copy
# files the host changed minutes ago and still get the old bytes. That used
# to surface as a test failing for reasons nobody could reproduce. Now it
# names itself.
if [ -n "${EXPECT_FINGERPRINT:-}" ]; then
    GOT="$(find "$WORK/dialog-cli/Sources" "$WORK/test-cases" "$WORK/mcp-server/src" \
        -type f \( -name '*.swift' -o -name '*.ts' -o -name '*.sh' -o -name '*.json' -o -name '*.tsv' \) \
        2>/dev/null | LC_ALL=C sort | xargs shasum 2>/dev/null | shasum | cut -c1-16)"
    if [ "$GOT" != "$EXPECT_FINGERPRINT" ]; then
        echo "expected $EXPECT_FINGERPRINT, guest has $GOT"
        finish "FAIL: stale share — the guest is not running the host's sources. Fix: launch.sh stop && launch.sh run" 1
    fi
    echo "==> fingerprint ok ($GOT)"
fi

# ── build ─────────────────────────────────────────────────────────────
echo ""
echo "==> bun install"
bun install --silent 2>&1 | tail -3

echo "==> swift build -c release (dialog-cli)"
if ! ( cd dialog-cli && swift build -c release 2>&1 | tail -15 ); then
    finish "FAIL: dialog-cli did not build" 1
fi

FAILED=()
ran() { echo ""; echo "── $1 ──"; }

# ── unit: the MCP server's own tests ──────────────────────────────────
if [[ " $SUITES " == *" unit "* ]]; then
    ran "unit"
    bun test 2>&1 | tail -20 || FAILED+=("unit")
fi

# ── layout: the suite that fails a build ──────────────────────────────
# Renders every state off-screen, measures the view tree and the bitmap,
# and asserts. This is the one whose green actually means something, and
# the one the container never used to run.
if [[ " $SUITES " == *" layout "* ]]; then
    ran "layout"
    bash test-cases/layout-audit.sh 2>&1 | tail -40 || FAILED+=("layout")
    if [ -d test-cases/skin-states/audit ]; then
        rm -rf "$SHARE_OUT/audit"
        cp -R test-cases/skin-states/audit "$SHARE_OUT/audit" 2>/dev/null || true
    fi
fi

# ── keyboard: the typing-vs-hotkey contract ───────────────────────────
# Spawns real dialogs and injects keys. Cannot run on a desktop somebody is
# using — it takes the keyboard for the length of the suite.
if [[ " $SUITES " == *" keyboard "* ]]; then
    ran "keyboard"
    bash test-cases/keyboard-tests.sh 2>&1 | tail -30 || FAILED+=("keyboard")
fi

# ── visual: screenshots for a human, plus OCR ─────────────────────────
if [[ " $SUITES " == *" visual "* ]]; then
    ran "visual"
    # The guest's compositor maps a new window more slowly than bare metal;
    # 0.4s misses the capture, 1.5s settles reliably.
    FAST="${FAST:-1}" RENDER_DELAY="${RENDER_DELAY:-1.5}" \
        bash test-cases/test-runner.sh 2>&1 | tail -30 || FAILED+=("visual")

    LATEST="$(ls -td "$WORK"/test-cases/screenshots/*/ 2>/dev/null | head -1)"
    if [ -n "$LATEST" ]; then
        # One shot of the expired overlay, which no fixture can reach: the
        # dialog has to actually time out while a camera is pointed at it.
        MCP_DIALOG_TIMEOUT_MS=800 DIALOG_TEST_KEYS="d7.0;esc" \
            ./dialog-cli/.build/release/DialogCLI confirm \
            "$(cat test-cases/cases/confirm/basic.json)" >/dev/null 2>&1 &
        EXP=$!
        sleep 4
        screencapture -x "$LATEST/expired-overlay.png" 2>/dev/null || true
        wait "$EXP" 2>/dev/null || true

        rm -rf "$SHARE_OUT/screenshots"
        cp -R "$LATEST" "$SHARE_OUT/screenshots" 2>/dev/null || true
    else
        FAILED+=("visual (no screenshots produced)")
    fi
fi

echo ""
echo "=============================================================="
if [ ${#FAILED[@]} -gt 0 ]; then
    finish "FAIL: ${FAILED[*]}" 1
fi
finish "PASS: $SUITES" 0
