#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
PASS=0; FAIL=0
pass() { echo "  [PASS] $1"; ((PASS++)) || true; }
fail() { echo "  [FAIL] $1"; ((FAIL++)) || true; }

echo "EDGE CASE: Unknown Chemical Handling"
echo "======================================"

# Verify screen.md contains instructions for unmatched chemicals
if grep -q "REQUIRES CAS VERIFICATION" "$PLUGIN_DIR/commands/screen.md"; then
    pass "screen.md handles unmatched chemicals with CAS VERIFICATION flag"
else
    fail "screen.md missing CAS VERIFICATION handling"
fi

# Verify screen.md warns about flammable catch-all
if grep -qi "does not guarantee.*unregulated\|not found in regulated lists" "$PLUGIN_DIR/commands/screen.md"; then
    pass "screen.md warns that absence from lists doesn't guarantee non-regulation"
else
    fail "screen.md missing non-regulation warning"
fi

# Verify the warning mentions flammable threshold
if grep -qi "flammable\|10,000\|10000" "$PLUGIN_DIR/commands/screen.md"; then
    pass "screen.md mentions flammable catch-all threshold"
else
    fail "screen.md missing flammable threshold reference"
fi

echo ""; echo "RESULTS: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
