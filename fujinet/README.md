# VICE + FujiNet-PC

Runs FujiNet's IEC devices, served by FujiNet-PC, on VICE's emulated serial bus:

    C64 program -> KERNAL -> VICE real-device support -> opencbm-netiec (this directory)
                -> NetIEC over TCP -> FujiNet-PC (FUJINET_TARGET=IEC) -> FujiNet IEC devices

VICE changes on this branch (in `vice/src`): units 12-30 can be real devices
(`-realdevice12` ... `-realdevice30`, resources `RealDevice12` ...), and the
KERNAL traps and the real-device calls carry 5-bit device numbers, so FujiNet's
network (16), clock (29) and FujiNet (30) devices are reachable. They work
through the KERNAL traps, so a stock KERNAL is needed.

## Build

FujiNet-PC (fujinet-firmware):

    ./build.sh -p IEC -g
    cd build/dist && ./run-fujinet      # NetIEC on localhost:1541

VICE (needs `xa`, `dos2unix` and GNU bison, e.g. `brew install xa dos2unix bison`):

    cd vice && ./autogen.sh
    mkdir ../../build-sdl2 && cd ../../build-sdl2
    ../svn-mirror/vice/configure --enable-sdl2ui --disable-pdf-docs --disable-html-docs \
        YACC="$(brew --prefix bison)/bin/bison -y"
    make -j

The bridge:

    make -C fujinet/opencbm-netiec

## Run

    fujinet/run-vice-fujinet.sh                          # devices 16, 29, 30
    FUJINET_UNITS="12 16 29 30" fujinet/run-vice-fujinet.sh

Then, on the C64, fujinet-lib programs work as on hardware, and with unit 12
handed over, `LOAD"CONFIG.PRG",12` and `RUN` start the FujiNet CONFIG program
from FujiNet-PC's flash directory.

To boot from FujiNet as drive 8, hand over unit 8 too; the launcher removes
VICE's own drive 8 for it. Disk images and programs mounted from TNFS hosts
then load with `LOAD"*",8`:

    FUJINET_UNITS="8 16 29 30" fujinet/run-vice-fujinet.sh

## Release

`release/` builds `VICE-FN_AppleSilicon`, a signed and notarized folder with
VICE, FujiNet-PC and a start app for Apple silicon Macs; see
[release/README.md](release/README.md).

## Limits

- Only the standard IEC protocol: no JiffyDOS or other fast loaders, and no
  line-level IEC device for units above 11.
- Programs built with fujinet-lib before the firmware's FujiIECPacket and unified
  N: device (#1541, #1624) speak the old text protocol to device 16 and fail
  their network calls against current FujiNet-PC, as they would on hardware.
