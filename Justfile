# Development recipes for consult-user-mcp

root := justfile_directory()

# Build and install to /Applications (dev workflow)
dev:
    bun run dev

# Test the tweak pane with a local HTML page (live-reloading)
tweak-test:
    #!/usr/bin/env bash
    set -euo pipefail
    ROOT="{{root}}"
    SRC="$ROOT/test-cases/cases/tweak/tweak-test-page.html"
    DEST="/tmp/tweak-test-page.html"
    CLI="$ROOT/dialog-cli/.build/debug/DialogCLI"
    PORT=8787

    if [ ! -f "$CLI" ]; then
        echo "Building dialog-cli..."
        cd "$ROOT/dialog-cli" && swift build
    fi

    # Copy and append live-reload script (polls Last-Modified header)
    cp "$SRC" "$DEST"
    cat >> "$DEST" << 'RELOAD'
    <script>
    let lm = '';
    setInterval(async () => {
        try {
            const r = await fetch(location.href, {method: 'HEAD', cache: 'no-store'});
            const m = r.headers.get('last-modified');
            if (lm && m !== lm) location.reload();
            lm = m;
        } catch {}
    }, 300);
    </script>
    RELOAD

    # Serve via HTTP (so fetch works) and clean up on exit
    python3 -m http.server "$PORT" --directory /tmp > /dev/null 2>&1 &
    SERVER_PID=$!
    trap "kill $SERVER_PID 2>/dev/null" EXIT

    echo "Live preview: http://localhost:$PORT/tweak-test-page.html"
    open "http://localhost:$PORT/tweak-test-page.html"
    sleep 0.5

    TWEAK_JSON='{
        "body": "Adjust typography and layout values",
        "parameters": [
            {"id":"h1-size","label":"font-size","element":"H1","file":"'"$DEST"'","line":17,"column":20,"expectedText":"2.5rem","current":2.5,"min":1.0,"max":5.0,"step":0.1,"unit":"rem"},
            {"id":"h1-spacing","label":"letter-spacing","element":"H1","file":"'"$DEST"'","line":18,"column":25,"expectedText":"-0.02em","current":-0.02,"min":-0.1,"max":0.1,"step":0.005,"unit":"em"},
            {"id":"h1-leading","label":"line-height","element":"H1","file":"'"$DEST"'","line":19,"column":22,"expectedText":"1.2","current":1.2,"min":0.8,"max":2.0,"step":0.05},
            {"id":"p-size","label":"font-size","element":"p","file":"'"$DEST"'","line":23,"column":20,"expectedText":"1.1rem","current":1.1,"min":0.8,"max":2.0,"step":0.05,"unit":"rem"},
            {"id":"p-spacing","label":"letter-spacing","element":"p","file":"'"$DEST"'","line":24,"column":25,"expectedText":"0.01em","current":0.01,"min":-0.05,"max":0.1,"step":0.005,"unit":"em"},
            {"id":"p-leading","label":"line-height","element":"p","file":"'"$DEST"'","line":25,"column":22,"expectedText":"1.6","current":1.6,"min":1.0,"max":2.5,"step":0.05},
            {"id":"col-gap","label":"gap","element":".columns","file":"'"$DEST"'","line":35,"column":14,"expectedText":"24px","current":24,"min":0,"max":64,"step":1,"unit":"px"},
            {"id":"divider-width","label":"column width","element":".divider","file":"'"$DEST"'","line":34,"column":36,"expectedText":"1px","current":1,"min":0,"max":8,"step":1,"unit":"px"},
            {"id":"divider-opacity","label":"opacity","element":".divider","file":"'"$DEST"'","line":40,"column":18,"expectedText":"0.6","current":0.6,"min":0,"max":1,"step":0.05},
            {"id":"card-radius","label":"border-radius","element":".card","file":"'"$DEST"'","line":45,"column":24,"expectedText":"12px","current":12,"min":0,"max":32,"step":1,"unit":"px"},
            {"id":"card-padding","label":"padding","element":".card","file":"'"$DEST"'","line":46,"column":18,"expectedText":"20px","current":20,"min":4,"max":48,"step":1,"unit":"px"},
            {"id":"card-border","label":"border-width","element":".card","file":"'"$DEST"'","line":47,"column":17,"expectedText":"1px","current":1,"min":0,"max":4,"step":1,"unit":"px"}
        ],
        "position": "right"
    }'

    echo ""
    echo "Sent to MCP:"
    echo "$TWEAK_JSON" | python3 -m json.tool
    echo ""

    RESULT=$("$CLI" tweak "$TWEAK_JSON")

    echo "Response:"
    echo "$RESULT" | python3 -m json.tool 2>/dev/null || echo "$RESULT"
    echo ""
    echo "Done."
