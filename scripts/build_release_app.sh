#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_DIR="${DERIVED_DATA_DIR:-/tmp/CleanMacOSReleaseDerivedData}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
SCHEME="${SCHEME:-CleanMacOS}"
PROJECT="${PROJECT:-CleanMacOS.xcodeproj}"
XCODE_DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

if [[ ! -x "$XCODE_DEVELOPER_DIR/usr/bin/xcodebuild" ]]; then
  echo "xcodebuild not found under: $XCODE_DEVELOPER_DIR"
  echo "Set DEVELOPER_DIR to a valid Xcode developer path."
  exit 1
fi

echo "==> Building Release app"
DEVELOPER_DIR="$XCODE_DEVELOPER_DIR" xcodebuild \
  -project "$ROOT_DIR/$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  clean build

APP_PATH="$DERIVED_DATA_DIR/Build/Products/Release/${SCHEME}.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found at: $APP_PATH"
  exit 1
fi

mkdir -p "$DIST_DIR"
VERSION="${1:-local}"
ZIP_PATH="$DIST_DIR/${SCHEME}-${VERSION}.zip"

echo "==> Packaging: $ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Done: $ZIP_PATH"
