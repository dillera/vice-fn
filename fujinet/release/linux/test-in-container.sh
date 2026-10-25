#!/bin/bash
# Install /out/$DEB in a fresh container of the release it is for, and smoke
# test it as a user would run it; build-debs.sh runs it. vice-fujinet starts
# FujiNet-PC and a headless VICE, which lists FujiNet's drive 8 and saves a
# screenshot of the listing next to the .deb.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq --no-install-recommends "/out/$DEB" >/dev/null
dpkg-query -W -f='installed ${Package} ${Version}\n' vice-fujinet
for f in /opt/vice-fujinet/bin/x64sc /opt/vice-fujinet/lib/libopencbm.so \
         /opt/vice-fujinet/fujinet-pc/fujinet; do
    if ldd "$f" | grep "not found"; then
        echo "FAIL: $f is missing libraries"
        exit 1
    fi
done

useradd -m tester
runuser -u tester -- env SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy vice-fujinet \
    -sounddev dummy -warp -keybuf 'load"$",8\nlist\n' -limitcycles 40000000 \
    -exitscreenshot /tmp/smoke.png || true

H=/home/tester/.local/share/vice-fujinet
fail=0
check() {
    if eval "$2"; then echo "ok: $1"; else echo "FAIL: $1"; fail=1; fi
}
check "the user's FujiNet-PC folder has the shipped host list" \
    "grep -q fujinet.online $H/fujinet-pc/fnconfig.ini"
check "FujiNet-PC started" "[ -s $H/fujinet-pc/fujinet-pc.log ]"
check "VICE found its keyboard maps" "! grep -q 'Default keymap not found' $H/vice.log"
check "VICE saved a screenshot" "[ -s /tmp/smoke.png ]"
check "FujiNet-PC stopped with VICE" "! grep -qx fujinet /proc/[0-9]*/comm 2>/dev/null"
cp /tmp/smoke.png "/out/${DEB%.deb}.png" 2>/dev/null || true
if [ $fail -ne 0 ]; then
    tail -20 $H/vice.log $H/fujinet-pc/fujinet-pc.log
    exit 1
fi
echo "=== Smoke test passed: $DEB"
