#!/bin/bash
# Build the vice-fujinet .debs: VICE (x64sc, SDL2) with the NetIEC bridge, and
# FujiNet-PC for the IEC bus, started together by the vice-fujinet launcher.
# Each target is built in a Docker container of its distribution release and
# architecture, then installed in a fresh one and smoke tested.
#
#   build-debs.sh [target...]
#
#   A target is <distro><release>-<arch>, e.g. ubuntu24.04-amd64 or
#   debian13-arm64. The default is Ubuntu 24.04 and Debian 13, amd64 and arm64.
#
#   RELEASE_DIR     work and output (default: ~/code/vice-fn/release); the
#                   .debs and their smoke-test screenshots go to
#                   $RELEASE_DIR/out/v<version>
#   VERSION         package version (default: the one in ../VERSION)
#   VICE_REF        the commit of this repository to take VICE and the bridge
#                   from (default: HEAD)
#   FIRMWARE_DIR    fujinet-firmware checkout (default: ~/code/fujinet-firmware)
#   FIRMWARE_REF    its commit to build (default: vice-fn)
#   PUBLISHED       the branch of both repositories that is on GitHub; the
#                   package carries later commits as patches (default:
#                   origin/vice-fn)
#   CONFIG_PRG      the C64 CONFIG program FujiNet-PC serves (default: the
#                   fujinet-config build in ~/code/vice-fn/fujinet-config)
#   CONFIG_SOURCE   where CONFIG_PRG's source is, for the README
#   MAINTAINER      the packages' Maintainer (default: git's user.name and
#                   user.email)
#   DOCKER_CONTEXT  the Docker to build with. On Apple silicon, amd64 builds
#                   want one that runs amd64 code with Rosetta, e.g.
#                     colima start --profile vice-fujinet --vm-type vz \
#                         --vz-rosetta --cpu 8 --memory 12
#                     DOCKER_CONTEXT=colima-vice-fujinet build-debs.sh
set -eo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SRC=$(cd "$HERE/.." && pwd)
SVN=$(cd "$SRC/../.." && pwd)
R=${RELEASE_DIR:-$HOME/code/vice-fn/release}
VERSION=${VERSION:-$(cat "$SRC/VERSION")}
OUT=${OUT:-$R/out/v$VERSION}
W=$R/linux
P=$W/in/pkg
VICE_REF=${VICE_REF:-HEAD}
FW=$(cd "${FIRMWARE_DIR:-$HOME/code/fujinet-firmware}" && pwd)
FW_REF=${FIRMWARE_REF:-vice-fn}
PUBLISHED=${PUBLISHED:-origin/vice-fn}
CONFIG_PRG=${CONFIG_PRG:-$HOME/code/vice-fn/fujinet-config/r2r/c64/config.prg}
CONFIG_SOURCE=${CONFIG_SOURCE:-https://github.com/FujiNetWIFI/fujinet-config/pull/322}
MAINTAINER=${MAINTAINER:-"$(git -C "$SVN" config user.name) <$(git -C "$SVN" config user.email)>"}
TARGETS=${*:-ubuntu24.04-amd64 ubuntu24.04-arm64 debian13-amd64 debian13-arm64}

SOURCE_DIR=$P/source
# shellcheck source=../scripts/sources.sh
. "$SRC/scripts/sources.sh"

echo "=== Sources"
rm -rf "$W/in"
mkdir -p "$P/source/packaging" "$P/icons" "$OUT"
# VICE and the bridge from this repository; the firmware with its history,
# which its version comes from
git -C "$SVN" archive --format=tar --prefix=vice-fn/ "$VICE_REF" vice fujinet/opencbm-netiec |
    tar -x -C "$W/in"
git clone -q --no-checkout "$FW" "$W/in/fujinet-firmware"
git -C "$W/in/fujinet-firmware" checkout -q --detach "$(git -C "$FW" rev-parse "$FW_REF")"

VICE_HEAD=$(git -C "$SVN" log -1 --format=%h "$VICE_REF" -- vice fujinet/opencbm-netiec)
VICE_BASE=$(unpublished "$SVN" "$VICE_REF" vice-fn-unpublished.patch vice fujinet/opencbm-netiec)
FW_HEAD=$(git -C "$FW" rev-parse --short "$FW_REF")
FW_BASE=$(unpublished "$FW" "$FW_REF" fujinet-firmware-unpublished.patch)
{
    source_line VICE "$SVN" "$VICE_BASE" "$VICE_HEAD" vice-fn-unpublished.patch \
        ", with the opencbm-netiec bridge in fujinet/opencbm-netiec"
    source_line FujiNet-PC "$FW" "$FW_BASE" "$FW_HEAD" fujinet-firmware-unpublished.patch \
        ", built with FUJINET_TARGET=IEC"
    printf '  %-11s %s\n' CONFIG "$CONFIG_SOURCE"
} >"$P/sources.txt"
cat "$P/sources.txt"
# The commit the README names
VICE_COMMIT=$VICE_BASE
if [ -f "$P/source/vice-fn-unpublished.patch" ]; then
    VICE_COMMIT=$VICE_HEAD
fi
echo "VICE_COMMIT=$VICE_COMMIT" >"$P/build-info"

cp "$HERE"/{vice-fujinet,vice-fujinet.desktop,README.txt,copyright} "$SRC/CHANGES.txt" "$P/"
cp "$HERE"/{build-in-container.sh,test-in-container.sh} "$P/"
cp "$HERE"/* "$SRC/VERSION" "$SRC/scripts/sources.sh" "$P/source/packaging/"
cp "$SRC"/icon/linux/vice-fujinet-*.png "$P/icons/"
cp "$CONFIG_PRG" "$P/config.prg"
cp "$SRC/launcher/fnconfig.ini" "$P/fnconfig.ini"

failed=""
shots=""
for t in $TARGETS; do
    distro=${t%-*}
    arch=${t##*-}
    case $distro in
        ubuntu*) image=ubuntu:${distro#ubuntu} ;;
        debian*) image=debian:${distro#debian} ;;
        *) echo "Unknown target: $t"; exit 1 ;;
    esac
    deb=vice-fujinet_${VERSION}_${distro}_$arch.deb
    run() {
        docker run --rm --platform "linux/$arch" -v "$W/in:/in:ro" -v "$OUT:/out" \
            -e VERSION="$VERSION" -e DISTRO="$distro" -e DEB="$deb" \
            -e MAINTAINER="$MAINTAINER" -e HOMEPAGE="$(github "$SVN")" \
            "$image" bash "/in/pkg/$1"
    }
    echo "=== $t: building $deb in $image"
    if ! run build-in-container.sh >"$W/$t-build.log" 2>&1; then
        tail -20 "$W/$t-build.log"
        echo "=== $t: the build failed; its log is $W/$t-build.log"
        failed="$failed $t"
        continue
    fi
    echo "=== $t: installing and testing it in a fresh $image"
    if ! run test-in-container.sh >"$W/$t-test.log" 2>&1; then
        tail -30 "$W/$t-test.log"
        echo "=== $t: the smoke test failed; its log is $W/$t-test.log"
        failed="$failed $t"
        continue
    fi
    grep -E '^(ok|FAIL):' "$W/$t-test.log"
    shots="$shots $OUT/${deb%.deb}.png"
done

# VICE stops after a set number of cycles, so the screenshots should all be
# the same; one that isn't shows a target that lists drive 8 differently
if [ "$(for s in $shots; do cksum <"$s"; done | sort -u | wc -l)" -gt 1 ]; then
    echo "=== The smoke-test screenshots differ between targets:$shots"
    failed="$failed (screenshots)"
fi
if [ -n "$failed" ]; then
    echo "=== Failed:$failed"
    exit 1
fi
sha256=sha256sum
command -v sha256sum >/dev/null || sha256="shasum -a 256"
(cd "$OUT" && $sha256 vice-fujinet_"${VERSION}"_*.deb >"vice-fujinet_${VERSION}_SHA256SUMS")
echo "=== Done: $OUT"
