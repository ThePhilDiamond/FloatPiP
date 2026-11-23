#!/bin/sh
# Builds build/FloatPiP.app: the release build, its Info.plist and icon, ad-hoc signed. See BUILDING.md.
set -eu
cd "$(dirname "$0")/.."
swift build -c release
APP=build/FloatPiP.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/FloatPiP "$APP/Contents/MacOS/FloatPiP"
cp Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp Resources/MenuIcon.png Resources/MenuIcon@2x.png "$APP/Contents/Resources/"
codesign --force --sign - "$APP"     # ad-hoc: not notarized (RELEASING.md)
echo "Built $APP"
