#!/bin/bash
# Build fujinet-pc (FUJINET_TARGET=IEC, Release) for the release folder: arm64,
# macOS 13 and later, with Mbed TLS and OpenSSL linked statically from
# build-deps.sh.
#
#   RELEASE_DIR   downloads, builds and output (default: ~/code/vice-fn/release)
#   FIRMWARE_PKG  the fujinet-firmware checkout to build; a worktree of the
#                 tested commit keeps the release apart from ongoing work
#                 (default: ~/code/fujinet-firmware-pkg)
#   FIRMWARE_DIR  a fujinet-firmware checkout whose build/.venv runs the
#                 build's Python steps (default: ~/code/fujinet-firmware)
set -e

R=${RELEASE_DIR:-$HOME/code/vice-fn/release}
FW=$(cd "${FIRMWARE_PKG:-$HOME/code/fujinet-firmware-pkg}" && pwd)
DEPS=$R/deps
MIN=13.0

export MACOSX_DEPLOYMENT_TARGET=$MIN
export PKG_CONFIG_LIBDIR=$DEPS/lib/pkgconfig # nothing from Homebrew
export PATH=${FIRMWARE_DIR:-$HOME/code/fujinet-firmware}/build/.venv/bin:$PATH

mkdir -p "$FW/build"
cd "$FW/build"
cmake .. -DFUJINET_TARGET=IEC -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET=$MIN \
      -DMBEDTLS_ROOT_DIR="$DEPS" \
      -DOPENSSL_ROOT_DIR="$DEPS" -DOPENSSL_USE_STATIC_LIBS=TRUE
cmake --build . -j10
cmake --build . --target dist
ctest --output-on-failure

echo "=== Done: $FW/build/dist"
