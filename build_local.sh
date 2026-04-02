#!/bin/bash
set -e

# MiddleScroller Build Script
# Usage: ./build_local.sh

echo "🚀 Starting MiddleScroller Local Build..."

# Ensure we are in the project directory
cd "$(dirname "$0")/MiddleScroller"

# 1. Clean and Build (Release Configuration)
echo "🛠️  Building Release version..."
xcodebuild -scheme MiddleScroller \
    -configuration Release \
    -derivedDataPath build \
    -destination 'platform=macOS' \
    clean build \
    | grep -A 5 "BUILD SUCCEEDED" || true # Suppress noisy output, show success

# 2. Run Unit Tests (Debug Configuration)
#echo "🧪  Running Unit Tests..."
#xcodebuild -scheme MiddleScroller \
#    -configuration Debug \
#    -destination 'platform=macOS' \
#    test \
#    | grep "Test Suite 'All tests' passed" || true

# 3. Check for create-dmg
if ! command -v create-dmg &> /dev/null; then
    echo "❌ create-dmg not found. Install with: brew install create-dmg"
    exit 1
fi

# 4. Generate DMG background image
echo "🎨  Generating DMG background..."
swift Resources/generate_dmg_background.swift Resources/dmg-background.png

# 5. Create DMG with create-dmg
echo "📦  Packaging MiddleScroller.dmg..."
rm -f MiddleScroller.dmg

create-dmg \
    --volname "MiddleScroller" \
    --volicon "AppIcon.icns" \
    --background "Resources/dmg-background.png" \
    --window-pos 200 120 \
    --window-size 660 480 \
    --icon-size 128 \
    --icon "MiddleScroller.app" 180 240 \
    --hide-extension "MiddleScroller.app" \
    --app-drop-link 480 240 \
    --no-internet-enable \
    "MiddleScroller.dmg" \
    "build/Build/Products/Release/MiddleScroller.app"

echo "✅  Success! Opening MiddleScroller.dmg..."
open MiddleScroller.dmg
