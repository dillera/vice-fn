#!/bin/bash
# Notarize the signed VICE-FN_AppleSilicon folder and staple the tickets.
# First the folder goes up as a zip, so the start app can be stapled; then a
# disk image of the stapled folder goes up and gets its own ticket.
#
#   NOTARY_PROFILE  keychain profile made with `xcrun notarytool store-credentials`
#   SIGN_IDENTITY   certificate for the disk image (default: as make-folder.sh)
#   RELEASE_DIR     downloads, builds and output (default: ~/code/vice-fn/release)
#   OUT             where make-folder.sh put the folder (default: $RELEASE_DIR/out)
set -e

R=${RELEASE_DIR:-$HOME/code/vice-fn/release}
OUT=${OUT:-$R/out}
IDENTITY=${SIGN_IDENTITY:-07F262C687B818C2CA8586C2B9444E95FDC507BC}
PROFILE=${NOTARY_PROFILE:?set NOTARY_PROFILE to a notarytool keychain profile}
NAME=VICE-FN_AppleSilicon
F=$OUT/$NAME
APP="$F/Start VICE-FN.app"

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
rm -f "$OUT/$NAME.zip"
ditto -c -k --keepParent "$F" "$OUT/$NAME.zip"
submit "$OUT/$NAME.zip"
xcrun stapler staple "$APP"
# The zip to share holds the stapled app
rm "$OUT/$NAME.zip"
ditto -c -k --keepParent "$F" "$OUT/$NAME.zip"

echo "=== Notarizing the disk image"
rm -f "$OUT/$NAME.dmg"
hdiutil create -volname "$NAME" -srcfolder "$F" -format UDZO -ov "$OUT/$NAME.dmg"
codesign --force --timestamp --sign "$IDENTITY" "$OUT/$NAME.dmg"
submit "$OUT/$NAME.dmg"
xcrun stapler staple "$OUT/$NAME.dmg"

echo "=== Checks"
xcrun stapler validate "$APP"
xcrun stapler validate "$OUT/$NAME.dmg"
spctl --assess --type execute -vv "$APP"
spctl --assess --type open --context context:primary-signature -vv "$OUT/$NAME.dmg"
echo "=== Done: $OUT/$NAME.zip and $OUT/$NAME.dmg"
