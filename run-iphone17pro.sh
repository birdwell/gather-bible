#!/bin/bash
# Run Gather Bible on iPhone 17 Pro simulator

SIMULATOR_ID="132A8978-C727-4BBF-B012-CC5A97606A73"
SIMULATOR_NAME="iPhone 17 Pro"
PROJECT_DIR="/Users/joshbirdwell/Personal/Gather Bible"
SCHEME="Gather Bible"
BUNDLE_ID="Josh-Birdwell.Gather-Bible"

echo "🔨 Building for $SIMULATOR_NAME..."
cd "$PROJECT_DIR"

xcodebuild -scheme "$SCHEME" -destination "id=$SIMULATOR_ID" -derivedDataPath build build -quiet

if [ $? -ne 0 ]; then
    echo "❌ Build failed - run without -quiet to see errors"
    exit 1
fi

echo "✅ Build succeeded!"
echo "📱 Booting $SIMULATOR_NAME..."
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true

echo "📦 Installing app..."
APP_PATH=$(find build -name "Gather Bible.app" -type d | head -1)
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"

echo "🚀 Launching app..."
xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID"

echo "✅ $SIMULATOR_NAME is running!"

