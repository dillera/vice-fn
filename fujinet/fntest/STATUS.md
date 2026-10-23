# fntest status: C64 over IEC (VICE + fujinet-pc)

Updated 2026-10-23 17:39. **6 of 14 test programs pass.**

- Tests: fujinet-lib's `tests-latest` release (fujinet-lib v5.0.1, tests commit
  31cea90). They're also on TNFS at `ayce.fozztexx.com/fntest/c64`. Local copies
  are in `prg/c64/`, and the sources are in `~/code/vice-fn/fujinet-lib/testing/tests/`.
  Since the cause E fix the tests are built from source; "How to run" says how.
  - The E and F fixes are committed in fujinet-lib on branch `c64-iec-fixes`:
    189fbdd (tests) and 26d1a03 (C64 bus).
  - Before those commits (17:19), builds showed as `31cea90*`.
- Firmware: `~/code/fujinet-firmware`, branch `vice-fn`. The fixes below are
  committed there, one commit each, as of 17:41.
- This folder is `fujinet/fntest` in the vice-fn repository, and
  `~/code/vice-fn/fntest` links to it.
  - `run-fntests.sh`, this file and `results.md` are in git.
  - `runs/`, `prg/`, the logs and the `fnconfig` copies are not.
- Every program stops at its first failure, so the checks after that point
  haven't run yet. Fixing one failure may expose the next.
- `results.md` logs every run (pass/fail and when). `runs/<date_time>/` holds each
  test's final screen and, from the 15:07 run on, the fujinet-pc log lines it
  produced.

## Per test (full run 2026-10-23 17:28, tests and library built from source, fujinet-pc restarted before each test)

| Test | Result | Passed / failed | First failure | Cause | Fix belongs in |
|---|---|---|---|---|---|
| appkey | PASS | 18 / 0 | | | |
| qrcode | PASS | 22 / 0 | | | |
| wifi | PASS | 18 / 0 | | | |
| clock | PASS | 48 / 0 | | | |
| html | PASS | 98 / 0 (1 skip) | was: decoded body equals ABC (http.c line 91) | E, fixed 16:15 | tests |
| netproto | PASS | 107 / 0 | was: 64 bytes match pattern (line 226) | E, fixed 16:15 | tests |
| netfile | FAIL | 10 / 1 | directory that was never created does not open (line 218) | A | firmware + fujinet-lib, needs design |
| clipbord | FAIL | 12 / 1 | write open on an older snippet fails (line 119) | A | firmware + fujinet-lib, needs design |
| parserr | FAIL | 0 / 1 | bare NET_PARSE with no channel reports an error (line 94) | A | same |
| devlist | FAIL | 3 / 1 | Network 1 online (line 93) | B | fujinet-lib + firmware, needs design |
| network | FAIL | 21 / 1 (1 skip) | N1 DOES NOT have bytes waiting (line 270) | B | same |
| net5plus | FAIL | 2 / 1 | listener reports connection (line 395) | B | same |
| disk | FAIL | 18 / 1 | the new image is the size asked for (line 323); was the new image is on the SD host (line 320), the IEC NEW DISK stub, fixed 17:17; before that fuji_create_new succeeds (line 317), cause F, fixed 16:49; before that SD host slot found (line 74), cause E, fixed | H (the C64 reads a file size as 16 bits), then A (line 331) | fujinet-lib and firmware, needs a decision |
| fujidev | FAIL | 17 / 1 | fuji_mount_host_slot with invalid host fails (line 138); was fuji_put_device_slots round-trip succeeds (line 125), cause F, fixed 16:49 | A | same as A |

With `FNPC_RESTART=1` netfile in a full run shows its real result (10 / 1 at line
218, as on its own). The 15:55 full run, without restarts, showed 2 / 1 at line
269: devlist runs first, stops before it clears its prefixes, and leaves
`/1-check-1/2-check-2/8-check-8/` on the one shared NDevice (cause B), so
netfile's `cd N1:/<guid>` landed in the wrong place.

disk's pass count depends on host slot 2 and on `lobby.dsk` (see E). The copy
test borrows the slot, and does two more checks, when it doesn't already read
`tnfs.fujinet.online`; it does one more when `lobby.dsk` is already on the SD
host (the timestamp check). The 16:52 run's 15 / 1 had the slot already renamed.
With the golden config the slot is borrowed (17:05 on), so the old firmware would
have stopped at line 320 with 17 passed (counted from disk.c, not run again); the
18 now is that plus the new image check. That timestamp check compares the minute
of two copies, so two disk runs in the same minute fail it at line 212.

## Causes

Each cause below was confirmed in the fujinet-pc log from the 15:07 run, except
parserr's, which is likely but not proven. G came from the 15:31 clock run. The
second half of C and netfile's case under A came from the 15:50 to 15:59 netfile
runs. F's fix, and what stops fujidev and disk behind it, come from the 16:49 and
16:52 runs. H, and the rest of the NEW DISK section, come from the disk runs of
17:17 to 17:35 and the c1541 checks.

