#!/bin/bash
set -euo pipefail

PROJ_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$PROJ_DIR/FlipCoin"
DIST_DIR="$PROJ_DIR/dist"
BUILD_DIR="$PROJ_DIR/build"

VERSION="${1:-1.0.0}"
MACOS_SDK=$(xcrun --show-sdk-path --sdk macosx)
ARCH="$(uname -m)"
MACOS_TARGET="${ARCH}-apple-macos12.0"

echo "=== FlipCoin Build & Package v${VERSION} ==="
echo ""

# --- Clean ---
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$DIST_DIR"

SWIFT_FILES=$(find "$SRC_DIR" -name "*.swift" | sort)

# ============================================
# 1. macOS .app
# ============================================
echo "━━━ macOS Build ━━━"

mkdir -p "$BUILD_DIR/macos"
APP_DIR="$BUILD_DIR/macos/FlipCoin.app"

echo "[compile] Compiling for macOS ${ARCH}..."
swiftc \
  -sdk "$MACOS_SDK" \
  -target "$MACOS_TARGET" \
  -framework SwiftUI \
  -framework SceneKit \
  -framework AppKit \
  -O \
  -o "$BUILD_DIR/macos/FlipCoin" \
  $SWIFT_FILES

echo "          Binary: $(du -sh "$BUILD_DIR/macos/FlipCoin" | cut -f1)"

# Assemble .app bundle
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/macos/FlipCoin" "$APP_DIR/Contents/MacOS/FlipCoin"
cp "$SRC_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
if [ -d "$SRC_DIR/Assets.xcassets" ]; then
    cp -R "$SRC_DIR/Assets.xcassets" "$APP_DIR/Contents/Resources/"
fi

echo "          .app:  $(du -sh "$APP_DIR" | cut -f1)"

# --- .app.zip ---
echo "[zip] Creating FlipCoin-v${VERSION}-macOS.zip..."
(cd "$BUILD_DIR/macos" && zip -r -q "$DIST_DIR/FlipCoin-v${VERSION}-macOS.zip" FlipCoin.app)
echo "          Zip: $(du -sh "$DIST_DIR/FlipCoin-v${VERSION}-macOS.zip" | cut -f1)"

# ============================================
# 2. macOS .dmg
# ============================================
echo "[dmg] Creating FlipCoin-v${VERSION}.dmg..."

DMG_DIR="$BUILD_DIR/dmg"
DMG_TMP="$BUILD_DIR/FlipCoin-tmp.dmg"
DMG_OUT="$DIST_DIR/FlipCoin-v${VERSION}.dmg"

mkdir -p "$DMG_DIR"
cp -R "$APP_DIR" "$DMG_DIR/"

# Create Applications symlink for drag-to-install
ln -s /Applications "$DMG_DIR/Applications"

# Create temporary read-write image
hdiutil create -volname "FlipCoin" -srcfolder "$DMG_DIR" \
    -ov -format UDRW "$DMG_TMP" -quiet

# Mount it and set layout
MOUNT_DIR=$(mktemp -d)
hdiutil attach "$DMG_TMP" -mountpoint "$MOUNT_DIR" -nobrowse -quiet

# Position icons
osascript <<EOF 2>/dev/null || true
tell application "Finder"
    set dmgPath to POSIX file "$MOUNT_DIR" as alias
    tell dmgPath
        open
        set current view to icon view
        set toolbar visible to false
        set statusbar visible to false
        set bounds to {100, 100, 600, 400}
        set position of item "FlipCoin.app" to {130, 130}
        set position of item "Applications" to {370, 130}
        set icon size to 96
        close
    end tell
end tell
EOF

# Finalize to compressed read-only
hdiutil detach "$MOUNT_DIR" -quiet
rm -rf "$MOUNT_DIR"

hdiutil convert "$DMG_TMP" -format UDZO -imagekey zlib-level=9 \
    -o "$DMG_OUT" -quiet
rm -f "$DMG_TMP"

echo "          DMG:  $(du -sh "$DMG_OUT" | cut -f1)"

# ============================================
# 3. iOS .ipa (unsigned, for sideload)
# ============================================
echo ""
echo "━━━ iOS Build ━━━"

IOS_SDK=$(xcrun --show-sdk-path --sdk iphoneos 2>/dev/null || echo "")
if [ -z "$IOS_SDK" ] || [ ! -d "$IOS_SDK" ]; then
    echo "[skip]  iOS SDK not available — install Xcode with iOS support"
    echo "        To build iOS: open FlipCoin/ in Xcode → Product → Archive"
else
    IOS_TARGET="${ARCH}-apple-ios16.0"
    IOS_BUILD_DIR="$BUILD_DIR/ios"
    mkdir -p "$IOS_BUILD_DIR"

    echo "[compile] Compiling for iOS..."
    if swiftc \
      -sdk "$IOS_SDK" \
      -target "$IOS_TARGET" \
      -framework SwiftUI \
      -framework SceneKit \
      -framework UIKit \
      -O \
      -o "$IOS_BUILD_DIR/FlipCoin" \
      $SWIFT_FILES 2>/dev/null; then
        echo "          Binary: $(du -sh "$IOS_BUILD_DIR/FlipCoin" | cut -f1)"
        echo "          ⚠️  Requires Xcode to bundle into .ipa with signing."
        echo "          Open FlipCoin/ in Xcode → select iOS target → Archive."
    else
        echo "[warn]  iOS compilation failed — may need Xcode project for proper linking."
        echo "        Source code is iOS-compatible (see README for Xcode instructions)."
    fi
fi

# ============================================
# Done
# ============================================
echo ""
echo "=== Release Artifacts ==="
ls -lh "$DIST_DIR/"
echo ""
echo "Ready for GitHub Release."
echo "Run: gh release create v${VERSION} $DIST_DIR/*"
