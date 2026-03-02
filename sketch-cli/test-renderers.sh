#!/bin/bash
# Test suite for DescriptionRenderer, AsciiRenderer, and PngRenderer
# Runs various layouts through 'describe' and 'render' commands
set -euo pipefail

CLI=".build/debug/SketchCLI"
OUT_DIR="/tmp/sketch-render-tests"
mkdir -p "$OUT_DIR"

bold="\033[1m"
dim="\033[2m"
reset="\033[0m"

run_test() {
    local name="$1"
    local json="$2"
    local slug
    slug=$(echo "$name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')

    echo -e "\n${bold}=== $name ===${reset}"

    # Summary + ASCII via describe
    echo -e "${dim}--- summary + ascii ---${reset}"
    "$CLI" describe "$json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d['summary'])
print()
print(d['ascii'])
"

    # Full render with PNG
    echo -e "${dim}--- render (with PNG) ---${reset}"
    "$CLI" render "$json" > "$OUT_DIR/${slug}.json"

    # Decode PNG to file
    python3 -c "
import json, base64, sys
d = json.load(open('$OUT_DIR/${slug}.json'))
if d.get('image'):
    png = base64.b64decode(d['image'])
    path = '$OUT_DIR/${slug}.png'
    open(path, 'wb').write(png)
    print(f'PNG saved: {path} ({len(png)} bytes)')
else:
    print('No image generated')
"
}

echo -e "${bold}Building...${reset}"
swift build 2>&1 | tail -1

# --- Test cases ---

run_test "1. Holy Grail Layout" '{
    "columns": 12, "rows": 8,
    "blocks": [
        {"label":"Header","x":0,"y":0,"w":12,"h":1},
        {"label":"Nav","x":0,"y":1,"w":2,"h":6},
        {"label":"Content","x":2,"y":1,"w":8,"h":6},
        {"label":"Sidebar","x":10,"y":1,"w":2,"h":6},
        {"label":"Footer","x":0,"y":7,"w":12,"h":1}
    ]
}'

run_test "2. Dashboard with Nested Widgets" '{
    "columns": 12, "rows": 8,
    "blocks": [
        {"label":"Header","x":0,"y":0,"w":12,"h":1},
        {"label":"Main Panel","x":0,"y":1,"w":8,"h":7},
        {"label":"Chart","x":1,"y":2,"w":3,"h":3},
        {"label":"Table","x":4,"y":2,"w":3,"h":3},
        {"label":"Stats","x":8,"y":1,"w":4,"h":3},
        {"label":"Activity","x":8,"y":4,"w":4,"h":4}
    ]
}'

run_test "3. Mobile Layout (tall narrow)" '{
    "columns": 4, "rows": 12,
    "blocks": [
        {"label":"Status Bar","x":0,"y":0,"w":4,"h":1},
        {"label":"Hero","x":0,"y":1,"w":4,"h":3},
        {"label":"CTA","x":0,"y":4,"w":4,"h":1},
        {"label":"Feed","x":0,"y":5,"w":4,"h":5},
        {"label":"Tab Bar","x":0,"y":10,"w":4,"h":1}
    ]
}'

run_test "4. Empty Grid" '{
    "columns": 6, "rows": 4,
    "blocks": []
}'

run_test "5. Single Block (full)" '{
    "columns": 6, "rows": 4,
    "blocks": [
        {"label":"Hero","x":0,"y":0,"w":6,"h":4}
    ]
}'

run_test "6. Quad Split" '{
    "columns": 8, "rows": 6,
    "blocks": [
        {"label":"Top Left","x":0,"y":0,"w":4,"h":3},
        {"label":"Top Right","x":4,"y":0,"w":4,"h":3},
        {"label":"Bottom Left","x":0,"y":3,"w":4,"h":3},
        {"label":"Bottom Right","x":4,"y":3,"w":4,"h":3}
    ]
}'

run_test "7. Complex Dashboard" '{
    "columns": 16, "rows": 10,
    "blocks": [
        {"label":"Logo","x":0,"y":0,"w":3,"h":1},
        {"label":"Search","x":3,"y":0,"w":10,"h":1},
        {"label":"User","x":13,"y":0,"w":3,"h":1},
        {"label":"Sidebar","x":0,"y":1,"w":3,"h":9},
        {"label":"KPI 1","x":3,"y":1,"w":4,"h":2},
        {"label":"KPI 2","x":7,"y":1,"w":4,"h":2},
        {"label":"KPI 3","x":11,"y":1,"w":5,"h":2},
        {"label":"Chart","x":3,"y":3,"w":8,"h":4},
        {"label":"Feed","x":11,"y":3,"w":5,"h":7},
        {"label":"Table","x":3,"y":7,"w":8,"h":3}
    ]
}'

run_test "8. Brief Detail Mode" '{
    "columns": 12, "rows": 8,
    "blocks": [
        {"label":"Header","x":0,"y":0,"w":12,"h":1},
        {"label":"Content","x":0,"y":1,"w":12,"h":7}
    ],
    "detail": "brief"
}'

echo -e "\n${bold}All tests complete.${reset}"
echo -e "PNGs saved to: ${OUT_DIR}/"
echo -e "Open all: ${dim}open ${OUT_DIR}/*.png${reset}"
