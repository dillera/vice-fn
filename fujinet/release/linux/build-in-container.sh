#!/bin/bash
# Build the vice-fujinet .deb inside a container of the distribution release
# it is for; build-debs.sh runs it. Reads /in (the sources and pkg/, this
# directory's files) and writes /out/$DEB.
#
#   VERSION     package version, e.g. 1.1
#   DISTRO      the release the package is for, e.g. ubuntu24.04
#   DEB         the .deb's file name
#   MAINTAINER  the package's Maintainer field
#   HOMEPAGE    the package's Homepage field
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

PREFIX=/opt/vice-fujinet
B=/build
ROOT=$B/root
PKG=/in/pkg
ARCH=$(dpkg --print-architecture)
# In subshells: os-release has a VERSION of its own
OS_NAME=$(. /etc/os-release && echo "$PRETTY_NAME")
CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")

echo "=== Build dependencies ($OS_NAME, $ARCH)"
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
    build-essential autoconf automake bison flex xa65 dos2unix pkg-config texinfo file \
    libsdl2-dev libsdl2-image-dev libpng-dev zlib1g-dev libcurl4-openssl-dev \
    libasound2-dev libpulse-dev \
    cmake python3 python-is-python3 python3-jinja2 python3-yaml git ca-certificates \
    libmbedtls-dev libssl-dev libexpat1-dev dpkg-dev >/dev/null
git config --global --add safe.directory '*'
mkdir -p $B
cp -a /in/vice-fn /in/fujinet-firmware $B/

