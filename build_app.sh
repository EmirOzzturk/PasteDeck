#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="PasteDeck"
BUILD_DIR="$PROJECT_DIR/.build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

CONFIG="${1:-release}"
if [ "$CONFIG" = "release" ]; then
    BINARY="$BUILD_DIR/release/$APP_NAME"
    echo "🔨 Building PasteDeck (release)..."
    swift build -c release
else
    BINARY="$BUILD_DIR/debug/$APP_NAME"
    echo "🔨 Building PasteDeck (debug)..."
    swift build
fi

echo "📦 Creating app bundle ($CONFIG)..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Copy icon
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Ad-hoc codesign (quarantine uyarısını azaltır)
codesign --force --deep -s - "$APP_BUNDLE" 2>/dev/null || true

echo "✅ App bundle created at: $APP_BUNDLE"
echo ""
echo "To run: open $APP_BUNDLE"
