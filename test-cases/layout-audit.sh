#!/bin/bash
# Layout audit — render every state for one or more skins and assert on the
# result. This is the asserting half of the visual harness: `test-runner.sh`
# spawns real dialogs and photographs them for a human, this one measures them
# and fails.
#
#   ./layout-audit.sh                 # every skin in the registry
#   SKINS=caret ./layout-audit.sh     # one skin
#   ./layout-audit.sh choose-         # only states whose name matches
#
# Env:
#   SKINS    space-separated skin ids (default: all four)
#   OUTROOT  where shots and reports land (default: skin-states/audit)
#   KEEP     set to keep previous output instead of clearing it
#
# Nothing appears on screen and nothing takes the keyboard: the renderer parks
# each window off-display and reads the view tree directly. A run can happen
# underneath whatever you are doing.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATES_DIR="$HERE/skin-states"
SKINS="${SKINS:-caret classic bracket alt}"
OUTROOT="${OUTROOT:-$STATES_DIR/audit}"
FILTER="${1:-}"

command -v bun >/dev/null || { echo "ERROR: bun required for the checker" >&2; exit 2; }

[ -z "${KEEP:-}" ] && rm -rf "$OUTROOT"
mkdir -p "$OUTROOT"

FAILED_SKINS=()

for skin in $SKINS; do
    echo "=============================================================="
    echo "  $skin"
    echo "=============================================================="
    outdir="$OUTROOT/$skin"
    render_log="$OUTROOT/$skin.render.log"
    SKIN="$skin" OUTDIR="$outdir" "$STATES_DIR/capture-states.sh" "$FILTER" > "$render_log" 2>&1

    # A build failure otherwise reaches the operator as the checker's usage
    # string, because the run produced no reports for it to read.
    if grep -q 'renderer build failed' "$render_log"; then
        echo "The renderer did not build. Compiler output:"
        grep -E '^(error|fatal error):' "$render_log" | sed 's/^/  /' | head -20
        FAILED_SKINS+=("$skin (build)")
        continue
    fi

    # A state that never rendered is not a state that passed. The usual cause
    # is a fixture the request model refuses to decode — a missing non-optional
    # field — which otherwise just quietly removes a case from the suite.
    if grep -q '^MISS' "$render_log"; then
        echo "States that failed to render (fixture will not decode, or unknown kind):"
        grep '^MISS' "$render_log" | sed 's/^MISS/  /'
        FAILED_SKINS+=("$skin (render)")
    fi

    if ! bun "$STATES_DIR/check-layout.ts" "$outdir"; then
        FAILED_SKINS+=("$skin")
    fi
done

echo "=============================================================="
if [ ${#FAILED_SKINS[@]} -gt 0 ]; then
    echo "Layout audit FAILED: ${FAILED_SKINS[*]}"
    echo "Shots and reports: $OUTROOT"
    exit 1
fi
echo "Layout audit passed for: $SKINS"
echo "Shots and reports: $OUTROOT"
