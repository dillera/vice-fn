# VICE-FN releases

Builds VICE with FujiNet-PC for Apple silicon Macs, as a signed folder, and for
Debian and Ubuntu, as `.deb` packages (see [below](#debian-and-ubuntu-packages)).

## Layout

| Path | |
|---|---|
| `scripts/build-deps.sh` | builds SDL2, SDL2_image, Mbed TLS and OpenSSL as static libraries for macOS 13. Homebrew's own builds target the running macOS. The sources are pinned by version and SHA-256. |
| `scripts/build-vice.sh` | builds `x64sc` from this checkout, and the bridge, against only system libraries and those static ones |
| `scripts/build-fujinet-pc.sh` | builds a Release fujinet-pc from `FIRMWARE_PKG` |
| `scripts/make-folder.sh` | assembles the folder, signs every binary and checks the signatures |
| `scripts/notarize.sh` | notarizes the folder (as a zip) and a disk image of it, and staples both |
| `scripts/make-icon.sh` | redraws `icon/AppIcon.icns`, VICE's C64 icon with the FujiNet logo, and the `.deb`'s icons in `icon/linux` |
| `launcher/` | the start app's source, `Info.plist` and read me, `x64sc`'s entitlements, and the shipped `fnconfig.ini` |
| `linux/` | the `.deb` packages' build and test scripts, launcher and read me |

Downloads, builds and output go to `RELEASE_DIR`, by default
`~/code/vice-fn/release`, outside the repository.

## Apple silicon

Builds `VICE-FN_AppleSilicon`, a folder people can download and run on an
Apple silicon Mac with macOS 13 or later:
- `Start VICE-FN.app` starts FujiNet-PC, then VICE with FujiNet on drive 8 and
  devices 16, 29 and 30. When VICE quits, it stops FujiNet-PC.
- `VICE/`: `x64sc` and the NetIEC bridge, `libopencbm.dylib`.
- `FujiNet-PC/`: `fujinet` built with `FUJINET_TARGET=IEC`, with its data, SD
  card and settings.

Everything is signed with a Developer ID and notarized. `launcher/README.txt`
becomes the folder's read me.

### Build

The tools needed:
- Xcode;
- `brew install cmake pkg-config bison xa dos2unix`;
- for the icon only, `librsvg` and `imagemagick`.

Then:

    fujinet/release/scripts/build-deps.sh
    fujinet/release/scripts/build-vice.sh
    fujinet/release/scripts/build-fujinet-pc.sh
    fujinet/release/scripts/make-folder.sh
    NOTARY_PROFILE=VICE-FN fujinet/release/scripts/notarize.sh

The output is `$RELEASE_DIR/out/VICE-FN_AppleSilicon` and its `.zip` and `.dmg`.

### Inputs

- **`FIRMWARE_PKG`** (default `~/code/fujinet-firmware-pkg`): the fujinet-firmware
  checkout to build. A git worktree of the tested commit keeps the release apart
  from ongoing work. Its uncommitted changes go into the folder as
  `source/fujinet-firmware-local-fixes.patch`.
- **`FIRMWARE_DIR`** (default `~/code/fujinet-firmware`): a checkout with a built
  `build/.venv`. The fujinet-pc build's Python steps run from it.
- **`CONFIG_PRG`**: the C64 CONFIG program FujiNet-PC serves on drive 8.
- **`SIGN_IDENTITY`**: the signing certificate. The default is the SHA-1 hash of
  "Developer ID Application: DILLER & ASSOC LLC (YBX2V97SYB)". Two
  certificates have that name, so the name alone is ambiguous.
- **`NOTARY_PROFILE`**: a keychain profile made once with
  `xcrun notarytool store-credentials VICE-FN --apple-id <Apple ID> --team-id YBX2V97SYB`.
  It asks for an app-specific password from account.apple.com.

### Notes

- **The entitlement:** VICE loads the bridge with `dlopen("libopencbm.dylib")`,
  so the start app sets `DYLD_LIBRARY_PATH` to `VICE/`. That needs `x64sc`'s one
  entitlement, `com.apple.security.cs.allow-dyld-environment-variables`.
  Library validation stays on, so only libraries signed by the same team can
  load.
- **No PNG:** this VICE is built `--without-png`, so it saves screenshots in
  the other formats.
- **CONFIG:** load it with `LOAD"CONFIG.PRG",8`; the name needs the `.prg`.
- **Testing alongside a running setup:** to try a build next to a FujiNet-PC
  already using port 1541, build a copy on other ports:

      OUT=/tmp/vfn LAUNCHER_CFLAGS='-DNETIEC_PORT=1542 -DWEB_UI="http://localhost:8065"' \
          BOIP_PORT=1542 fujinet/release/scripts/make-folder.sh

## Debian and Ubuntu packages

`linux/build-debs.sh` builds `vice-fujinet_<version>_<release>_<arch>.deb`, one
for each distribution release and architecture, by default Ubuntu 24.04 and
Debian 13 for amd64 and arm64. Each package holds:
- `/usr/bin/vice-fujinet`, a script that starts FujiNet-PC in the user's
  `~/.local/share/vice-fujinet`, then VICE with FujiNet on drive 8 and devices
  16, 29 and 30, and stops FujiNet-PC when VICE quits;
- `/opt/vice-fujinet`: `x64sc` (SDL2), the bridge `libopencbm.so`, the C64's
  VICE data, and FujiNet-PC with its data, SD card and settings;
- a desktop menu entry and icons, and `linux/README.txt` with the licenses
  and the sources in `/usr/share/doc/vice-fujinet`.

Each target builds in a Docker container of its release, then is installed in a
fresh one, where a headless VICE lists FujiNet's drive 8 through the package's
launcher. The listing's screenshot goes next to the `.deb`.

    DOCKER_CONTEXT=colima-vice-fujinet fujinet/release/linux/build-debs.sh [target...]

A target is `<distro><release>-<arch>`, such as `ubuntu24.04-amd64` or
`debian13-arm64`. The output, with `SHA256SUMS`, is in `$RELEASE_DIR/out`. The
build stops if the targets' screenshots differ, as they did while an
x86-64-only bug garbled FujiNet-PC's directory text.

To run fujinet-lib's C64 tests against a package, each in a fresh container
with the package's settings, and log them in `fntest/results.md`:

    DOCKER_CONTEXT=colima-vice-fujinet PRG_DIR=<test PRGs> \
        fujinet/release/linux/fntest-deb.sh $RELEASE_DIR/out/<package>.deb [test...]

### Inputs

- **`VICE_REF`** (default `HEAD`): the commit of this repository whose `vice/`
  and `fujinet/opencbm-netiec` are built.
- **`FIRMWARE_DIR`** and **`FIRMWARE_REF`** (default `~/code/fujinet-firmware`
  and `vice-fn`): the firmware commit to build.
- **`PUBLISHED`** (default `origin/vice-fn`): the branch on GitHub. Commits after
  it go into the package as patches in `source/`.
- **`CONFIG_PRG`**, as for the Mac folder, and **`VERSION`** (default `1.0`).

### Notes

- **Docker on Apple silicon:** arm64 builds run natively. amd64 builds need a
  Docker VM that runs amd64 code with Rosetta; QEMU works but is many times
  slower. A Colima VM just for these builds:

      colima start --profile vice-fujinet --vm-type vz --vz-rosetta --cpu 8 --memory 12

  `colima start` makes its VM Docker's current context; switch back with
  `docker context use <previous>`, and point the build at it with
  `DOCKER_CONTEXT=colima-vice-fujinet`.
- **Any CPU:** VICE's configure adds `-march=native` unless given
  `--disable-arch`, which the build passes.
- **The bridge:** `x64sc` has `/opt/vice-fujinet/lib` as its run path, so its
  `dlopen("libopencbm.so")` finds the bridge without `LD_LIBRARY_PATH`.
- **Next to other VICEs:** everything but the launcher, menu entry and icons is
  in `/opt/vice-fujinet`, and `vice-fujinet` gives VICE its own settings file,
  so the package doesn't conflict with Debian's `vice`.
