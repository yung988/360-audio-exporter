#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$SCRIPT_DIR"
BUILD_DIR="$WORKSPACE/.build/release"
APP_NAME="Orbit360"
APP_BUNDLE_NAME="Orbit 360"
EXECUTABLE_NAME="Orbit360"
ARM64_BINARY="$WORKSPACE/.build/arm64-apple-macosx/release/$APP_NAME"
X86_64_BINARY="$WORKSPACE/.build/x86_64-apple-macosx/release/$APP_NAME"
APP_BUNDLE="$WORKSPACE/$APP_BUNDLE_NAME.app"
ICON_SOURCE="${ICON_SOURCE:-$WORKSPACE/Resources/AppIcon.png}"
ICON_ICNS="${ICON_ICNS:-$WORKSPACE/Resources/AppIcon.icns}"

echo "Creating App Bundle Directory Structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "Copying Binary..."
if [ -f "$ARM64_BINARY" ] && [ -f "$X86_64_BINARY" ]; then
    echo "Creating universal binary..."
    UNIVERSAL_TEMP_DIR="$WORKSPACE/universal_temp"
    rm -rf "$UNIVERSAL_TEMP_DIR"
    mkdir -p "$UNIVERSAL_TEMP_DIR"
    cp "$ARM64_BINARY" "$UNIVERSAL_TEMP_DIR/arm64"
    cp "$X86_64_BINARY" "$UNIVERSAL_TEMP_DIR/x86_64"
    codesign --remove-signature "$UNIVERSAL_TEMP_DIR/arm64" >/dev/null 2>&1 || true
    codesign --remove-signature "$UNIVERSAL_TEMP_DIR/x86_64" >/dev/null 2>&1 || true
    lipo -create "$UNIVERSAL_TEMP_DIR/arm64" "$UNIVERSAL_TEMP_DIR/x86_64" -output "$APP_BUNDLE/Contents/MacOS/$EXECUTABLE_NAME"
    rm -rf "$UNIVERSAL_TEMP_DIR"
elif [ -f "$BUILD_DIR/$APP_NAME" ]; then
    cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$EXECUTABLE_NAME"
else
    echo "Release binary not found. Run swift build -c release first."
    exit 1
fi
chmod +x "$APP_BUNDLE/Contents/MacOS/$EXECUTABLE_NAME"

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

if [ -f "$WORKSPACE/Resources/ffmpeg" ] && [ -f "$WORKSPACE/Resources/ffprobe" ]; then
    echo "Copying bundled ffmpeg and ffprobe..."
    cp "$WORKSPACE/Resources/ffmpeg" "$APP_BUNDLE/Contents/Resources/ffmpeg"
    cp "$WORKSPACE/Resources/ffprobe" "$APP_BUNDLE/Contents/Resources/ffprobe"
    chmod +x "$APP_BUNDLE/Contents/Resources/ffmpeg"
    chmod +x "$APP_BUNDLE/Contents/Resources/ffprobe"
else
    echo "No bundled ffmpeg/ffprobe found in Resources/. Users can configure paths in Settings."
fi

if [ -f "$WORKSPACE/THIRD_PARTY_NOTICES.md" ]; then
    cp "$WORKSPACE/THIRD_PARTY_NOTICES.md" "$APP_BUNDLE/Contents/Resources/THIRD_PARTY_NOTICES.md"
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
    <string>$EXECUTABLE_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.jangajdos.orbit360</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Orbit 360</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
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

rm -f "$WORKSPACE/Orbit360.dmg"
hdiutil create -volname "Orbit 360" -srcfolder "$DMG_TEMP_DIR" -ov -format UDZO "$WORKSPACE/Orbit360.dmg"
rm -rf "$DMG_TEMP_DIR"

echo "DMG created successfully at $WORKSPACE/Orbit360.dmg"
