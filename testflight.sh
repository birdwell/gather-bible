#!/usr/bin/env bash
# Build the app on this Mac and upload it to TestFlight. See fastlane/Fastfile.
# Usage: ./testflight.sh
set -euo pipefail

cd "$(dirname "$0")"

command -v fastlane >/dev/null || { echo "Install fastlane first: brew install fastlane" >&2; exit 1; }

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_HIDE_CHANGELOG=1 FASTLANE_OPT_OUT_USAGE=1

exec fastlane ios beta
