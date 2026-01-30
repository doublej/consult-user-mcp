#!/bin/bash
set -e

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
APP_PATH="/Applications/Consult User MCP.app"

# Build all components
echo "Building dialog-cli..."
cd "$ROOT/dialog-cli" && swift build

echo "Building mcp-server..."
cd "$ROOT/mcp-server" && bun run build:ts

echo "Building macOS app..."
cd "$ROOT/macos-app" && swift build

# Copy binaries into installed app
if [ -d "$APP_PATH" ]; then
    echo "Installing to $APP_PATH..."
    cp "$ROOT/macos-app/.build/debug/ConsultUserMCP" "$APP_PATH/Contents/MacOS/ConsultUserMCP"
    cp "$ROOT/dialog-cli/.build/debug/DialogCLI" "$APP_PATH/Contents/Resources/dialog-cli/dialog-cli"
    cp -r "$ROOT/mcp-server/dist/"* "$APP_PATH/Contents/Resources/mcp-server/dist/"
    echo "Done. Restart the app to pick up changes."
else
    echo "App not found at $APP_PATH — run 'bun run build:bundle' first to create it."
    exit 1
fi
