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
    DMG_PATH="/tmp/Consult.User.MCP.dmg"
    PLATFORM_LABEL="macOS"
    ;;
  windows)
    VERSION_FILE="windows-app/VERSION"
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

# 3b. Validate CHANGELOG.md is up-to-date with releases.json
CHANGELOG_BACKUP=$(mktemp)
cp CHANGELOG.md "$CHANGELOG_BACKUP"
bun run scripts/generate-changelog.ts 2>/dev/null
if ! diff -q CHANGELOG.md "$CHANGELOG_BACKUP" > /dev/null 2>&1; then
  cp "$CHANGELOG_BACKUP" CHANGELOG.md
  rm -f "$CHANGELOG_BACKUP"
  echo "error: CHANGELOG.md is out of date — run 'bun run changelog' and commit" >&2
  exit 1
fi
cp "$CHANGELOG_BACKUP" CHANGELOG.md
rm -f "$CHANGELOG_BACKUP"
echo "ok: CHANGELOG.md is up-to-date"

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
  RELEASE_BUILD=1 bun run build:bundle

  if [[ ! -d "$APP_PATH" ]]; then
    echo "error: $APP_PATH not found after build" >&2
    exit 1
  fi
  echo "ok: app bundle exists"

  # ditto, not zip: it preserves symlinks and extended attributes, which
  # notarization and stapling both depend on.
  makezip() {
    rm -f "$ZIP_PATH"
    ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
    # An AppleDouble member here means unzip will drop a `._name` file inside
    # the bundle and break its seal, so every existing install that updates
    # through this asset gets an app that will not launch. Fail the release.
    if unzip -l "$ZIP_PATH" | grep -q '/\._'; then
      echo "error: zip contains AppleDouble members — an update from it would" >&2
      echo "       break the code signature. Strip xattrs before signing." >&2
      unzip -l "$ZIP_PATH" | grep '/\._' >&2
      exit 1
    fi
  }

  # The dmg is what a human downloads; the zip is what install.sh and the
  # in-app updater consume. Both ship.
  bash scripts/make-dmg.sh "$APP_PATH" "$DMG_PATH"

  # Notarize. Needs a stored keychain profile — see the release-app skill.
  # One submission covers both assets: the ticket issued for the dmg also
  # covers the app nested inside it, so the app staples from the same run.
  # Two things had to be right here and neither was.
  #
  # `-dvv`, not `-dv`: the Authority lines only appear at verbose level 2, so at
  # level 1 the test could never match.
  #
  # And the output is captured rather than piped into `grep -q`. Under
  # `pipefail`, `grep -q` exiting on the first match can hand `codesign` a
  # SIGPIPE while it is still writing — the pipeline then reports 141 and the
  # test fails even though the pattern matched. It is a race, so it failed
  # intermittently, which is the worst way for a release gate to be wrong.
  SIGN_INFO="$(codesign -dvv "$APP_PATH" 2>&1 || true)"
  if grep -q "Authority=Developer ID Application" <<< "$SIGN_INFO"; then
    echo "notarizing (this takes a few minutes)..."
    xcrun notarytool submit "$DMG_PATH" --keychain-profile "${NOTARY_PROFILE:-consult-user-mcp}" --wait
    xcrun stapler staple "$DMG_PATH"
    xcrun stapler staple "$APP_PATH"
    echo "ok: notarized and stapled"
  else
    echo "warning: app is not Developer ID signed — shipping unsigned, users will hit Gatekeeper" >&2
  fi

  makezip   # after stapling, so the zipped app carries the ticket
  echo "ok: zip created at $ZIP_PATH"

  if [[ ! -f "$DMG_PATH" ]]; then
    echo "error: dmg not found at $DMG_PATH" >&2
    exit 1
  fi
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

ASSETS=("$ZIP_PATH")
if [[ "$PLATFORM" == "macos" ]]; then
  ASSETS+=("$DMG_PATH")
fi

gh release create "$TAG" "${ASSETS[@]}" \
  --title "$PLATFORM_LABEL v$VERSION — $HIGHLIGHT" \
  --notes "## Changes
$CHANGES"

echo ""
echo "release $TAG created with assets attached: ${ASSETS[*]}"
