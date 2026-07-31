#!/bin/bash
# Host driver for the macOS container — the place this project's tests are
# meant to run.
#
# Two of the three visual suites spawn real windows and take the keyboard.
# Run them on your own desktop and they fight you for the screen for minutes,
# and any stray focus change corrupts the result. The container gives them a
# machine of their own: a fixed OS version, a fixed display, fixed fonts, and
# nothing else competing for focus.
#
# Subcommands:
#   check  — preflight only: tart, TART_HOME volume, VM, guest agent
#   init   — clone the base image → CUM_VM_NAME, size it
#   prep   — provision the guest (Xcode CLT check, brew, deps, bun, TCC, agent)
#   run    — sync the repo in and run the suites, artifacts back to ./out/
#   shell  — boot with a VNC viewer for interactive debugging
#   stop   — shut the VM down
#   clean  — delete the clone (leaves the base image alone)
#
# Env:
#   CUM_VM_NAME       VM clone name (default: tahoe-consult)
#   CUM_BASE_VM       base image to clone (default: tahoe-base)
#   CUM_REPO          host path to the repo (default: this file's repo)
#   CUM_CPU/CUM_MEM   resources (defaults: 6 / 12288 MiB)
#   SUITES            which suites the guest runs
#                     (default: "unit layout keyboard visual")
#   REUSE=1           reuse a already-running VM instead of rebooting it
#   TIMEOUT           seconds to wait for the guest pass (default: 1800)

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${CUM_REPO:-$(dirname "$HERE")}"
VM_NAME="${CUM_VM_NAME:-tahoe-consult}"
BASE_VM="${CUM_BASE_VM:-tahoe-base}"
OUT_DIR="$HERE/out"
CPU="${CUM_CPU:-6}"
MEM="${CUM_MEM:-12288}"
SUITES="${SUITES:-unit layout keyboard visual}"
TIMEOUT="${TIMEOUT:-1800}"

# ── preflight ─────────────────────────────────────────────────────────
#
# Every failure below used to present as something else: a missing volume
# looked like "the VM is gone", a missing binary looked like a syntax error.
# They are checked up front so the message names the actual cause.

die() { echo "ERROR: $*" >&2; exit 1; }

