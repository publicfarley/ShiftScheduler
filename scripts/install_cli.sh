#!/usr/bin/env bash
# Build the signed ShiftSchedulerCLI scheme and install it for command-line use.
#
# Copies the whole shift-scheduler.app bundle (the CloudKit entitlement lives in
# the embedded provisioning profile, so the bare binary will not work) to
# ~/Applications and links the executable into ~/bin.
#
# Usage: scripts/install_cli.sh [Debug|Release]   (default: Debug)
set -euo pipefail

CONFIG="${1:-Debug}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$HOME/Applications"
BIN_DIR="$HOME/bin"
APP="$APP_DIR/shift-scheduler.app"
LINK="$BIN_DIR/shift-scheduler"

cd "$REPO"
COMMON=(-project ShiftScheduler.xcodeproj -scheme ShiftSchedulerCLI
        -configuration "$CONFIG" -destination 'platform=macOS,arch=arm64')

echo "Building ShiftSchedulerCLI ($CONFIG)..."
xcodebuild "${COMMON[@]}" build -quiet

PRODUCTS_DIR="$(xcodebuild "${COMMON[@]}" -showBuildSettings 2>/dev/null \
  | awk '$1 == "BUILT_PRODUCTS_DIR" { sub(/^[^=]*= /, ""); print; exit }')"
BUILT="$PRODUCTS_DIR/shift-scheduler.app"
[[ -d "$BUILT" ]] || { echo "error: built bundle not found at $BUILT" >&2; exit 1; }

mkdir -p "$APP_DIR" "$BIN_DIR"
rm -rf "$APP"
cp -R "$BUILT" "$APP"
ln -sfn "$APP/Contents/MacOS/shift-scheduler" "$LINK"

codesign --verify "$APP"
echo "Installed $APP"
echo "Linked    $LINK -> $(readlink "$LINK")"
