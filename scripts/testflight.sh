#!/usr/bin/env bash
# Archive ShiftScheduler and upload it to TestFlight in one step.
#
# Usage:
#   scripts/testflight.sh [upload] [options]     Test, archive and upload (default)
#   scripts/testflight.sh store-key <AuthKey_XXXX.p8> <issuer-id>
#                                                Save an App Store Connect API key in the Keychain
#   scripts/testflight.sh remove-key             Delete the saved key from the Keychain
#
# Upload options:
#   --build-number N   Use N as the build number (default: UTC timestamp, e.g. 20261111.0150)
#   --skip-tests       Don't run the unit tests before archiving
#   --xcode-account    Ignore any saved API key and upload with the Apple ID signed in to Xcode
#   --dry-run          Print the xcodebuild commands without running them
#
# How it signs in to App Store Connect, in order:
#   1. ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH environment variables (for CI, from secrets)
#   2. An API key saved in your login Keychain with `store-key`
#   3. The Apple ID signed in to Xcode (Xcode > Settings > Accounts); no key needed
#
# Key storage: the .p8 never lives in the repo (*.p8 is gitignored). `store-key` saves it in
# the login Keychain with no apps pre-approved, so macOS asks before anything reads it. At
# upload time the key is written to a private temp folder (mode 700) and deleted on exit.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="ShiftScheduler.xcodeproj"
SCHEME="ShiftScheduler"
TEST_DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro,OS=latest"
EXPORT_OPTIONS="$REPO/scripts/ExportOptions.plist"
OUT_DIR="$REPO/build/testflight"
KEYCHAIN_SERVICE="ShiftScheduler.AppStoreConnectAPIKey"
KEYCHAIN_ACCOUNT="ShiftScheduler"

die() { echo "error: $*" >&2; exit 1; }
info() { echo "==> $*"; }

require_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || die "this script needs macOS with Xcode installed"
  command -v xcodebuild >/dev/null || die "xcodebuild not found; install Xcode 26"
  command -v security >/dev/null || die "the macOS 'security' tool was not found"
}

# --- Keychain ---------------------------------------------------------------

store_key() {
  local key_file="${1:-}" issuer_id="${2:-}"
  [[ -n "$key_file" && -n "$issuer_id" ]] || die "usage: scripts/testflight.sh store-key <AuthKey_XXXX.p8> <issuer-id>"
  [[ -f "$key_file" ]] || die "key file not found: $key_file"

  local base key_id
  base="$(basename "$key_file")"
  [[ "$base" =~ ^AuthKey_([A-Z0-9]+)\.p8$ ]] || die "expected a file named AuthKey_<KEYID>.p8 as downloaded from App Store Connect"
  key_id="${BASH_REMATCH[1]}"
  [[ "$issuer_id" =~ ^[0-9a-fA-F-]{36}$ ]] || die "issuer ID should be a UUID (App Store Connect > Users and Access > Integrations)"
  grep -q "BEGIN PRIVATE KEY" "$key_file" || die "$key_file does not look like a .p8 private key"

  # One Keychain item holds "<key id> <issuer id> <base64 key>".
  # -T "" pre-approves no apps, so macOS asks you before any program (this script included) reads it.
  local secret
  secret="$key_id $issuer_id $(base64 < "$key_file" | tr -d '\n')"
  security add-generic-password -U -T "" \
    -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" \
    -l "ShiftScheduler App Store Connect API key ($key_id)" \
    -w "$secret"
  unset secret

  info "Saved API key $key_id to your login Keychain (item: $KEYCHAIN_SERVICE)."
  echo "    macOS will ask for permission the first time the upload reads it."
  echo "    You can now delete $key_file, or move it into your password manager as a backup."
}

remove_key() {
  if security delete-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" >/dev/null 2>&1; then
    info "Removed the saved API key from your Keychain."
  else
    info "No saved API key found."
  fi
}

# Sets AUTH_ARGS for xcodebuild. Writes the key to a private temp dir if it came from the Keychain.
AUTH_ARGS=()
TMP_DIR=""
cleanup() { [[ -n "$TMP_DIR" ]] && rm -rf "$TMP_DIR"; }
trap cleanup EXIT

