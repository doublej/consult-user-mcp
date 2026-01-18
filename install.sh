#!/bin/bash
set -e

APP_NAME="Consult User MCP.app"
ZIP_NAME="Consult.User.MCP.app.zip"
INSTALL_DIR="/Applications"
REPO="doublej/consult-user-mcp"

echo "Downloading latest release..."
curl -sL "https://github.com/$REPO/releases/latest/download/$ZIP_NAME" -o "/tmp/$ZIP_NAME"

echo "Extracting..."
unzip -q -o "/tmp/$ZIP_NAME" -d "/tmp"

echo "Installing to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR/$APP_NAME"
mv "/tmp/$APP_NAME" "$INSTALL_DIR/"

echo "Removing quarantine flag..."
xattr -cr "$INSTALL_DIR/$APP_NAME"

rm "/tmp/$ZIP_NAME"

MCP_PATH="$INSTALL_DIR/$APP_NAME/Contents/Resources/mcp-server/dist/index.js"

echo "Done! Add to your MCP config:"
echo ""
echo '{'
echo '  "mcpServers": {'
echo '    "consult-user-mcp": {'
echo '      "command": "node",'
echo "      \"args\": [\"$MCP_PATH\"]"
echo '    }'
echo '  }'
echo '}'
echo ""
echo "Or launch the app and use 'Install for Claude Code':"
echo "  open '/Applications/$APP_NAME'"
