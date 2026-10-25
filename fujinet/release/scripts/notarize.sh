#!/bin/bash
# Notarize the signed VICE-FN_AppleSilicon folder and staple the tickets.
# First the folder goes up as a zip, so the start app can be stapled; then a
# disk image of the stapled folder goes up and gets its own ticket. Both are
# named with the version: VICE-FN_AppleSilicon_v<version>.zip and .dmg.
#
#   NOTARY_PROFILE  keychain profile made with `xcrun notarytool store-credentials`
#   SIGN_IDENTITY   certificate for the disk image (default: as make-folder.sh)
#   RELEASE_DIR     downloads, builds and output (default: ~/code/vice-fn/release)
#   VERSION         the release's version (default: the one in ../VERSION)
#   OUT             where make-folder.sh put the folder
#                   (default: $RELEASE_DIR/out/v<version>)
set -e

SRC=$(cd "$(dirname "$0")/.." && pwd)
R=${RELEASE_DIR:-$HOME/code/vice-fn/release}
VERSION=${VERSION:-$(cat "$SRC/VERSION")}
OUT=${OUT:-$R/out/v$VERSION}
IDENTITY=${SIGN_IDENTITY:-07F262C687B818C2CA8586C2B9444E95FDC507BC}
PROFILE=${NOTARY_PROFILE:?set NOTARY_PROFILE to a notarytool keychain profile}
NAME=VICE-FN_AppleSilicon
F=$OUT/$NAME
APP="$F/Start VICE-FN.app"
ZIP=$OUT/${NAME}_v$VERSION.zip
DMG=$OUT/${NAME}_v$VERSION.dmg

# submit <file>: notarize it, and show Apple's log if it isn't accepted
submit() {
    local result id

    result=$(xcrun notarytool submit "$1" --keychain-profile "$PROFILE" --wait 2>&1)
    echo "$result"
    if ! grep -q "status: Accepted" <<< "$result"; then
        id=$(awk '/^  id:/ { print $2; exit }' <<< "$result")
        [ -n "$id" ] && xcrun notarytool log "$id" --keychain-profile "$PROFILE"
        exit 1
    fi
}

echo "=== Notarizing the folder"
rm -f "$ZIP"
ditto -c -k --keepParent "$F" "$ZIP"
submit "$ZIP"
xcrun stapler staple "$APP"
# The zip to share holds the stapled app
rm "$ZIP"
ditto -c -k --keepParent "$F" "$ZIP"

echo "=== Notarizing the disk image"
rm -f "$DMG"
# The disk image holds the folder itself, for people to copy out of it
STAGE=$(mktemp -d)
ditto "$F" "$STAGE/$NAME"
hdiutil create -volname "VICE-FN v$VERSION" -srcfolder "$STAGE" -format UDZO -ov "$DMG"
rm -rf "$STAGE"
codesign --force --timestamp --sign "$IDENTITY" "$DMG"
submit "$DMG"
xcrun stapler staple "$DMG"

echo "=== Checks"
xcrun stapler validate "$APP"
xcrun stapler validate "$DMG"
spctl --assess --type execute -vv "$APP"
spctl --assess --type open --context context:primary-signature -vv "$DMG"
echo "=== Done: $ZIP and $DMG"
