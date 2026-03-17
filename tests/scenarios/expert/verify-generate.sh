#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="${1:-.}"
PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; ((PASS++)) || true; }
fail() { echo "  [FAIL] $1"; ((FAIL++)) || true; }

echo "EXPERT SCENARIO — Post-Generation Verification"
echo "================================================"
echo ""

# --- Standard generation checks (same as beginner) ---

# 1. Check all expected directories exist
EXPECTED_DIRS=(
    "PSM_PROGRAM/00_MASTER"
    "PSM_PROGRAM/01_EMPLOYEE_PARTICIPATION"
    "PSM_PROGRAM/02_PROCESS_SAFETY_INFORMATION"
    "PSM_PROGRAM/03_PROCESS_HAZARD_ANALYSIS"
    "PSM_PROGRAM/04_OPERATING_PROCEDURES"
    "PSM_PROGRAM/05_TRAINING"
    "PSM_PROGRAM/06_CONTRACTORS"
    "PSM_PROGRAM/07_PSSR"
    "PSM_PROGRAM/08_MECHANICAL_INTEGRITY"
    "PSM_PROGRAM/09_HOT_WORK"
    "PSM_PROGRAM/10_MOC"
    "PSM_PROGRAM/11_INCIDENT_INVESTIGATION"
    "PSM_PROGRAM/12_EMERGENCY_RESPONSE"
    "PSM_PROGRAM/13_COMPLIANCE_AUDITS"
    "PSM_PROGRAM/14_TRADE_SECRETS"
    "PSM_PROGRAM/90_FORMS"
    "PSM_PROGRAM/92_REGISTERS"
)
ALL_DIRS_OK=true
for d in "${EXPECTED_DIRS[@]}"; do
    if [ ! -d "$WORK_DIR/$d" ]; then
        fail "Missing directory: $d"
        ALL_DIRS_OK=false
    fi
done
if $ALL_DIRS_OK; then
    pass "All expected directories exist (${#EXPECTED_DIRS[@]} directories)"
fi

