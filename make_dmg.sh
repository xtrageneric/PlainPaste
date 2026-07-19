#!/bin/bash
# Builds PlainPaste and packages it into a polished, drag-to-install DMG
# with a custom branded background image. Run this instead of manually
# zipping/copying when cutting a new release.
#
# Output: PlainPaste.dmg in this folder — attach it to a GitHub Release
# (always with that exact filename, so the README's "latest release"
# download link keeps working).

set -e
cd "$(dirname "$0")"

APP_NAME="PlainPaste"
VOLUME_NAME="PlainPaste"
DMG_TMP="./dmg_tmp.dmg"
DMG_FINAL="./PlainPaste.dmg"
STAGING="./dmg_staging"
BACKGROUND_IMG="$(pwd)/dmg_assets/background.png"
MOUNT_DIR="/Volumes/$VOLUME_NAME"

XCODEBUILD="/Applications/Xcode-beta.app/Contents/Developer/usr/bin/xcodebuild"
if [ ! -x "$XCODEBUILD" ]; then
    XCODEBUILD="xcodebuild"
fi

echo "Building..."
"$XCODEBUILD" -scheme PlainPaste -configuration Debug build

DERIVED_DATA_APP=$(find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -name "PlainPaste-*" -print -quit)/Build/Products/Debug/PlainPaste.app

echo "Staging..."
# Unmount any stale leftover volume from a previous failed run
if [ -d "$MOUNT_DIR" ]; then
    hdiutil detach "$MOUNT_DIR" -force 2>/dev/null || true
fi
rm -rf "$STAGING" "$DMG_TMP" "$DMG_FINAL"
mkdir -p "$STAGING/.background"
cp -R "$DERIVED_DATA_APP" "$STAGING/$APP_NAME.app"
ln -s /Applications "$STAGING/Applications"
cp "$BACKGROUND_IMG" "$STAGING/.background/background.png"

echo "Creating temporary disk image..."
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$STAGING" -ov -format UDRW -fs HFS+ "$DMG_TMP"

echo "Mounting..."
hdiutil attach "$DMG_TMP" -mountpoint "$MOUNT_DIR"
sleep 2

echo "Styling the Finder window (this may prompt for Automation permission the first time)..."
osascript <<OSASCRIPT_EOF
tell application "Finder"
    repeat with w in (every window whose name is "$VOLUME_NAME")
        close w
    end repeat
    tell disk "$VOLUME_NAME"
        open
        close
        open
        delay 1
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 760, 588}
        close
        open
        delay 1
        set the bounds of container window to {100, 100, 760, 588}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set background picture of viewOptions to file ".background:background.png"
        set position of item "$APP_NAME.app" to {165, 210}
        set position of item "Applications" to {495, 210}
        update without registering applications
        delay 1
        close
    end tell
end tell
OSASCRIPT_EOF

sync
sleep 1

echo "Unmounting..."
hdiutil detach "$MOUNT_DIR"

echo "Converting to final compressed DMG..."
hdiutil convert "$DMG_TMP" -format UDZO -o "$DMG_FINAL"

rm -rf "$STAGING" "$DMG_TMP"

echo "Done: $DMG_FINAL"
