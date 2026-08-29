#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../Config/upstream.env
source "$ROOT_DIR/Config/upstream.env"

APP_NAME="RustDeskX"
BUNDLE_ID="com.omzcj.rustdeskx"
EXECUTABLE_NAME="RustDeskX"
TEAM_ID="566UG6DQ7E"
RELEASE_VERSION="${UPSTREAM_VERSION}.${RELEASE_REVISION}"
UPSTREAM_DMG_NAME="rustdesk-${UPSTREAM_VERSION}-${UPSTREAM_ARCH}.dmg"
UPSTREAM_DMG_URL="https://github.com/rustdesk/rustdesk/releases/download/${UPSTREAM_VERSION}/${UPSTREAM_DMG_NAME}"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '==> %s\n' "$*"
}

