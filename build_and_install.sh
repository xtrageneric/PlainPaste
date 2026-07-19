#!/bin/bash
# Rebuilds PlainPaste and installs it to /Applications, replacing any running copy.
# Run this any time after editing the Swift files: ./build_and_install.sh

set -e
cd "$(dirname "$0")"

XCODEBUILD="/Applications/Xcode-beta.app/Contents/Developer/usr/bin/xcodebuild"
if [ ! -x "$XCODEBUILD" ]; then
    # Fall back to whatever Xcode is currently selected, in case Xcode-beta
    # has since been replaced by a non-beta release.
    XCODEBUILD="xcodebuild"
fi

echo "Building..."
"$XCODEBUILD" -scheme PlainPaste -configuration Debug build

DERIVED_DATA_APP=$(find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -name "PlainPaste-*" -print -quit)/Build/Products/Debug/PlainPaste.app

echo "Installing to /Applications..."
killall PlainPaste 2>/dev/null || true
sleep 1
rm -rf /Applications/PlainPaste.app
cp -R "$DERIVED_DATA_APP" /Applications/PlainPaste.app

echo "Launching..."
open /Applications/PlainPaste.app

echo "Done. PlainPaste rebuilt and relaunched from /Applications/PlainPaste.app"