resolve_auth() {
  local use_xcode_account="$1"

  if [[ "$use_xcode_account" == "1" ]]; then
    info "Signing in with the Apple ID in Xcode (--xcode-account)."
    return
  fi

  if [[ -n "${ASC_KEY_ID:-}" || -n "${ASC_ISSUER_ID:-}" || -n "${ASC_KEY_PATH:-}" ]]; then
    [[ -n "${ASC_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" && -n "${ASC_KEY_PATH:-}" ]] \
      || die "set all three of ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH, or none"
    [[ -f "$ASC_KEY_PATH" ]] || die "ASC_KEY_PATH does not point to a file"
    AUTH_ARGS=(-authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
    info "Signing in with API key $ASC_KEY_ID from the environment."
    return
  fi

  if ! security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" >/dev/null 2>&1; then
    info "No saved API key; signing in with the Apple ID in Xcode."
    return
  fi

  local secret key_id issuer_id key_b64
  secret="$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" -w)" \
    || die "couldn't read the API key from the Keychain (access denied?)"
  read -r key_id issuer_id key_b64 <<<"$secret"
  unset secret
  [[ -n "$key_id" && -n "$issuer_id" && -n "$key_b64" ]] || die "the saved Keychain item is malformed; run store-key again"

  TMP_DIR="$(mktemp -d)"
  chmod 700 "$TMP_DIR"
  local key_path="$TMP_DIR/AuthKey_${key_id}.p8"
  (umask 077; printf '%s' "$key_b64" | base64 --decode > "$key_path")
  unset key_b64

  AUTH_ARGS=(-authenticationKeyPath "$key_path" -authenticationKeyID "$key_id" -authenticationKeyIssuerID "$issuer_id")
  info "Signing in with API key $key_id from your Keychain."
}

# --- Upload -----------------------------------------------------------------

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '+'; printf ' %q' "$@"; printf '\n'
  else
    "$@"
  fi
}

upload() {
  local build_number="" skip_tests=0 use_xcode_account=0
  DRY_RUN=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --build-number) build_number="${2:-}"; shift 2 ;;
      --skip-tests) skip_tests=1; shift ;;
      --xcode-account) use_xcode_account=1; shift ;;
      --dry-run) DRY_RUN=1; shift ;;
      -h|--help) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
      *) die "unknown option: $1 (see --help)" ;;
    esac
  done

  build_number="${build_number:-$(date -u +%Y%m%d.%H%M)}"
  [[ "$build_number" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]] || die "build number must be 1 to 3 dot-separated integers"

  cd "$REPO"
  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    echo "warning: you have uncommitted changes; they will be included in this build" >&2
  fi

  local version
  version="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings 2>/dev/null \
    | awk '$1 == "MARKETING_VERSION" { print $3; exit }')"
  info "ShiftScheduler ${version:-?} ($build_number), commit $(git rev-parse --short HEAD 2>/dev/null || echo '?')"

  resolve_auth "$use_xcode_account"

  if [[ "$skip_tests" == "0" ]]; then
    info "Running unit tests..."
    run xcodebuild test -quiet -project "$PROJECT" -scheme "$SCHEME" \
      -destination "$TEST_DESTINATION" -only-testing:ShiftSchedulerTests
  fi

  local archive="$OUT_DIR/ShiftScheduler-$build_number.xcarchive"
  info "Archiving to $archive ..."
  run mkdir -p "$OUT_DIR"
  run xcodebuild archive -quiet -project "$PROJECT" -scheme "$SCHEME" \
    -configuration Release -destination "generic/platform=iOS" \
    -archivePath "$archive" -allowProvisioningUpdates ${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"} \
    CURRENT_PROJECT_VERSION="$build_number"

  info "Uploading to App Store Connect..."
  run xcodebuild -exportArchive -archivePath "$archive" \
    -exportOptionsPlist "$EXPORT_OPTIONS" -exportPath "$OUT_DIR/export-$build_number" \
    -allowProvisioningUpdates ${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"}

  info "Uploaded ShiftScheduler ${version:-?} ($build_number)."
  echo "    Apple emails you when processing finishes (usually 5 to 30 minutes);"
  echo "    the build then appears under TestFlight in App Store Connect."
}

# --- Main -------------------------------------------------------------------

require_macos
case "${1:-upload}" in
  store-key) shift; store_key "$@" ;;
  remove-key) remove_key ;;
  upload) shift || true; upload "$@" ;;
  -*) upload "$@" ;;
  *) die "unknown command: $1 (use upload, store-key or remove-key)" ;;
esac
