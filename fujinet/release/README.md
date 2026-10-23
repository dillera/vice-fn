# VICE-FN release for Apple silicon

Builds `VICE-FN_AppleSilicon`, a folder people can download and run on an
Apple silicon Mac with macOS 13 or later:
- `Start VICE-FN.app` starts FujiNet-PC, then VICE with FujiNet on drive 8 and
  devices 16, 29 and 30. When VICE quits, it stops FujiNet-PC.
- `VICE/`: `x64sc` and the NetIEC bridge, `libopencbm.dylib`.
- `FujiNet-PC/`: `fujinet` built with `FUJINET_TARGET=IEC`, with its data, SD
  card and settings.

Everything is signed with a Developer ID and notarized. `launcher/README.txt`
becomes the folder's read me.

## Layout

| Path | |
|---|---|
| `scripts/build-deps.sh` | builds SDL2, SDL2_image, Mbed TLS and OpenSSL as static libraries for macOS 13. Homebrew's own builds target the running macOS. The sources are pinned by version and SHA-256. |
| `scripts/build-vice.sh` | builds `x64sc` from this checkout, and the bridge, against only system libraries and those static ones |
| `scripts/build-fujinet-pc.sh` | builds a Release fujinet-pc from `FIRMWARE_PKG` |
| `scripts/make-folder.sh` | assembles the folder, signs every binary and checks the signatures |
| `scripts/notarize.sh` | notarizes the folder (as a zip) and a disk image of it, and staples both |
| `scripts/make-icon.sh` | redraws `icon/AppIcon.icns`, VICE's C64 icon with the FujiNet logo |
| `launcher/` | the start app's source, `Info.plist` and read me, `x64sc`'s entitlements, and the shipped `fnconfig.ini` |

Downloads, builds and output go to `RELEASE_DIR`, by default
`~/code/vice-fn/release`, outside the repository.

## Build

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

## Inputs

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

## Notes

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