# A step failed: show why, and keep the build's logs next to the .deb
failed() {
    echo "=== $1 failed:"
    grep -h -E ': (fatal )?error:|Error [0-9]+|Killed|internal compiler error|Segmentation fault' \
        "$2" | head -20 || true
    tail -20 "$2"
    mkdir -p "/out/${DEB%.deb}-logs"
    cp $B/*.log "/out/${DEB%.deb}-logs/"
    exit 1
}

echo "=== NetIEC bridge"
make -C $B/vice-fn/fujinet/opencbm-netiec libopencbm.so

echo "=== VICE"
# --disable-arch: no -march=native, so the binary runs on any CPU of its
# architecture, not just the build machine's
(cd $B/vice-fn/vice && ./autogen.sh) >$B/vice-autogen.log 2>&1
mkdir -p $B/build-vice
cd $B/build-vice
$B/vice-fn/vice/configure --prefix=$PREFIX --enable-sdl2ui --disable-arch \
    --disable-pdf-docs --disable-html-docs LDFLAGS="-Wl,-rpath,$PREFIX/lib" \
    >$B/vice-configure.log 2>&1 || failed "VICE's configure" $B/vice-configure.log
make -j"$(nproc)" >$B/vice-make.log 2>&1 || failed "VICE's make" $B/vice-make.log
VICE_VERSION=$(sed -n 's/^#define VERSION "\(.*\)"/\1/p' src/config.h)
echo "VICE $VICE_VERSION"

echo "=== FujiNet-PC"
cd $B/fujinet-firmware
cmake -S . -B build -DFUJINET_TARGET=IEC -DCMAKE_BUILD_TYPE=Release >$B/fujinet-cmake.log 2>&1 ||
    failed "FujiNet-PC's cmake" $B/fujinet-cmake.log
cmake --build build -j"$(nproc)" >$B/fujinet-build.log 2>&1 ||
    failed "FujiNet-PC's build" $B/fujinet-build.log
cmake --build build --target dist >$B/fujinet-dist.log 2>&1 ||
    failed "FujiNet-PC's dist" $B/fujinet-dist.log
(cd build && ctest --output-on-failure | tail -3)
FW_DESCRIBE=$(git describe --tags --always)
MBEDTLS_VERSION=$(dpkg-query -W -f='${Version}' libmbedtls-dev | sed 's/-.*//')

echo "=== Package tree"
rm -rf $ROOT
install -d $ROOT$PREFIX/bin $ROOT$PREFIX/lib $ROOT$PREFIX/share/vice $ROOT$PREFIX/fujinet-pc
install -m 755 $B/build-vice/src/x64sc $ROOT$PREFIX/bin/
install -m 644 $B/vice-fn/fujinet/opencbm-netiec/libopencbm.so $ROOT$PREFIX/lib/
# VICE's data as its make install has it, for the C64 only
make -C $B/build-vice/data install DESTDIR=$B/vice-install >/dev/null
for d in C64 DRIVES PRINTER common; do
    cp -R $B/vice-install$PREFIX/share/vice/$d $ROOT$PREFIX/share/vice/
done
# FujiNet-PC, with the C64 CONFIG program and the shipped settings
cp -R $B/fujinet-firmware/build/dist/{fujinet,data,SD} $ROOT$PREFIX/fujinet-pc/
cp $PKG/config.prg $ROOT$PREFIX/fujinet-pc/data/config.prg
cp $PKG/fnconfig.ini $ROOT$PREFIX/fujinet-pc/fnconfig.ini
strip --strip-unneeded $ROOT$PREFIX/bin/x64sc $ROOT$PREFIX/lib/libopencbm.so \
    $ROOT$PREFIX/fujinet-pc/fujinet
cat >$ROOT$PREFIX/VERSION <<EOF
vice-fujinet $VERSION for $DISTRO $ARCH
VICE $VICE_VERSION, vice-fn $(sed -n 's/^VICE_COMMIT=//p' $PKG/build-info)
FujiNet-PC $FW_DESCRIBE
EOF

install -D -m 755 $PKG/vice-fujinet $ROOT/usr/bin/vice-fujinet
install -D -m 644 $PKG/vice-fujinet.desktop $ROOT/usr/share/applications/vice-fujinet.desktop
for png in $PKG/icons/vice-fujinet-*.png; do
    s=$(basename "$png" .png)
    s=${s##*-}
    install -D -m 644 "$png" $ROOT/usr/share/icons/hicolor/${s}x$s/apps/vice-fujinet.png
done

DOC=$ROOT/usr/share/doc/vice-fujinet
install -d $DOC/licenses
sed -e "s/@VERSION@/$VERSION/g" -e "s/@VICE_VERSION@/$VICE_VERSION/" \
    -e "s/@MBEDTLS_VERSION@/$MBEDTLS_VERSION/" \
    -e '/@SOURCES@/{' -e "r $PKG/sources.txt" -e 'd' -e '}' $PKG/README.txt >$DOC/README.txt
cp $PKG/CHANGES.txt $DOC/CHANGES.txt
cp $PKG/copyright $DOC/copyright
cp -R $PKG/source $DOC/source
cp $B/vice-fn/vice/COPYING $DOC/licenses/VICE-COPYING.txt
cp $B/fujinet-firmware/LICENSE $DOC/licenses/FujiNet-firmware-LICENSE.txt
for c in cJSON libnfs libsmb2 libssh miniaudio mongoose; do
    for f in $B/fujinet-firmware/components_pc/$c/{LICENSE,COPYING}; do
        if [ -f "$f" ]; then cp "$f" "$DOC/licenses/$c-$(basename "$f").txt"; fi
    done
done
cp "$(ls /usr/share/doc/libmbedtls-dev/copyright /usr/share/doc/libmbed*/copyright 2>/dev/null |
    head -1)" $DOC/licenses/MbedTLS-copyright.txt
{
    echo "vice-fujinet ($VERSION-1~$DISTRO) $CODENAME; urgency=medium"
    echo
    echo "  * VICE $VICE_VERSION (x64sc, SDL2) with the NetIEC bridge, and"
    echo "    FujiNet-PC $FW_DESCRIBE for the IEC bus."
    echo
    echo " -- $MAINTAINER  $(date -R)"
} | gzip -9n >$DOC/changelog.Debian.gz

find $ROOT -type d -exec chmod 755 {} +
find $ROOT -type f -exec chmod 644 {} +
chmod 755 $ROOT/usr/bin/vice-fujinet $ROOT$PREFIX/bin/x64sc $ROOT$PREFIX/fujinet-pc/fujinet

echo "=== Control"
# dpkg-shlibdeps wants a debian/control to read
mkdir -p $B/shlibs/debian
printf 'Source: vice-fujinet\n\nPackage: vice-fujinet\nArchitecture: any\n' >$B/shlibs/debian/control
DEPENDS=$(cd $B/shlibs && dpkg-shlibdeps -O --warnings=0 \
    $ROOT$PREFIX/bin/x64sc $ROOT$PREFIX/lib/libopencbm.so $ROOT$PREFIX/fujinet-pc/fujinet |
    sed -n 's/^shlibs:Depends=//p')
mkdir -p $ROOT/DEBIAN
# FujiNet-PC checks HTTPS servers against /etc/ssl/certs/ca-certificates.crt
cat >$ROOT/DEBIAN/control <<EOF
Package: vice-fujinet
Version: $VERSION-1~$DISTRO
Architecture: $ARCH
Maintainer: $MAINTAINER
Installed-Size: $(du -ks $ROOT | cut -f1)
Depends: $DEPENDS, ca-certificates
Suggests: zenity
Section: otherosfs
Priority: optional
Homepage: $HOMEPAGE
Description: VICE C64 emulator with FujiNet-PC on its serial bus
 VICE $VICE_VERSION (x64sc, SDL2) with a NetIEC bridge, and FujiNet-PC built
 for the Commodore IEC bus, started together by vice-fujinet. The emulated C64
 gets FujiNet: CONFIG, disk images and programs from TNFS servers, network
 apps, and the clock.
 .
 It installs in /opt/vice-fujinet, next to any other VICE.
EOF
(cd $ROOT && find . -path ./DEBIAN -prune -o -type f -printf '%P\0' | xargs -0 md5sum) \
    >$ROOT/DEBIAN/md5sums
chmod 644 $ROOT/DEBIAN/control $ROOT/DEBIAN/md5sums
cat $ROOT/DEBIAN/control

echo "=== $DEB"
dpkg-deb --root-owner-group -Zxz --build $ROOT /out/$DEB
ls -la /out/$DEB