**A. IEC can't report a refused command.** On IEC,
`systemBus::transaction_error()` does nothing, so the C64 gets `FN_ERR_OK` even
when the firmware refuses a command. For example, the log shows "Snippet 1 is
read only ... Error: 167", but the open still succeeds. fujinet-lib already
marks this as `FN_BROKEN_transaction_error` for the C64, but clipbord and
parserr don't check that flag. The same problem makes `clock_set_tz` and the
net5plus client open report success, and `fuji_mount_host_slot(0xFF)` (fujidev,
line 138) and NEW DISK over a file that exists (disk, line 331, see "NEW DISK on
IEC"). parserr's log shows
the bare NET_PARSE arriving but no error message, so its cause is likely A but not
proven.

netfile stops on A at line 218, "directory that was never created does not
open". Its log (`runs/2026-10-23_155917/netfile.log`) shows the firmware
refusing the open: the WebDAV PROPFIND returns 404, then "Protocol unable to
make connection. Error: 170" (file not found). The C64 still gets `FN_ERR_OK`,
because `network_open()` only checks that the bus write went through (its STATUS
check is under `#if 0`). netfile.c doesn't check `FN_BROKEN_network_open_invalid`,
which fujinet-lib's `broken-v5.h` defines for the C64 together with
`FN_BROKEN_transaction_error`. The checks after line 218 haven't run.

**B. IEC has only one network unit.** fujinet-lib's C64 bus
(`bus/c64/fujinet-bus-c64.c`) sends every N1–N8 command to IEC device 16. For
CD, PWD, STATUS and OPEN, the unit number is lost. The firmware has a single
NDevice on IEC, which causes three failures:
- devlist: N8's directory replaces N1's.
- network: N1 reports N2's waiting bytes.
- net5plus: opening N2 closes N1's listening socket.

A commented-out line in fujinet-bus-c64.c sent each unit on its own channel.
That may be how this was meant to work. The design needs agreement with the
maintainers first.

After fix C, devlist's PWD no longer starts with `N8:`. On a fresh fujinet-pc
the eight `cd N<n>:/<n>-check-<n>` commands build one prefix between them, and N1
reads back `/1-check-1/2-check-2/8-check-8/` where it expects `/1-check-1`
(`runs/2026-10-23_155428/devlist.log`). That is `fujicore_set_prefix()` taking
the third `/` of the prefix as the end of the host: on a prefix with no host, an
absolute cd is appended to what is there instead of replacing it. It only shows
here because all eight cds hit one prefix. The test also stops before it clears
the eight prefixes, so they stay on the shared NDevice and break whatever cds
next (see netfile above).

**C. CD, PWD, the filesystem commands and GENERATE GUID skipped the PETSCII
conversion. Fixed 15:52.** `NDevice::fujidev_set_prefix()` and
`fujidev_get_prefix()` didn't call `nativeTextToUnicode()` or
`unicodeTextToNative()`, but OPEN does. The PETSCII `N1:` (`CE 31 3A`) wasn't
recognized as a device name and stayed in the directory. `fs_op()`, which
rename, delete, lock, unlock, mkdir and rmdir all go through, had the same gap.
- Fix 1: in `lib/device/NDevice/NDevice.cpp`, `fujidev_set_prefix()` and
  `fs_op()` call `nativeTextToUnicode()` as OPEN does, and `fujidev_get_prefix()`
  sends the prefix through `unicodeTextToNative()`. The NDevice README says so.
- Result of fix 1: the log shows `NDevice::set_prefix(/9B8941AA-...)` with no
  `N1:`. It was **not enough** for line 269 (`runs/2026-10-23_155001`). mkdir and
  rmdir parse as `HTTPS://www.webdavserver.net/...` (seen in the 15:52 run).
  rename, delete, lock and unlock use the same code, but netfile hasn't reached
  them.
- Why: `fuji_generate_guid` returns the GUID as ASCII, and the C64 sends it back
  inside the PETSCII devicespec. `toUTF8` reads lowercase ASCII 0x61–0x7A as
  PETSCII shifted letters, so `9b8941aa` became `9B8941AA` in the prefix, and PWD
  sent it back as PETSCII (`C1`–`C6`). The test compares that with its original
  ASCII bytes. The test's GUID is not "ASCII on both sides" once it goes through
  the conversion.
- Fix 2: in `lib/device/fujiDevice/fujiDevice.cpp`, `fujicmd_generate_guid()`
  sends the GUID through `unicodeTextToNative()`, as `HashMixin` does for hex
  digests and `Base64Mixin` for its output. The GUID is then PETSCII lowercase
  (`41`–`46` for a–f), converts back to the same lowercase ASCII, and the PWD
  round trip is exact. The WebDAV directory is created with the lowercase GUID.
- Result of fix 2: netfile goes from 2 passed checks to 10 (`runs/2026-10-23_155259`
  and `runs/2026-10-23_155917`): cd, pwd and "working directory matches" pass,
  and so do the full-URL-with-a-prefix checks, `network_fs_mkdir` (MKCOL returns
  201) and the directory open. It then stops on A at line 218.
- No effect on other buses: both conversions are identity functions there. On
  IEC, a client that relied on an ASCII GUID would now get PETSCII; fujinet-lib
  v5's only users are netfile and crypto.c, which isn't in the C64 set and only
  checks the length and that two GUIDs differ.
- Not changed, same kind of gap: `NET_USERNAME`, `NET_PASSWORD`, the UDP
  destination, and the FujiNet-device commands that take a path
  (`fujicmd_open_directory_success()` reads the path raw; the others haven't been
  checked). netfile's later checks (`fuji_open_directory_filter`) will show
  whether they matter; none of that has run yet.

**D. The IEC time zone setter keeps the length field. Fixed 15:35.**
fujinet-lib sends a 2-byte length before the time zone name (`CLKCALL_B12_D`).
`iecFuji::fujidev_read_tz()` treated those bytes as part of the name, so the
firmware logged "Rejecting malformed timezone".
- Fix: `iecFuji::fujidev_read_tz()` in `lib/device/iec/iecFuji.cpp` now reads the
  length first with `_packet->param16(0)`, as `adamClock::fujidev_read_tz()`
  does. `_packet` is `fujiClock`'s member and isn't ambiguous in `iecFuji`. The
  alternate time zone command (0x99) goes through the same function.
- Result: the log shows "system tz set to <America/New_York>" and the read-back
  matches. Clock got from 4 passed checks to 32, then stopped on G at the SOS
  time.
- Side effect: each clock run makes the firmware save `fnconfig.ini` twice, since
  the test sets the time zone and then restores it. The zone ends as `UTC`, the
  value it started with.

**E. Tests compare PETSCII text with ASCII data. Fixed 16:15 (html and netproto
pass; disk got past it at 16:22).** cc65 compiles `'S'`, `"ABC"` and `'a'` to
PETSCII (`D3`, `C1 C2 C3`, `41`). The firmware and the servers send ASCII (`SD`,
`41 42 43`, `61 62 ...`), and the log shows the right bytes arrived. The fix is
in the tests: compare against ASCII byte values on the C64. No firmware change.
- cc65 2.19 translates the characters of a literal but not its escapes:
  `"\x41\x42\x43"` and `"\101"` stay `41 42 43`, `'\x53'` stays `53` (checked
  with `cc65 -t c64` and in the assembly of the fixed disk.c). qrcode.c already
  relies on this for `QR_INPUT` (`#ifdef __CBM__`, "Hack to avoid cc65 converting
  to PETSCII"), so the fix reuses that idiom. Also from the probe: on the C64
  `'\n'` is 0x0D and `'\r'` is 0x0A, so a literal `"\r\n"` goes out as `0A 0D`.
- Files, all in `fujinet-lib/testing/tests/` and uncommitted (3 files, +36/-15):
  - `constants.h`: `RANGE_BYTE(i)` is `0x61 + i % 26` instead of `'a' + i % 26`
    (netproto's pattern checks; net5plus.c's seek/tell checks use it too and
    haven't run yet). New `NET_HTTP_HELD_BODY` (`"\x41\x42\x43"`) next to the two
    held-peer URLs.
  - `http.c`: both "decoded body equals ABC" checks (fixed length, line 91, and
    chunked, line 118) compare with `NET_HTTP_HELD_BODY`.
  - `disk.c`: the SD host slot is found by `0x53 0x44` (two places). On
    `__CBM__` the host name `tnfs.fujinet.online`, the paths `/COCO/lobby.dsk`
    and `/lobby.dsk`, the copy spec `COCO/lobby.dsk|lobby.dsk` and the new-disk
    name `/fnnewdisk.img` are written as `\x` escapes; other platforms keep their
    literals through macros. The host slot and the `fuji_copy_file()` spec go to
    FujiNet raw, and `fuji_file_stat()` sends its directory raw and compares the
    file name with the ASCII directory entries on the C64.
    The first disk run after the SD fix stopped at `fuji_file_stat()` of
    `/COCO/lobby.dsk` (line 158): the log shows OPEN DIRECTORY with
    `2F C3 CF C3 CF`, which the TNFS server can't find. With ASCII paths the
    copy test passes (161280 bytes copied, size matches, timestamp changes).
- Result: html 7 / 1 -> 98 passed, 1 skipped, 0 failed; netproto 2 / 1 -> 107
  passed, 0 failed (it now reads every protocol to EOF: HTTP, FTP, WebDAV, TNFS,
  SD, clipboard, ICAL); disk 1 / 1 -> 14 / 1, then F (below).
- What the firmware converts, from the logs: devicespecs, JSON/HTML query strings
  and their results (so html's strip-tags and Moby-Dick checks pass with PETSCII
  literals, as the result is PETSCII too: `C9 20 3C 33 20 C6 55 4A ...`). It does
  not convert raw reads and writes, host slots, directory entries, or the paths
  and names in FujiNet-device commands (OPEN DIRECTORY, COPY FILE, NEW DISK); a C64
  program has to supply ASCII for those. That is why the disk paths are the
  tests' job, not cause C.
- Not changed, because no check fails: bodies the tests send as PETSCII.
  http.c's POST and PUT bodies only have their status and size checked.
  netproto's `ICS_BODY` is PUT to the WebDAV server as PETSCII (`C2 C5 C7 C9 CE
  3A ...`, line ends `0A 0D`), so the ICAL row reads back "ICAL: 0 events in
  window" and the two bytes `30 9B`. The row passes only because it checks that
  some data came back. To make it test the calendar, `ICS_BODY` needs to reach the
  server as ASCII (hex escapes, or a conversion at run time); that is the user's
  decision.
- Side effect on the rig, needs the user: the disk test borrows host slot 2 for
  `tnfs.fujinet.online` and puts the old name back at the end. The 16:15 run, still
  with the PETSCII host name, stopped at line 158 before that, so fujinet-pc
  saved `TNFS.FUJINET.ONLINE` to `build/dist/fnconfig.ini` in place of
  `fujinet.online`. The later runs took that as the original, and the firmware
  ignores a rename that changes only the case ("new name matches old - nothing
  changes" in the log), so `[Host2]` now reads `name=tnfs.fujinet.online`. It is
  not restored: that writes `fnconfig.ini`, which these passes may not touch (a
  one-off C64 program for it was refused). The disk test treats the slot as
  already present and no longer borrows it. To restore it, set `[Host2]
  name=fujinet.online` with fujinet-pc stopped (the runner starts it again).

**F. The C64 packet buffer was too small for the device slots. Fixed 16:49
(fujidev got past line 125, disk past line 317).** `fuji_bus_call()` in
fujinet-lib's `bus/c64/fujinet-bus-c64.c` copies the aux bytes and the data into
`fb_packet.data` (258 bytes) and returns false, sending nothing, when they don't
fit. `fuji_put_device_slots` (8 x 38 = 304 bytes) and `fuji_create_new` (the C64
`NewDisk`, 2 + 2 + 1 + 1 + 256 = 262 bytes) didn't fit, and the log had no `F1`
or `E7`. `fuji_set_device_filename` didn't fit either (3 aux bytes + 256 = 259),
but fujidev stops before it.
- Fix: `data[258]` is now `data[8 * sizeof(DeviceSlot)]` (304 bytes) with a short
  comment, plus one line in `Changelog.md`. Both are uncommitted in `fujinet-lib`.
  No firmware change.
- The largest payload, from every data-carrying call in `include/` and `common/`
  (the C64 library is those plus `bus/c64/`): device slots 304, NewDisk 262,
  device filename 259, copy file 258, open directory and host prefix 257, host
  slots and JSON query 256, SSID 98, appkey 64. The calls that take the caller's
  length (`network_open` and the other devicespec commands, plus hash, base64 and
  QR input, which add 1 or 2 bytes) can still exceed 304; they still return false.
- RAM: `fb_packet` goes from 260 to 306 bytes of BSS (+46). Code and the `.prg`
  sizes don't change, because BSS isn't in the file. fujidev's BSS goes from 2007
  to 2053 bytes, disk's from 3079 to 3125.
- `network_bus_write()` caps a write at `sizeof(fb_packet.data)`, so its chunk is
  now 304 bytes instead of 258. html's 1200-byte POST goes out as 304 + 304 + 304
  + 288 (it was 258 x 4 + 168), the server still receives all 1200 bytes, and
  html is 98 passed, 1 skipped, as before.
- Firmware: nothing limits a payload on IEC. `virtualDevice::write()` appends
  every byte of a LISTEN session to a vector, and NetIEC passes every byte on.
  The log shows `RAW payload len=304` followed by "Fuji cmd: WRITE DEVICE
  SLOTS" (`fnconfig.ini` is not rewritten, because the slots are unchanged), and
  the 262-byte `NewDisk` arrives as `D0 02 80 00 00 01 "/fnnewdisk.img"`.
- Not done: sending the data from the caller's buffer would save about 250 bytes
  of RAM. The aux bytes and the data would still have to go in one LISTEN session
  (the firmware ends a command at UNLISTEN, and each `cbm_write()` ends with
  one), so it can't be two `cbm_write()` calls; it needs its own CKOUT, BSOUT and
  CLRCH loop.

Result (16:49, and the 16:52 full run): fujidev 14 / 1 to 17 / 1, disk 14 / 1 to
15 / 1. The other 12 programs are unchanged, so 6 still pass.

What stops them now:
- **fujidev, line 138, `fuji_mount_host_slot(0xFF)` should fail: cause A.** The
  log shows `02 F9`, the payload `FF`, "!! Invalid host slot 255", and then
  nothing. `fujicmd_mount_host_success()` calls `transaction_error()`, a no-op on
  IEC, so the C64 gets OK and `fuji_mount_host_slot` returns true. The test skips
  this check only where `FN_BROKEN_fuji_mount_host_slot_error` is defined (Adam),
  not for `FN_BROKEN_transaction_error`. Not changed. The checks after it haven't
  run: the oversized host slot write, device filename, host prefix, directory
  ops, GUID, base64 and hashing. From the code, none of them sends more than 304
  bytes except the oversized write (`HOST_TABLE_LEN + 64` = 320), which the C64
  library still refuses on its side (the test prints "refused" and goes on), so on
  the C64 that test never reaches the firmware.
  Watch out: `test_fuji_device_filename` is the first thing that rewrites device
  slot 1 (`[Mount1]`, host slot 6, `/fntest/c64/appkey.prg`). The firmware saves
  `fnconfig.ini` when a slot changes, and the test puts the slot back only at its
  end, so a check failing in between leaves `/test_filename` in `[Mount1]`. Back
  `fnconfig.ini` up before running fujidev past line 138.
- **disk, line 320, the new image is on the SD host: the IEC NEW DISK stub.
  Fixed 17:17, see "NEW DISK on IEC".** The 262-byte `E7` arrived, but
  `iecFuji::fujicmd_new_disk()` only called `transaction_error()` (a no-op, cause
  A) and logged nothing, so `fuji_create_new` returned true without making an image.

**G. The clock's GET_SOS and the FujiNet device's STATUS are both 0x53 on IEC.
Fixed 15:35.** fujinet-lib sends every clock command to device 30, the same IEC
device as the FujiNet device (on the other buses the clock has its own device
ID). `iecFuji::processCommand()` offered each command to `fujiDevice` first,
which took 0x53 as STATUS. The log showed `02 53 00` followed by "Fuji cmd:
STATUS" and 4 zero bytes, not the 19-byte time string, so clock failed at
"APPLE3_SOS reserved byte[8] is 0" (line 184). No other clock command shares a
byte with a FujiNet command.
- Fix: fujinet-lib sends STATUS with no payload (`fuji_status()` on the C64, and
  the appkey status check, both use `OPCODE_NO_PAYLOAD`) and GET_SOS with the
  alternate time zone flag. `iecFuji::processCommand()` now sends a 0x53 that has
  a payload straight to `fujiClock`. This needed a new accessor,
  `FujiIECPacket::hasPayload()` in `lib/bus/iec/FujiIECPacket.h`, because
  `data()` caches the payload and a later `param(0)` read would then assert. A
  unit test covers it.
- Result: GET_SOS returns the 19 bytes `202610230193555000` + NUL (byte 8 is the
  reserved `0`; see `runs/2026-10-23_153547/clock.log`), and clock passes all 48
  checks. STATUS without a payload still works: appkey logs 10 of them and
  passes.
- Assumption: any client that sends STATUS to device 30 with a payload would now
  get the time string. fujinet-lib v5 doesn't.

**NEW DISK on IEC. Implemented 17:17 (disk got past line 320).** The user asked
for the feature, so fujinet-lib's `fuji_create_new()` makes an image from a C64.
The shared `fujiDevice::fujicmd_new_disk()` and `fujicore_new_disk_success()` run
on IEC as they are; nothing in `fujiDevice` had to change.
- What changed (uncommitted; item 9 of "Local firmware fixes"):
  - The `iecFuji::fujicmd_new_disk()` stub is gone (`iecFuji.h`, `iecFuji.cpp`).
  - `iecDrive::NewDiskRequest` (`lib/device/iec/drive.h`) is the 262-byte layout the
    C64 sends: `u16le_t numSectors`, `u16le_t sectorSize`, `hostSlot`,
    `deviceSlot` and a 256-byte name, packed like `sioDisk`'s. It was
    `{hostSlot, deviceSlot, filename}`.
  - `iecDrive::write_blank()` (`drive.cpp`) calls the new `BlankImage::create()`
    (`lib/media/cbm/blankImage.h` and `.cpp`: image formats belong to the media
    layer; `lib/media/media.h` includes the header and `fujinet_pc.cmake` lists the
    files). A `.d64`, `.d71` or `.d81` name, in any case
    (`MediaType::discover_mediatype()`), gets that drive's image at its standard
    size (174848, 349696 or 819200 bytes), whatever size the request names: a BAM
    with every block free (664, 1328 or 3160), an empty directory, the file's base
    name in upper case as the disk name (16 characters, `$A0` padded), ID `FN`
    and DOS type 2A (3D on a D81). Any other name gets `sectorSize * numSectors`
    zero bytes, 92160 for the disk test. A size of 0, or over 16 MiB (the largest
    CMD native partition), is refused, and the shared flow then deletes the empty
    file it had opened.
  - READMEs: `lib/device/iec/README.md`, `lib/media/cbm/README.md` (it also said
    "ESP32 only" and "Not compiled on PC", which the PC IEC target had made untrue)
    and `tests/README.md`. No other README said IEC can't create disks.
- Unit tests: `tests/BlankImageTests.cpp` is the new `blankimage_tests` (10 cases,
  305 assertions). It checks the raw size and zeros; that 0 and more than 16 MiB are
  refused and 16 MiB is not; the D64's BAM (18/0 links to 18/1, DOS version `A`,
  664 free blocks with every count matching the bits of its bitmap, 18/0 and 18/1
  allocated), name, ID and DOS type; the D71 (double-sided flag, 1328 free, track
  53 allocated) and D81 (links, `D` and its complement, 3160 free); an extension in
  any case; and that no other sector holds anything. All 34 ctests pass (33
  before). Six deliberately broken copies of `blankImage.cpp` (wrong version byte,
  18/1 left free, wrong directory link, size 0 accepted, D71 track 53 free, wrong D81
  BAM link) each fail it.
- Independent check with VICE's `c1541`, on images from a host-side harness built from
  `blankImage.cpp` and `mediaType.cpp` (written in the scratchpad; nothing is left in
  the repo): `-list` shows `0 "refdisk" fn 2a`, "Empty image" and 664 blocks free for
  the D64, 1328 for the D71, and `0 "refdisk" fn 3d` and 3160 for the D81. All three
  files are byte for byte what `c1541 -format refdisk,fn <type>` writes. `-write` and
  `-validate` work on each, leaving one block fewer free. The image the C64 made
  through NEW DISK (from a scratch build of disk.c that asks for `/fnnewdisk.d64`)
  lists the same way.
- On the rig (`runs/2026-10-23_171753`, `_172757`, `_172832`): the log shows "Fuji cmd:
  NEW DISK", "Creating file /fnnewdisk.img on host slot 0 for disk slot 1", "BLANK
  IMAGE /fnnewdisk.img" and "fujicore_new_disk succeeded", and
  `build/dist/SD/fnnewdisk.img` is 92160 bytes of zeros. disk goes from 17 / 1 at line
  320 to 18 / 1 at line 323 (see the note under the table for the 17).
- A run that stops early leaves `fnnewdisk.img` on `build/dist/SD`. The next disk run
  deletes it first, and I removed the ones my runs left.

What stops disk now:
- **H. The IEC directory entry has a 16-bit file size (line 323, the new image is
  the size asked for).** `iecFuji::set_additional_direntry_details()` sends
  `{modified, uint16_t size, flags, mediatype}`, and fujinet-lib's C64
  `FujiDirEntry` reads a `uint16_t size`; the entry on every other platform has 32
  bits. The test prints "size 26624, 92160 expected": 26624 is 92160 mod 65536,
  although the file is 92160 bytes on the SD host. So `e->size == want` can't hold
  on the C64 for any image of 64 KiB or more, whatever NEW DISK writes. The copy
  test's "dest lobby.dsk size matches source" passes only because both sizes are cut
  the same way (161280 to 30208).
  Not changed. Both sides read the entry by offset (`fuji_file_stat()` asks for
  `sizeof(entry) - sizeof(entry.filename) + strlen(name) + 1` bytes), so a wider
  field means changing the firmware and fujinet-lib together, and a C64 program
  built with the old library would misread the new entry. The user decides: widen
  it on both sides, or have the C64 test compare the low 16 bits (a change in
  `fujinet-lib/testing/tests/disk.c`; nothing changes in the firmware).
- **A (line 331, creating it again over the existing file fails).** The log shows
  `fujicore_new_disk File exists: "/fnnewdisk.img"`, so the firmware refuses, but
  `transaction_error()` is a no-op and the C64 gets OK. disk skips this check only
  for `FN_BROKEN_fuji_create_new_error`, which broken-v5.h defines for ADAM and not
  for C64.
- Nothing else is left in `test_fuji_create_new`. A scratch copy of fujinet-lib (in
  the scratchpad, not the repo) that compares the size as 16 bits and defines
  `FN_BROKEN_fuji_create_new_error` for the C64 runs disk to the end: 20 passed, 1
  skipped, 0 failed, including "the image is deleted". With only the size change it
  stops at line 331 (19 / 1).

Found on the way; no test fails on it, since none of the 14 lists an image:
- **I. The firmware can't list an empty image or a D71, and counts a D81's free
  blocks wrong.** With c1541-made images on the SD host, mounted on drive 8 through
  the web UI (`/mount?hostslot=0&deviceslot=0&mode=1&filename=<path>`), then
  `LOAD"$",8` and `LIST` in VICE:
  - A D64 with two files lists, and ends "662 blocks free" (right).
  - A D81 with two files lists, and ends "1948 blocks free" where 3158 is right.
    `D81MStream` (`lib/meatloaf/disk/d81.h`) reads the second BAM from 40/0, which
    is the header; the standard place is 40/2.
  - An empty D64, D81 or D71 gives `?FILE NOT FOUND` (each is byte for byte the image
    NEW DISK writes), and so does a D71 with two files. For the empty ones: in
    `iecDrive::open()` (`lib/device/iec/drive.cpp`) a directory with no entries
    counts as a directory only when the image's stream can't be opened
    (`isProperDir`); an image's stream opens, so it is treated as a file, of size 0.
    The D71 with files probably reads as empty: `D71MStream`
    (`lib/meatloaf/disk/d71.h`) puts the header and directory on track 1 where a
    standard D71 has them on 18/0 and 18/1 (not tested further).
  - So the images NEW DISK makes are valid (c1541), but a C64 can't list a new one
    until a file is on it, and can't put one there: `iecDrive::open()` refuses a
    write to a file on disk media ("writing to files on disk media not supported"),
    and `D64MStream::writeFile()` and `allocateBlock()` are stubs. Not changed; the
    user's decision whether any of that is wanted.

## Firmware fixes (committed on `vice-fn`, 17:41)

| Commit | Fixes |
|---|---|
| 495e6be4a `[iec] Return no data for a FujiIECPacket sent without a payload` | 1 |
| 35fd5e80d `[pc] Keep PETSCII bytes from 0x80 up in mstr::toUTF8` | 4 |
| 9e0e49a40 `[iec] Answer fujinet-lib's clock commands on the FujiNet device` | 2, 3, 5, 6 |
| 938a3120a `[network] Convert paths from the bus's charset in CD, PWD and file commands` | 7 |
| 827c4b0a2 `[fuji] Send generated GUIDs in the bus's charset` | 8 |
| 910fba672 `[iec] Create disk images with NEW DISK` | 9 |

Each commit is one PR's worth. The clock commit's unit test sits in the test
file that commit 495e6be4a adds, so that PR needs it too.

The fixes, by number:

1. FujiIECPacket: `data()` no longer asserts when there is no payload. This
   fixes a crash on an empty WRITE APPKEY, and it affects hardware too. A unit
   test was added.
2. The IEC FujiNet device (#30) answers fujinet-lib's clock commands through
   `fujiClock`. This fixed "UTC ISO: BROKEN".
3. Clock strings are sent as PETSCII on IEC (`fujiClock::send_string`).
4. `mstr::toUTF8` drops only NUL bytes. On PC it used to drop bytes from
   0x80 up. This fix let clipbord, html, netproto and network get further.
5. Cause D: `iecFuji::fujidev_read_tz()` reads the 2-byte length before the time
   zone name (`lib/device/iec/iecFuji.cpp`). This fixed the time zone setters in
   clock.
6. Cause G: `iecFuji::processCommand()` sends a 0x53 with a payload to
   `fujiClock` (GET_SOS) instead of `fujiDevice` (STATUS). It adds
   `FujiIECPacket::hasPayload()` (`lib/bus/iec/FujiIECPacket.h`) and a unit test
   in `tests/FujiIECPacketTests.cpp`. This fixed the SOS time in clock.
7. Cause C: `NDevice::fujidev_set_prefix()` and `fs_op()` convert with
   `nativeTextToUnicode()`, and `fujidev_get_prefix()` with
   `unicodeTextToNative()` (`lib/device/NDevice/NDevice.cpp`, plus a bullet in
   its README). This fixed CD and PWD in netfile and devlist, and makes the
   filesystem commands parse a PETSCII spec.
8. Cause C: `fujiDevice::fujicmd_generate_guid()` sends the GUID through
   `unicodeTextToNative()` (`lib/device/fujiDevice/fujiDevice.cpp`). Without it
   fix 7 doesn't get netfile past line 269.
9. NEW DISK on IEC (section above): the `iecFuji::fujicmd_new_disk()` stub is
   removed, `iecDrive::NewDiskRequest` has the C64's layout and
   `iecDrive::write_blank()` writes the image through the new `BlankImage` in
   `lib/media/cbm/`. Files: new `lib/media/cbm/blankImage.h`, `blankImage.cpp` and
   `tests/BlankImageTests.cpp`; changed `lib/device/iec/drive.h`, `drive.cpp`,
   `iecFuji.h`, `iecFuji.cpp`, `lib/media/media.h`, `fujinet_pc.cmake`,
   `tests/CMakeLists.txt` and the READMEs of `lib/device/iec`, `lib/media/cbm` and
   `tests`. This fixed disk's "the new image is on the SD host".

Fixes 5 and 6 only make sense with fix 2, so 2, 5 and 6 probably belong in one
PR. `lib/device/iec/README.md` and `lib/device/fujiClock/README.md` still said the
IEC clock doesn't use `fujiClock`; they now match these fixes. Fix 6's unit test
is in the test file that fix 1 adds, so that PR also needs fix 1. Fixes 7 and 8
touch no other fix's files. Fix 8 is in `fujiDevice`, not NDevice, so it can be its
own PR; fix 7 alone leaves netfile where it was, because of the GUID. Neither has
a unit test: the NDevice tests only build for the ATARI target, where the
conversions do nothing.

Fix 9 works without the others and is its own PR. It edits files that fixes 1, 5 and 6
touch too, on lines next to theirs: `iecFuji.h` and `iecFuji.cpp` (it drops the
`fujicmd_new_disk()` stub beside fix 5's `fujidev_read_tz()`), `lib/device/iec/README.md`,
`tests/CMakeLists.txt` and `tests/README.md` (fix 1's test entry), so expect a
trivial rebase.

Each fix should become its own branch off master with its own PR.

## Next steps

1. A and B: open issues first, since both need design agreement. fujidev
   resumes at line 138 once A is settled (see F for the `fnconfig.ini` backup).
   netfile resumes at line 218 once A is settled. Its later checks haven't run,
   so expect more there: E (the listing and file checks compare ASCII names and
   data with PETSCII literals; use the `\x` escapes as in disk.c, and see E for
   what the firmware converts) and possibly missing conversions for
   `NET_USERNAME`, `NET_PASSWORD` and the UDP destination (see C). The
   FujiNet-device path commands are not a gap: disk shows they take ASCII.
2. F is fixed (fujinet-lib `bus/c64/fujinet-bus-c64.c` and `Changelog.md`, one
   fujinet-lib PR; no firmware change). NEW DISK on IEC is implemented (firmware PR,
   item 9). disk now stops on H, the 16-bit file size (line 323), and then A (line
   331); nothing else is left in `test_fuji_create_new`. Decide H: widen the IEC
   directory entry's size to 32 bits in firmware and fujinet-lib together, or have
   the C64 test compare 16 bits. A goes with the other A rows; or define
   `FN_BROKEN_fuji_create_new_error` for C64 in `broken-v5.h` until it is fixed.
3. E is done in three test files (`constants.h`, `disk.c`, `http.c`): one
   fujinet-lib PR. Decide whether netproto's `ICS_BODY` should be ASCII on the C64
   (see E).
4. Done 17:05: `[Host2] name=fujinet.online` is back in `fnconfig.ini`, and
   `fnconfig.golden.ini` keeps it there (see "How to run").
5. Make a PR branch off master for each firmware commit (see "Firmware fixes"),
   and fujinet-lib PRs from `c64-iec-fixes`, one for the tests (189fbdd) and one
   for the bus (26d1a03).
6. Prefixes left by devlist: `FNPC_RESTART=1` (see "How to run") avoids it until B
   is fixed.
7. Decide whether the drive should list and write the images NEW DISK makes (I): an
   empty D64, D81 or D71 gives `?FILE NOT FOUND` on `LOAD"$",8`, a D71 doesn't
   list even with files on it, a D81's blocks free is wrong, and nothing can be
   saved to a D64. These are in `iecDrive::open()` and Meatloaf, not in NEW DISK.

## How to run

1. Start fujinet-pc:
   `cd ~/code/fujinet-firmware/build/dist && ./fujinet -u http://localhost:8064 > fnpc.log 2>&1`
   - To rebuild: `PATH=build/.venv/bin:$PATH cmake --build build -j10 && cp build/fujinet build/dist/fujinet`.
   - Don't build the `dist` target, because it overwrites `fnconfig.ini`.
2. Start VICE from `~/code/vice-fn`:
   `FUJINET_UNITS="8 16 29 30" svn-mirror/fujinet/run-vice-fujinet.sh -default -remotemonitor -remotemonitoraddress ip4://127.0.0.1:6510`
   - Add `VICE_BUILD=$PWD/build-headless` to run without a window.
3. Run the tests:
   `FNPC_LOG=~/code/fujinet-firmware/build/dist/fnpc.log ./run-fntests.sh [test ...]`
   - With no test names, it runs all 14.
   - Each test takes about 10 seconds.
   - It adds rows to `results.md` and saves screens and logs in `runs/`.
   - A failed devlist leaves its prefixes on fujinet-pc's one NDevice, which
     breaks netfile's cd. Restart fujinet-pc before netfile if devlist ran first,
     or set `FNPC_RESTART=1` to have the runner do it before every test.
   - Also set `FNPC_CONFIG=~/code/vice-fn/fntest/fnconfig.golden.ini`. With
     `FNPC_RESTART=1`, the runner then copies the user's settings into place
     before every restart and again at the end. A test that stops halfway can
     then no longer leave host or device slots changed, as disk once did to host
     slot 2 and fujidev can do to device slot 1.
     - `fnconfig.golden.ini` is the user's config with host slot 2 back to
       `fujinet.online` (17:05).
     - `fnconfig.as-found-2026-10-23.ini` is the config as it was found before
       that restore.
   - Recommended:
     `FNPC_RESTART=1 FNPC_CONFIG=~/code/vice-fn/fntest/fnconfig.golden.ini FNPC_LOG=~/code/vice-fn/fntest/fnpc.log ./run-fntests.sh [test ...]`
4. Build the test programs from source and run them (needs cc65 2.19):
   - `cd ~/code/vice-fn/fujinet-lib && make c64` builds the library into
     `r2r/c64/fujinet.c64.lib`, which `testing/Makefile` finds through
     `FUJINET_LIB = ..`.
   - `cd testing && make c64/clean && make c64` builds the 14 programs into
     `testing/r2r/c64/`. After editing `tests/*.c`, or rebuilding the library,
     run the clean first: a .prg depends only on its own `src/` objects, not on
     `fnlib-test.c64.lib` or `fujinet.c64.lib`, so a plain `make c64` doesn't
     relink it. The clean only removes things under `testing/`.
   - For a program's segment sizes, relink one by hand with a map file, for
     example `cd testing && cl65 -t c64 -m /tmp/fujidev.map
     build/fujidev/c64/src/init_video.o build/fujidev/c64/src/main.o --lib-path
     r2r/c64 fnlib-test.c64.lib --lib-path ../r2r/c64 fujinet.c64.lib -o
     /tmp/fujidev.prg`; the build's own link prints no map.
   - Run them with `PRG_DIR`:
     `FNPC_RESTART=1 PRG_DIR=~/code/vice-fn/fujinet-lib/testing/r2r/c64 FNPC_LOG=~/code/vice-fn/fntest/fnpc.log ./run-fntests.sh [test ...]`
   - Uncommitted changes in the fujinet-lib tree show as `31cea90*` on the
     program's last screen and in the Tests column of `results.md`. The runner's
     pattern used to stop at the `*`, so the rows up to the 16:25 run were patched
     by hand (the 16:07 rows are a clean build of 31cea90, so they have no `*`).
   - Until 17:05, with `FNPC_RESTART=1` a shell started by the runner kept its
     stdout open, so piping the runner into `tail` never returned. The runner
     now starts fujinet-pc without that shell. Redirecting to a file still works.
   - The fujinet-pc log has non-UTF-8 bytes: search it with `LC_ALL=C grep -a`.
   - disk compares the minute of two copies of `lobby.dsk` (line 212), so two disk
     runs in one minute fail it. A disk run that stops early leaves `fnnewdisk.img` on
     `build/dist/SD`; the next run deletes it first.
5. Check a blank image with VICE's c1541, without VICE or fujinet-pc running: build
   a small program that opens a file and calls `BlankImage::create(f, path, 128,
   720)` with `-DBUILD_IEC -DUNIT_TESTS -DFNIO_IS_STDIO -Iinclude -Ilib/FileSystem
   -Ilib/media/cbm -Icomponents_pc` from `blankImage.cpp` and `mediaType.cpp`, run it
   for `x.d64`, `x.d71` and `x.d81` in a temp directory, then
   `~/code/vice-fn/build-sdl2/src/c1541 -attach x.d64 -list` and `cmp` against
   `c1541 -format x,fn d64 ref.d64`.
