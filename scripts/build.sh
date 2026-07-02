#!/bin/bash
set -euo pipefail

PROJ_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$PROJ_DIR/FlipCoin"
BUILD_DIR="$PROJ_DIR/build"
APP_DIR="$BUILD_DIR/FlipCoin.app"
SDK_PATH=$(xcrun --show-sdk-path --sdk macosx)
TARGET="$(uname -m)-apple-macos12.0"

echo "=== FlipCoin Build Script ==="
echo ""

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Collect all Swift source files
SWIFT_FILES=$(find "$SRC_DIR" -name "*.swift" | sort)
FILE_COUNT=$(echo "$SWIFT_FILES" | wc -l | tr -d ' ')
echo "[1/3] Found $FILE_COUNT Swift source files"

# Compile
echo "[2/3] Compiling..."
swiftc \
  -sdk "$SDK_PATH" \
  -target "$TARGET" \
  -framework SwiftUI \
  -framework SceneKit \
  -framework AppKit \
  -O \
  -o "$BUILD_DIR/FlipCoin" \
  $SWIFT_FILES

echo "       Binary size: $(du -sh "$BUILD_DIR/FlipCoin" | cut -f1)"

# Create .app bundle
echo "[3/3] Creating .app bundle..."

mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/FlipCoin" "$APP_DIR/Contents/MacOS/FlipCoin"
cp "$SRC_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"

# Copy assets if present
if [ -d "$SRC_DIR/Assets.xcassets" ]; then
    cp -R "$SRC_DIR/Assets.xcassets" "$APP_DIR/Contents/Resources/"
fi

echo ""
echo "=== Build Complete ==="
echo "App:  $APP_DIR"
echo "Size: $(du -sh "$APP_DIR" | cut -f1)"
echo ""
echo "To run: open $APP_DIR"
