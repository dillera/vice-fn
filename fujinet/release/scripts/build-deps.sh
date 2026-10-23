#!/bin/bash
# Build the libraries VICE and fujinet-pc need, as static arm64 libraries for
# macOS 13 and later, into $RELEASE_DIR/deps. Homebrew's own builds target the
# running macOS, so bundling them would shut out older Macs.
#
#   RELEASE_DIR  downloads, builds and output (default: ~/code/vice-fn/release)
set -e

R=${RELEASE_DIR:-$HOME/code/vice-fn/release}
PREFIX=$R/deps
WORK=$R/work
export MACOSX_DEPLOYMENT_TARGET=13.0
CMAKE_ARGS=(-DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX"
            -DCMAKE_PREFIX_PATH="$PREFIX" -DCMAKE_OSX_ARCHITECTURES=arm64
            -DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET)

SDL2=2.32.10
SDL2_IMAGE=2.8.12
MBEDTLS=3.6.7
OPENSSL=3.5.9

mkdir -p "$PREFIX" "$WORK"

# fetch <dir> <url> <sha256>: download a source tarball once, check it, and
# print its path
fetch() {
    local file
    file=$R/src/$1/$(basename "$2")

    if [ ! -f "$file" ]; then
        mkdir -p "$R/src/$1"
        curl -fsSL -o "$file" "$2" || return 1
    fi
    if ! echo "$3  $file" | shasum -a 256 -c - >/dev/null; then
        echo "Checksum mismatch: $file" >&2
        return 1
    fi
    echo "$file"
}

# unpack <tarball> <dir name>: a fresh copy of the sources in work/
unpack() {
    rm -rf "${WORK:?}/$2"
    mkdir -p "$WORK/$2"
    tar -xf "$1" -C "$WORK/$2" --strip-components 1
}

echo "=== SDL2 $SDL2"
f=$(fetch sdl2 https://github.com/libsdl-org/SDL/releases/download/release-$SDL2/SDL2-$SDL2.tar.gz \
          5f5993c530f084535c65a6879e9b26ad441169b3e25d789d83287040a9ca5165)
unpack "$f" sdl2
cmake -S "$WORK/sdl2" -B "$WORK/sdl2/build" "${CMAKE_ARGS[@]}" \
      -DSDL_SHARED=OFF -DSDL_STATIC=ON -DSDL_TEST=OFF
cmake --build "$WORK/sdl2/build" -j10
cmake --install "$WORK/sdl2/build"

echo "=== SDL2_image $SDL2_IMAGE"
f=$(fetch sdl2_image https://github.com/libsdl-org/SDL_image/releases/download/release-$SDL2_IMAGE/SDL2_image-$SDL2_IMAGE.tar.gz \
          393f5efb50536ec13ca4f4affb69cc9966d3c3f969e6c5e701faddf9f9785381)
unpack "$f" sdl2_image
# PNG and JPEG through the bundled stb_image; no other image libraries
cmake -S "$WORK/sdl2_image" -B "$WORK/sdl2_image/build" "${CMAKE_ARGS[@]}" \
      -DBUILD_SHARED_LIBS=OFF -DSDL2IMAGE_SAMPLES=OFF -DSDL2IMAGE_TESTS=OFF \
      -DSDL2IMAGE_VENDORED=OFF -DSDL2IMAGE_BACKEND_STB=ON -DSDL2IMAGE_BACKEND_IMAGEIO=OFF \
      -DSDL2IMAGE_AVIF=OFF -DSDL2IMAGE_JXL=OFF -DSDL2IMAGE_TIF=OFF -DSDL2IMAGE_WEBP=OFF
cmake --build "$WORK/sdl2_image/build" -j10
cmake --install "$WORK/sdl2_image/build"

echo "=== Mbed TLS $MBEDTLS"
f=$(fetch mbedtls https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-$MBEDTLS/mbedtls-$MBEDTLS.tar.bz2 \
          a7e8bcbec0e6f761b4af24f25677626b35f762f68eef79c08677a363212d11f6)
unpack "$f" mbedtls
# The same configuration as Homebrew's mbedtls@3, which fujinet-pc is tested with
sed -i '' -e 's|//#define MBEDTLS_THREADING_PTHREAD|#define MBEDTLS_THREADING_PTHREAD|' \
          -e 's|//#define MBEDTLS_THREADING_C|#define MBEDTLS_THREADING_C|' \
          -e 's|//#define MBEDTLS_SSL_DTLS_SRTP|#define MBEDTLS_SSL_DTLS_SRTP|' \
          "$WORK/mbedtls/include/mbedtls/mbedtls_config.h"
cmake -S "$WORK/mbedtls" -B "$WORK/mbedtls/build" "${CMAKE_ARGS[@]}" \
      -DUSE_SHARED_MBEDTLS_LIBRARY=OFF -DUSE_STATIC_MBEDTLS_LIBRARY=ON \
      -DENABLE_PROGRAMS=OFF -DENABLE_TESTING=OFF -DGEN_FILES=OFF
cmake --build "$WORK/mbedtls/build" -j10
cmake --install "$WORK/mbedtls/build"

echo "=== OpenSSL $OPENSSL"
f=$(fetch openssl https://github.com/openssl/openssl/releases/download/openssl-$OPENSSL/openssl-$OPENSSL.tar.gz \
          603f5602e2eef00d77fbd429d34dcd5822bb301757a1bc9cdb24c670f1eb859a)
unpack "$f" openssl
(cd "$WORK/openssl" &&
 ./Configure darwin64-arm64-cc no-shared no-tests no-docs \
             --prefix="$PREFIX" --openssldir="$PREFIX/ssl" --libdir=lib \
             -mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET &&
 make -j10 && make install_sw)

echo "=== Done: $PREFIX"
