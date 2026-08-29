#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

SOURCE_APP="${1:-}"
OUTPUT_APP="${2:-}"
SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"

[[ "$(uname -s)" == "Darwin" ]] || die "macOS is required"
[[ -n "$SOURCE_APP" && -d "$SOURCE_APP" ]] || die "usage: $0 SOURCE_APP OUTPUT_APP"
[[ -n "$OUTPUT_APP" && "$OUTPUT_APP" == *.app ]] || die "output must be an .app path"
[[ ! -e "$OUTPUT_APP" ]] || die "output already exists: $OUTPUT_APP"

SOURCE_PLIST="$SOURCE_APP/Contents/Info.plist"
[[ -f "$SOURCE_PLIST" ]] || die "source Info.plist is missing"
SOURCE_VERSION="$(/usr/bin/plutil -extract CFBundleShortVersionString raw "$SOURCE_PLIST")"
[[ "$SOURCE_VERSION" == "$UPSTREAM_VERSION" ]] || die "expected RustDesk $UPSTREAM_VERSION, got $SOURCE_VERSION"

OLD_EXECUTABLE="$(/usr/bin/plutil -extract CFBundleExecutable raw "$SOURCE_PLIST")"
[[ -x "$SOURCE_APP/Contents/MacOS/$OLD_EXECUTABLE" ]] || die "source executable is missing"

/bin/mkdir -p "$(dirname "$OUTPUT_APP")"
/usr/bin/ditto "$SOURCE_APP" "$OUTPUT_APP"
/usr/bin/xattr -cr "$OUTPUT_APP"

OUTPUT_PLIST="$OUTPUT_APP/Contents/Info.plist"
/bin/mv "$OUTPUT_APP/Contents/MacOS/$OLD_EXECUTABLE" "$OUTPUT_APP/Contents/MacOS/$EXECUTABLE_NAME"
/bin/chmod +x "$OUTPUT_APP/Contents/MacOS/$EXECUTABLE_NAME"

/usr/bin/plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$OUTPUT_PLIST"
/usr/bin/plutil -replace CFBundleExecutable -string "$EXECUTABLE_NAME" "$OUTPUT_PLIST"
/usr/bin/plutil -replace CFBundleName -string "$APP_NAME" "$OUTPUT_PLIST"
if /usr/bin/plutil -extract CFBundleDisplayName raw "$OUTPUT_PLIST" >/dev/null 2>&1; then
  /usr/bin/plutil -replace CFBundleDisplayName -string "$APP_NAME" "$OUTPUT_PLIST"
else
  /usr/bin/plutil -insert CFBundleDisplayName -string "$APP_NAME" "$OUTPUT_PLIST"
fi

if /usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes:0:CFBundleURLName' "$OUTPUT_PLIST" >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleURLTypes:0:CFBundleURLName $BUNDLE_ID" "$OUTPUT_PLIST"
fi
if /usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes:0:CFBundleURLSchemes:0' "$OUTPUT_PLIST" >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c 'Set :CFBundleURLTypes:0:CFBundleURLSchemes:0 rustdeskx' "$OUTPUT_PLIST"
fi

# File-provider backed folders can reattach Finder metadata while the bundle is
# being modified. Clear it immediately before signing as well as after copying.
/usr/bin/xattr -cr "$OUTPUT_APP"

TIMESTAMP_ARGS=(--timestamp)
if [[ "$SIGN_IDENTITY" == "-" ]]; then
  TIMESTAMP_ARGS=(--timestamp=none)
fi

sign_path() {
  if [[ -n "${CODE_SIGN_KEYCHAIN:-}" ]]; then
    /usr/bin/codesign --force --sign "$SIGN_IDENTITY" --options runtime \
      "${TIMESTAMP_ARGS[@]}" --keychain "$CODE_SIGN_KEYCHAIN" "$1"
  else
    /usr/bin/codesign --force --sign "$SIGN_IDENTITY" --options runtime \
      "${TIMESTAMP_ARGS[@]}" "$1"
  fi
}

info "Checking that every Mach-O binary is arm64-only"
while IFS= read -r -d '' candidate; do
  if /usr/bin/file -b "$candidate" | /usr/bin/grep -q 'Mach-O'; then
    ARCHS="$(/usr/bin/lipo -archs "$candidate")"
    [[ "$ARCHS" == "arm64" ]] || die "non-arm64 binary found: $candidate ($ARCHS)"
  fi
done < <(/usr/bin/find "$OUTPUT_APP/Contents" -type f -print0)

info "Signing nested Mach-O files"
while IFS= read -r -d '' candidate; do
  if /usr/bin/file -b "$candidate" | /usr/bin/grep -q 'Mach-O'; then
    sign_path "$candidate"
  fi
done < <(/usr/bin/find "$OUTPUT_APP/Contents" -type f -print0)

info "Signing nested code bundles"
while IFS= read -r -d '' bundle; do
  sign_path "$bundle"
done < <(/usr/bin/find "$OUTPUT_APP/Contents" -depth -type d \
  \( -name '*.framework' -o -name '*.xpc' -o -name '*.appex' -o -name '*.plugin' -o -name '*.app' \) -print0)

sign_path "$OUTPUT_APP"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$OUTPUT_APP"

ACTUAL_ID="$(/usr/bin/plutil -extract CFBundleIdentifier raw "$OUTPUT_PLIST")"
ACTUAL_EXECUTABLE="$(/usr/bin/plutil -extract CFBundleExecutable raw "$OUTPUT_PLIST")"
[[ "$ACTUAL_ID" == "$BUNDLE_ID" ]] || die "bundle identifier verification failed"
[[ "$ACTUAL_EXECUTABLE" == "$EXECUTABLE_NAME" ]] || die "executable name verification failed"
[[ "$(/usr/bin/lipo -archs "$OUTPUT_APP/Contents/MacOS/$EXECUTABLE_NAME")" == "arm64" ]] || die "main executable is not arm64-only"

info "Created $OUTPUT_APP"
