#!/bin/bash
# Code-sign the app bundle with a Developer ID Application identity.
#
# Inside-out: the nested CLI binaries first, the bundle last — otherwise the
# bundle's resource seal is computed over binaries that are about to change.
#
# No identity in the keychain: skip silently. An unsigned bundle is the
# pre-Developer-ID status quo and still runs locally, so this must not be a
# hard failure for anyone building without certs.
#
# Usage: codesign-app.sh <app-path> [--release]
#   --release  request a secure timestamp (required for notarization, needs
#              network). Omitted for dev builds so `bun run dev` stays fast.
set -e

APP_PATH="${1:?usage: codesign-app.sh <app-path> [--release]}"
MODE="${2:-}"

IDENTITY="${CODESIGN_IDENTITY:-$(security find-identity -v -p codesigning \
    | sed -n 's/.*"\(Developer ID Application: .*\)"$/\1/p' | head -1)}"

if [ -z "$IDENTITY" ]; then
    echo "  No Developer ID Application identity in keychain — skipping code signing"
    exit 0
fi

if [ "$MODE" = "--release" ]; then
    TIMESTAMP="--timestamp"
else
    TIMESTAMP="--timestamp=none"
fi

echo "  Signing with: $IDENTITY"

codesign --force --options runtime "$TIMESTAMP" --sign "$IDENTITY" \
    "$APP_PATH/Contents/Resources/dialog-cli/dialog-cli" \
    "$APP_PATH/Contents/Resources/sketch-cli/sketch-cli"

codesign --force --options runtime "$TIMESTAMP" --sign "$IDENTITY" "$APP_PATH"

codesign --verify --strict "$APP_PATH"
echo "  Signature verified"
