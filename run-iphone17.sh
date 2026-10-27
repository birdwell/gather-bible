#!/bin/bash
# Run Gather Bible on iPhone 17 simulator

SIMULATOR_ID="A447D21C-03D6-4BCF-A50E-BAB895757EA3"
SIMULATOR_NAME="iPhone 17"
PROJECT_DIR="/Users/joshbirdwell/Personal/Gather Bible"
SCHEME="Gather Bible"
BUNDLE_ID="Josh-Birdwell.Gather-Bible"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

cd "$PROJECT_DIR" || {
  echo "Could not enter $PROJECT_DIR" >&2
  exit 1
}

# shellcheck disable=SC1091
source "$SCRIPT_DIR/scripts/youversion-build-setting.sh"
if ! youversion_prepare_xcode_args; then
  echo "YOUVERSION_APP_KEY is not set. Export it, or copy Config/Local.xcconfig.example to Config/Local.xcconfig and set YOUVERSION_APP_KEY. See docs/testflight-ci.md." >&2
  exit 1
fi

echo "🔨 Building for $SIMULATOR_NAME..."
xcodebuild -scheme "$SCHEME" -destination "id=$SIMULATOR_ID" -derivedDataPath build build -quiet "${YOUVERSION_XCODE_ARGS[@]}"

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

