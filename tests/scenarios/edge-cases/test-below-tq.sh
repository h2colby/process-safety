#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
PASS=0; FAIL=0
pass() { echo "  [PASS] $1"; ((PASS++)) || true; }
fail() { echo "  [FAIL] $1"; ((FAIL++)) || true; }

echo "EDGE CASE: Below-TQ Determination"
echo "==================================="

# Test: Ammonia at 5000 lbs should be BELOW the TQ of 10000
if python3 -c "
import json
with open('$PLUGIN_DIR/data/appendix-a.json') as f:
    data = json.load(f)
ammonia = [c for c in data['chemicals'] if c['cas'] == '7664-41-7' and 'Anhydrous' in c['chemical']][0]
assert 5000 < ammonia['tq_lbs'], f'5000 should be below TQ of {ammonia[\"tq_lbs\"]}'
print(f'Ammonia TQ is {ammonia[\"tq_lbs\"]} lbs; 5000 lbs is below threshold')
" 2>/dev/null; then
    pass "Below-TQ comparison works for ammonia (5000 < 10000)"
else
    fail "Below-TQ comparison failed for ammonia"
fi

# Test: Chlorine at 2000 lbs should be ABOVE the TQ of 1500
if python3 -c "
import json
with open('$PLUGIN_DIR/data/appendix-a.json') as f:
    data = json.load(f)
chlorine = [c for c in data['chemicals'] if c['chemical'] == 'Chlorine'][0]
assert 2000 >= chlorine['tq_lbs'], f'2000 should meet/exceed TQ of {chlorine[\"tq_lbs\"]}'
print(f'Chlorine TQ is {chlorine[\"tq_lbs\"]} lbs; 2000 lbs meets threshold')
" 2>/dev/null; then
    pass "At/above-TQ comparison works for chlorine (2000 >= 1500)"
else
    fail "At/above-TQ comparison failed for chlorine"
fi

# Test: All TQ values are positive integers
if python3 -c "
import json
with open('$PLUGIN_DIR/data/appendix-a.json') as f:
    data = json.load(f)
for c in data['chemicals']:
    assert isinstance(c['tq_lbs'], int) and c['tq_lbs'] > 0, f'{c[\"chemical\"]}: invalid TQ {c[\"tq_lbs\"]}'
print(f'All {len(data[\"chemicals\"])} chemicals have valid positive integer TQ values')
" 2>/dev/null; then
    pass "All Appendix A TQ values are positive integers"
else
    fail "Some Appendix A TQ values are invalid"
fi

# Same for RMP
if python3 -c "
import json
with open('$PLUGIN_DIR/data/rmp-chemicals.json') as f:
    data = json.load(f)
for c in data['toxic_substances'] + data['flammable_substances']:
    assert isinstance(c['tq_lbs'], int) and c['tq_lbs'] > 0, f'{c[\"chemical\"]}: invalid TQ'
total = len(data['toxic_substances']) + len(data['flammable_substances'])
print(f'All {total} RMP chemicals have valid positive integer TQ values')
" 2>/dev/null; then
    pass "All RMP TQ values are positive integers"
else
    fail "Some RMP TQ values are invalid"
fi

echo ""; echo "RESULTS: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
