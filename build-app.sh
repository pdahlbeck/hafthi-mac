#!/bin/sh
set -eu

swift build -c release --build-system native
APP="build/Hafþi.app"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources" "$APP/Contents/Resources/bin"
cp ".build/release/HafthiMac" "$APP/Contents/MacOS/Hafthi"
cp Info.plist "$APP/Contents/Info.plist"
cp Sources/HafthiMac/Resources/SamplerDefault.yml "$APP/Contents/Resources/SamplerDefault.yml"
install -m 755 Sources/HafthiMac/Resources/g "$APP/Contents/Resources/bin/g"
if [ -f ".build/checkouts/SwiftTerm/LICENSE" ]; then
    cp ".build/checkouts/SwiftTerm/LICENSE" "$APP/Contents/Resources/SwiftTerm-LICENSE.txt"
fi

# Export the same icon shown in the Dock so Finder shows it before launch.
ICONSET="build/Hafthi.iconset"
mkdir -p "$ICONSET"
swiftc Sources/HafthiMac/AppIcon.swift scripts/export-icon.swift -o build/export-icon
build/export-icon build/Hafthi-icon.png
for size in 16 32 128 256 512; do
    sips -s format png -z "$size" "$size" build/Hafthi-icon.png \
        --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -s format png -z "$double" "$double" build/Hafthi-icon.png \
        --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/Hafthi.icns"
printf 'Built %s\n' "$APP"
