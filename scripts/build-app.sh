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
cp "$ROOT/macos-app/VERSION" "$APP_PATH/Contents/Resources/mcp-server/VERSION"

# Install production dependencies
echo "  Installing node dependencies..."
cd "$APP_PATH/Contents/Resources/mcp-server"
bun install --production

# 8. Generate AppIcon.icns from appiconset PNGs if missing
ICNS_PATH="$ROOT/macos-app/Sources/Resources/AppIcon.icns"
if [ ! -f "$ICNS_PATH" ]; then
    echo "  Generating AppIcon.icns..."
    ICONSET_DIR=$(mktemp -d)/AppIcon.iconset
    mkdir -p "$ICONSET_DIR"
    APPICONSET="$ROOT/macos-app/Sources/Resources/Assets.xcassets/AppIcon.appiconset"
    cp "$APPICONSET/icon_16x16.png" "$ICONSET_DIR/icon_16x16.png"
    cp "$APPICONSET/icon_32x32.png" "$ICONSET_DIR/icon_16x16@2x.png"
    cp "$APPICONSET/icon_32x32.png" "$ICONSET_DIR/icon_32x32.png"
    cp "$APPICONSET/icon_64x64.png" "$ICONSET_DIR/icon_32x32@2x.png"
    cp "$APPICONSET/icon_128x128.png" "$ICONSET_DIR/icon_128x128.png"
    cp "$APPICONSET/icon_256x256.png" "$ICONSET_DIR/icon_128x128@2x.png"
    cp "$APPICONSET/icon_256x256.png" "$ICONSET_DIR/icon_256x256.png"
    cp "$APPICONSET/icon_512x512.png" "$ICONSET_DIR/icon_256x256@2x.png"
    cp "$APPICONSET/icon_512x512.png" "$ICONSET_DIR/icon_512x512.png"
    cp "$APPICONSET/icon_1024x1024.png" "$ICONSET_DIR/icon_512x512@2x.png"
    iconutil -c icns -o "$ICNS_PATH" "$ICONSET_DIR"
    rm -rf "$(dirname "$ICONSET_DIR")"
fi

# Copy resources (icon, update script, logos)
cp "$ICNS_PATH" "$APP_PATH/Contents/Resources/"
cp "$ROOT/macos-app/Sources/Resources/update.sh" "$APP_PATH/Contents/Resources/"
cp "$ROOT/macos-app/Sources/Resources/claude-logo.png" "$APP_PATH/Contents/Resources/"
cp "$ROOT/macos-app/Sources/Resources/openai-logo.png" "$APP_PATH/Contents/Resources/"
cp "$ROOT/macos-app/Sources/Resources/base-prompt.md" "$APP_PATH/Contents/Resources/"
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
