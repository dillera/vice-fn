# What a release says about the sources it was built from. make-folder.sh and
# linux/build-debs.sh source this file.
#
#   PUBLISHED   the branch of both repositories that is on GitHub, e.g.
#               origin/vice-fn; later commits ship as patches
#   SOURCE_DIR  the release's source/ folder, where those patches go

# The GitHub page of a repository's origin
github() {
    git -C "$1" remote get-url origin | sed -e 's#^git@github.com:#https://github.com/#' -e 's#\.git$##'
}

# Writes the commits of <repo> up to <ref> that aren't on GitHub, if any touch
# [paths...], to $SOURCE_DIR/<patch>, and prints the last published commit.
#   unpublished <repo> <ref> <patch> [paths...]
unpublished() {
    local repo=$1 ref=$2 patch=$3 base
    shift 3
    base=$(git -C "$repo" merge-base "$ref" "$PUBLISHED")
    if [ -n "$(git -C "$repo" rev-list "$base..$ref" -- "$@")" ]; then
        git -C "$repo" format-patch --stdout "$base..$ref" -- "$@" >"$SOURCE_DIR/$patch"
    fi
    git -C "$repo" rev-parse --short "$base"
}

# One source line of a read me: where it is, and the patch on top if any
#   source_line <name> <repo> <base> <head> <patch> <how>
source_line() {
    local plus=""
    if [ -f "$SOURCE_DIR/$5" ]; then
        plus=", plus source/$5 (up to $4)"
    fi
    printf '  %-11s %s, branch %s,\n' "$1" "$(github "$2")" "${PUBLISHED#*/}"
    printf 'commit %s%s%s\n' "$3" "$plus" "$6" | fold -s -w 62 | sed -e 's/ *$//' -e 's/^/              /'
}
