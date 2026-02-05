#!/usr/bin/env bash
set -euo pipefail

# Create a distributable DMG for MiddleFlickOS
# Usage: scripts/make_dmg.sh /path/to/MiddleFlickOS.app [output.dmg]

APP_PATH=${1:-}
DMG_OUT=${2:-}

if [[ -z "$APP_PATH" ]]; then
  echo "Usage: $0 /path/to/MiddleFlickOS.app [output.dmg]" >&2
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found: $APP_PATH" >&2
  exit 1
fi

APP_NAME=$(basename "$APP_PATH" .app)

if [[ -z "$DMG_OUT" ]]; then
  DMG_OUT="./${APP_NAME}.dmg"
fi

# Create a temp directory for the DMG contents
STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT

echo "Copying app to staging area..."
cp -R "$APP_PATH" "$STAGING/"

echo "Creating Applications symlink..."
ln -s /Applications "$STAGING/Applications"

# Remove any existing DMG at the output path
rm -f "$DMG_OUT"

echo "Creating DMG..."
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING" \
  -ov \
  -fs HFS+ \
  -format UDZO \
  "$DMG_OUT"

echo ""
echo "DMG created: $DMG_OUT"
echo "SHA-256: $(shasum -a 256 "$DMG_OUT" | awk '{print $1}')"
