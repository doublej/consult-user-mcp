#!/bin/zsh
# Screenshot every state in states.tsv for one skin.
#
#   ./capture-states.sh [name-filter]
#
# Env:
#   SKIN         skin id to render (default: bracket)
#   OUTDIR       where shots land (default: ./shots)
#
# Per row: launch the CLI backgrounded with DIALOG_SKIN set, wait settleDelay,
# resolve the window id, screencapture just that window, kill the process.
# Writes shots/<name>.png plus an index.html contact sheet.

set -u
HERE=${0:A:h}
ROOT=${HERE:h:h}
SKIN=${SKIN:-bracket}
OUTDIR=${OUTDIR:-$HERE/shots}
FILTER=${1:-}
CLI="$ROOT/dialog-cli/.build/debug/DialogCLI"
FINDWIN="$HERE/.findwin"

if [[ ! -x "$CLI" ]]; then
  echo "build first:  cd $ROOT/dialog-cli && swift build" >&2
  exit 1
fi

# capture-dialog.swift takes ~2s to compile each run, which is longer than some
# of the states being captured. Compile it once.
if [[ ! -x "$FINDWIN" || "$ROOT/test-cases/capture-dialog.swift" -nt "$FINDWIN" ]]; then
  swiftc -O -o "$FINDWIN" "$ROOT/test-cases/capture-dialog.swift" || exit 1
fi

# A stray snooze silently suppresses every interactive surface, so a capture run
# would return nothing at all. Park it and restore on the way out.
SETTINGS="$HOME/Library/Application Support/ConsultUserMCP/settings.json"
BACKUP="$HERE/.settings.backup.json"
if [[ -f "$SETTINGS" ]]; then
  cp "$SETTINGS" "$BACKUP"
  python3 - "$SETTINGS" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path))
if data.pop("snoozeUntil", None) is not None:
    json.dump(data, open(path, "w"), indent=2)
PY
fi
restore() {
  [[ -f "$BACKUP" ]] && mv "$BACKUP" "$SETTINGS"
}
trap restore EXIT INT TERM

mkdir -p "$OUTDIR"
NAMES=()

while IFS=$'\t' read -r NAME DIR CASE DELAY PANE KEYS; do
  [[ -z "${NAME:-}" || "$NAME" == \#* ]] && continue
  [[ -n "$FILTER" && "$NAME" != *"$FILTER"* ]] && continue

  case "$DIR" in
    confirm)    CMD=confirm ;;
    choose)     CMD=choose ;;
    text-input) CMD=textInput ;;
    questions)  CMD=questions ;;
    notify)     CMD=notify ;;
    preview)    CMD=preview ;;
    *) echo "unknown fixture dir: $DIR" >&2; continue ;;
  esac

  FIX="$ROOT/test-cases/cases/$DIR/$CASE.json"
  # Surfaces with no shared cases/ directory keep their fixtures beside the
  # manifest rather than being added to the shared corpus.
  [[ -f "$FIX" ]] || FIX="$HERE/fixtures/$DIR/$CASE.json"
  if [[ ! -f "$FIX" ]]; then
    echo "missing fixture: $FIX" >&2
    continue
  fi

  (
    export DIALOG_SKIN="$SKIN"
    if [[ -n "${PANE:-}" && "$PANE" != "-" ]]; then export DIALOG_TEST_PANE="$PANE"; fi
    if [[ -n "${KEYS:-}" && "$KEYS" != "-" ]]; then export DIALOG_TEST_KEYS="$KEYS"; fi
    "$CLI" "$CMD" "$(cat "$FIX")" >/dev/null 2>&1
  ) &
  PID=$!
  sleep "$DELAY"
  WID=$("$FINDWIN" 2>/dev/null)
  if [[ -n "$WID" ]]; then
    screencapture -o -x -l"$WID" "$OUTDIR/$NAME.png"
    echo "ok   $NAME"
    NAMES+=("$NAME")
  else
    echo "MISS $NAME"
  fi
  kill $PID 2>/dev/null
  wait $PID 2>/dev/null
done < "$HERE/states.tsv"

{
  echo "<!doctype html><meta charset=utf-8><title>$SKIN states</title>"
  echo "<style>body{background:#141416;color:#e8e8ea;font:13px -apple-system,sans-serif;margin:24px}"
  echo "h1{font-size:15px;letter-spacing:.08em;text-transform:uppercase;color:#98989f}"
  echo ".g{display:grid;grid-template-columns:repeat(auto-fill,minmax(380px,1fr));gap:20px}"
  echo "figure{margin:0}figcaption{font:11px ui-monospace,monospace;color:#98989f;padding:6px 0}"
  echo "img{max-width:100%;border-radius:8px;display:block;background:#000}</style>"
  echo "<h1>$SKIN — ${#NAMES} states</h1><div class=g>"
  for N in "${NAMES[@]}"; do
    echo "<figure><img src=\"shots/$N.png\"><figcaption>$N</figcaption></figure>"
  done
  echo "</div>"
} > "$HERE/index.html"

echo "contact sheet: $HERE/index.html"
