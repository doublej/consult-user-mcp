#!/usr/bin/env bash
set -e

# The user's global ~/.claude/CLAUDE.md records the bundled
# base-prompt.md path as an HTML-comment marker. The actual guide
# content is delivered per-session by the MCP server's protocol
# `instructions` field — the marker must NOT be an @-import (which
# would expand the file inline and double up the prompt).
GLOBAL_CLAUDE_MD="$HOME/.claude/CLAUDE.md"
EXPECTED_MARKER="<!-- consult-user-mcp-baseprompt: /Applications/Consult User MCP.app/Contents/Resources/base-prompt.md -->"

echo "🔍 Validating baseprompt marker in $GLOBAL_CLAUDE_MD..."

if [ ! -f "$GLOBAL_CLAUDE_MD" ]; then
    if [ -n "$CI" ]; then
        echo "⏭️  Skipping: $GLOBAL_CLAUDE_MD not found in CI (this file is developer-machine-only)"
        exit 0
    fi
    echo "❌ Error: $GLOBAL_CLAUDE_MD not found"
    exit 1
fi

if ! grep -Fq "$EXPECTED_MARKER" "$GLOBAL_CLAUDE_MD"; then
    echo "❌ Error: baseprompt marker not found"
    echo "   Expected line: $EXPECTED_MARKER"
    echo "   Add it to $GLOBAL_CLAUDE_MD."
    exit 1
fi

if grep -Fq "@/Applications/Consult User MCP.app/Contents/Resources/base-prompt.md" "$GLOBAL_CLAUDE_MD"; then
    echo "❌ Error: found an @-import for base-prompt.md"
    echo "   That expands the file inline. Use the HTML-comment marker instead."
    exit 1
fi

echo "✅ Marker present, no @-import: $EXPECTED_MARKER"
