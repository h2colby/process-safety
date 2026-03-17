#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
PASS=0; FAIL=0
pass() { echo "  [PASS] $1"; ((PASS++)) || true; }
fail() { echo "  [FAIL] $1"; ((FAIL++)) || true; }

echo "EDGE CASE: Double Generate Protection"
echo "======================================="

# Check generate.md contains overwrite warning logic
if grep -qi "already generated\|overwrite\|re-generat" "$PLUGIN_DIR/commands/generate.md"; then
    pass "generate.md contains overwrite warning for existing programs"
else
    fail "generate.md missing overwrite protection"
fi

# Check generate.md checks for prior generation in state
if grep -qi "generation.completed\|generation.*completed\|prior generation" "$PLUGIN_DIR/commands/generate.md"; then
    pass "generate.md checks generation.completed state"
else
    fail "generate.md doesn't check prior generation state"
fi

# Check generate.md asks for user confirmation before overwrite
if grep -qi "confirm\|proceed\|want to" "$PLUGIN_DIR/commands/generate.md"; then
    pass "generate.md asks for confirmation before overwriting"
else
    fail "generate.md missing confirmation prompt"
fi

echo ""; echo "RESULTS: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
