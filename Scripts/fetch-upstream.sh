#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

OUTPUT_APP="${1:-$ROOT_DIR/dist/upstream/RustDesk.app}"
CACHE_DIR="${RUSTDESKX_CACHE_DIR:-$ROOT_DIR/.cache}"
DMG_PATH="$CACHE_DIR/$UPSTREAM_DMG_NAME"
MOUNT_DIR=""

cleanup() {
  if [[ -n "$MOUNT_DIR" ]] && /sbin/mount | /usr/bin/grep -Fq "on $MOUNT_DIR "; then
    /usr/bin/hdiutil detach "$MOUNT_DIR" -quiet || true
  fi
  if [[ -n "$MOUNT_DIR" && -d "$MOUNT_DIR" ]]; then
    /bin/rmdir "$MOUNT_DIR" 2>/dev/null || true
  fi
}
trap cleanup EXIT

[[ "$(uname -s)" == "Darwin" ]] || die "macOS is required"
/bin/mkdir -p "$CACHE_DIR" "$(dirname "$OUTPUT_APP")"

if [[ ! -f "$DMG_PATH" ]] || ! printf '%s  %s\n' "$UPSTREAM_DMG_SHA256" "$DMG_PATH" | /usr/bin/shasum -a 256 -c - >/dev/null 2>&1; then
  info "Downloading RustDesk $UPSTREAM_VERSION for arm64"
  /usr/bin/curl --fail --location --retry 3 --output "$DMG_PATH.part" "$UPSTREAM_DMG_URL"
  /bin/mv "$DMG_PATH.part" "$DMG_PATH"
fi

printf '%s  %s\n' "$UPSTREAM_DMG_SHA256" "$DMG_PATH" | /usr/bin/shasum -a 256 -c -

MOUNT_DIR="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/rustdeskx-mount.XXXXXX")"
/usr/bin/hdiutil attach "$DMG_PATH" -nobrowse -readonly -mountpoint "$MOUNT_DIR" -quiet
[[ -d "$MOUNT_DIR/RustDesk.app" ]] || die "RustDesk.app was not found in the upstream DMG"
[[ ! -e "$OUTPUT_APP" ]] || die "output already exists: $OUTPUT_APP"
/usr/bin/ditto "$MOUNT_DIR/RustDesk.app" "$OUTPUT_APP"
info "Upstream app copied to $OUTPUT_APP"

