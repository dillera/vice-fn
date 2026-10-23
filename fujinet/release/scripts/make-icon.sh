#!/bin/bash
# Make icon/AppIcon.icns, the start app's icon: VICE's C64 icon with the
# FujiNet logo in its lower band. Needs rsvg-convert and ImageMagick
# (brew install librsvg imagemagick).
#
#   FUJINET_LOGO  the FujiNet logo SVG (default: the one in ~/code/fujinet-firmware)
set -e

SRC=$(cd "$(dirname "$0")/.." && pwd)
SVN=$(cd "$SRC/../.." && pwd)
LOGO=${FUJINET_LOGO:-$HOME/code/fujinet-firmware/data/webui/template/www/logo.svg}
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

rsvg-convert -w 1024 -h 1024 "$SVN/vice/data/common/vice-x64_1024.svg" -o "$T/c64.png"
rsvg-convert -w 600 "$LOGO" -o "$T/logo.png"
# White logo on the gray band; negating keeps its one hollow stone
magick "$T/logo.png" -channel RGB -negate +channel -resize 500x "$T/logo-white.png"
magick "$T/c64.png" "$T/logo-white.png" -gravity center -geometry +0+405 -composite "$T/icon-1024.png"
# macOS's usual margin around the artwork
magick "$T/icon-1024.png" -resize 840x840 -background none -gravity center -extent 1024x1024 "$T/icon.png"

mkdir "$T/AppIcon.iconset"
for s in 16 32 128 256 512; do
    magick "$T/icon.png" -resize ${s}x${s} "$T/AppIcon.iconset/icon_${s}x${s}.png"
    magick "$T/icon.png" -resize $((s * 2))x$((s * 2)) "$T/AppIcon.iconset/icon_${s}x${s}@2x.png"
done
iconutil -c icns "$T/AppIcon.iconset" -o "$SRC/icon/AppIcon.icns"
echo "=== Done: $SRC/icon/AppIcon.icns"
