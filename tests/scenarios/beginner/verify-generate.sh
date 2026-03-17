#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="${1:-.}"
PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; ((PASS++)) || true; }
fail() { echo "  [FAIL] $1"; ((FAIL++)) || true; }

echo "BEGINNER SCENARIO — Post-Generation Verification"
echo "=================================================="
echo ""

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

# 3. All 14 element procedure files exist (one per element folder)
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

# 4. All 13 forms exist in 90_FORMS/
FORM_COUNT=$(find "$WORK_DIR/PSM_PROGRAM/90_FORMS" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$FORM_COUNT" -ge 13 ]; then
    pass "Forms count is $FORM_COUNT (>= 13 required)"
else
    fail "Forms count is $FORM_COUNT (expected >= 13)"
fi

# 5. All 7 registers exist in 92_REGISTERS/
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

# 7. Compliance crosswalk exists and has >80 CFR clause references
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

# 8. Gap register exists and has at least one entry
GAP_REG=$(find "$WORK_DIR/PSM_PROGRAM" -name "*gap*register*" -o -name "*Gap*Register*" -o -name "*GAP*" 2>/dev/null | head -1)
if [ -n "$GAP_REG" ] && [ -f "$GAP_REG" ]; then
    GAP_LINES=$(wc -l < "$GAP_REG" | tr -d ' ')
    if [ "$GAP_LINES" -gt 5 ]; then
        pass "Gap register exists with content ($GAP_LINES lines)"
    else
        fail "Gap register exists but appears empty"
    fi
else
    fail "Gap register not found"
fi

# 9. Document register exists
if find "$WORK_DIR/PSM_PROGRAM" -name "*document*register*" -o -name "*Document*Register*" -o -name "*doc*register*" 2>/dev/null | grep -q .; then
    pass "Document register exists"
else
    fail "Document register not found"
fi

# 10. No "Tobe Energy" strings in generated docs (company should be "TestCo")
TOBE_REFS=$(grep -rl "Tobe Energy" "$WORK_DIR/PSM_PROGRAM/" 2>/dev/null | wc -l | tr -d ' ')
if [ "$TOBE_REFS" -eq 0 ]; then
    pass "No 'Tobe Energy' references found (correctly using TestCo)"
else
    fail "Found 'Tobe Energy' in $TOBE_REFS files (should be TestCo)"
fi

# 11. Company name "TestCo" appears in master manual
MASTER=$(find "$WORK_DIR/PSM_PROGRAM/00_MASTER" -name "*manual*" -o -name "*Manual*" 2>/dev/null | head -1)
if [ -n "$MASTER" ] && grep -q "TestCo" "$MASTER" 2>/dev/null; then
    pass "Company name 'TestCo' appears in master manual"
else
    fail "Company name 'TestCo' not found in master manual"
fi

# 12. State file shows generation.completed = true
if python3 -c "
import json
with open('$WORK_DIR/.claude/process-safety.local.json') as f:
    state = json.load(f)
assert state['generation']['completed'] == True
" 2>/dev/null; then
    pass "State: generation.completed is true"
else
    fail "State: generation.completed is not true"
fi

# 13. State file shows document_count >= 41
if python3 -c "
import json
with open('$WORK_DIR/.claude/process-safety.local.json') as f:
    state = json.load(f)
assert state['generation']['document_count'] >= 41, f'document_count is {state[\"generation\"][\"document_count\"]}'
" 2>/dev/null; then
    pass "State: document_count >= 41"
else
    fail "State: document_count < 41"
fi

# 14. Self-review report exists
if find "$WORK_DIR/PSM_PROGRAM" -name "*self-review*" -o -name "*validation*" -o -name "*self_review*" 2>/dev/null | grep -q .; then
    pass "Self-review / validation report exists"
else
    fail "Self-review / validation report not found"
fi

echo ""
echo "=================================================="
echo "RESULTS: $PASS passed, $FAIL failed, $((PASS+FAIL)) total"
[ $FAIL -eq 0 ] && exit 0 || exit 1
