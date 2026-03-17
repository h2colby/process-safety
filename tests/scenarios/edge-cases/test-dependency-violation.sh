#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
PASS=0; FAIL=0
pass() { echo "  [PASS] $1"; ((PASS++)) || true; }
fail() { echo "  [FAIL] $1"; ((FAIL++)) || true; }

echo "EDGE CASE: Dependency Violation Prevention"
echo "============================================"

# Check implement.md enforces PSI before PHA
if grep -qi "never suggest PHA.*PSI.*incomplete\|PSI.*must.*complete.*before.*PHA\|never.*PHA.*if.*PSI" "$PLUGIN_DIR/commands/implement.md"; then
    pass "implement.md enforces PSI-before-PHA dependency"
else
    fail "implement.md missing PSI-before-PHA enforcement"
fi

# Check implement.md enforces PHA before procedures
if grep -qi "never suggest.*procedure.*PHA.*incomplete\|PHA.*must.*complete.*before.*procedure\|never.*procedure.*if.*PHA" "$PLUGIN_DIR/commands/implement.md"; then
    pass "implement.md enforces PHA-before-procedures dependency"
else
    fail "implement.md missing PHA-before-procedures enforcement"
fi

# Check implement.md enforces procedures before training
if grep -qi "never suggest.*training.*procedure.*don.t exist\|procedure.*must.*exist.*before.*training\|never.*training.*if.*procedure" "$PLUGIN_DIR/commands/implement.md"; then
    pass "implement.md enforces procedures-before-training dependency"
else
    fail "implement.md missing procedures-before-training enforcement"
fi

# Check implement.md puts compliance audits last
if grep -qi "audit.*last\|audit.*only after\|audit.*PARTIAL" "$PLUGIN_DIR/commands/implement.md"; then
    pass "implement.md puts compliance audits last in sequence"
else
    fail "implement.md missing audits-last enforcement"
fi

# Check implement.md has the dependency graph
if grep -qi "dependency\|sequencing" "$PLUGIN_DIR/commands/implement.md"; then
    pass "implement.md documents the dependency graph"
else
    fail "implement.md missing dependency graph documentation"
fi

echo ""; echo "RESULTS: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
