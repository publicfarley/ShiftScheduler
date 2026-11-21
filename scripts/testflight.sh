#!/usr/bin/env bash
# Archive the ShiftScheduler iOS app and upload it to App Store Connect (TestFlight).
#
# Steps: preflight checks -> archive (Release, generic iOS device) -> export + upload.
# Nothing in the repo is modified: the build number and encryption flag are passed
# as build-setting overrides, and the archive lives in build/testflight/.
#
# Usage:
#   scripts/testflight.sh [--skip-tests] [--no-upload] [--build-number N]
#
#   --skip-tests       Skip the unit test run before archiving.
#   --no-upload        Archive and export an .ipa locally; do not upload.
#   --build-number N   Override the build number (default: UTC timestamp yyyymmddHHMM,
#                      which always increases, so there is no counter to maintain).
#
# Authentication (pick one):
#   1. App Store Connect API key (recommended, works headless):
#        export ASC_KEY_ID=ABC123DEFG
#        export ASC_ISSUER_ID=00000000-0000-0000-0000-000000000000
#        export ASC_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_ABC123DEFG.p8
#   2. Otherwise, the Apple ID signed in to Xcode (Settings > Accounts) is used.
#
# One-time setup this script cannot do for you:
#   - Create the app record in App Store Connect (bundle ID functioncraft.ShiftScheduler).
#   - Deploy the CloudKit schema to Production in the CloudKit Dashboard.
#   - Add testers in App Store Connect once the build finishes processing.
set -euo pipefail

SCHEME="ShiftScheduler"
PROJECT="ShiftScheduler.xcodeproj"
ENTITLEMENTS="ShiftScheduler.entitlements"
SIM_DEST='platform=iOS Simulator,name=iPhone 18 Pro,OS=latest'

RUN_TESTS=1
UPLOAD=1
BUILD_NUMBER="$(date -u +%Y%m%d%H%M)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-tests)   RUN_TESTS=0 ;;
    --no-upload)    UPLOAD=0 ;;
    --build-number) BUILD_NUMBER="${2:?--build-number needs a value}"; shift ;;
    -h|--help)      sed -n '2,/^set -euo/p' "${BASH_SOURCE[0]}" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "error: unknown option $1" >&2; exit 2 ;;
  esac
  shift
done

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

fail() { echo "error: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

# ---------------------------------------------------------------- preflight
step "Preflight"

[[ "$(git rev-parse --abbrev-ref HEAD)" == "main" ]] \
  || echo "warning: not on main ($(git rev-parse --abbrev-ref HEAD))"
if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  echo "warning: uncommitted changes will be included in this build:"
  git status --short --untracked-files=no | sed 's/^/    /'
fi

SETTINGS="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=iOS' -showBuildSettings 2>/dev/null)"
setting() { awk -v k="$1" '$1 == k { sub(/^[^=]*= /, ""); print; exit }' <<<"$SETTINGS"; }

BUNDLE_ID="$(setting PRODUCT_BUNDLE_IDENTIFIER)"
TEAM_ID="$(setting DEVELOPMENT_TEAM)"
VERSION="$(setting MARKETING_VERSION)"
[[ -n "$BUNDLE_ID" && -n "$TEAM_ID" && -n "$VERSION" ]] \
  || fail "could not read bundle ID / team / version from build settings"
echo "Bundle ID : $BUNDLE_ID"
echo "Team      : $TEAM_ID"
echo "Version   : $VERSION ($BUILD_NUMBER)"

[[ -f "$ENTITLEMENTS" ]] || fail "$ENTITLEMENTS not found"
grep -q "aps-environment" "$ENTITLEMENTS" \
  || echo "warning: no aps-environment entitlement (fine unless you use CloudKit push subscriptions)"
[[ -n "$(find ShiftScheduler -name PrivacyInfo.xcprivacy -print -quit)" ]] \
  || echo "warning: no PrivacyInfo.xcprivacy found (Apple may flag required-reason API use)"
echo "reminder: CloudKit schema must be deployed to Production before testers sync."

# ------------------------------------------------------------ auth arguments
AUTH=()
if [[ -n "${ASC_KEY_ID:-}" || -n "${ASC_ISSUER_ID:-}" || -n "${ASC_KEY_PATH:-}" ]]; then
  [[ -n "${ASC_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" && -n "${ASC_KEY_PATH:-}" ]] \
    || fail "set all of ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH, or none"
  [[ -f "$ASC_KEY_PATH" ]] || fail "API key not found at $ASC_KEY_PATH"
  AUTH=(-authenticationKeyPath "$ASC_KEY_PATH"
        -authenticationKeyID "$ASC_KEY_ID"
        -authenticationKeyIssuerID "$ASC_ISSUER_ID")
  echo "Auth      : App Store Connect API key"
else
  echo "Auth      : Apple ID signed in to Xcode"
fi

# -------------------------------------------------------------------- tests
if [[ "$RUN_TESTS" -eq 1 ]]; then
  step "Running unit tests"
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$SIM_DEST" \
    -only-testing:ShiftSchedulerTests test -quiet \
    || fail "tests failed; fix them or pass --skip-tests"
fi

# ------------------------------------------------------------------ archive
OUT="$REPO/build/testflight"
ARCHIVE="$OUT/$SCHEME-$BUILD_NUMBER.xcarchive"
EXPORT_DIR="$OUT/export-$BUILD_NUMBER"
mkdir -p "$OUT"

step "Archiving ($VERSION build $BUILD_NUMBER)"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates ${AUTH[@]+"${AUTH[@]}"} \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  INFOPLIST_KEY_ITSAppUsesNonExemptEncryption=NO \
  archive -quiet
[[ -d "$ARCHIVE" ]] || fail "archive not produced at $ARCHIVE"

# ------------------------------------------------------------- export/upload
EXPORT_PLIST="$OUT/ExportOptions-$BUILD_NUMBER.plist"
if [[ "$UPLOAD" -eq 1 ]]; then DEST="upload"; else DEST="export"; fi
cat >"$EXPORT_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key><string>app-store-connect</string>
	<key>destination</key><string>$DEST</string>
	<key>teamID</key><string>$TEAM_ID</string>
	<key>signingStyle</key><string>automatic</string>
	<key>uploadSymbols</key><true/>
	<key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
PLIST

if [[ "$UPLOAD" -eq 1 ]]; then
  step "Exporting and uploading to App Store Connect"
else
  step "Exporting .ipa (no upload)"
fi
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_PLIST" -allowProvisioningUpdates \
  ${AUTH[@]+"${AUTH[@]}"}

echo
if [[ "$UPLOAD" -eq 1 ]]; then
  echo "Uploaded $BUNDLE_ID $VERSION ($BUILD_NUMBER)."
  echo "Processing takes a few minutes; then add testers at:"
  echo "  https://appstoreconnect.apple.com/apps  ->  TestFlight"
else
  echo "Exported to $EXPORT_DIR"
fi
echo "Archive: $ARCHIVE"
