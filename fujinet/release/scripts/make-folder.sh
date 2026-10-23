#!/bin/bash
# Assemble VICE-FN_AppleSilicon from the release builds, sign everything with
# the Developer ID, and check the signatures.
#
#   RELEASE_DIR      downloads, builds and output (default: ~/code/vice-fn/release)
#   OUT              where the folder goes (default: $RELEASE_DIR/out)
#   FIRMWARE_PKG     the fujinet-firmware checkout build-fujinet-pc.sh built
#                    (default: ~/code/fujinet-firmware-pkg)
#   CONFIG_PRG       the C64 CONFIG program FujiNet-PC serves (default: the
#                    fujinet-config build in ~/code/vice-fn/fujinet-config)
#   SIGN_IDENTITY    certificate hash or name (default: Developer ID
#                    Application: DILLER & ASSOC LLC (YBX2V97SYB))
#   LAUNCHER_CFLAGS  extra flags for the start app, e.g. other ports for a test
#   BOIP_PORT        NetIEC port written to the folder's fnconfig.ini
set -e

SRC=$(cd "$(dirname "$0")/.." && pwd)
SVN=$(cd "$SRC/../.." && pwd)
R=${RELEASE_DIR:-$HOME/code/vice-fn/release}
OUT=${OUT:-$R/out}
FW=$(cd "${FIRMWARE_PKG:-$HOME/code/fujinet-firmware-pkg}" && pwd)
CONFIG_PRG=${CONFIG_PRG:-$HOME/code/vice-fn/fujinet-config/r2r/c64/config.prg}
IDENTITY=${SIGN_IDENTITY:-07F262C687B818C2CA8586C2B9444E95FDC507BC}
NAME=VICE-FN_AppleSilicon
F=$OUT/$NAME
APP="$F/Start VICE-FN.app"
VERSION=$(date +%Y.%m.%d)
WORK=$R/work

rm -rf "$F"
mkdir -p "$F/VICE/data" "$F/FujiNet-PC" "$F/source/licenses"

# VICE: x64sc, the NetIEC bridge and the data x64sc uses
cp "$R/build-vice/src/x64sc" "$R/build-vice/bridge/libopencbm.dylib" "$F/VICE/"
for d in C64 DRIVES PRINTER common; do
    cp -R "$SVN/vice/data/$d" "$F/VICE/data/"
done
find "$F/VICE/data" \( -name 'Makefile*' -o -name icon_sources \) -prune -exec rm -rf {} +

# FujiNet-PC, with the C64 CONFIG program and the shipped settings
cp "$FW/build/dist/fujinet" "$FW/build/dist/run-fujinet" "$F/FujiNet-PC/"
cp -R "$FW/build/dist/data" "$FW/build/dist/SD" "$F/FujiNet-PC/"
cp "$CONFIG_PRG" "$F/FujiNet-PC/data/config.prg"
# fnconfig.ini has CRLF line endings
perl -pe 'BEGIN { $port = shift } $sect = $1 if /^\[(\w+)\]/;
          s/^port=(\r?)$/port=$port$1/ if $sect eq "BOIP"' \
     "${BOIP_PORT:-}" "$SRC/launcher/fnconfig.ini" > "$F/FujiNet-PC/fnconfig.ini"

# The start app
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
# shellcheck disable=SC2086
clang -O2 -arch arm64 -mmacosx-version-min=13.0 -Wall -Wextra $LAUNCHER_CFLAGS \
      -framework CoreFoundation -o "$APP/Contents/MacOS/start-vice-fn" "$SRC/launcher/start-vice-fn.c"
sed "s/@VERSION@/$VERSION/" "$SRC/launcher/Info.plist" > "$APP/Contents/Info.plist"
cp "$SRC/icon/AppIcon.icns" "$APP/Contents/Resources/"

# Read me, sources of what isn't on GitHub, licenses
cp "$SRC/launcher/README.txt" "$F/"
git -C "$FW" diff HEAD > "$F/source/fujinet-firmware-local-fixes.patch"
cp "$SRC/launcher/start-vice-fn.c" "$F/source/"
L=$F/source/licenses
cp "$SVN/vice/COPYING" "$L/VICE-COPYING.txt"
cp "$FW/LICENSE" "$L/FujiNet-firmware-LICENSE.txt"
cp "$WORK/sdl2/LICENSE.txt" "$L/SDL2-LICENSE.txt"
cp "$WORK/sdl2_image/LICENSE.txt" "$L/SDL2_image-LICENSE.txt"
cp "$WORK/mbedtls/LICENSE" "$L/MbedTLS-LICENSE.txt"
cp "$WORK/openssl/LICENSE.txt" "$L/OpenSSL-LICENSE.txt"
for c in cJSON libnfs libsmb2 libssh miniaudio mongoose; do
    for f in "$FW/components_pc/$c"/LICENSE "$FW/components_pc/$c"/COPYING; do
        [ -f "$f" ] && cp "$f" "$L/$c-$(basename "$f").txt"
    done
done

# Extended attributes (Finder info, quarantine) would break the signatures
xattr -cr "$F"

# Sign from the inside out, with the hardened runtime that notarization needs
sign() { codesign --force --timestamp --options runtime --sign "$IDENTITY" "$@"; }
sign --identifier org.diller.vice-fn.libopencbm "$F/VICE/libopencbm.dylib"
sign --identifier org.diller.vice-fn.x64sc --entitlements "$SRC/launcher/x64sc.entitlements" "$F/VICE/x64sc"
sign --identifier org.diller.vice-fn.fujinet-pc "$F/FujiNet-PC/fujinet"
sign "$APP"

# Every Mach-O file must be signed by us
find "$F" -type f -perm -u+x -o -type f -name '*.dylib' | while read -r f; do
    if file "$f" | grep -q Mach-O; then
        codesign --verify --strict "$f"
        codesign -dv "$f" 2>&1 | grep -q 'TeamIdentifier=YBX2V97SYB' || { echo "Not ours: $f"; exit 1; }
        echo "signed: ${f#"$F"/}"
    fi
done
codesign --verify --deep --strict --verbose=2 "$APP"
echo "=== Done: $F"
