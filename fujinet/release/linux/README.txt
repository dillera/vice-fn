VICE FujiNet for Debian and Ubuntu
==================================

VICE, the Commodore 64 emulator, with FujiNet-PC on its serial bus. The
emulated C64 gets FujiNet: CONFIG, disk images and programs from TNFS servers,
network apps, and the clock.

Each .deb is built for one distribution release and architecture, which its
file name gives, e.g. vice-fujinet_1.0_ubuntu24.04_amd64.deb.


Getting started
---------------
1. Install the package; apt fetches the libraries it needs:

       sudo apt install ./vice-fujinet_1.0_ubuntu24.04_amd64.deb

2. Start "VICE FujiNet" from your desktop's menu, or run vice-fujinet in a
   terminal. It starts FujiNet-PC, then VICE. When you quit VICE, FujiNet-PC
   stops too.

3. In VICE, load CONFIG from FujiNet and run it:

       LOAD"CONFIG.PRG",8
       RUN

   Pick a host, a disk image or program, and a drive slot. Press RETURN on
   the drive slots screen to boot what you mounted.

VICE's menu is on F12. FujiNet-PC's web page, for its settings and host list,
is at http://localhost:8064 while it runs.


Devices
-------
   8   FujiNet's drive: CONFIG, and the disk images you mount
  16   network (N:)
  29   clock
  30   FujiNet itself (fujinet-lib talks to it)

VICE's own drives 9-11 still work as usual.


Files
-----
/usr/bin/vice-fujinet          starts FujiNet-PC and VICE; options you give
                               it go to VICE
/opt/vice-fujinet/bin/x64sc    VICE @VICE_VERSION@ (SDL2) with FujiNet support
/opt/vice-fujinet/lib/libopencbm.so
                               the bridge VICE uses to reach FujiNet-PC, over
                               NetIEC on this computer's TCP port 1541
/opt/vice-fujinet/share/vice   VICE's ROMs and keyboard maps
/opt/vice-fujinet/fujinet-pc   FujiNet-PC for the Commodore IEC bus, with the
                               settings, SD card and CONFIG it starts from

Each user's FujiNet-PC runs in ~/.local/share/vice-fujinet/fujinet-pc, with
its own settings (fnconfig.ini) and SD card (SD), copied there the first time.
VICE keeps its settings in ~/.local/share/vice-fujinet/vicerc, apart from any
other VICE's.

Logs: ~/.local/share/vice-fujinet/fujinet-pc/fujinet-pc.log and
      ~/.local/share/vice-fujinet/vice.log


Troubleshooting
---------------
- "FujiNet-PC stopped as soon as it started": another program is using port
  1541 or 8064. fujinet-pc.log has the details.
- If a FujiNet-PC is already running on port 1541, vice-fujinet uses that one
  instead of starting its own.
- To run the two by hand, in one terminal:

      cd ~/.local/share/vice-fujinet/fujinet-pc
      /opt/vice-fujinet/fujinet-pc/fujinet -u http://localhost:8064

  and in a second:

      /opt/vice-fujinet/bin/x64sc \
          -drive8type 0 +drive8truedrive -devicebackend8 2 -trapdevice8 \
          -realdevice16 -realdevice29 -realdevice30


Source and licenses
-------------------
VICE is GPL 2 and the FujiNet firmware GPL 3. This build comes from:

@SOURCES@

The scripts that build these packages are in fujinet/release/linux in the
vice-fn repository, and in source/packaging here.

FujiNet-PC includes Mbed TLS @MBEDTLS_VERSION@ and the other libraries listed in
copyright; their licenses are in licenses/, and the GPL texts in
/usr/share/common-licenses.
