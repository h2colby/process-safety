#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="${1:-.}"
PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; ((PASS++)) || true; }
fail() { echo "  [FAIL] $1"; ((FAIL++)) || true; }

echo "BEGINNER SCENARIO — Post-Screening Verification"
echo "================================================="
echo ""

# Check screening report exists
if [ -f "$WORK_DIR/PSM_PROGRAM/00_MASTER/screening-report.md" ]; then
    pass "Screening report exists"
else
    fail "Screening report not found at PSM_PROGRAM/00_MASTER/screening-report.md"
fi

# Check state file exists
if [ -f "$WORK_DIR/.claude/process-safety.local.json" ]; then
    pass "State file exists"
else
    fail "State file not found"
    echo ""; echo "RESULTS: $PASS passed, $FAIL failed"; exit 1
fi

# Check screening completed
if python3 -c "
import json
with open('$WORK_DIR/.claude/process-safety.local.json') as f:
    state = json.load(f)
assert state['screening']['completed'] == True
" 2>/dev/null; then
    pass "Screening marked as completed"
else
    fail "Screening not marked as completed in state"
fi

# Check PSM applicable
if python3 -c "
import json
with open('$WORK_DIR/.claude/process-safety.local.json') as f:
    state = json.load(f)
assert state['screening']['psm_applicable'] == True
" 2>/dev/null; then
    pass "PSM marked as applicable"
else
    fail "PSM not marked as applicable"
fi

# Check RMP applicable
if python3 -c "
import json
with open('$WORK_DIR/.claude/process-safety.local.json') as f:
    state = json.load(f)
assert state['screening']['rmp_applicable'] == True
" 2>/dev/null; then
    pass "RMP marked as applicable"
else
    fail "RMP not marked as applicable"
fi

# Check RMP program level
if python3 -c "
import json
with open('$WORK_DIR/.claude/process-safety.local.json') as f:
    state = json.load(f)
assert state['screening']['rmp_program_level'] == 3
" 2>/dev/null; then
    pass "RMP Program Level is 3"
else
    fail "RMP Program Level is not 3"
fi

# Check ammonia is in chemicals array
if python3 -c "
import json
with open('$WORK_DIR/.claude/process-safety.local.json') as f:
    state = json.load(f)
chems = state.get('chemicals', [])
assert len(chems) > 0, 'No chemicals in state'
found = any('7664-41-7' in str(c.get('cas','')) for c in chems)
assert found, 'Ammonia CAS 7664-41-7 not found in chemicals'
" 2>/dev/null; then
    pass "Ammonia (CAS 7664-41-7) in chemicals array"
else
    fail "Ammonia not found in chemicals array"
fi

# Check screening report mentions PSM applicable
if grep -qi "psm.*applicable\|applicable.*psm\|PSM Applicable\|OSHA PSM.*YES\|PSM.*YES" "$WORK_DIR/PSM_PROGRAM/00_MASTER/screening-report.md" 2>/dev/null; then
    pass "Screening report indicates PSM applicable"
else
    fail "Screening report doesn't clearly indicate PSM applicability"
fi

echo ""
echo "================================================="
echo "RESULTS: $PASS passed, $FAIL failed, $((PASS+FAIL)) total"
[ $FAIL -eq 0 ] && exit 0 || exit 1
