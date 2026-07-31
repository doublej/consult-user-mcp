#!/bin/zsh
# Screenshot every state in states.tsv for one skin, without ever putting a
# window on screen or taking the keyboard.
#
#   ./capture-states.sh [name-filter]
#
# Env:
#   SKIN               skin id to render (default: caret)
#   OUTDIR             where shots land (default: ./shots)
#   STATES             manifest to read (default: ./states.tsv)
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
STATES=${STATES:-$HERE/states.tsv}
FILTER=${1:-}
SRC="$ROOT/dialog-cli/Sources/DialogCLI"
BIN="$HERE/.render"

NEWEST=$(find "$SRC" "$HERE/render" -name '*.swift' -newer "$BIN" -print -quit 2>/dev/null)
if [[ ! -x "$BIN" || -n "$NEWEST" ]]; then
  echo "compiling renderer…"
  FILES=("${(@f)$(find $SRC -name '*.swift' ! -name 'Main.swift')}")
  RENDER=("${(@f)$(find $HERE/render -name '*.swift')}")
  # Same module name and language mode SwiftPM uses for this target, so the
  # sources see exactly the declarations they see in the real build.
  if ! swiftc -Onone -swift-version 5 -module-name DialogCLI \
       -target arm64-apple-macos14.0 -o "$BIN" \
       "${RENDER[@]}" "${FILES[@]}" 2>"$HERE/.render.log"; then
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

# Each state runs in its own process — deliberately, so one state's leftover
# key monitor cannot eat the next one's script — and writes only to its own
# two files. So they can run at once. But only some of them.
#
# A state that opens a pane or types a key script is waiting on an animation
# to settle, and its delay in states.tsv was measured on a machine doing one
# thing at a time. Run those under load and the probe measures a surface
# mid-transition: content taller than its window, controls still outside it.
# Every one of the eleven states that went red the first time this ran in
# parallel was a pane or a key script, and all of them were correct.
#
# So the split is not a tuning knob, it is the rule: parallelism must not be
# able to change the verdict. States with nothing to settle go wide; states
# that are timing-sensitive stay serial and keep their calibration.
JOBS=${JOBS:-$(( $(sysctl -n hw.ncpu) - 2 ))}
(( JOBS < 1 )) && JOBS=1
STATUS=$(mktemp -d)

PENDING=()   # manifest order, for reporting
FAST=()      # nothing to settle — safe to run alongside anything
SLOW=()      # pane or key script — must have the machine to itself
while IFS=$'\t' read -r NAME DIR CASE SETTLE PANE KEYS REST; do
  [[ -z "${NAME:-}" || "$NAME" == \#* ]] && continue
  [[ -n "$FILTER" && "$NAME" != *"$FILTER"* ]] && continue
  PENDING+=("$NAME")
  if [[ "${PANE:--}" == "-" && "${KEYS:--}" == "-" ]]; then
    FAST+=("$NAME")
  else
    SLOW+=("$NAME")
  fi
done < "$STATES"

render() { "$BIN" "$STATES" "$OUTDIR" "$SKIN" "=$1" >/dev/null 2>&1; }

for NAME in "${FAST[@]}"; do
  # Wait for a slot. zsh has no `wait -n`, so poll — states take seconds
  # each and the poll costs nothing next to that.
  while (( $(jobs -rp | wc -l) >= JOBS )); do sleep 0.05; done
  { render "$NAME" && echo ok > "$STATUS/$NAME" || echo miss > "$STATUS/$NAME" } &
done
wait

for NAME in "${SLOW[@]}"; do
  render "$NAME" && echo ok > "$STATUS/$NAME" || echo miss > "$STATUS/$NAME"
done

# Reported in manifest order regardless of the order they finished, so the
# log stays diffable between runs.
for NAME in "${PENDING[@]}"; do
  if [[ "$(cat "$STATUS/$NAME" 2>/dev/null)" == ok ]]; then
    NAMES+=("$NAME")
    echo "ok   $NAME"
  else
    MISSED+=("$NAME")
    echo "MISS $NAME"
  fi
done
rm -rf "$STATUS"

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
