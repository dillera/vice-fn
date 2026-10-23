#!/bin/bash
# Build x64sc (SDL2 UI) and the NetIEC bridge from this checkout for the
# release folder: arm64, macOS 13 and later, linked only against system
# libraries and the static libraries from build-deps.sh.
#
#   RELEASE_DIR  downloads, builds and output (default: ~/code/vice-fn/release)
set -e

SRC=$(cd "$(dirname "$0")/.." && pwd)
SVN=$(cd "$SRC/../.." && pwd)
R=${RELEASE_DIR:-$HOME/code/vice-fn/release}
DEPS=$R/deps
BUILD=$R/build-vice
MIN=13.0

export MACOSX_DEPLOYMENT_TARGET=$MIN
export PKG_CONFIG_LIBDIR=$DEPS/lib/pkgconfig # nothing from Homebrew
pc() { pkg-config "$@"; }

mkdir -p "$BUILD"
cd "$BUILD"
if [ ! -f Makefile ]; then
    # The ac_cv_ overrides stop configure adding Homebrew's include and
    # library paths, and libintl for netplay.
    "$SVN/vice/configure" --enable-sdl2ui --disable-pdf-docs --disable-html-docs \
        --without-libusb --without-png \
        YACC="$(brew --prefix bison)/bin/bison -y" \
        CFLAGS="-O2 -mmacosx-version-min=$MIN" \
        CXXFLAGS="-O2 -mmacosx-version-min=$MIN" \
        OBJCFLAGS="-O2 -mmacosx-version-min=$MIN" \
        LDFLAGS="-mmacosx-version-min=$MIN" \
        SDL2_CFLAGS="$(pc --cflags sdl2)" \
        SDL2_LIBS="-L$DEPS/lib -lSDL2main $(pc --static --libs sdl2)" \
        SDL2_IMAGE_CFLAGS="$(pc --cflags SDL2_image)" \
        SDL2_IMAGE_LIBS="$(pc --static --libs SDL2_image)" \
        libcurl_CFLAGS=" " libcurl_LIBS="-lcurl" \
        ac_cv_file__opt_homebrew_include=no ac_cv_file__opt_homebrew_lib=no \
        ac_cv_file__opt_homebrew_include_libomp=no ac_cv_file__opt_homebrew_lib_libomp=no \
        ac_cv_lib_intl_dgettext=no
fi
make -j10

# The bridge VICE loads for real devices
BRIDGE=$SVN/fujinet/opencbm-netiec
make -C "$BRIDGE" clean
make -C "$BRIDGE" libopencbm.dylib CFLAGS="-O2 -mmacosx-version-min=$MIN"
mkdir -p "$BUILD/bridge"
mv "$BRIDGE/libopencbm.dylib" "$BUILD/bridge/"
# Put back the developer build that run-vice-fujinet.sh uses
make -C "$BRIDGE" >/dev/null

echo "=== Done: $BUILD/src/x64sc and $BUILD/bridge/libopencbm.dylib"
