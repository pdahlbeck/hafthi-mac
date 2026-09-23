#!/bin/sh
set -eu

swift build -c release
APP="build/HafthiMac.app"
mkdir -p "$APP/Contents/MacOS"
cp ".build/release/HafthiMac" "$APP/Contents/MacOS/HafthiMac"
cp Info.plist "$APP/Contents/Info.plist"
printf 'Built %s\n' "$APP"
