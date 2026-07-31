#!/bin/bash
# Guest provisioning. Idempotent — re-running is cheap, and it only needs
# re-running when this file changes, not when the harness does.
#
# What it installs is deliberately small: toolchain, the LaunchAgents that
# get work into the Aqua session, and the Screen Recording grant. The suite
# itself is not baked in — see the invoke shim below.
set -euo pipefail

SENTINEL="$HOME/.consult-mcp-prepped"
TRIGGER_DIR="$HOME/.consult-mcp-runner"
PLIST="$HOME/Library/LaunchAgents/dev.consult-mcp.runner.plist"
INVOKE_SH="$TRIGGER_DIR/invoke.sh"
UID_NUM="$(id -u)"

echo "==> Guest: $(sw_vers -productName) $(sw_vers -productVersion) / $(uname -m)"

if ! xcode-select -p >/dev/null 2>&1; then
    echo "ERROR: Xcode CLT missing. Run 'launch.sh shell' and: xcode-select --install"
    exit 1
fi
echo "==> swift: $(swift --version 2>&1 | head -1)"

# ── toolchain ─────────────────────────────────────────────────────────
if ! command -v brew >/dev/null 2>&1; then
    echo "==> Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    BREW="$( [ -d /opt/homebrew ] && echo /opt/homebrew || echo /usr/local )/bin/brew"
    echo "eval \"\$($BREW shellenv)\"" >> "$HOME/.zprofile"
fi
eval "$($(command -v brew || echo /opt/homebrew/bin/brew) shellenv)"

NEEDED=(tesseract imagemagick jq bc rsync)
MISSING=()
for pkg in "${NEEDED[@]}"; do
    brew list --formula "$pkg" >/dev/null 2>&1 || MISSING+=("$pkg")
