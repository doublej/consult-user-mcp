#!/bin/bash
set -e

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
APP_NAME="Consult User MCP"
APP_PATH="/Applications/${APP_NAME}.app"

# Read version from VERSION files
APP_VERSION=$(cat "$ROOT/macos-app/VERSION" | tr -d '[:space:]')
CLI_VERSION=$(cat "$ROOT/dialog-cli/VERSION" | tr -d '[:space:]')

echo "Building ${APP_NAME} v${APP_VERSION}..."

# 1. Build dialog-cli
echo "  Building dialog-cli..."
cd "$ROOT/dialog-cli"
swift build -c release

# 2. Build mcp-server
echo "  Building mcp-server..."
cd "$ROOT/mcp-server"
bun run build

# 3. Build macOS app
echo "  Building macOS app..."
cd "$ROOT/macos-app"
swift build -c release

# 4. Create app bundle structure
echo "  Creating app bundle..."
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources/dialog-cli"
mkdir -p "$APP_PATH/Contents/Resources/mcp-server/dist"

# 5. Copy executable
cp "$ROOT/macos-app/.build/release/ConsultUserMCP" "$APP_PATH/Contents/MacOS/"

# 6. Copy dialog-cli binary and VERSION
cp "$ROOT/dialog-cli/.build/release/DialogCLI" "$APP_PATH/Contents/Resources/dialog-cli/dialog-cli"
cp "$ROOT/dialog-cli/VERSION" "$APP_PATH/Contents/Resources/dialog-cli/VERSION"

# 7. Copy mcp-server dist and dependencies
cp -r "$ROOT/mcp-server/dist/"* "$APP_PATH/Contents/Resources/mcp-server/dist/"
cp "$ROOT/mcp-server/package.json" "$APP_PATH/Contents/Resources/mcp-server/"

# Install production dependencies
echo "  Installing node dependencies..."
cd "$APP_PATH/Contents/Resources/mcp-server"
bun install --production

# 8. Copy resources (icon, update script)
cp "$ROOT/macos-app/Sources/Resources/AppIcon.icns" "$APP_PATH/Contents/Resources/"
cp "$ROOT/macos-app/Sources/Resources/update.sh" "$APP_PATH/Contents/Resources/"
chmod +x "$APP_PATH/Contents/Resources/update.sh"

# 9. Create Info.plist (with dynamic version)
cat > "$APP_PATH/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ConsultUserMCP</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.doublej.ConsultUserMCP</string>
    <key>CFBundleName</key>
    <string>Consult User MCP</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "Done! App installed at: $APP_PATH"
