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
        -not -path '*/audit/*' -not -path '*/screenshots/*' \
        -not -path '*/.build/*' -not -path '*/node_modules/*' \
        2>/dev/null | sed "s|^$WORK/||" | LC_ALL=C sort \
        | while read -r f; do shasum "$WORK/$f" 2>/dev/null | cut -d' ' -f1; done \
        | shasum | cut -c1-16)"
    if [ "$GOT" != "$EXPECT_FINGERPRINT" ]; then
        echo "expected $EXPECT_FINGERPRINT, guest has $GOT"
        finish "FAIL: stale share — the guest is not running the host's sources. Fix: launch.sh stop && launch.sh run" 1
    fi
    echo "==> fingerprint ok ($GOT)"
fi

# ── the screen the audit is calibrated against ────────────────────────
# `tart set --display` only advertises the mode; the guest keeps whatever
# resolution it booted with, and --display-refit reconfigures to fit a viewer
# window that a headless boot does not have. So the mode is selected here.
#
# This is not cosmetic. The dialog height cap comes from the screen, so on
# tart's 768pt-tall default six states clamp that do not clamp on any machine
# a customer owns — and the container disagreed with the host about whether
# the surface was sound.
if [ -n "${DISPLAY_SIZE:-}" ]; then
    /usr/bin/swift -e "
import Cocoa
let want = \"$DISPLAY_SIZE\".split(separator: \"x\").compactMap { Int(\$0) }
guard want.count == 2, let screen = NSScreen.main else { exit(0) }
let id = (screen.deviceDescription[NSDeviceDescriptionKey(\"NSScreenNumber\")] as! NSNumber).uint32Value
if Int(screen.frame.width) == want[0] && Int(screen.frame.height) == want[1] {
    print(\"screen already \\(want[0])x\\(want[1])\"); exit(0)
}
guard let modes = CGDisplayCopyAllDisplayModes(id, nil) as? [CGDisplayMode],
      let mode = modes.first(where: { \$0.width == want[0] && \$0.height == want[1] }) else {
    print(\"no \\(want[0])x\\(want[1]) mode offered; staying at \\(Int(screen.frame.width))x\\(Int(screen.frame.height))\")
    exit(0)
}
var config: CGDisplayConfigRef?
CGBeginDisplayConfiguration(&config)
CGConfigureDisplayWithDisplayMode(config, id, mode, nil)
CGCompleteDisplayConfiguration(config, .permanently)
print(\"screen set to \\(want[0])x\\(want[1])\")
" 2>&1 | tail -1
    sleep 2
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

# Each suite's full output goes to its own file in the shared folder, and only
# the tail reaches the console. Tailing alone threw away exactly what a
# failure needs — which of 78 cases bled into the margin, which of 24
# assertions broke — and left a summary saying it happened 14 times.
suite() {
    local name="$1"; shift
    local log="$SHARE_OUT/$name.log"
    ran "$name"
    if "$@" > "$log" 2>&1; then
        tail -"${TAIL_LINES:-25}" "$log"
    else
        tail -"${TAIL_LINES:-25}" "$log"
        FAILED+=("$name")
    fi
    echo "   full output: out/$name.log ($(wc -l < "$log" | tr -d ' ') lines)"
}

# Any dialog still on screen from an earlier run holds focus, and the next
# suite's keystrokes go to it instead of to the dialog under test — which
# presents as a watchdog timeout on a test that is perfectly fine.
pkill -f DialogCLI 2>/dev/null || true
launchctl bootout gui/"$(id -u)"/dev.consult-mcp.spawn 2>/dev/null || true
sleep 0.5

# ── unit: the MCP server's own tests ──────────────────────────────────
if [[ " $SUITES " == *" unit "* ]]; then
    suite unit bun test
fi

# ── layout: the suite that fails a build ──────────────────────────────
# Renders every state off-screen, measures the view tree and the bitmap,
# and asserts. This is the one whose green actually means something, and
# the one the container never used to run.
if [[ " $SUITES " == *" layout "* ]]; then
    TAIL_LINES=40 suite layout bash test-cases/layout-audit.sh
    if [ -d test-cases/skin-states/audit ]; then
        rm -rf "$SHARE_OUT/audit"
        cp -R test-cases/skin-states/audit "$SHARE_OUT/audit" 2>/dev/null || true
    fi
fi

# ── keyboard: the typing-vs-hotkey contract ───────────────────────────
# Spawns real dialogs and injects keys. Cannot run on a desktop somebody is
# using — it takes the keyboard for the length of the suite.
if [[ " $SUITES " == *" keyboard "* ]]; then
    # Typing only works when the dialog can take key focus, and it cannot
    # while another application holds the foreground. The guest accumulates
    # them — a Phone window from the base image, a Terminal, and a
    # UserNotificationCenter alert that relaunches itself — and the suite
    # swings between 22 of 24 and 15 of 24 depending on what happens to be
    # in front. Clearing them first is what makes the run repeatable.
    /usr/bin/swift -e '
import Cocoa
for a in NSWorkspace.shared.runningApplications where a.activationPolicy == .regular {
    if a.bundleIdentifier == "com.apple.finder" { continue }
    a.forceTerminate()
}' 2>/dev/null || true
    killall UserNotificationCenter 2>/dev/null || true
    sleep 1
    TAIL_LINES=30 suite keyboard bash test-cases/keyboard-tests.sh
fi

# ── visual: screenshots for a human, plus OCR ─────────────────────────
if [[ " $SUITES " == *" visual "* ]]; then
    # The guest's compositor maps a new window more slowly than bare metal;
    # 0.4s misses the capture, 1.5s settles reliably.
    export FAST="${FAST:-1}" RENDER_DELAY="${RENDER_DELAY:-1.5}"
    suite visual bash test-cases/test-runner.sh

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
