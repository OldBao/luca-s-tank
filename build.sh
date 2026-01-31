#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="BattleCity"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "Building $APP_NAME..."

# Create build directory
mkdir -p "$BUILD_DIR"

# Compile
swiftc \
    -target arm64-apple-macos13.0 \
    -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
    -framework SpriteKit \
    -framework Cocoa \
    -framework AVFoundation \
    -O \
    -o "$BUILD_DIR/$APP_NAME" \
    $(find "$PROJECT_DIR/BattleCity/Sources" -name "*.swift" | sort)

echo "Compilation successful."

# Create .app bundle
echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "$PROJECT_DIR/BattleCity/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "Build complete: $APP_BUNDLE"
echo ""
echo "To run: open $APP_BUNDLE"
echo "Or:     $APP_BUNDLE/Contents/MacOS/$APP_NAME"
