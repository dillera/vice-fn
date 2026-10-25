#!/bin/bash
# Run fujinet-lib's C64 tests (fujinet/fntest) against a vice-fujinet .deb.
# Each test gets a fresh container of the package's release, with the
# package installed and started by vice-fujinet, so every test starts from
# the shipped settings. The results go to fntest/results.md like any other
# run, with the .deb's name as the firmware, and each test's fujinet-pc log
# next to its screen in fntest/runs.
#
#   fntest-deb.sh <.deb> [test...]
#
#   PRG_DIR         the test programs (default: fntest/prg/c64)
#   PORT            the host port for VICE's monitor (default: 6511, so a VICE
#                   on 6510 can keep running)
#   DOCKER_CONTEXT  as for build-debs.sh
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
FNTEST=$(cd "$HERE/../../fntest" && pwd)
if [ ! -f "${1:-}" ]; then
    echo "usage: $(basename "$0") <.deb> [test...]" >&2
    exit 1
fi
DEB_DIR=$(cd "$(dirname "$1")" && pwd)
DEB=$(basename "$1")
shift
NAME=${DEB%.deb}         # vice-fujinet_1.1_ubuntu24.04_amd64
ARCH=${NAME##*_}
DISTRO=${NAME%_*}
DISTRO=${DISTRO##*_}
case $DISTRO in
    ubuntu*) IMAGE=ubuntu:${DISTRO#ubuntu} ;;
    debian*) IMAGE=debian:${DISTRO#debian} ;;
    *) echo "Can't tell the release from $DEB" >&2; exit 1 ;;
esac
PRG_DIR=${PRG_DIR:-$FNTEST/prg/c64}
PORT=${PORT:-6511}
TAG=vice-fujinet-fntest:$DISTRO-$ARCH
C=vice-fujinet-fntest

docker rm -f $C >/dev/null 2>&1
docker run --platform "linux/$ARCH" --name $C -v "$DEB_DIR:/deb:ro" "$IMAGE" bash -c \
    "apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
     --no-install-recommends /deb/$DEB >/dev/null && useradd -m tester" || exit 1
docker commit $C "$TAG" >/dev/null
docker rm $C >/dev/null

tests=${*:-$(cd "$PRG_DIR" && ls ./*.prg | sed -e 's#^\./##' -e 's/\.prg$//')}
for t in $tests; do
    docker run -d --rm --platform "linux/$ARCH" --name $C -p "127.0.0.1:$PORT:6510" \
        -v "$PRG_DIR:$PRG_DIR:ro" "$TAG" runuser -u tester -- \
        env SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy vice-fujinet -sounddev dummy \
        -remotemonitor -remotemonitoraddress ip4://0.0.0.0:6510 >/dev/null || exit 1
    # Docker's port forward accepts before VICE listens: wait for the monitor
    for _ in $(seq 60); do
        printf 'x\n' | nc -w 2 127.0.0.1 "$PORT" 2>/dev/null | grep -q 'C:' && break
        sleep 1
    done
    VMON_PORT=$PORT PRG_DIR=$PRG_DIR FIRMWARE_LABEL=$NAME "$FNTEST/run-fntests.sh" "$t"
    run=$(ls -td "$FNTEST"/runs/*/ | head -1)
    docker exec $C cat /home/tester/.local/share/vice-fujinet/fujinet-pc/fujinet-pc.log \
        >"$run/$t.log" 2>/dev/null
    docker rm -f $C >/dev/null
done
docker rmi "$TAG" >/dev/null
