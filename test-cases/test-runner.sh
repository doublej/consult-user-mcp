#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CLI_PATH="$PROJECT_ROOT/dialog-cli/.build/release/DialogCLI"
CASES_DIR="$SCRIPT_DIR/cases"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SCREENSHOT_DIR="$SCRIPT_DIR/screenshots/$TIMESTAMP"

# Render delay in seconds (increase if dialogs aren't captured)
RENDER_DELAY="${RENDER_DELAY:-1.2}"

# Theme from environment (default: none, uses system default)
THEME="${DIALOG_THEME:-}"

# Debug mode
DEBUG="${DEBUG:-}"

echo "=== Dialog Visual Test Runner ==="
echo "Timestamp: $TIMESTAMP"
[ -n "$THEME" ] && echo "Theme: $THEME"
echo ""

# Build CLI if needed
build_cli() {
    if [ ! -f "$CLI_PATH" ]; then
        echo "Building DialogCLI..."
        cd "$PROJECT_ROOT/dialog-cli"
        swift build -c release
        cd - > /dev/null
    fi
}

# Capture DialogCLI window using CoreGraphics window ID
capture_frontmost_window() {
    local output_path="$1"

    # Get DialogCLI window ID using Swift
    local window_id
    if [ -n "$DEBUG" ]; then
        window_id=$(swift "$SCRIPT_DIR/capture-dialog.swift" 2>&1)
        echo "    [debug] window lookup: $window_id" >&2
    else
        window_id=$(swift "$SCRIPT_DIR/capture-dialog.swift" 2>/dev/null)
    fi

    # Extract just the number (first line that's a number)
    window_id=$(echo "$window_id" | grep -E '^[0-9]+$' | head -1)

    if [ -n "$window_id" ]; then
        [ -n "$DEBUG" ] && echo "    [debug] capturing window $window_id" >&2
        screencapture -o -l "$window_id" "$output_path" 2>/dev/null
    else
        [ -n "$DEBUG" ] && echo "    [debug] no window found, skipping capture" >&2
        return 1
    fi
}

# Dismiss dialog with Escape key (works for all dialog types)
dismiss_dialog() {
    osascript -e 'tell application "System Events" to key code 53' 2>/dev/null || true
}

# Map directory name to CLI command
get_command() {
    local dir="$1"
    case "$dir" in
        confirm) echo "confirm" ;;
        choose) echo "choose" ;;
        text-input) echo "textInput" ;;
        questions) echo "questions" ;;
        *) echo "" ;;
    esac
}

# Run a single test case
run_test_case() {
    local json_file="$1"
    local command="$2"
    local case_name
    case_name=$(basename "$json_file" .json)
    local category
    category=$(basename "$(dirname "$json_file")")
    local output_name="${category}_${case_name}.png"
    local output_path="$SCREENSHOT_DIR/$output_name"

    echo -n "  $case_name ... "

    # Read JSON from file
    local json
    json=$(cat "$json_file")

    # Extract projectPath from JSON (if present)
    local project_path
    project_path=$(echo "$json" | jq -r '.projectPath // empty')

    # Build environment
    local env_vars=()
    [ -n "$THEME" ] && env_vars+=("DIALOG_THEME=$THEME")
    [ -n "$project_path" ] && env_vars+=("MCP_PROJECT_PATH=$project_path")

    # Launch dialog in background
    if [ ${#env_vars[@]} -gt 0 ]; then
        env "${env_vars[@]}" "$CLI_PATH" "$command" "$json" > /dev/null 2>&1 &
    else
        "$CLI_PATH" "$command" "$json" > /dev/null 2>&1 &
    fi
    local pid=$!

    # Wait for render
    sleep "$RENDER_DELAY"

    # Capture frontmost window (dialog should be frontmost)
    capture_frontmost_window "$output_path"

    # Dismiss dialog
    dismiss_dialog

    # Wait for dialog process to exit
    wait $pid 2>/dev/null || true

    if [ -f "$output_path" ] && [ -s "$output_path" ]; then
        echo "OK"
        return 0
    else
        echo "FAILED"
        return 1
    fi
}

# Main execution
main() {
    build_cli

    mkdir -p "$SCREENSHOT_DIR"
    echo "Output: $SCREENSHOT_DIR"
    echo ""

    local total=0
    local captured=0

    # Process each category
    for category_dir in "$CASES_DIR"/*/; do
        [ -d "$category_dir" ] || continue

        local category
        category=$(basename "$category_dir")
        local command
        command=$(get_command "$category")

        if [ -z "$command" ]; then
            echo "Warning: Unknown category '$category', skipping"
            continue
        fi

        echo "[$category]"

        # Process each test case
        for json_file in "$category_dir"*.json; do
            [ -f "$json_file" ] || continue
            ((total++)) || true

            if run_test_case "$json_file" "$command"; then
                ((captured++)) || true
            fi

            # Brief pause between tests
            sleep 0.3
        done
        echo ""
    done

    echo "=== Summary ==="
    echo "Captured: $captured / $total"
    echo ""
    echo "Screenshots: $SCREENSHOT_DIR"
    echo ""
    echo "Review:"
    echo "  open \"$SCREENSHOT_DIR\""
    echo "  See: $SCRIPT_DIR/verify-checklist.md"
    echo ""
    echo "Themes: DIALOG_THEME=sunset|midnight $0"
    echo "Debug:  DEBUG=1 $0"
}

main "$@"
