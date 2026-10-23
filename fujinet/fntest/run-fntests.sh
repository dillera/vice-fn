#!/bin/bash
# Run the fujinet-lib C64 test programs in a running VICE and log the
# results. Each test adds a row to results.md; its last screen, and the
# fujinet-pc log lines it caused when FNPC_LOG is set, go to runs/<date_time>/.
#
# Needs x64sc with its remote monitor on 127.0.0.1:$VMON_PORT and FujiNet
# attached; STATUS.md shows how to start both.
#
# Usage: run-fntests.sh [test ...]      run tests (default: all of prg/c64)
#        run-fntests.sh --relog <run dir> <firmware>
#                                       log a saved run's screens again
#   FNPC_LOG      fujinet-pc's log file
#   FIRMWARE_DIR  fujinet-firmware checkout (default: ~/code/fujinet-firmware)
#   PRG_DIR       test programs to run (default: prg/c64, the release build)
#   VMON_PORT     VICE remote monitor port (default: 6510)
#   FNPC_RESTART  1: restart fujinet-pc before each test, so what one test
#                 leaves behind (such as an N: directory) can't affect the next
#   FNPC_URL      fujinet-pc's web UI address, which also identifies the
#                 process to restart (default: http://localhost:8064)
#   FNPC_CONFIG   with FNPC_RESTART=1, an fnconfig.ini to put in place before
#                 each restart and again at the end, so every test starts from
#                 the same settings and none are left changed (the user's own:
#                 fnconfig.golden.ini)

here=$(cd "$(dirname "$0")" && pwd)
prgdir=${PRG_DIR:-$here/prg/c64}
results=$here/results.md
port=${VMON_PORT:-6510}
fwdir=${FIRMWARE_DIR:-$HOME/code/fujinet-firmware}
fnpc_url=${FNPC_URL:-http://localhost:8064}
export LC_ALL=C # screens have non-UTF-8 bytes

# Send monitor commands, then resume emulation
vmon() {
    { printf '%s\n' "$@"; printf 'x\n'; } | nc -w 2 127.0.0.1 "$port"
}

# The 40-column text screen, trailing blanks removed
screen() {
    vmon screen 2>/dev/null | tr '\r' '\n' | grep '^\*C:' | cut -c 10- | sed 's/ *$//'
}

# Start the firmware's build/dist fujinet-pc afresh; VICE's bridge reconnects
restart_fnpc() {
    pkill -f "fujinet -u $fnpc_url"
    sleep 1
    [ -n "$FNPC_CONFIG" ] && cp "$FNPC_CONFIG" "$fwdir/build/dist/fnconfig.ini"
    # Background only fujinet: `cd && nohup ... &` would leave a shell
    # holding our stdout open until fujinet exits
    (cd "$fwdir/build/dist" || exit 1
     nohup ./fujinet -u "$fnpc_url" >> "${FNPC_LOG:-/dev/null}" 2>&1 < /dev/null &)
}

# Branch, commit and a hash of uncommitted changes: vice-fn b80e8728+55d0f7
firmware_id() {
    local id

    if ! git -C "$fwdir" rev-parse 2>/dev/null; then
        echo "?"
        return
    fi
    id="$(git -C "$fwdir" branch --show-current) $(git -C "$fwdir" rev-parse --short=8 HEAD)"
    git -C "$fwdir" diff --quiet HEAD || id="$id+$(git -C "$fwdir" diff HEAD | shasum | cut -c1-6)"
    echo "$id"
}

# log_row <screen file> <when> <firmware> <run>: add the test's row
log_row() {
    local name flat result passed=? skipped=? failed=? first= tests=?
    local all='=== All ([0-9]+) tests passed, ([0-9]+) skipped ==='
    local some='=== Results: ([0-9]+) passed, ([0-9]+) skipped, ([0-9]+) failed'
    local fail='FAIL (.*) \(line ([0-9]+)\)'
    local tid='tests git commit ID ([0-9a-f]+\*?)'

    name=$(basename "$1" .txt)
    # Pad the lines back to 40 columns so joining them undoes the wrapping
    flat=$(awk '{ printf "%-40s", $0 }' "$1" | tr -s ' ')
    if [[ $flat =~ $all ]]; then
        result=PASS passed=${BASH_REMATCH[1]} skipped=${BASH_REMATCH[2]} failed=0
    elif [[ $flat =~ $some ]]; then
        passed=${BASH_REMATCH[1]} skipped=${BASH_REMATCH[2]} failed=${BASH_REMATCH[3]}
        result=FAIL
        [ "$failed" = 0 ] && result=PASS
    else
        result="NO RESULT"
    fi
    [[ $flat =~ $fail ]] && first="${BASH_REMATCH[1]} (line ${BASH_REMATCH[2]})"
    [[ $flat =~ $tid ]] && tests=${BASH_REMATCH[1]}

    if [ ! -f "$results" ]; then
        cat > "$results" <<'EOF'
# fntest results

C64 test programs from fujinet-lib's `tests-latest` release, run in VICE
against fujinet-pc over NetIEC. `run-fntests.sh` adds one row per test per
run. Each program stops at its first failure, so Passed and Failed count only
the checks that ran. STATUS.md explains the failures.

| When | Test | Result | Passed | Skipped | Failed | First failure | Firmware | Tests | Run |
|---|---|---|---|---|---|---|---|---|---|
EOF
    fi
    printf '| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n' \
           "$2" "$name" "$result" "$passed" "$skipped" "$failed" \
           "${first//|/\\|}" "$3" "$tests" "$4" | tee -a "$results"
}

if [ "$1" = --relog ]; then
    run=$(basename "$2")
    t=${run#*_}
    for f in "$here/runs/$run"/*.txt; do
        log_row "$f" "${run%%_*} ${t:0:2}:${t:2:2}" "$3" "runs/$run"
    done
    exit 0
fi

if [ $# -gt 0 ]; then
    tests=("$@")
else
    tests=()
    for prg in "$prgdir"/*.prg; do
        tests+=("$(basename "$prg" .prg)")
    done
fi

if ! vmon >/dev/null 2>&1; then
    echo "No VICE monitor on 127.0.0.1:$port" >&2
    exit 1
fi

run=$(date +%Y-%m-%d_%H%M%S)
when=$(date '+%Y-%m-%d %H:%M')
fw=$(firmware_id)
out=$here/runs/$run
mkdir -p "$out"

for name in "${tests[@]}"; do
    prg=$prgdir/$name.prg
    if [ ! -f "$prg" ]; then
        echo "No $prg" >&2
        continue
    fi
    [ -f "$FNPC_LOG" ] && start=$(($(wc -l < "$FNPC_LOG") + 1))
    [ "$FNPC_RESTART" = 1 ] && restart_fnpc
    vmon 'reset 0' >/dev/null 2>&1
    sleep 4
    vmon "load \"$prg\" 0" >/dev/null 2>&1
    vmon 'keybuf run\n' >/dev/null 2>&1
    t=0
    while [ $t -lt 300 ]; do
        sleep 5
        t=$((t + 5))
        screen > "$out/$name.txt"
        grep -q "Press SPACE or ENTER" "$out/$name.txt" && break
    done
    [ -f "$FNPC_LOG" ] && sed -n "$start,\$p" "$FNPC_LOG" > "$out/$name.log"
    log_row "$out/$name.txt" "$when" "$fw" "runs/$run"
done

# Leave fujinet-pc running with the settings the run started from
[ "$FNPC_RESTART" = 1 ] && [ -n "$FNPC_CONFIG" ] && restart_fnpc
exit 0
