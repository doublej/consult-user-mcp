#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "=== DRY RUN ==="
fi

VERSION_FILE="macos-app/VERSION"
RELEASES_JSON="docs/src/lib/data/releases.json"
APP_PATH="/Applications/Consult User MCP.app"
ZIP_PATH="/tmp/Consult.User.MCP.app.zip"

# 1. Read version
if [[ ! -f "$VERSION_FILE" ]]; then
  echo "error: $VERSION_FILE not found" >&2
  exit 1
fi
VERSION=$(tr -d '[:space:]' < "$VERSION_FILE")
TAG="v${VERSION}"
echo "version: $VERSION (tag: $TAG)"

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

# 3. Check releases.json has entry for this version
if ! grep -q "\"version\": \"$VERSION\"" "$RELEASES_JSON"; then
  echo "error: no entry for version $VERSION in $RELEASES_JSON" >&2
  exit 1
fi
echo "ok: releases.json has entry for $VERSION"

# 4. Validate baseprompt version
bash scripts/validate-baseprompt-version.sh
echo "ok: baseprompt version valid"

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

# 6. Build bundle
echo ""
echo "building app bundle..."
bun run build:bundle

# 7. Verify app exists
if [[ ! -d "$APP_PATH" ]]; then
  echo "error: $APP_PATH not found after build" >&2
  exit 1
fi
echo "ok: app bundle exists"

# 8. Create zip
rm -f "$ZIP_PATH"
(cd /Applications && zip -r "$ZIP_PATH" "Consult User MCP.app" -x "*.DS_Store")
echo "ok: zip created at $ZIP_PATH"

# 9. Verify zip is non-empty
ZIP_SIZE=$(stat -f%z "$ZIP_PATH" 2>/dev/null || stat --printf="%s" "$ZIP_PATH" 2>/dev/null)
if [[ "$ZIP_SIZE" -lt 1000 ]]; then
  echo "error: zip is suspiciously small (${ZIP_SIZE} bytes)" >&2
  exit 1
fi
echo "ok: zip is ${ZIP_SIZE} bytes"

# 10. Create tag and push
git tag -a "$TAG" -m "$TAG"
git push origin "$TAG"
echo "ok: tag $TAG pushed"

# 11. Create GitHub release with zip
HIGHLIGHT=$(python3 -c "
import json, sys
data = json.load(open('$RELEASES_JSON'))
for r in data['releases']:
    if r['version'] == '$VERSION':
        print(r.get('highlight', '$VERSION'))
        sys.exit(0)
print('$VERSION')
")

CHANGES=$(python3 -c "
import json, sys
data = json.load(open('$RELEASES_JSON'))
for r in data['releases']:
    if r['version'] == '$VERSION':
        for c in r.get('changes', []):
            print(f\"- {c['text']}\")
        sys.exit(0)
")

gh release create "$TAG" "$ZIP_PATH" \
  --title "$TAG — $HIGHLIGHT" \
  --notes "## Changes
$CHANGES"

echo ""
echo "release $TAG created with zip asset attached"
