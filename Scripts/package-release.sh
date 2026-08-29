#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

VERSION="${1:-$RELEASE_VERSION}"
[[ "$VERSION" == "$RELEASE_VERSION" ]] || die "expected release version $RELEASE_VERSION"

DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
SOURCE_APP="${SOURCE_APP:-$DIST_DIR/upstream/RustDesk.app}"
OUTPUT_APP="$DIST_DIR/$APP_NAME.app"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION-arm64.zip"
SHA_PATH="$ZIP_PATH.sha256"

/bin/mkdir -p "$DIST_DIR"
if [[ ! -d "$SOURCE_APP" ]]; then
  "$SCRIPT_DIR/fetch-upstream.sh" "$SOURCE_APP"
fi

[[ ! -e "$OUTPUT_APP" ]] || /bin/rm -rf -- "$OUTPUT_APP"
[[ ! -e "$ZIP_PATH" ]] || /bin/rm -f -- "$ZIP_PATH" "$SHA_PATH"
"$SCRIPT_DIR/rebrand-app.sh" "$SOURCE_APP" "$OUTPUT_APP"

/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$OUTPUT_APP" "$ZIP_PATH"
(
  cd "$DIST_DIR"
  /usr/bin/shasum -a 256 "$(basename "$ZIP_PATH")" > "$(basename "$SHA_PATH")"
)

info "Package: $ZIP_PATH"
info "SHA-256: $SHA_PATH"

