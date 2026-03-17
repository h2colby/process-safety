#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="${1:-.}"
PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; ((PASS++)) || true; }
fail() { echo "  [FAIL] $1"; ((FAIL++)) || true; }

echo "BEGINNER SCENARIO — Implementation Dependency Verification"
echo "============================================================"
echo ""

# 1. State file exists and generation is complete
if python3 -c "
import json
with open('$WORK_DIR/.claude/process-safety.local.json') as f:
    state = json.load(f)
assert state['generation']['completed'] == True
" 2>/dev/null; then
    pass "State file exists and generation is complete"
else
    fail "State file missing or generation not complete"
    echo ""; echo "RESULTS: $PASS passed, $FAIL failed"; exit 1
fi

# 2. Implementation phase is PSI-related
if python3 -c "
import json
with open('$WORK_DIR/.claude/process-safety.local.json') as f:
    state = json.load(f)
phase = state.get('implementation', {}).get('phase', '')
assert 'psi' in phase.lower(), f'Implementation phase is \"{phase}\", expected PSI-related'
" 2>/dev/null; then
    pass "Implementation phase is PSI-related"
else
    fail "Implementation phase is not PSI-related (PSI should be first priority)"
fi

# 3. Crosswalk shows PSI-related clauses (1910.119(d)) as GAP or NEEDS INPUT
CROSSWALK=$(find "$WORK_DIR/PSM_PROGRAM/00_MASTER" -name "*crosswalk*" -o -name "*Crosswalk*" -o -name "*CROSSWALK*" 2>/dev/null | head -1)
if [ -n "$CROSSWALK" ] && [ -f "$CROSSWALK" ]; then
    # PSI clauses are 1910.119(d) — they should NOT be COMPLETE yet
    if grep "1910\.119(d)" "$CROSSWALK" 2>/dev/null | grep -qi "COMPLETE"; then
        fail "PSI clauses (1910.119(d)) marked COMPLETE before implementation"
    else
        pass "PSI clauses (1910.119(d)) are not marked COMPLETE (correct — PSI not yet implemented)"
    fi
else
    fail "Crosswalk not found — cannot verify PSI clause status"
fi

# 4. PHA clauses (1910.119(e)) should be GAP (PHA can't be done before PSI)
if [ -n "$CROSSWALK" ] && [ -f "$CROSSWALK" ]; then
    if grep "1910\.119(e)" "$CROSSWALK" 2>/dev/null | grep -qi "COMPLETE"; then
        fail "PHA clauses (1910.119(e)) marked COMPLETE before PSI is done"
    else
        pass "PHA clauses (1910.119(e)) are not marked COMPLETE (correct — PHA depends on PSI)"
    fi
else
    fail "Crosswalk not found — cannot verify PHA clause status"
fi

# 5. Next priority in state mentions PSI
if python3 -c "
import json
with open('$WORK_DIR/.claude/process-safety.local.json') as f:
    state = json.load(f)
impl = state.get('implementation', {})
phase = impl.get('phase', '').lower()
next_priority = impl.get('next_priority', '').lower()
combined = phase + ' ' + next_priority
assert 'psi' in combined or 'process safety information' in combined, \
    f'Next priority does not mention PSI: phase=\"{phase}\", next_priority=\"{next_priority}\"'
" 2>/dev/null; then
    pass "Next priority references PSI (not PHA, not procedures, not training)"
else
    fail "Next priority does not reference PSI — dependency order may be wrong"
fi

echo ""
echo "============================================================"
echo "RESULTS: $PASS passed, $FAIL failed, $((PASS+FAIL)) total"
[ $FAIL -eq 0 ] && exit 0 || exit 1
