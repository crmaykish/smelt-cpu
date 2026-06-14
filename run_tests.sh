#!/usr/bin/env bash
#
# Smelt regression runner. Assembles every asm/*.s, runs it against its golden
# file through the self-checking testbench, and reports a single green/red.
#
# A test passes iff the sim prints ALL_PASS (keying on its *presence* means a
# timeout -- which prints no sentinel -- fails safely). Tests named in
# FAULT_TESTS are expected to fault (sticky `error` output); all others must
# finish cleanly.
#
# Usage:  make test        (builds the sim, then runs this)
#         ./run_tests.sh    (requires sim/smelt.vvp already built)
set -u

cd "$(dirname "$0")"

ASM=tools/assembler/smeltasm.py
VVP=sim/smelt.vvp

# Tests expected to set the error output (illegal opcode, etc.).
FAULT_TESTS=" illegal_op_test "

if [ ! -f "$VVP" ]; then
    echo "error: $VVP not found -- run 'make test' (builds the sim first)" >&2
    exit 2
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

pass=0
fail=0
failed=""

echo "-----------------------------------------"

for s in asm/*.s; do
    name=$(basename "$s" .s)
    golden="asm/$name.golden"
    if [ ! -f "$golden" ]; then
        printf '  SKIP %-18s (no golden)\n' "$name"
        continue
    fi

    expect_error=0
    case "$FAULT_TESTS" in *" $name "*) expect_error=1 ;; esac

    hex="$work/$name.hex"
    if ! python3 "$ASM" "$s" -o "$hex" 2>"$work/asm.err"; then
        printf '  FAIL %-18s (assemble)\n' "$name"
        sed 's/^/       /' "$work/asm.err"
        fail=$((fail + 1)); failed="$failed $name"
        continue
    fi

    out=$(vvp "$VVP" +hex="$hex" +golden="$golden" +expect_error="$expect_error" 2>/dev/null)
    if echo "$out" | grep -q 'ALL_PASS'; then
        printf '  PASS %-18s\n' "$name"
        pass=$((pass + 1))
    else
        printf '  FAIL %-18s\n' "$name"
        echo "$out" | grep -E 'FAIL|FAILURES|ERROR|Timed out' | sed 's/^/       /'
        fail=$((fail + 1)); failed="$failed $name"
    fi
done

echo "-----------------------------------------"
if [ "$fail" -eq 0 ]; then
    echo "PASS: all $pass tests green"
    exit 0
else
    echo "FAIL:$failed  ($pass passed, $fail failed)"
    exit 1
fi
