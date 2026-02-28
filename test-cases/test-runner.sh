#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CLI_PATH="$PROJECT_ROOT/dialog-cli/.build/release/DialogCLI"
CASES_DIR="$SCRIPT_DIR/cases"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SCREENSHOT_DIR="$SCRIPT_DIR/screenshots/$TIMESTAMP"

# Fast mode: minimal delays for rapid iteration
FAST="${FAST:-}"

# Render delay in seconds (increase if dialogs aren't captured)
if [ -n "$FAST" ]; then
    RENDER_DELAY="${RENDER_DELAY:-0.4}"
else
    RENDER_DELAY="${RENDER_DELAY:-1.2}"
fi

# Theme from environment (default: none, uses system default)
THEME="${DIALOG_THEME:-}"

# Debug mode
DEBUG="${DEBUG:-}"

# OCR verification: margin strip width in pixels (edges checked for text bleed)
MARGIN_STRIP_PX="${MARGIN_STRIP_PX:-40}"

# Verification counters
VERIFY_TOTAL=0
VERIFY_CONTENT_FAILS=0
VERIFY_MARGIN_FAILS=0

echo "=== Dialog Visual Test Runner ==="
echo "Timestamp: $TIMESTAMP"
[ -n "$THEME" ] && echo "Theme: $THEME"
[ -n "$FAST" ] && echo "Mode: fast (render delay: ${RENDER_DELAY}s)"
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

# Dismiss dialog by killing its process (no keyboard simulation needed)
dismiss_dialog() {
    local pid="${1:-}"
    [ -z "$pid" ] && return 0
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
}

# Map directory name to CLI command
get_command() {
    local dir="$1"
    case "$dir" in
        confirm) echo "confirm" ;;
        choose) echo "choose" ;;
        text-input) echo "textInput" ;;
        questions) echo "questions" ;;
        notify) echo "notify" ;;
        tweak) echo "tweak" ;;
        *) echo "" ;;
    esac
}

# Extract expected content words from test case JSON
# Only checks text visible in the initial viewport:
#   - title + body (always visible)
#   - confirm: button labels
#   - choose: first 5 choices + descriptions (viewport limit)
#   - questions: all question headers + first question's options
#   - tweak: all parameter labels
extract_expected_words() {
    local json_file="$1"
    local command="$2"
    local text=""
    text+=" $(jq -r '.body // empty' "$json_file")"
    text+=" $(jq -r '.title // empty' "$json_file")"
    case "$command" in
        confirm)
            # Only check button labels short enough to not be truncated
            local confirm_label cancel_label
            confirm_label=$(jq -r '.confirmLabel // empty' "$json_file")
            cancel_label=$(jq -r '.cancelLabel // empty' "$json_file")
            [ ${#confirm_label} -le 25 ] && text+=" $confirm_label"
            [ ${#cancel_label} -le 25 ] && text+=" $cancel_label"
            ;;
        choose)
            text+=" $(jq -r 'try ([.choices[]][0:5][])' "$json_file")"
            text+=" $(jq -r 'try ([.descriptions[]][0:5][])' "$json_file")"
            ;;
        questions)
            local mode
            mode=$(jq -r '.mode // "accordion"' "$json_file")
            if [ "$mode" = "wizard" ]; then
                # Wizard: only first question page visible
                text+=" $(jq -r 'try (.questions[0].question)' "$json_file")"
            else
                # Accordion: all question headers visible (collapsed)
                text+=" $(jq -r 'try (.questions[].question)' "$json_file")"
            fi
            text+=" $(jq -r 'try (.questions[0].options[].label // .questions[0].options[])' "$json_file")"
            text+=" $(jq -r 'try (.questions[0].options[].description // empty)' "$json_file")"
            ;;
        tweak)
            text+=" $(jq -r 'try ([.parameters[]][0:6][].label)' "$json_file")"
            ;;
    esac
    # Strip markdown: extract link text (discard URLs), remove syntax chars
    echo "$text" \
        | sed -E 's/\[([^]]*)\]\([^)]*\)/\1/g' \
        | sed -E 's|https?://[^ ]*||g' \
        | sed 's/[*`#>{}|\\~]//g' \
        | tr '[:upper:]' '[:lower:]' \
        | tr -cs '[:alnum:]' '\n' \
        | awk 'length >= 4' \
        | sort -u
}

