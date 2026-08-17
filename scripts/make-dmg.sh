#!/bin/bash
# Build a .dmg from an app bundle — the app next to an /Applications symlink,
# so the drag-to-install gesture is the whole instruction.
#
# Signed with the same Developer ID identity as the bundle when one is present,
# skipped silently when there is none: an unsigned dmg still mounts.
#
# Usage: make-dmg.sh <app-path> <dmg-path>
set -e

APP_PATH="${1:?usage: make-dmg.sh <app-path> <dmg-path>}"
DMG_PATH="${2:?usage: make-dmg.sh <app-path> <dmg-path>}"

VOL_NAME="$(basename "$APP_PATH" .app)"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

cp -R "$APP_PATH" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG_PATH"
hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG_PATH" >/dev/null
echo "  dmg created at $DMG_PATH"

IDENTITY="${CODESIGN_IDENTITY:-$(security find-identity -v -p codesigning \
    | sed -n 's/.*"\(Developer ID Application: .*\)"$/\1/p' | head -1)}"

if [ -z "$IDENTITY" ]; then
    echo "  No Developer ID Application identity in keychain — dmg left unsigned"
    exit 0
fi

codesign --force --timestamp --sign "$IDENTITY" "$DMG_PATH"
codesign --verify --strict "$DMG_PATH"
echo "  dmg signed and verified"
