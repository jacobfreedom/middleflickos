#!/usr/bin/env bash
set -euo pipefail

# Build a macOS AppIcon.appiconset from a 1024x1024 base PNG
# Usage: scripts/build_appiconset.sh /path/to/base_1024.png /path/to/Assets.xcassets/AppIcon.appiconset

BASE=${1:-}
OUT=${2:-}

if [[ -z "$BASE" || -z "$OUT" ]]; then
  echo "Usage: $0 /path/to/base_1024.png /path/to/Assets.xcassets/AppIcon.appiconset" >&2
  exit 1
fi

if [[ ! -f "$BASE" ]]; then
  echo "Base PNG not found: $BASE" >&2
  exit 1
fi

mkdir -p "$OUT"

# macOS app icons: 16, 32, 128, 256, 512 at 1x and 2x
# (512@2x = 1024px, which is the largest slot)
sizes=(16 32 128 256 512)

for s in "${sizes[@]}"; do
  s2x=$(( s * 2 ))
  out1x="$OUT/icon_${s}x${s}.png"
  out2x="$OUT/icon_${s}x${s}@2x.png"
  sips -z "$s" "$s" "$BASE" --out "$out1x" >/dev/null
  sips -z "$s2x" "$s2x" "$BASE" --out "$out2x" >/dev/null
  echo "Wrote $out1x and $out2x"
done

# Contents.json for macOS
cat > "$OUT/Contents.json" << 'JSON'
{
  "images" : [
    { "idiom" : "mac", "size" : "16x16",   "scale" : "1x", "filename" : "icon_16x16.png" },
    { "idiom" : "mac", "size" : "16x16",   "scale" : "2x", "filename" : "icon_16x16@2x.png" },
    { "idiom" : "mac", "size" : "32x32",   "scale" : "1x", "filename" : "icon_32x32.png" },
    { "idiom" : "mac", "size" : "32x32",   "scale" : "2x", "filename" : "icon_32x32@2x.png" },
    { "idiom" : "mac", "size" : "128x128", "scale" : "1x", "filename" : "icon_128x128.png" },
    { "idiom" : "mac", "size" : "128x128", "scale" : "2x", "filename" : "icon_128x128@2x.png" },
    { "idiom" : "mac", "size" : "256x256", "scale" : "1x", "filename" : "icon_256x256.png" },
    { "idiom" : "mac", "size" : "256x256", "scale" : "2x", "filename" : "icon_256x256@2x.png" },
    { "idiom" : "mac", "size" : "512x512", "scale" : "1x", "filename" : "icon_512x512.png" },
    { "idiom" : "mac", "size" : "512x512", "scale" : "2x", "filename" : "icon_512x512@2x.png" }
  ],
  "info" : { "version" : 1, "author" : "xcode" }
}
JSON

echo "AppIcon.appiconset ready at $OUT"
