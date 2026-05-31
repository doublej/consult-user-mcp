#!/usr/bin/env bash
set -e

# The user's global ~/.claude/CLAUDE.md @-imports the bundled
# base-prompt.md from the installed .app, instead of embedding the
# guide inline. This check just confirms that import is still there.
GLOBAL_CLAUDE_MD="$HOME/.claude/CLAUDE.md"
EXPECTED_IMPORT="@/Applications/Consult User MCP.app/Contents/Resources/base-prompt.md"

echo "🔍 Validating baseprompt reference in $GLOBAL_CLAUDE_MD..."

if [ ! -f "$GLOBAL_CLAUDE_MD" ]; then
    echo "❌ Error: $GLOBAL_CLAUDE_MD not found"
    exit 1
fi

if ! grep -Fq "$EXPECTED_IMPORT" "$GLOBAL_CLAUDE_MD"; then
    echo "❌ Error: baseprompt @-import not found"
    echo "   Expected line: $EXPECTED_IMPORT"
    echo "   Add it to $GLOBAL_CLAUDE_MD so Claude Code loads the guide."
    exit 1
fi

echo "✅ Reference present: $EXPECTED_IMPORT"
