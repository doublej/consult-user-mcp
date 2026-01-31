#!/bin/bash
# Validate that file monitors don't use DispatchSource (which breaks on atomic writes).
# All file monitoring should use polling via Timer + modification date checks.

set -euo pipefail

SOURCES_DIR="macos-app/Sources"

if grep -rl 'makeFileSystemObjectSource' "$SOURCES_DIR" 2>/dev/null; then
    echo "ERROR: Found DispatchSource file monitors (break on atomic writes)."
    echo "Use Timer-based polling with modification date checks instead."
    exit 1
fi

echo "No DispatchSource file monitors found (atomic-write safe)."
