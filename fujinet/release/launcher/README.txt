VICE-FN for Apple silicon Macs
==============================

Version @VERSION@. CHANGES.txt lists what changed in each version.

VICE, the Commodore 64 emulator, with FujiNet-PC on its serial bus. The
emulated C64 gets FujiNet: CONFIG, disk images and programs from TNFS servers,
network apps, and the clock.

Needs a Mac with Apple silicon (M1 or later) and macOS 13 Ventura or later.
Everything here is signed with a Developer ID and notarized by Apple.


Getting started
---------------
1. Copy the VICE-FN_AppleSilicon folder to a place you can write to, such as
   your Applications folder or your home folder. FujiNet-PC keeps its settings
   and its SD card in the folder, so it can't run from the disk image.

   Upgrading: to keep your settings and SD card, copy fnconfig.ini and SD
   from the old folder's FujiNet-PC into the new one's.

2. Double-click "Start VICE-FN". It starts FujiNet-PC, then VICE. When you
   quit VICE, FujiNet-PC stops too.

3. In VICE, load CONFIG from FujiNet and run it:

       LOAD"CONFIG.PRG",8
       RUN

   Pick a host, a disk image or program, and a drive slot. Press RETURN on
   the drive slots screen to boot what you mounted.

FujiNet-PC's web page, for its settings and host list, is at
http://localhost:8064 while it runs.


Devices
-------
   8   FujiNet's drive: CONFIG, and the disk images you mount
  16   network (N:)
  29   clock
  30   FujiNet itself (fujinet-lib talks to it)

VICE's own drives 9-11 still work as usual.


What's in the folder
--------------------
Start VICE-FN.app        starts FujiNet-PC and VICE
CHANGES.txt              what changed in each version
VICE/x64sc               VICE 3.10 (SDL2 build) with FujiNet support
VICE/libopencbm.dylib    the bridge VICE uses to reach FujiNet-PC, over
                         NetIEC on this Mac's TCP port 1541
VICE/data                VICE's ROMs and keyboard maps
FujiNet-PC/fujinet       FujiNet-PC for the Commodore IEC bus
FujiNet-PC/fnconfig.ini  FujiNet-PC's settings
FujiNet-PC/SD            FujiNet-PC's SD card
FujiNet-PC/data          CONFIG and the other files FujiNet-PC serves
source/                  source of the parts not on GitHub, and licenses

Logs: FujiNet-PC/fujinet-pc.log and VICE/vice.log


Troubleshooting
---------------
- "FujiNet-PC stopped as soon as it started": another program is using
  port 1541 or 8064. FujiNet-PC/fujinet-pc.log has the details.
- If a FujiNet-PC is already running on port 1541, Start VICE-FN uses that
  one instead of starting its own.
- To run the two by hand in Terminal, from the VICE-FN_AppleSilicon folder:

      cd FujiNet-PC && ./run-fujinet -u http://localhost:8064

  and in a second window:

      cd VICE && DYLD_LIBRARY_PATH="$PWD" ./x64sc -directory data \
          -drive8type 0 +drive8truedrive -devicebackend8 2 -trapdevice8 \
          -realdevice16 -realdevice29 -realdevice30


Source and licenses
-------------------
VICE is GPL 2 and the FujiNet firmware GPL 3. This build comes from:

@SOURCES@

The scripts that build, sign and notarize this folder are in fujinet/release
in the vice-fn repository.

They're built with SDL2 2.32.10 and SDL2_image 2.8.12 (zlib license),
Mbed TLS 3.6.7 and OpenSSL 3.5.9 (Apache 2.0). Their licenses, and those of
the libraries FujiNet-PC includes, are in source/licenses.
