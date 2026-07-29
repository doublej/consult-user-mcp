#!/bin/zsh
# Screenshot every state in states.tsv for one skin, without ever putting a
# window on screen or taking the keyboard.
#
#   ./capture-states.sh [name-filter]
#
# Env:
#   SKIN               skin id to render (default: caret)
#   OUTDIR             where shots land (default: ./shots)
#   DIALOG_THEME       palette to render in (e.g. light)
#   MCP_PROJECT_PATH   project identity shown on the surfaces
#
# The renderer under render/ builds each surface through the real
# `DialogManager` window path — real two-pass sizing, real size observer, real
# key router — but parks the window far outside every display and captures it
# with `cacheDisplay` rather than `screencapture`. Nothing appears, nothing
# activates, and the whole manifest runs in one process.

set -u
HERE=${0:A:h}
ROOT=${HERE:h:h}
SKIN=${SKIN:-caret}
OUTDIR=${OUTDIR:-$HERE/shots}
FILTER=${1:-}
SRC="$ROOT/dialog-cli/Sources/DialogCLI"
BIN="$HERE/.render"

# Rebuild when any product source or the harness itself is newer than the
# binary. Compiling the whole target takes a while, so do not do it per state.
NEWEST=$(find "$SRC" "$HERE/render" -name '*.swift' -newer "$BIN" -print -quit 2>/dev/null)
if [[ ! -x "$BIN" || -n "$NEWEST" ]]; then
  echo "compiling renderer…"
  FILES=("${(@f)$(find $SRC -name '*.swift' ! -name 'Main.swift')}")
  # Same module name and language mode SwiftPM uses for this target, so the
  # sources see exactly the declarations they see in the real build.
  if ! swiftc -Onone -swift-version 5 -module-name DialogCLI \
       -target arm64-apple-macos14.0 -o "$BIN" \
       "$HERE/render/main.swift" "${FILES[@]}" 2>"$HERE/.render.log"; then
    # Print error headlines only. The compiler echoes source context, and the
    # sources it echoes include the styles this work is deliberately blind to.
    python3 - "$HERE/.render.log" <<'PY'
import re, sys
seen = []
for line in open(sys.argv[1], errors="replace"):
    m = re.match(r"^(?:(/\S+?):(\d+):(\d+): )?(error|fatal error): (.*)$", line.rstrip("\n"))
    if not m:
        continue
    path, ln, _, kind, msg = m.groups()
    where = f"{path.split('/')[-1]}:{ln}" if path else "link"
    seen.append(f"{kind}: {where}  {msg}")
for s in list(dict.fromkeys(seen))[:25]:
    print(s)
PY
    echo "renderer build failed" >&2
    exit 1
  fi
fi

mkdir -p "$OUTDIR"
"$BIN" "$HERE/states.tsv" "$OUTDIR" "$SKIN" "$FILTER"
