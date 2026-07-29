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
# render/ builds each surface through the real `DialogManager` window path —
# real two-pass sizing, real size observer, real key router — but parks the
# window outside every display and captures it with `cacheDisplay` rather than
# `screencapture`. Nothing appears and nothing activates, so a run can happen
# underneath whatever you are doing.
#
# One process per state, on purpose: a surface installs a key monitor and a
# size observer that outlive the run loop turn its window closes on, and
# sharing a process let one state's leftovers eat the next state's script.

set -u
HERE=${0:A:h}
ROOT=${HERE:h:h}
SKIN=${SKIN:-caret}
OUTDIR=${OUTDIR:-$HERE/shots}
FILTER=${1:-}
SRC="$ROOT/dialog-cli/Sources/DialogCLI"
BIN="$HERE/.render"

NEWEST=$(find "$SRC" "$HERE/render" -name '*.swift' -newer "$BIN" -print -quit 2>/dev/null)
if [[ ! -x "$BIN" || -n "$NEWEST" ]]; then
  echo "compiling renderer…"
  FILES=("${(@f)$(find $SRC -name '*.swift' ! -name 'Main.swift')}")
  # Same module name and language mode SwiftPM uses for this target, so the
  # sources see exactly the declarations they see in the real build.
  if ! swiftc -Onone -swift-version 5 -module-name DialogCLI \
       -target arm64-apple-macos14.0 -o "$BIN" \
       "$HERE/render/main.swift" "${FILES[@]}" 2>"$HERE/.render.log"; then
    # Error headlines only. The compiler echoes source context, and the sources
    # it echoes include the styles this work is deliberately blind to.
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
NAMES=()
MISSED=()

while IFS=$'\t' read -r NAME REST; do
  [[ -z "${NAME:-}" || "$NAME" == \#* ]] && continue
  [[ -n "$FILTER" && "$NAME" != *"$FILTER"* ]] && continue
  if "$BIN" "$HERE/states.tsv" "$OUTDIR" "$SKIN" "=$NAME" >/dev/null 2>&1; then
    NAMES+=("$NAME")
    echo "ok   $NAME"
  else
    MISSED+=("$NAME")
    echo "MISS $NAME"
  fi
done < "$HERE/states.tsv"

python3 - "$HERE/index.html" "$OUTDIR" "$SKIN" "${NAMES[@]}" <<'PY'
import sys
out, outdir, skin, names = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:]
cards = "\n".join(
    f'<figure><img src="{outdir}/{n}.png"><figcaption>{n}</figcaption></figure>' for n in names
)
open(out, "w").write(f"""<!doctype html><meta charset=utf-8><title>{skin} states</title>
<style>body{{background:#141416;color:#e8e8ea;font:13px -apple-system,sans-serif;margin:24px}}
h1{{font-size:15px;letter-spacing:.08em;text-transform:uppercase;color:#98989f}}
.g{{display:grid;grid-template-columns:repeat(auto-fill,minmax(440px,1fr));gap:20px}}
figure{{margin:0}}figcaption{{font:11px ui-monospace,monospace;color:#98989f;padding:6px 0}}
img{{max-width:100%;border-radius:8px;display:block}}</style>
<h1>{skin} — {len(names)} states</h1><div class=g>
{cards}
</div>""")
PY

(( ${#MISSED} )) && echo "missed: ${MISSED[*]}"
echo "contact sheet: $HERE/index.html"