# Verify screenshot content and margins via single OCR pass
# Sets _VERIFY_RESULT and updates global counters
verify_screenshot() {
    local image="$1"
    local json_file="$2"
    local command="$3"

    if ! command -v tesseract &>/dev/null; then
        _VERIFY_RESULT="skip:no-tesseract"
        return
    fi

    local img_width img_height
    img_width=$(sips -g pixelWidth "$image" 2>/dev/null | awk '/pixelWidth/{print $2}')
    img_height=$(sips -g pixelHeight "$image" 2>/dev/null | awk '/pixelHeight/{print $2}')
    if [ -z "$img_width" ] || [ -z "$img_height" ]; then
        _VERIFY_RESULT="skip:no-dims"
        return
    fi

    # Crop edge strips and centre for visual inspection
    local base="${image%.png}"
    local center_width=$((img_width - 2 * MARGIN_STRIP_PX))
    local right_x=$((img_width - MARGIN_STRIP_PX))
    magick "$image" -crop "${MARGIN_STRIP_PX}x${img_height}+0+0" +repage "${base}_edge-left.png" 2>/dev/null
    magick "$image" -crop "${MARGIN_STRIP_PX}x${img_height}+${right_x}+0" +repage "${base}_edge-right.png" 2>/dev/null
    magick "$image" -crop "${center_width}x${img_height}+${MARGIN_STRIP_PX}+0" +repage "${base}_cropped.png" 2>/dev/null

    # Margin check: OCR on original image (bounding boxes in original pixel coords)
    local tsv
    tsv=$(tesseract "$image" stdout tsv 2>/dev/null)

    # Content check: two OCR passes merged for maximum detection
    # Pass 1: grayscale + threshold + PSM 11 (sparse text) for highlighted/selected rows
    local upscaled="${base}_ocr.png"
    magick "$image" -colorspace Gray -threshold 55% -negate -resize 300% -density 300 "$upscaled" 2>/dev/null
    local ocr_tsv
    ocr_tsv=$(tesseract "$upscaled" stdout --dpi 300 --psm 11 tsv 2>/dev/null)
    # Pass 2: color upscale + PSM 6 (block text) for normal text
    local upscaled_color="${base}_ocr2.png"
    magick "$image" -resize 300% -density 300 "$upscaled_color" 2>/dev/null
    local ocr_tsv2
    ocr_tsv2=$(tesseract "$upscaled_color" stdout --dpi 300 --psm 6 tsv 2>/dev/null)
    rm -f "$upscaled" "$upscaled_color"
    local ocr_text
    ocr_text=$({ echo "$ocr_tsv"; echo "$ocr_tsv2"; } | awk -F'\t' 'NR>1{w=$12; gsub(/^ +| +$/,"",w); if(w!="") print tolower(w)}' | tr '_' '\n' | sort -u)
    local expected
    expected=$(extract_expected_words "$json_file" "$command")

    local total=0 found=0 missing=""
    while IFS= read -r word; do
        [ -z "$word" ] && continue
        ((total++)) || true
        if echo "$ocr_text" | grep -qw "$word"; then
            ((found++)) || true
        else
            missing+="${missing:+,}$word"
        fi
    done <<< "$expected"

    # --- Margin check: any word bounding boxes within edge strips? ---
    # TSV level 5 = word, cols: left=$7, width=$9, text=$12
    local margin_result
    margin_result=$(echo "$tsv" | awk -F'\t' -v strip="$MARGIN_STRIP_PX" -v iw="$img_width" '
        NR>1 && $1=="5" && $12!="" && $12!=" " {
            left=int($7); w=int($9)
            if (left < strip) has_left=1
            if (left+w > iw-strip) has_right=1
        }
        END {
            if (has_left && has_right) print "left+right"
            else if (has_left) print "left"
            else if (has_right) print "right"
            else print "ok"
        }
    ')

    # Update global counters
    ((VERIFY_TOTAL++)) || true
    if [ "$total" -gt 0 ] && [ "$found" -lt "$total" ]; then
        ((VERIFY_CONTENT_FAILS++)) || true
    fi
    [ "$margin_result" != "ok" ] && ((VERIFY_MARGIN_FAILS++)) || true

    if [ -n "$missing" ]; then
        _VERIFY_RESULT="$found/$total words MISSING:[$missing] | margins: $margin_result"
    else
        _VERIFY_RESULT="$found/$total words | margins: $margin_result"
    fi
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

    # Optional pane activation for screenshoting expanded toolbar state
    local test_pane
    test_pane=$(echo "$json" | jq -r '.testPane // empty')

    # Copy companion setup files (e.g. .css for tweak test cases)
    local setup_file="${json_file%.json}.css"
    if [ -f "$setup_file" ]; then
        cp "$setup_file" /tmp/tweak-test.css
    fi

    # Build environment
    local env_vars=()
    [ -n "$THEME" ] && env_vars+=("DIALOG_THEME=$THEME")
    [ -n "$project_path" ] && env_vars+=("MCP_PROJECT_PATH=$project_path")
    [ -n "$test_pane" ] && env_vars+=("DIALOG_TEST_PANE=$test_pane")

    # Launch dialog in background
    if [ ${#env_vars[@]} -gt 0 ]; then
        env "${env_vars[@]}" "$CLI_PATH" "$command" "$json" > /dev/null 2>&1 &
    else
        "$CLI_PATH" "$command" "$json" > /dev/null 2>&1 &
    fi
    local pid=$!

    # Wait for render (pane auto-opens via DIALOG_TEST_PANE env var)
    if [ -n "$test_pane" ]; then
        # Extra time for pane animation to settle
        sleep "$(echo "$RENDER_DELAY + 0.35" | bc)"
    else
        sleep "$RENDER_DELAY"
    fi

    # Capture frontmost window (retry once if first attempt fails)
    if ! capture_frontmost_window "$output_path"; then
        sleep 0.5
        capture_frontmost_window "$output_path" || true
    fi

    # Dismiss dialog by killing the process directly
    dismiss_dialog "$pid"

    if [ -f "$output_path" ] && [ -s "$output_path" ]; then
        verify_screenshot "$output_path" "$json_file" "$command"
        echo "OK ($_VERIFY_RESULT)"
        return 0
    else
        echo "FAILED (no screenshot)"
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
            [ -z "$FAST" ] && sleep 0.3
        done
        echo ""
    done

    echo "=== Summary ==="
    echo "Captured: $captured / $total"
    if [ "$VERIFY_TOTAL" -gt 0 ]; then
        echo "OCR verified: $VERIFY_TOTAL (content fails: $VERIFY_CONTENT_FAILS, margin fails: $VERIFY_MARGIN_FAILS)"
    fi
    echo ""
    echo "Screenshots: $SCREENSHOT_DIR"
    echo ""
    echo "Review:"
    echo "  open \"$SCREENSHOT_DIR\""
    echo "  See: $SCRIPT_DIR/verify-checklist.md"
    echo ""
    echo "Themes: DIALOG_THEME=sunset|midnight $0"
    echo "Fast:   FAST=1 $0"
    echo "Debug:  DEBUG=1 $0"
}

main "$@"
