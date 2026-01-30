#!/usr/bin/env bash
# Check if baseprompt content changed without version bump
# Usage: bash scripts/check-baseprompt-version-bump.sh [base-ref]
# Default base-ref: main

set -e

BASE_REF="${1:-main}"
BASEPROMPT_FILE="macos-app/Sources/Resources/base-prompt.md"

echo "🔍 Checking if baseprompt version was bumped when content changed..."

# First validate current version format
bash scripts/validate-baseprompt-version.sh || exit 1

# Check if we're in a git repo and have the base ref
if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
    echo "⚠️  Warning: Base ref '$BASE_REF' not found, skipping version bump check"
    exit 0
fi

# Check if baseprompt file changed
if ! git diff --quiet "$BASE_REF" -- "$BASEPROMPT_FILE" 2>/dev/null; then
    echo "📝 Baseprompt file has changes"

    # Extract current version
    CURRENT_VERSION=$(grep -oE '<!-- version: ([0-9]+\.[0-9]+\.[0-9]+) -->' "$BASEPROMPT_FILE" | sed -E 's/<!-- version: ([0-9]+\.[0-9]+\.[0-9]+) -->/\1/')

    # Extract version from base ref
    BASE_VERSION=$(git show "$BASE_REF:$BASEPROMPT_FILE" 2>/dev/null | grep -oE '<!-- version: ([0-9]+\.[0-9]+\.[0-9]+) -->' | sed -E 's/<!-- version: ([0-9]+\.[0-9]+\.[0-9]+) -->/\1/' || echo "0.0.0")

    echo "   Base version: v$BASE_VERSION"
    echo "   Current version: v$CURRENT_VERSION"

    # Compare versions (simple string comparison works for semver)
    if [ "$CURRENT_VERSION" = "$BASE_VERSION" ]; then
        echo "❌ Error: Baseprompt content changed but version was not bumped"
        echo "   Please update the version comment on the first line of $BASEPROMPT_FILE"
        echo "   Current: <!-- version: $CURRENT_VERSION -->"
        echo "   Suggested: <!-- version: $(echo $CURRENT_VERSION | awk -F. '{print $1"."$2"."$3+1}') --> (patch bump)"
        exit 1
    fi

    echo "✅ Baseprompt version was bumped: v$BASE_VERSION → v$CURRENT_VERSION"
else
    echo "✅ Baseprompt file unchanged, no version bump required"
fi
