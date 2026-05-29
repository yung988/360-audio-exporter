#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$SCRIPT_DIR"
BUILD_DIR="$WORKSPACE/.build/release"
APP_NAME="360AudioExporter"
APP_BUNDLE="$WORKSPACE/$APP_NAME.app"
ICON_SOURCE="${ICON_SOURCE:-$WORKSPACE/Resources/AppIcon.png}"
ICON_ICNS="${ICON_ICNS:-$WORKSPACE/Resources/AppIcon.icns}"

echo "Creating App Bundle Directory Structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "Copying Binary..."
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

if [ -f "$ICON_ICNS" ]; then
    echo "Copying AppIcon.icns..."
    cp "$ICON_ICNS" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
elif [ -f "$ICON_SOURCE" ]; then
    echo "Generating Iconset..."
    ICONSET_DIR="$WORKSPACE/AppIcon.iconset"
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"

    sips -z 16 16     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null 2>&1
    sips -z 32 32     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null 2>&1
    sips -z 32 32     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null 2>&1
    sips -z 64 64     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null 2>&1
    sips -z 128 128   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null 2>&1
    sips -z 256 256   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null 2>&1
    sips -z 256 256   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null 2>&1
    sips -z 512 512   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null 2>&1
    sips -z 512 512   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null 2>&1
    sips -z 1024 1024 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null 2>&1

    echo "Converting Iconset to .icns..."
    iconutil -c icns "$ICONSET_DIR" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    rm -rf "$ICONSET_DIR"
else
    echo "No app icon found. Set ICON_ICNS or ICON_SOURCE to include one."
fi

echo "Writing Info.plist..."
cat <<EOF > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.txt">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.jangajdos.$APP_NAME</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>360 Audio Exporter</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "App bundle created successfully at $APP_BUNDLE"

echo "Building DMG installer..."
DMG_TEMP_DIR="$WORKSPACE/dmg_temp"
rm -rf "$DMG_TEMP_DIR"
mkdir -p "$DMG_TEMP_DIR"
cp -R "$APP_BUNDLE" "$DMG_TEMP_DIR/"
ln -s /Applications "$DMG_TEMP_DIR/Applications"

rm -f "$WORKSPACE/360AudioExporter.dmg"
hdiutil create -volname "360 Audio Exporter" -srcfolder "$DMG_TEMP_DIR" -ov -format UDZO "$WORKSPACE/360AudioExporter.dmg"
rm -rf "$DMG_TEMP_DIR"

echo "DMG created successfully at $WORKSPACE/360AudioExporter.dmg"