# 2. Total document count >= 41
DOC_COUNT=$(find "$WORK_DIR/PSM_PROGRAM" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$DOC_COUNT" -ge 41 ]; then
    pass "Document count is $DOC_COUNT (>= 41 required)"
else
    fail "Document count is $DOC_COUNT (expected >= 41)"
fi

# 3. All 14 element procedure files exist
ELEMENT_DIRS=(
    "01_EMPLOYEE_PARTICIPATION"
    "02_PROCESS_SAFETY_INFORMATION"
    "03_PROCESS_HAZARD_ANALYSIS"
    "04_OPERATING_PROCEDURES"
    "05_TRAINING"
    "06_CONTRACTORS"
    "07_PSSR"
    "08_MECHANICAL_INTEGRITY"
    "09_HOT_WORK"
    "10_MOC"
    "11_INCIDENT_INVESTIGATION"
    "12_EMERGENCY_RESPONSE"
    "13_COMPLIANCE_AUDITS"
    "14_TRADE_SECRETS"
)
ALL_PROCS_OK=true
for d in "${ELEMENT_DIRS[@]}"; do
    MD_COUNT=$(find "$WORK_DIR/PSM_PROGRAM/$d" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$MD_COUNT" -lt 1 ]; then
        fail "No procedure file in $d"
        ALL_PROCS_OK=false
    fi
done
if $ALL_PROCS_OK; then
    pass "All 14 element folders contain at least one procedure file"
fi

# 4. Forms count
FORM_COUNT=$(find "$WORK_DIR/PSM_PROGRAM/90_FORMS" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$FORM_COUNT" -ge 13 ]; then
    pass "Forms count is $FORM_COUNT (>= 13 required)"
else
    fail "Forms count is $FORM_COUNT (expected >= 13)"
fi

# 5. Registers count
REG_COUNT=$(find "$WORK_DIR/PSM_PROGRAM/92_REGISTERS" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$REG_COUNT" -ge 7 ]; then
    pass "Register count is $REG_COUNT (>= 7 required)"
else
    fail "Register count is $REG_COUNT (expected >= 7)"
fi

# 6. Master manual exists
if find "$WORK_DIR/PSM_PROGRAM/00_MASTER" -name "*manual*" -o -name "*Manual*" -o -name "*MANUAL*" 2>/dev/null | grep -q .; then
    pass "Master manual exists in 00_MASTER"
else
    fail "Master manual not found in 00_MASTER"
fi

# 7. Compliance crosswalk exists
CROSSWALK=$(find "$WORK_DIR/PSM_PROGRAM/00_MASTER" -name "*crosswalk*" -o -name "*Crosswalk*" -o -name "*CROSSWALK*" 2>/dev/null | head -1)
if [ -n "$CROSSWALK" ] && [ -f "$CROSSWALK" ]; then
    CFR_REFS=$(grep -c "1910\.119" "$CROSSWALK" 2>/dev/null || echo 0)
    if [ "$CFR_REFS" -ge 80 ]; then
        pass "Compliance crosswalk has $CFR_REFS CFR references (>= 80 required)"
    else
        fail "Compliance crosswalk has only $CFR_REFS CFR references (expected >= 80)"
    fi
else
    fail "Compliance crosswalk not found in 00_MASTER"
fi

# 8. State file shows generation complete
if python3 -c "
import json
with open('$WORK_DIR/.claude/process-safety.local.json') as f:
    state = json.load(f)
assert state['generation']['completed'] == True
assert state['generation']['document_count'] >= 41
" 2>/dev/null; then
    pass "State: generation complete with >= 41 documents"
else
    fail "State: generation not complete or document_count < 41"
fi

# --- Expert-specific checks ---

# 9. No "Tobe Energy" or "TestCo" — company should be "HydroChem"
TOBE_REFS=$(grep -rl "Tobe Energy" "$WORK_DIR/PSM_PROGRAM/" 2>/dev/null | wc -l | tr -d ' ')
TESTCO_REFS=$(grep -rl "TestCo" "$WORK_DIR/PSM_PROGRAM/" 2>/dev/null | wc -l | tr -d ' ')
if [ "$TOBE_REFS" -eq 0 ] && [ "$TESTCO_REFS" -eq 0 ]; then
    pass "No 'Tobe Energy' or 'TestCo' references (correctly using HydroChem)"
else
    fail "Found stale company names: Tobe Energy in $TOBE_REFS files, TestCo in $TESTCO_REFS files"
fi

# 10. Company name "HydroChem" appears in master manual
MASTER=$(find "$WORK_DIR/PSM_PROGRAM/00_MASTER" -name "*manual*" -o -name "*Manual*" 2>/dev/null | head -1)
if [ -n "$MASTER" ] && grep -q "HydroChem" "$MASTER" 2>/dev/null; then
    pass "Company name 'HydroChem' appears in master manual"
else
    fail "Company name 'HydroChem' not found in master manual"
fi

# 11. Covered process register has 2 entries (CP-001, CP-002)
PROC_REG=$(find "$WORK_DIR/PSM_PROGRAM/92_REGISTERS" -name "*process*" -o -name "*covered*" 2>/dev/null | head -1)
if [ -n "$PROC_REG" ] && [ -f "$PROC_REG" ]; then
    CP001=$(grep -c "CP-001" "$PROC_REG" 2>/dev/null || echo 0)
    CP002=$(grep -c "CP-002" "$PROC_REG" 2>/dev/null || echo 0)
    if [ "$CP001" -ge 1 ] && [ "$CP002" -ge 1 ]; then
        pass "Covered process register has both CP-001 and CP-002"
    else
        fail "Covered process register missing CP-001 ($CP001 refs) or CP-002 ($CP002 refs)"
    fi
else
    fail "Covered process register not found in 92_REGISTERS"
fi

# 12. Chemical inventory register has both hydrogen and ammonia
CHEM_REG=$(find "$WORK_DIR/PSM_PROGRAM/92_REGISTERS" -name "*chemical*" -o -name "*inventory*" 2>/dev/null | head -1)
if [ -n "$CHEM_REG" ] && [ -f "$CHEM_REG" ]; then
    HAS_H2=$(grep -ci "1333-74-0\|hydrogen" "$CHEM_REG" 2>/dev/null || echo 0)
    HAS_NH3=$(grep -ci "7664-41-7\|ammonia" "$CHEM_REG" 2>/dev/null || echo 0)
    if [ "$HAS_H2" -ge 1 ] && [ "$HAS_NH3" -ge 1 ]; then
        pass "Chemical inventory register has hydrogen (1333-74-0) and ammonia (7664-41-7)"
    else
        fail "Chemical inventory missing hydrogen ($HAS_H2 refs) or ammonia ($HAS_NH3 refs)"
    fi
else
    fail "Chemical inventory register not found in 92_REGISTERS"
fi

# 13. PHA schedule has 2 entries
PHA_REG=$(find "$WORK_DIR/PSM_PROGRAM/92_REGISTERS" -name "*pha*" -o -name "*PHA*" -o -name "*hazard*" 2>/dev/null | head -1)
if [ -n "$PHA_REG" ] && [ -f "$PHA_REG" ]; then
    PHA_CP001=$(grep -c "CP-001\|H2 Production\|Hydrogen" "$PHA_REG" 2>/dev/null || echo 0)
    PHA_CP002=$(grep -c "CP-002\|NH3 Refrigeration\|Ammonia" "$PHA_REG" 2>/dev/null || echo 0)
    if [ "$PHA_CP001" -ge 1 ] && [ "$PHA_CP002" -ge 1 ]; then
        pass "PHA schedule has entries for both processes"
    else
        fail "PHA schedule missing entries for CP-001 ($PHA_CP001) or CP-002 ($PHA_CP002)"
    fi
else
    fail "PHA schedule register not found"
fi

# 14. Gap register reflects that P&IDs exist (P&ID gaps at lower severity)
GAP_REG=$(find "$WORK_DIR/PSM_PROGRAM" -name "*gap*register*" -o -name "*Gap*Register*" -o -name "*GAP*" 2>/dev/null | head -1)
if [ -n "$GAP_REG" ] && [ -f "$GAP_REG" ]; then
    # P&ID gaps should exist but at LOW severity since P&IDs already exist
    PID_GAPS=$(grep -i "P&ID\|PID\|piping.*instrument" "$GAP_REG" 2>/dev/null || true)
    if echo "$PID_GAPS" | grep -qi "low\|existing\|available"; then
        pass "Gap register reflects existing P&IDs (lower severity)"
    elif [ -z "$PID_GAPS" ]; then
        pass "No P&ID gaps listed (P&IDs exist, gaps correctly omitted)"
    else
        fail "Gap register has P&ID gaps but doesn't reflect that P&IDs already exist"
    fi
else
    fail "Gap register not found"
fi

# 15. Roles include real names
ALL_DOCS=$(find "$WORK_DIR/PSM_PROGRAM" -name "*.md" -type f 2>/dev/null)
NAMES_FOUND=0
for NAME in Sarah Mike Tom Carlos Lisa; do
    if echo "$ALL_DOCS" | xargs grep -l "$NAME" 2>/dev/null | head -1 | grep -q .; then
        ((NAMES_FOUND++))
    fi
done
if [ "$NAMES_FOUND" -ge 4 ]; then
    pass "At least $NAMES_FOUND of 5 personnel names found in generated documents"
else
    fail "Only $NAMES_FOUND of 5 personnel names found (expected >= 4)"
fi

echo ""
echo "================================================"
echo "RESULTS: $PASS passed, $FAIL failed, $((PASS+FAIL)) total"
[ $FAIL -eq 0 ] && exit 0 || exit 1
