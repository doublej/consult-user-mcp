#!/usr/bin/env bash
set -e

BASEPROMPT_FILE="macos-app/Sources/Resources/base-prompt.md"

echo "🔍 Validating baseprompt version..."

# Check if file exists
if [ ! -f "$BASEPROMPT_FILE" ]; then
    echo "❌ Error: $BASEPROMPT_FILE not found"
    exit 1
fi

# Extract version from comment
VERSION=$(grep -oE '<!-- version: ([0-9]+\.[0-9]+\.[0-9]+) -->' "$BASEPROMPT_FILE" | sed -E 's/<!-- version: ([0-9]+\.[0-9]+\.[0-9]+) -->/\1/')

if [ -z "$VERSION" ]; then
    echo "❌ Error: No version comment found in $BASEPROMPT_FILE"
    echo "   Expected format: <!-- version: X.Y.Z -->"
    exit 1
fi

# Validate semver format
if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "❌ Error: Version '$VERSION' is not valid semver (X.Y.Z)"
    exit 1
fi

# Check if version is at line 1
FIRST_LINE=$(head -n 1 "$BASEPROMPT_FILE")
if ! echo "$FIRST_LINE" | grep -qE '<!-- version: [0-9]+\.[0-9]+\.[0-9]+ -->'; then
    echo "❌ Error: Version comment must be on the first line"
    echo "   Found: $FIRST_LINE"
    exit 1
fi

echo "✅ Baseprompt version is valid: v$VERSION"

# Check if version matches what Swift would extract
echo "   Version will be embedded as: <consult-user-mcp-baseprompt version=\"$VERSION\">"