done
if [ ${#MISSING[@]} -gt 0 ]; then
    echo "==> brew install ${MISSING[*]}"
    brew install "${MISSING[@]}"
else
    echo "==> brew deps already installed"
fi

# bun runs the checker the layout audit fails on, and the server's own
# tests. Without it the container can only take photographs.
if ! "$HOME/.bun/bin/bun" --version >/dev/null 2>&1; then
    echo "==> Installing bun"
    curl -fsSL https://bun.sh/install | bash
fi
export PATH="$HOME/.bun/bin:$PATH"
echo "==> bun: $(bun --version 2>&1)"

# ──────────────────────────────────────────────────────────────────────
# The Aqua-session runner.
#
# tart-guest-agent lives in `user/501`, a LaunchAgent domain with no GUI.
# Anything `tart exec` starts can spawn AppKit processes, but the
# WindowServer never maps their windows, so `screencapture -l <wid>` fails
# and every on-screen suite reports nothing rather than failing honestly.
#
# A per-user LaunchAgent under ~/Library/LaunchAgents auto-loads into
# `gui/<uid>` at login. It watches a trigger file; the host touches it, the
# agent runs the pass where windows are real.
#
# The shim below is the ONLY part of the suite baked into the VM, and it is
# deliberately trivial: sync, then hand over to the repo's own guest-run.sh.
# Everything that changes lives in the repo and arrives with the code under
# test, so a harness edit never needs a re-prep and the guest can never run
# a suite that disagrees with the sources beneath it.
# ──────────────────────────────────────────────────────────────────────

mkdir -p "$TRIGGER_DIR"

cat > "$INVOKE_SH" <<'INVOKE'
#!/bin/bash
set -uo pipefail
SRC="/Volumes/My Shared Files/repo"
SHARE_OUT="/Volumes/My Shared Files/out"
WORK="$HOME/work/consult-user-mcp"

# WatchPaths fires on any event on the directory, including our own writes.
REQ="$HOME/.consult-mcp-runner/request"
[ -f "$REQ" ] || exit 0
rm -f "$REQ"

: > "$SHARE_OUT/run.log"
exec >>"$SHARE_OUT/run.log" 2>&1

if [ ! -d "$SRC" ]; then
    echo "FAIL: shared repo not mounted at $SRC" | tee "$SHARE_OUT/done"
    exit 1
fi

# Settings travel by file: a LaunchAgent inherits no environment.
set -a
[ -f "$SHARE_OUT/request.env" ] && . "$SHARE_OUT/request.env"
set +a

mkdir -p "$WORK"
echo "==> rsync repo → $WORK"
rsync -a --delete \
    --exclude '.build/' --exclude 'node_modules/' --exclude '.git/' \
    --exclude 'test-cases/screenshots/' --exclude 'test-cases/skin-states/audit/' \
    --exclude 'container/out/' \
    "$SRC/" "$WORK/"

exec bash "$WORK/container/guest-run.sh"
INVOKE
chmod +x "$INVOKE_SH"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>            <string>dev.consult-mcp.runner</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$INVOKE_SH</string>
  </array>
  <key>WatchPaths</key>
  <array><string>$TRIGGER_DIR/request</string></array>
  <key>RunAtLoad</key>        <false/>
  <key>StandardOutPath</key>  <string>$TRIGGER_DIR/agent.log</string>
  <key>StandardErrorPath</key><string>$TRIGGER_DIR/agent.log</string>
</dict>
</plist>
EOF

echo "==> Loading runner agent into gui/$UID_NUM"
launchctl bootout "gui/$UID_NUM/dev.consult-mcp.runner" 2>/dev/null || true
launchctl bootstrap "gui/$UID_NUM" "$PLIST"
launchctl enable "gui/$UID_NUM/dev.consult-mcp.runner"

# ──────────────────────────────────────────────────────────────────────
# Interactive spawn agent, used by vnc-matrix.sh. The host writes a
# per-scenario request into the shared folder, points spawn.idx at it and
# bootstraps this agent; it opens one dialog and waits. Plist and script
# live under ~/Library so they survive a reboot — /tmp does not.
# ──────────────────────────────────────────────────────────────────────

#
# Its plist deliberately does NOT live in ~/Library/LaunchAgents: launchd
# auto-loads everything there at login, and with RunAtLoad set that opened a
# dialog on every boot. It then sat on screen holding focus, and the next
# suite's keystrokes went to it instead — seven keyboard tests timing out
# against a window nobody asked for. Kept out of the auto-load directory, it
# runs only when the matrix bootstraps it by path.
SPAWN_DIR="$HOME/.consult-mcp-spawn"
SPAWN_PLIST="$SPAWN_DIR/dev.consult-mcp.spawn.plist"
SPAWN_SH="$SPAWN_DIR/spawn.sh"
mkdir -p "$SPAWN_DIR"
rm -f "$HOME/Library/LaunchAgents/dev.consult-mcp.spawn.plist"

cat > "$SPAWN_SH" <<'SPAWN'
#!/bin/bash
SHARED="/Volumes/My Shared Files/out"
IDX=$(cat "$HOME/.consult-mcp-spawn/spawn.idx" 2>/dev/null)
SUF="${IDX:+-$IDX}"
REQ="$SHARED/interact-request$SUF.json"
OUT="$SHARED/interact-result$SUF.json"
ERR="$SHARED/interact-result$SUF.err"
READY="$SHARED/interact-ready$SUF"
DONE="$SHARED/interact-done$SUF"
CLI="$HOME/work/consult-user-mcp/dialog-cli/.build/release/DialogCLI"

# VirtioFS hands over a partially-written file often enough to matter: copy
# locally and retry until it parses.
LOCAL="$HOME/.consult-mcp-spawn/req.json"
for try in 1 2 3 4 5; do
    cp "$REQ" "$LOCAL" 2>/dev/null
    /opt/homebrew/bin/jq -e . "$LOCAL" >/dev/null 2>&1 && break
    sleep 0.3
done

CMD=$(/opt/homebrew/bin/jq -r .command "$LOCAL")
BODY=$(/opt/homebrew/bin/jq -c .body "$LOCAL")

cd "$HOME/work/consult-user-mcp" || exit 1
"$CLI" "$CMD" "$BODY" >"$OUT" 2>"$ERR" &
DPID=$!
sleep 2.2
touch "$READY"
wait $DPID
touch "$DONE"
SPAWN
chmod +x "$SPAWN_SH"

cat > "$SPAWN_PLIST" <<EOF
<?xml version="1.0"?><plist version="1.0"><dict>
<key>Label</key><string>dev.consult-mcp.spawn</string>
<key>ProgramArguments</key><array><string>/bin/bash</string><string>$SPAWN_SH</string></array>
<key>RunAtLoad</key><true/>
<key>StandardOutPath</key><string>$SPAWN_DIR/agent.log</string>
<key>StandardErrorPath</key><string>$SPAWN_DIR/agent.log</string>
</dict></plist>
EOF
launchctl bootout "gui/$UID_NUM/dev.consult-mcp.spawn" 2>/dev/null || true
echo "==> spawn agent installed (bootstrapped on demand by vnc-matrix.sh)"

# ── Screen Recording ──────────────────────────────────────────────────
# `screencapture -l <wid>` is TCC-gated. Without the grant it fails with
# "could not create image from window" even though the window is on screen
# — which reads as a layout bug rather than a permissions one. SIP is off
# in the cirruslabs base images, so the grant can be written directly.
echo "==> Pre-granting kTCCServiceScreenCapture"
sudo -n killall tccd 2>/dev/null || true
sudo -n sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" "
UPDATE access SET auth_value=2, auth_reason=4 WHERE service='kTCCServiceScreenCapture';
INSERT OR REPLACE INTO access (service,client,client_type,auth_value,auth_reason,auth_version,indirect_object_identifier,flags)
  VALUES ('kTCCServiceScreenCapture','/bin/bash',1,2,4,1,'UNUSED',0);
INSERT OR REPLACE INTO access (service,client,client_type,auth_value,auth_reason,auth_version,indirect_object_identifier,flags)
  VALUES ('kTCCServiceScreenCapture','/usr/sbin/screencapture',1,2,4,1,'UNUSED',0);
INSERT OR REPLACE INTO access (service,client,client_type,auth_value,auth_reason,auth_version,indirect_object_identifier,flags)
  VALUES ('kTCCServiceScreenCapture','dev.consult-mcp.runner',0,2,4,1,'UNUSED',0);
" 2>&1 | grep -v "^$" || true

touch "$SENTINEL"
echo "==> Prep complete"