# tart keeps its images under TART_HOME. Ours lives on an external disk,
# which macOS unmounts on sleep, eject or a bad cable — and an unmounted
# TART_HOME does not error, it just reports zero VMs. `diskutil mount`
# takes a volume name and is idempotent, so this is safe to always run.
ensure_tart_home() {
    local home="${TART_HOME:-$HOME/.tart}"
    [ -d "$home" ] && return 0
    case "$home" in
        /Volumes/*)
            local name="${home#/Volumes/}"
            name="${name%%/*}"
            echo "==> TART_HOME is on /Volumes/$name, not mounted — mounting"
            diskutil mount "$name" >/dev/null 2>&1 \
                || die "could not mount /Volumes/$name (TART_HOME=$home). Is the disk attached?"
            [ -d "$home" ] || die "mounted /Volumes/$name but $home is still missing"
            ;;
        *) die "TART_HOME=$home does not exist" ;;
    esac
}

preflight() {
    command -v tart >/dev/null || die "tart not installed — brew install cirruslabs/cli/tart"
    ensure_tart_home
    [ -d "$REPO/test-cases" ] || die "repo not found at $REPO (override with CUM_REPO=)"
    mkdir -p "$OUT_DIR"
}

vm_exists()  { tart list 2>/dev/null | awk '{print $2}' | grep -qx "$VM_NAME"; }
vm_running() { tart list 2>/dev/null | awk -v n="$VM_NAME" '$2==n && $NF=="running"{print}' | grep -q .; }
tart_exec()  { tart exec "$VM_NAME" "$@"; }

ensure_vm() {
    vm_exists && return 0
    vm_exists_base() { tart list 2>/dev/null | awk '{print $2}' | grep -qx "$BASE_VM"; }
    vm_exists_base || die "base image '$BASE_VM' not found — tart pull ghcr.io/cirruslabs/macos-tahoe-base:latest && tart clone …"
    echo "==> Cloning $BASE_VM → $VM_NAME"
    tart clone "$BASE_VM" "$VM_NAME"
    echo "==> Sizing: $CPU cores / $MEM MiB"
    tart set "$VM_NAME" --cpu "$CPU" --memory "$MEM"
}

# The repo goes in read-only and the guest works on an rsync copy; `out` is
# read-write and is how artifacts come back.
#
# --vnc-experimental, not --no-graphics: without an attached framebuffer the
# WindowServer never maps a window, so makeKeyAndOrderFront silently no-ops
# and every capture comes back 0x0. It exposes a VNC server but opens no
# viewer on the host, which is what makes the run invisible.
boot_headless() {
    ensure_vm
    if vm_running; then
        if [ -n "${REUSE:-}" ]; then
            echo "==> $VM_NAME already running (REUSE=1)"
            return 0
        fi
        # A long-running VM's VirtioFS share serves stale file content: the
        # guest rsyncs files the host changed minutes ago and gets the old
        # ones. Remounting is the only reliable fix, so a fresh boot is the
        # default and reuse is opt-in.
        echo "==> $VM_NAME running — restarting to remount the share (REUSE=1 to skip)"
        tart stop "$VM_NAME" || true
        sleep 2
    fi
    echo "==> Booting $VM_NAME"
    nohup tart run "$VM_NAME" \
        --vnc-experimental \
        --dir="repo:$REPO:ro" \
        --dir="out:$OUT_DIR" \
        >"/tmp/tart-$VM_NAME.log" 2>&1 &
    echo "    pid=$! log=/tmp/tart-$VM_NAME.log"
    wait_for_agent
}

wait_for_agent() {
    printf "==> Waiting for guest agent"
    local i
    for i in $(seq 1 90); do
        if tart_exec true >/dev/null 2>&1; then echo " ready"; return 0; fi
        printf "."
        sleep 2
    done
    echo " timeout"
    die "guest agent never came up — see /tmp/tart-$VM_NAME.log"
}

# A fingerprint of the sources under test, computed identically on both
# sides. The guest recomputes it after its rsync; a mismatch means the share
# handed over stale content, which used to surface as a confusing test
# failure rather than as the infrastructure problem it is.
fingerprint() {
    find "$REPO/dialog-cli/Sources" "$REPO/test-cases" "$REPO/mcp-server/src" \
        -type f \( -name '*.swift' -o -name '*.ts' -o -name '*.sh' -o -name '*.json' -o -name '*.tsv' \) \
        2>/dev/null | LC_ALL=C sort | xargs shasum 2>/dev/null | shasum | cut -c1-16
}

cmd_check() {
    preflight
    echo "==> tart      $(tart --version 2>/dev/null || echo '?')"
    echo "==> TART_HOME ${TART_HOME:-$HOME/.tart}"
    echo "==> repo      $REPO"
    echo "==> fingerprint $(fingerprint)"
    if vm_exists; then
        echo "==> VM        $VM_NAME ($(vm_running && echo running || echo stopped))"
    else
        echo "==> VM        $VM_NAME MISSING — run: $0 init && $0 prep"
        return 1
    fi
    if vm_running; then
        tart_exec test -f '/Users/admin/.consult-mcp-prepped' 2>/dev/null \
            && echo "==> guest     prepped" \
            || echo "==> guest     NOT prepped — run: $0 prep"
    fi
}

cmd_init() { preflight; ensure_vm; echo "==> $VM_NAME ready — next: $0 prep"; }

cmd_prep() {
    preflight
    boot_headless
    echo "==> Provisioning guest"
    tart_exec bash -lc "$(cat "$HERE/prep.sh")"
}

cmd_run() {
    preflight
    local fp; fp="$(fingerprint)"
    echo "==> Suites: $SUITES"
    echo "==> Fingerprint: $fp"
    boot_headless

    tart_exec test -f '/Users/admin/.consult-mcp-prepped' 2>/dev/null \
        || die "guest not provisioned — run: $0 prep"

    rm -f "$OUT_DIR/done" "$OUT_DIR/run.log"

    # The pass has to happen inside the Aqua session or no window is ever
    # mapped. `tart exec` lands in user/501, which has no GUI — so the run is
    # started by a LaunchAgent in gui/501 that watches a trigger file, and
    # its settings arrive through the shared folder rather than the
    # environment, which a LaunchAgent does not inherit.
    {
        echo "SUITES=$SUITES"
        echo "EXPECT_FINGERPRINT=$fp"
        echo "DIALOG_SKIN=${DIALOG_SKIN:-caret}"
        echo "SKINS=${SKINS:-caret}"
    } > "$OUT_DIR/request.env"

    echo "==> Running in guest (up to ${TIMEOUT}s)"
    tart_exec bash -lc 'mkdir -p "$HOME/.consult-mcp-runner" && date +%s > "$HOME/.consult-mcp-runner/request"'

    local deadline=$(( $(date +%s) + TIMEOUT ))
    while [ "$(date +%s)" -lt "$deadline" ]; do
        [ -f "$OUT_DIR/done" ] && break
        sleep 3
    done

    if [ ! -f "$OUT_DIR/done" ]; then
        echo "==> Tail of guest log:"; tail -60 "$OUT_DIR/run.log" 2>/dev/null || true
        die "guest run timed out after ${TIMEOUT}s"
    fi

    local status; status="$(cat "$OUT_DIR/done")"
    echo ""
    tail -80 "$OUT_DIR/run.log" 2>/dev/null || true
    echo ""
    echo "=============================================================="
    echo "  $status"
    echo "  artifacts: $OUT_DIR"
    echo "=============================================================="
    [[ "$status" == PASS* ]]
}

cmd_shell() {
    preflight
    vm_running && die "$VM_NAME is running headless — stop it first: $0 stop"
    ensure_vm
    echo "==> Booting $VM_NAME with a viewer (close the window to shut down)"
    tart run "$VM_NAME" --vnc --dir="repo:$REPO:ro" --dir="out:$OUT_DIR"
}

cmd_stop() {
    ensure_tart_home
    if vm_running; then echo "==> Stopping $VM_NAME"; tart stop "$VM_NAME"
    else echo "==> $VM_NAME not running"; fi
}

cmd_clean() {
    cmd_stop || true
    vm_exists && { echo "==> Deleting $VM_NAME"; tart delete "$VM_NAME"; }
    echo "==> $BASE_VM untouched"
}

cmd_help() { sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; }

case "${1:-help}" in
    check) cmd_check ;;
    init)  cmd_init  ;;
    prep)  cmd_prep  ;;
    run)   cmd_run   ;;
    shell) cmd_shell ;;
    stop)  cmd_stop  ;;
    clean) cmd_clean ;;
    help|-h|--help) cmd_help ;;
    *) echo "Unknown command: $1" >&2; cmd_help; exit 1 ;;
esac
