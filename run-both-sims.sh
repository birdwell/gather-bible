#!/bin/bash
# Run Gather Bible on both iPhone 17 and iPhone 17 Pro simulators

PROJECT_DIR="/Users/joshbirdwell/Personal/Gather Bible"
SCHEME="Gather Bible"
BUNDLE_ID="Josh-Birdwell.Gather-Bible"

SIM1_ID="A447D21C-03D6-4BCF-A50E-BAB895757EA3"
SIM1_NAME="iPhone 17"

SIM2_ID="132A8978-C727-4BBF-B012-CC5A97606A73"
SIM2_NAME="iPhone 17 Pro"

cd "$PROJECT_DIR"

echo "🔨 Building app..."
xcodebuild -scheme "$SCHEME" -destination "generic/platform=iOS Simulator" -derivedDataPath build build -quiet

if [ $? -ne 0 ]; then
    echo "❌ Build failed - run without -quiet to see errors"
    exit 1
fi

echo "✅ Build succeeded!"
APP_PATH=$(find build -name "Gather Bible.app" -type d | head -1)

echo ""
echo "📱 Setting up $SIM1_NAME..."
xcrun simctl boot "$SIM1_ID" 2>/dev/null || true
xcrun simctl install "$SIM1_ID" "$APP_PATH"
xcrun simctl launch "$SIM1_ID" "$BUNDLE_ID"
echo "✅ $SIM1_NAME is running!"

echo ""
echo "📱 Setting up $SIM2_NAME..."
xcrun simctl boot "$SIM2_ID" 2>/dev/null || true
xcrun simctl install "$SIM2_ID" "$APP_PATH"
xcrun simctl launch "$SIM2_ID" "$BUNDLE_ID"
echo "✅ $SIM2_NAME is running!"

echo ""
echo "🎉 Both simulators are running!"
echo "   - Use $SIM1_NAME as HOST (create session)"
echo "   - Use $SIM2_NAME as GUEST (join session)"

