#!/bin/sh
set -eu

swift build -c release --build-system native
APP="build/HafthiMac.app"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
cp ".build/release/HafthiMac" "$APP/Contents/MacOS/HafthiMac"
cp Info.plist "$APP/Contents/Info.plist"
if [ -f ".build/checkouts/SwiftTerm/LICENSE" ]; then
    cp ".build/checkouts/SwiftTerm/LICENSE" "$APP/Contents/Resources/SwiftTerm-LICENSE.txt"
fi
printf 'Built %s\n' "$APP"
