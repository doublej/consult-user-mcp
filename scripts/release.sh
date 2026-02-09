#!/usr/bin/env bash
set -euo pipefail

# --- Parse arguments ---
DRY_RUN=false
PLATFORM=""
ZIP_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --zip) ZIP_ARG="$2"; shift 2 ;;
    *) echo "error: unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$PLATFORM" ]]; then
  echo "error: --platform macos|windows is required" >&2
  exit 1
fi

# --- Platform config ---
RELEASES_JSON="docs/src/lib/data/releases.json"

case "$PLATFORM" in
  macos)
    VERSION_FILE="macos-app/VERSION"
    TAG_PREFIX="macos/v"
    APP_PATH="/Applications/Consult User MCP.app"
    ZIP_PATH="/tmp/Consult.User.MCP.app.zip"
    PLATFORM_LABEL="macOS"
    ;;
  windows)
    VERSION_FILE="windows-tray-app/VERSION"
    TAG_PREFIX="windows/v"
    PLATFORM_LABEL="Windows"
    if [[ -z "$ZIP_ARG" ]]; then
      echo "error: --zip <path> is required for Windows releases (cannot build .NET on macOS)" >&2
      exit 1
    fi
    ZIP_PATH="$ZIP_ARG"
    ;;
  *)
    echo "error: --platform must be macos or windows" >&2
    exit 1
    ;;
esac

# 1. Read version
if [[ ! -f "$VERSION_FILE" ]]; then
  echo "error: $VERSION_FILE not found" >&2
  exit 1
fi
VERSION=$(tr -d '[:space:]' < "$VERSION_FILE")
TAG="${TAG_PREFIX}${VERSION}"
echo "platform: $PLATFORM_LABEL"
echo "version: $VERSION (tag: $TAG)"

if $DRY_RUN; then
  echo "=== DRY RUN ==="
fi

# 2. Check tag doesn't already exist
if git tag -l "$TAG" | grep -q "$TAG"; then
  echo "error: tag $TAG already exists locally" >&2
  exit 1
fi
if git ls-remote --tags origin "refs/tags/$TAG" | grep -q "$TAG"; then
  echo "error: tag $TAG already exists on remote" >&2
  exit 1
fi
echo "ok: tag $TAG does not exist"

# 3. Check releases.json has entry for this version AND platform
MATCH=$(python3 -c "
import json, sys
data = json.load(open('$RELEASES_JSON'))
for r in data['releases']:
    if r['version'] == '$VERSION' and r.get('platform') == '$PLATFORM':
        print('found')
        sys.exit(0)
sys.exit(1)
" 2>/dev/null || true)

if [[ "$MATCH" != "found" ]]; then
  echo "error: no entry for $PLATFORM v$VERSION in $RELEASES_JSON" >&2
  exit 1
fi
echo "ok: releases.json has $PLATFORM entry for $VERSION"

# 4. Validate baseprompt version (macOS only)
if [[ "$PLATFORM" == "macos" ]]; then
  bash scripts/validate-baseprompt-version.sh
  echo "ok: baseprompt version valid"
fi

# 5. Check working tree is clean
if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: working tree is not clean — commit changes first" >&2
  git status --short >&2
  exit 1
fi
echo "ok: working tree clean"

if $DRY_RUN; then
  echo ""
  echo "=== DRY RUN COMPLETE ==="
  echo "all pre-conditions passed. Run without --dry-run to execute."
  exit 0
fi

# 6. Build (macOS only)
if [[ "$PLATFORM" == "macos" ]]; then
  echo ""
  echo "building app bundle..."
  bun run build:bundle

  if [[ ! -d "$APP_PATH" ]]; then
    echo "error: $APP_PATH not found after build" >&2
    exit 1
  fi
  echo "ok: app bundle exists"

  # Create zip
  rm -f "$ZIP_PATH"
  (cd /Applications && zip -r "$ZIP_PATH" "Consult User MCP.app" -x "*.DS_Store")
  echo "ok: zip created at $ZIP_PATH"
fi

# 7. Verify zip exists and is non-empty
if [[ ! -f "$ZIP_PATH" ]]; then
  echo "error: zip not found at $ZIP_PATH" >&2
  exit 1
fi
ZIP_SIZE=$(stat -f%z "$ZIP_PATH" 2>/dev/null || stat --printf="%s" "$ZIP_PATH" 2>/dev/null)
if [[ "$ZIP_SIZE" -lt 1000 ]]; then
  echo "error: zip is suspiciously small (${ZIP_SIZE} bytes)" >&2
  exit 1
fi
echo "ok: zip is ${ZIP_SIZE} bytes"

# 8. Create tag and push
git tag -a "$TAG" -m "$TAG"
git push origin "$TAG"
echo "ok: tag $TAG pushed"

# 9. Create GitHub release with zip
HIGHLIGHT=$(python3 -c "
import json, sys
data = json.load(open('$RELEASES_JSON'))
for r in data['releases']:
    if r['version'] == '$VERSION' and r.get('platform') == '$PLATFORM':
        print(r.get('highlight', '$VERSION'))
        sys.exit(0)
print('$VERSION')
")

CHANGES=$(python3 -c "
import json, sys
data = json.load(open('$RELEASES_JSON'))
for r in data['releases']:
    if r['version'] == '$VERSION' and r.get('platform') == '$PLATFORM':
        for c in r.get('changes', []):
            print(f\"- {c['text']}\")
        sys.exit(0)
")

gh release create "$TAG" "$ZIP_PATH" \
  --title "$PLATFORM_LABEL v$VERSION — $HIGHLIGHT" \
  --notes "## Changes
$CHANGES"

echo ""
echo "release $TAG created with zip asset attached"
