#!/bin/sh
# Start VICE with FujiNet-PC's IEC devices on the emulated serial bus.
#
#   run-vice-fujinet.sh [x64sc|x64|x128|xscpu64] [VICE options...]
#
#   FUJINET_UNITS  device numbers handed to FujiNet-PC (default: 16 29 30, the
#                  network, clock and FujiNet devices; add 8-15 for its drives)
#   VICE_BUILD     VICE build directory holding src/x64sc (default: ../../build-sdl2)
#   NETIEC_HOST, NETIEC_PORT, NETIEC_TRACE are passed to the bridge library

here=$(cd "$(dirname "$0")" && pwd)
build=${VICE_BUILD:-$here/../../build-sdl2}
emu=x64sc

case "$1" in
    x64sc|x64|x128|xscpu64) emu=$1; shift ;;
esac

# -default resets every option given before it, so it has to come first
reset=""
if [ "$1" = "-default" ]; then
    reset="-default"
    shift
fi

# units 8-11 replace VICE's own drives: no drive or true drive emulation,
# OpenCBM backend, traps on
units=""
for unit in ${FUJINET_UNITS:-16 29 30}; do
    case "$unit" in
        8|9|10|11) units="$units -drive${unit}type 0 +drive${unit}truedrive -devicebackend$unit 2 -trapdevice$unit" ;;
        *) units="$units -realdevice$unit" ;;
    esac
done

bridge="$here/opencbm-netiec"
if [ ! -f "$bridge/libopencbm.dylib" ] && [ ! -f "$bridge/libopencbm.so" ]; then
    make -C "$bridge" >/dev/null || exit 1
fi

DYLD_LIBRARY_PATH="$bridge${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
LD_LIBRARY_PATH="$bridge${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
exec "$build/src/$emu" $reset -directory "$here/../vice/data" $units "$@"
