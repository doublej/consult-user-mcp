#!/bin/bash
set -e

APP_NAME="Consult User MCP.app"
ZIP_NAME="Consult.User.MCP.app.zip"
INSTALL_DIR="/Applications"
REPO="doublej/consult-user-mcp"

echo "Finding latest macOS release..."
ZIP_URL=$(curl -sL "https://api.github.com/repos/$REPO/releases" \
  | python3 -c "
import json, sys
for r in json.load(sys.stdin):
    tag = r.get('tag_name', '')
    if not (tag.startswith('macos/v') or (tag.startswith('v') and len(tag) > 1 and tag[1].isdigit())):
        continue
    if r.get('draft'):
        continue
    for a in r.get('assets', []):
        if a['name'].endswith('.zip'):
            print(a['browser_download_url'])
            sys.exit(0)
print('', file=sys.stderr)
sys.exit(1)
")

if [ -z "$ZIP_URL" ]; then
  echo "Error: could not find a macOS release with a zip asset" >&2
  exit 1
fi

echo "Downloading $ZIP_URL..."
curl -sL "$ZIP_URL" -o "/tmp/$ZIP_NAME"

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
