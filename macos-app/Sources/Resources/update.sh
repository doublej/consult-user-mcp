#!/bin/bash
# Update script for Consult User MCP
# Runs after app quits to replace itself with new version

set -e

APP_NAME="Consult User MCP"
APP_PATH="/Applications/${APP_NAME}.app"
BACKUP_PATH="/tmp/${APP_NAME}_backup.app"
ZIP_PATH="$1"
PARENT_PID="$2"

log() {
    echo "[update] $1"
}

cleanup() {
    rm -rf "$BACKUP_PATH"
    rm -f "$ZIP_PATH"
}

restore_backup() {
    log "Restoring backup..."
    rm -rf "$APP_PATH"
    mv "$BACKUP_PATH" "$APP_PATH"
}

if [ -z "$ZIP_PATH" ] || [ -z "$PARENT_PID" ]; then
    echo "Usage: $0 <zip_path> <parent_pid>"
    exit 1
fi

log "Waiting for app (PID $PARENT_PID) to quit..."
while kill -0 "$PARENT_PID" 2>/dev/null; do
    sleep 0.5
done
log "App has quit"

# Backup current app
log "Backing up current app..."
rm -rf "$BACKUP_PATH"
cp -R "$APP_PATH" "$BACKUP_PATH"

# Extract and replace
log "Extracting update from $ZIP_PATH..."
TEMP_DIR=$(mktemp -d)
unzip -q "$ZIP_PATH" -d "$TEMP_DIR"

# Find the .app in extracted contents
EXTRACTED_APP=$(find "$TEMP_DIR" -maxdepth 2 -name "*.app" -type d | head -1)
if [ -z "$EXTRACTED_APP" ]; then
    log "ERROR: No .app found in zip"
    cleanup
    exit 1
fi

log "Installing update..."
rm -rf "$APP_PATH"
mv "$EXTRACTED_APP" "$APP_PATH"

# Remove quarantine flag
log "Removing quarantine flag..."
xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

# Verify the new app exists
if [ ! -d "$APP_PATH" ]; then
    log "ERROR: Installation failed"
    restore_backup
    cleanup
    exit 1
fi

# Cleanup
log "Cleaning up..."
rm -rf "$TEMP_DIR"
cleanup

# Relaunch
log "Relaunching app..."
open "$APP_PATH"

log "Update complete!"
