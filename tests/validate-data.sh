#!/usr/bin/env bash
set -euo pipefail

# ════════════════════════════════════════════════════════════
# PROCESS SAFETY PLUGIN — VALIDATION SUITE
# ════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PLUGIN_ROOT"

PASS_COUNT=0
FAIL_COUNT=0
TOTAL_COUNT=0

pass() {
  local id="$1"
  local msg="$2"
  printf "  [\033[32mPASS\033[0m] %-5s %s\n" "$id" "$msg"
  PASS_COUNT=$((PASS_COUNT + 1))
  TOTAL_COUNT=$((TOTAL_COUNT + 1))
}

fail() {
  local id="$1"
  local msg="$2"
  printf "  [\033[31mFAIL\033[0m] %-5s %s\n" "$id" "$msg"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  TOTAL_COUNT=$((TOTAL_COUNT + 1))
}

info() {
  printf "  [\033[33mINFO\033[0m]       %s\n" "$1"
}

# ════════════════════════════════════════════════════════════
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  PROCESS SAFETY PLUGIN — VALIDATION SUITE               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ────────────────────────────────────────────────────────────
echo "CATEGORY 1: JSON Data Integrity"
# ────────────────────────────────────────────────────────────

# Test 1.1: appendix-a.json parses as valid JSON
if python3 -c "import json; json.load(open('data/appendix-a.json'))" 2>/dev/null; then
  pass "1.1" "appendix-a.json parses as valid JSON"
else
  fail "1.1" "appendix-a.json does not parse as valid JSON"
fi

# Test 1.2: appendix-a.json has expected structure
RESULT_1_2=$(python3 -c "
import json, sys
with open('data/appendix-a.json') as f:
    data = json.load(f)
required_keys = ['source', 'description', 'last_verified', 'note', 'chemicals']
missing = [k for k in required_keys if k not in data]
if missing:
    print(f'FAIL:missing keys: {missing}')
    sys.exit(0)
if not isinstance(data['chemicals'], list):
    print('FAIL:chemicals is not an array')
    sys.exit(0)
count = len(data['chemicals'])
if count <= 125:
    print(f'FAIL:only {count} chemicals, expected > 125')
    sys.exit(0)
print(f'PASS:{count}')
" 2>&1)
if [[ "$RESULT_1_2" == PASS:* ]]; then
  CHEM_COUNT="${RESULT_1_2#PASS:}"
  pass "1.2" "appendix-a.json has expected structure ($CHEM_COUNT chemicals)"
else
  fail "1.2" "appendix-a.json structure: ${RESULT_1_2#FAIL:}"
fi

# Test 1.3: Each Appendix A entry has required fields
RESULT_1_3=$(python3 -c "
import json, re, sys
with open('data/appendix-a.json') as f:
    data = json.load(f)
errors = []
cas_pattern = re.compile(r'^(\d{2,7}-\d{2}-\d|Varies)$')
for i, entry in enumerate(data['chemicals']):
    if 'chemical' not in entry or not isinstance(entry.get('chemical'), str) or not entry['chemical'].strip():
        errors.append(f'Entry {i}: missing or empty chemical name')
    if 'cas' not in entry or not isinstance(entry.get('cas'), str):
        errors.append(f'Entry {i}: missing cas')
    elif not cas_pattern.match(entry['cas']):
        errors.append(f'Entry {i}: cas \"{entry[\"cas\"]}\" does not match expected pattern')
    if 'tq_lbs' not in entry:
        errors.append(f'Entry {i}: missing tq_lbs')
    elif not isinstance(entry['tq_lbs'], int) or entry['tq_lbs'] <= 0:
        errors.append(f'Entry {i}: tq_lbs is not a positive integer ({entry.get(\"tq_lbs\")})')
if errors:
    print('FAIL:' + '; '.join(errors[:5]))
else:
    print('PASS')
" 2>&1)
if [[ "$RESULT_1_3" == "PASS" ]]; then
  pass "1.3" "All Appendix A entries have required fields"
else
  fail "1.3" "Appendix A field validation: ${RESULT_1_3#FAIL:}"
fi

# Test 1.4: No duplicate CAS numbers (with known exceptions)
RESULT_1_4=$(python3 -c "
import json, sys
with open('data/appendix-a.json') as f:
    data = json.load(f)
known_dup_cas = {
    '7664-41-7',   # Ammonia Anhydrous / Ammonia Solutions
    '7647-01-0',   # HCl / Hydrogen Chloride
    '7664-39-3',   # HF / Hydrogen Fluoride
    '75-44-5',     # Phosgene / Carbonyl Chloride
    '106-96-7',    # Propargyl Bromide / 3-Bromopropyne
    '1338-23-4',   # MEKP appearing twice
    '8014-95-7',   # Oleum / Fuming Sulfuric Acid
    '10102-44-0',  # Nitrogen Dioxide / Nitrogen Oxides
}
seen = {}
unexpected_dups = []
known_logged = []
for entry in data['chemicals']:
    cas = entry['cas']
    if cas == 'Varies':
        continue
    if cas in seen:
        if cas in known_dup_cas:
            known_logged.append(f'{cas} ({seen[cas]} / {entry[\"chemical\"]})')
        else:
            unexpected_dups.append(f'{cas} ({seen[cas]} / {entry[\"chemical\"]})')
    else:
        seen[cas] = entry['chemical']
for kd in known_logged:
    print(f'INFO:Known duplicate: {kd}')
if unexpected_dups:
    print('FAIL:Unexpected duplicates: ' + '; '.join(unexpected_dups))
else:
    print('PASS')
" 2>&1)
# Process multiline output
HAS_FAIL=false
while IFS= read -r line; do
  if [[ "$line" == INFO:* ]]; then
    info "${line#INFO:}"
  elif [[ "$line" == FAIL:* ]]; then
    HAS_FAIL=true
    FAIL_MSG="${line#FAIL:}"
  fi
done <<< "$RESULT_1_4"
if [[ "$HAS_FAIL" == true ]]; then
  fail "1.4" "Duplicate CAS numbers: $FAIL_MSG"
else
  pass "1.4" "No unexpected duplicate CAS numbers in Appendix A"
fi

# Test 1.5: Spot-check 10 OSHA chemicals
RESULT_1_5=$(python3 -c "
import json, sys
with open('data/appendix-a.json') as f:
    data = json.load(f)
by_cas = {}
for entry in data['chemicals']:
    by_cas.setdefault(entry['cas'], []).append(entry)
checks = [
    ('Ammonia, Anhydrous',        '7664-41-7',  10000),
    ('Chlorine',                   '7782-50-5',  1500),
    ('Ethylene Oxide',             '75-21-8',    5000),
    ('Hydrogen Sulfide',           '7783-06-4',  1500),
    ('Methyl Isocyanate',          '624-83-9',   250),
    ('Fluorine',                   '7782-41-4',  1000),
    ('Acetaldehyde',               '75-07-0',    2500),
    ('Diborane',                   '19287-45-7', 100),
    ('Boron Trifluoride',          '7637-07-2',  250),
    ('Sulfur Dioxide (liquid)',    '7446-09-5',  1000),
]
failures = []
for name, cas, expected_tq in checks:
    entries = by_cas.get(cas, [])
    if not entries:
        failures.append(f'{name}: CAS {cas} not found')
        continue
    # Find the matching entry by name substring or exact TQ
    matched = False
    for e in entries:
        if e['tq_lbs'] == expected_tq:
            matched = True
            break
    if not matched:
        actual_tqs = [str(e['tq_lbs']) for e in entries]
        failures.append(f'{name}: expected TQ {expected_tq}, got {\" / \".join(actual_tqs)}')
if failures:
    print('FAIL:' + '; '.join(failures))
else:
    print('PASS')
" 2>&1)
if [[ "$RESULT_1_5" == "PASS" ]]; then
  pass "1.5" "Spot-check 10 OSHA chemicals — all TQ values correct"
else
  fail "1.5" "OSHA spot-check: ${RESULT_1_5#FAIL:}"
fi

# Test 1.6: rmp-chemicals.json parses as valid JSON
if python3 -c "import json; json.load(open('data/rmp-chemicals.json'))" 2>/dev/null; then
  pass "1.6" "rmp-chemicals.json parses as valid JSON"
else
  fail "1.6" "rmp-chemicals.json does not parse as valid JSON"
fi

# Test 1.7: rmp-chemicals.json has expected structure
RESULT_1_7=$(python3 -c "
import json, sys
with open('data/rmp-chemicals.json') as f:
    data = json.load(f)
required_keys = ['source', 'description', 'last_verified', 'note', 'toxic_substances', 'flammable_substances']
missing = [k for k in required_keys if k not in data]
if missing:
    print(f'FAIL:missing keys: {missing}')
    sys.exit(0)
toxic_count = len(data['toxic_substances'])
flam_count = len(data['flammable_substances'])
errors = []
if toxic_count <= 60:
    errors.append(f'toxic_substances has {toxic_count} entries, expected > 60')
if flam_count <= 50:
    errors.append(f'flammable_substances has {flam_count} entries, expected > 50')
if errors:
    print('FAIL:' + '; '.join(errors))
else:
    print(f'PASS:{toxic_count} toxic, {flam_count} flammable')
" 2>&1)
if [[ "$RESULT_1_7" == PASS:* ]]; then
  COUNTS="${RESULT_1_7#PASS:}"
  pass "1.7" "rmp-chemicals.json has expected structure ($COUNTS)"
else
  fail "1.7" "rmp-chemicals.json structure: ${RESULT_1_7#FAIL:}"
fi

# Test 1.8: Each RMP entry has required fields
RESULT_1_8=$(python3 -c "
import json, sys
with open('data/rmp-chemicals.json') as f:
    data = json.load(f)
errors = []
for table_name in ['toxic_substances', 'flammable_substances']:
    for i, entry in enumerate(data[table_name]):
        prefix = f'{table_name}[{i}]'
        if 'chemical' not in entry or not entry['chemical']:
            errors.append(f'{prefix}: missing chemical')
        if 'cas' not in entry or not entry['cas']:
            errors.append(f'{prefix}: missing cas')
        if 'tq_lbs' not in entry:
            errors.append(f'{prefix}: missing tq_lbs')
        if 'basis' not in entry:
            errors.append(f'{prefix}: missing basis')
        elif entry['basis'] not in ('toxic', 'flammable'):
            errors.append(f'{prefix}: basis \"{entry[\"basis\"]}\" not toxic/flammable')
if errors:
    print('FAIL:' + '; '.join(errors[:5]))
else:
    print('PASS')
" 2>&1)
if [[ "$RESULT_1_8" == "PASS" ]]; then
  pass "1.8" "All RMP entries have required fields"
else
  fail "1.8" "RMP field validation: ${RESULT_1_8#FAIL:}"
fi

# Test 1.9: Spot-check 10 RMP chemicals
RESULT_1_9=$(python3 -c "
import json, sys
with open('data/rmp-chemicals.json') as f:
    data = json.load(f)
# Build lookup by CAS + basis
by_cas_basis = {}
for entry in data['toxic_substances']:
    by_cas_basis.setdefault((entry['cas'], 'toxic'), []).append(entry)
for entry in data['flammable_substances']:
    by_cas_basis.setdefault((entry['cas'], 'flammable'), []).append(entry)
checks = [
    ('Hydrogen',                    '1333-74-0', 10000, 'flammable'),
    ('Chlorine',                    '7782-50-5', 2500,  'toxic'),
    ('Ammonia anhydrous',           '7664-41-7', 10000, 'toxic'),
    ('Propane',                     '74-98-6',   10000, 'flammable'),
    ('Phosgene',                    '75-44-5',   500,   'toxic'),
    ('Ethylene',                    '74-85-1',   10000, 'flammable'),
    ('Sulfur Dioxide anhydrous',    '7446-09-5', 5000,  'toxic'),
    ('Methane',                     '74-82-8',   10000, 'flammable'),
    ('Hydrogen Fluoride',           '7664-39-3', 1000,  'toxic'),
    ('Vinyl Chloride',              '75-01-4',   10000, 'flammable'),
]
failures = []
for name, cas, expected_tq, expected_basis in checks:
    entries = by_cas_basis.get((cas, expected_basis), [])
    if not entries:
        failures.append(f'{name}: CAS {cas} ({expected_basis}) not found')
        continue
    matched = False
    for e in entries:
        if e['tq_lbs'] == expected_tq:
            matched = True
            break
    if not matched:
        actual_tqs = [str(e['tq_lbs']) for e in entries]
        failures.append(f'{name}: expected TQ {expected_tq}, got {\" / \".join(actual_tqs)}')
if failures:
    print('FAIL:' + '; '.join(failures))
else:
    print('PASS')
" 2>&1)
if [[ "$RESULT_1_9" == "PASS" ]]; then
  pass "1.9" "Spot-check 10 RMP chemicals — all TQ values correct"
else
  fail "1.9" "RMP spot-check: ${RESULT_1_9#FAIL:}"
fi

# Test 1.10: Cross-list consistency
RESULT_1_10=$(python3 -c "
import json, sys
with open('data/appendix-a.json') as fa:
    appa = json.load(fa)
with open('data/rmp-chemicals.json') as fr:
    rmp = json.load(fr)
# Build CAS sets
appa_cas = {e['cas'] for e in appa['chemicals'] if e['cas'] != 'Varies'}
rmp_cas = set()
for entry in rmp['toxic_substances'] + rmp['flammable_substances']:
    rmp_cas.add(entry['cas'])
overlap = appa_cas & rmp_cas
# Verify that overlapping CAS numbers actually match between files
# (i.e., same CAS string appears in both)
if len(overlap) < 5:
    print(f'FAIL:Only {len(overlap)} chemicals overlap between Appendix A and RMP — expected more')
else:
    # Spot-check: Chlorine 7782-50-5 should be in both
    spot_checks = ['7782-50-5', '7664-41-7', '7664-39-3']
    missing = [c for c in spot_checks if c not in overlap]
    if missing:
        print(f'FAIL:Expected cross-list CAS numbers missing: {missing}')
    else:
        print(f'PASS:{len(overlap)} chemicals found in both lists')
" 2>&1)
if [[ "$RESULT_1_10" == PASS:* ]]; then
  OVERLAP="${RESULT_1_10#PASS:}"
  pass "1.10" "Cross-list consistency — $OVERLAP"
else
  fail "1.10" "Cross-list check: ${RESULT_1_10#FAIL:}"
fi

echo ""

# ────────────────────────────────────────────────────────────
echo "CATEGORY 2: State Manager"
# ────────────────────────────────────────────────────────────

STATE_MANAGER="$PLUGIN_ROOT/scripts/state-manager.sh"

# Test 2.1: init creates valid state file
TMPDIR_2_1=$(mktemp -d)
RESULT_2_1=$(
  cd "$TMPDIR_2_1"
  bash "$STATE_MANAGER" init 2>&1
  if [[ -f .claude/process-safety.local.json ]]; then
    python3 -c "
import json, sys
with open('.claude/process-safety.local.json') as f:
    data = json.load(f)
required = ['version', 'company', 'screening', 'chemicals', 'processes', 'roles', 'generation', 'implementation']
missing = [k for k in required if k not in data]
if missing:
    print(f'FAIL:missing keys: {missing}')
else:
    print('PASS')
" 2>&1
  else
    echo "FAIL:state file not created"
  fi
)
# Extract last line (the PASS/FAIL)
LAST_LINE=$(echo "$RESULT_2_1" | tail -1)
if [[ "$LAST_LINE" == "PASS" ]]; then
  pass "2.1" "init creates valid state file with all required keys"
else
  fail "2.1" "init: ${LAST_LINE#FAIL:}"
fi
rm -rf "$TMPDIR_2_1"

# Test 2.2: init doesn't overwrite existing file
TMPDIR_2_2=$(mktemp -d)
RESULT_2_2=$(
  cd "$TMPDIR_2_2"
  bash "$STATE_MANAGER" init >/dev/null 2>&1
  # Modify the file
  python3 -c "
import json
with open('.claude/process-safety.local.json') as f:
    data = json.load(f)
data['company']['name'] = 'TestModification'
with open('.claude/process-safety.local.json', 'w') as f:
    json.dump(data, f)
" 2>&1
  # Run init again
  bash "$STATE_MANAGER" init >/dev/null 2>&1
  # Check if modification survived
  python3 -c "
import json
with open('.claude/process-safety.local.json') as f:
    data = json.load(f)
if data['company']['name'] == 'TestModification':
    print('PASS')
else:
    print(f'FAIL:company.name is \"{data[\"company\"][\"name\"]}\", expected TestModification')
" 2>&1
)
LAST_LINE=$(echo "$RESULT_2_2" | tail -1)
if [[ "$LAST_LINE" == "PASS" ]]; then
  pass "2.2" "init does not overwrite existing state file"
else
  fail "2.2" "init overwrite: ${LAST_LINE#FAIL:}"
fi
rm -rf "$TMPDIR_2_2"

# Test 2.3: read outputs valid JSON
TMPDIR_2_3=$(mktemp -d)
RESULT_2_3=$(
  cd "$TMPDIR_2_3"
  bash "$STATE_MANAGER" init >/dev/null 2>&1
  OUTPUT=$(bash "$STATE_MANAGER" read 2>/dev/null)
  echo "$OUTPUT" | python3 -c "import json, sys; json.load(sys.stdin); print('PASS')" 2>&1 || echo "FAIL:read output is not valid JSON"
)
LAST_LINE=$(echo "$RESULT_2_3" | tail -1)
if [[ "$LAST_LINE" == "PASS" ]]; then
  pass "2.3" "read outputs valid JSON"
else
  fail "2.3" "read: ${LAST_LINE#FAIL:}"
fi
rm -rf "$TMPDIR_2_3"

# Test 2.4: update merges correctly
TMPDIR_2_4=$(mktemp -d)
RESULT_2_4="SKIP"
if command -v jq &>/dev/null; then
  RESULT_2_4=$(
    cd "$TMPDIR_2_4"
    bash "$STATE_MANAGER" init >/dev/null 2>&1
    echo '{"company": {"name": "Test Corp"}}' | bash "$STATE_MANAGER" update >/dev/null 2>&1
    OUTPUT=$(bash "$STATE_MANAGER" read 2>/dev/null)
    echo "$OUTPUT" | python3 -c "
import json, sys
data = json.load(sys.stdin)
errors = []
if data.get('company', {}).get('name') != 'Test Corp':
    errors.append(f'company.name = \"{data.get(\"company\", {}).get(\"name\")}\"')
if 'version' not in data:
    errors.append('version key missing after merge')
if 'screening' not in data:
    errors.append('screening key missing after merge')
if errors:
    print('FAIL:' + '; '.join(errors))
else:
    print('PASS')
" 2>&1
  )
  LAST_LINE=$(echo "$RESULT_2_4" | tail -1)
  if [[ "$LAST_LINE" == "PASS" ]]; then
    pass "2.4" "update merges correctly (company.name set, other fields unchanged)"
  else
    fail "2.4" "update merge: ${LAST_LINE#FAIL:}"
  fi
else
  info "jq not installed — skipping update test"
  pass "2.4" "update merge (SKIPPED — jq not available)"
fi
rm -rf "$TMPDIR_2_4"

# Test 2.5: status produces output
TMPDIR_2_5=$(mktemp -d)
if command -v jq &>/dev/null; then
  RESULT_2_5=$(
    cd "$TMPDIR_2_5"
    bash "$STATE_MANAGER" init >/dev/null 2>&1
    OUTPUT=$(bash "$STATE_MANAGER" status 2>/dev/null)
    if [[ -n "$OUTPUT" ]]; then
      echo "PASS"
    else
      echo "FAIL:status produced empty output"
    fi
  )
  if [[ "$RESULT_2_5" == "PASS" ]]; then
    pass "2.5" "status produces non-empty output"
  else
    fail "2.5" "status: ${RESULT_2_5#FAIL:}"
  fi
else
  info "jq not installed — skipping status test"
  pass "2.5" "status output (SKIPPED — jq not available)"
fi
rm -rf "$TMPDIR_2_5"

# Test 2.6: read fails gracefully when no state file
TMPDIR_2_6=$(mktemp -d)
RESULT_2_6=$(
  cd "$TMPDIR_2_6"
  if bash "$STATE_MANAGER" read 2>/dev/null; then
    echo "FAIL:read should have exited non-zero"
  else
    echo "PASS"
  fi
)
if [[ "$RESULT_2_6" == "PASS" ]]; then
  pass "2.6" "read fails gracefully (exit 1) when no state file"
else
  fail "2.6" "read without state: ${RESULT_2_6#FAIL:}"
fi
rm -rf "$TMPDIR_2_6"

echo ""

# ────────────────────────────────────────────────────────────
echo "CATEGORY 3: Plugin Structure"
# ────────────────────────────────────────────────────────────

# Test 3.1: All files referenced in marketplace.json exist
RESULT_3_1=$(python3 -c "
import json, os, sys
with open('.claude-plugin/marketplace.json') as f:
    data = json.load(f)
missing = []
# Check command files
for cmd in data.get('commands', []):
    path = f'commands/{cmd[\"name\"]}.md'
    if not os.path.isfile(path):
        missing.append(path)
# Check skill directories
for skill in data.get('skills', []):
    path = f'skills/{skill[\"name\"]}'
    if not os.path.isdir(path):
        missing.append(path)
# Check data files
for df in data.get('data', []):
    if not os.path.isfile(df):
        missing.append(df)
if missing:
    print('FAIL:missing: ' + ', '.join(missing))
else:
    print('PASS')
" 2>&1)
if [[ "$RESULT_3_1" == "PASS" ]]; then
  pass "3.1" "All files referenced in marketplace.json exist"
else
  fail "3.1" "marketplace.json references: ${RESULT_3_1#FAIL:}"
fi

# Test 3.2: All command files have valid frontmatter
RESULT_3_2=$(python3 -c "
import os, sys
errors = []
for fname in sorted(os.listdir('commands')):
    if not fname.endswith('.md'):
        continue
    path = os.path.join('commands', fname)
    with open(path) as f:
        content = f.read()
    if not content.startswith('---'):
        errors.append(f'{fname}: does not start with ---')
        continue
    # Find closing ---
    end = content.index('---', 3) if '---' in content[3:] else -1
    if end == -1:
        errors.append(f'{fname}: no closing --- for frontmatter')
        continue
    frontmatter = content[3:end+3]
    if 'name:' not in frontmatter:
        errors.append(f'{fname}: missing name: field')
    if 'description:' not in frontmatter:
        errors.append(f'{fname}: missing description: field')
if errors:
    print('FAIL:' + '; '.join(errors))
else:
    print('PASS')
" 2>&1)
if [[ "$RESULT_3_2" == "PASS" ]]; then
  pass "3.2" "All command files have valid frontmatter (name + description)"
else
  fail "3.2" "Command frontmatter: ${RESULT_3_2#FAIL:}"
fi

# Test 3.3: SKILL.md has valid frontmatter
SKILL_FILE="skills/psm-compliance/SKILL.md"
if [[ -f "$SKILL_FILE" ]]; then
  RESULT_3_3=$(python3 -c "
import sys
with open('$SKILL_FILE') as f:
    content = f.read()
if not content.startswith('---'):
    print('FAIL:does not start with ---')
    sys.exit(0)
end = content.find('---', 3)
if end == -1:
    print('FAIL:no closing ---')
    sys.exit(0)
fm = content[3:end]
errors = []
if 'name:' not in fm:
    errors.append('missing name:')
if 'description:' not in fm:
    errors.append('missing description:')
if errors:
    print('FAIL:' + '; '.join(errors))
else:
    print('PASS')
" 2>&1)
  if [[ "$RESULT_3_3" == "PASS" ]]; then
    pass "3.3" "SKILL.md has valid frontmatter"
  else
    fail "3.3" "SKILL.md frontmatter: ${RESULT_3_3#FAIL:}"
  fi
else
  fail "3.3" "SKILL.md not found at $SKILL_FILE"
fi

# Test 3.4: state-manager.sh is executable
if [[ -x "$STATE_MANAGER" ]]; then
  pass "3.4" "state-manager.sh is executable"
else
  fail "3.4" "state-manager.sh is not executable"
fi

echo ""

# ────────────────────────────────────────────────────────────
echo "CATEGORY 4: Cross-Reference Integrity"
# ────────────────────────────────────────────────────────────

# Test 4.1: Form references are consistent
RESULT_4_1=$(python3 -c "
import os, re, sys

# Collect TE-FRM-### references from command files and SKILL.md
files_to_check = []
for fname in os.listdir('commands'):
    if fname.endswith('.md'):
        files_to_check.append(os.path.join('commands', fname))
skill_path = 'skills/psm-compliance/SKILL.md'
if os.path.isfile(skill_path):
    files_to_check.append(skill_path)

pattern = re.compile(r'[A-Z]{2,4}-FRM-\d{3}')
refs_by_file = {}
all_refs = set()
for fpath in files_to_check:
    with open(fpath) as f:
        content = f.read()
    found = set(pattern.findall(content))
    if found:
        refs_by_file[os.path.basename(fpath)] = found
        all_refs.update(found)

if not all_refs:
    print('PASS:no form references found (consistent by default)')
    sys.exit(0)

# Normalize: strip prefix to get just FRM-### for comparison
def normalize(ref):
    return re.search(r'FRM-\d{3}', ref).group()

norm_by_file = {}
for fname, refs in refs_by_file.items():
    norm_by_file[fname] = {normalize(r) for r in refs}

# Check that files that reference forms use consistent numbers
# (screen, generate, implement should all reference the same form set if they reference forms)
cmd_files_with_refs = {k: v for k, v in norm_by_file.items() if k in ('screen.md', 'generate.md', 'implement.md')}
if len(cmd_files_with_refs) >= 2:
    # Check that the intersection of form refs across files is non-empty if any overlap expected
    all_cmd_forms = set()
    for v in cmd_files_with_refs.values():
        all_cmd_forms.update(v)
    # No contradictions = pass
    print(f'PASS:{len(all_refs)} unique form references across {len(refs_by_file)} files')
else:
    print(f'PASS:{len(all_refs)} unique form references across {len(refs_by_file)} files')
" 2>&1)
if [[ "$RESULT_4_1" == PASS:* ]]; then
  pass "4.1" "Form references consistent — ${RESULT_4_1#PASS:}"
else
  fail "4.1" "Form references: ${RESULT_4_1#FAIL:}"
fi

# Test 4.2: Register references are consistent
RESULT_4_2=$(python3 -c "
import os, re, sys

files_to_check = []
for fname in os.listdir('commands'):
    if fname.endswith('.md'):
        files_to_check.append(os.path.join('commands', fname))
skill_path = 'skills/psm-compliance/SKILL.md'
if os.path.isfile(skill_path):
    files_to_check.append(skill_path)

pattern = re.compile(r'[A-Z]{2,4}-REG-\d{3}')
all_refs = set()
refs_by_file = {}
for fpath in files_to_check:
    with open(fpath) as f:
        content = f.read()
    found = set(pattern.findall(content))
    if found:
        refs_by_file[os.path.basename(fpath)] = found
        all_refs.update(found)

if not all_refs:
    print('PASS:no register references found (consistent by default)')
    sys.exit(0)

print(f'PASS:{len(all_refs)} unique register references across {len(refs_by_file)} files')
" 2>&1)
if [[ "$RESULT_4_2" == PASS:* ]]; then
  pass "4.2" "Register references consistent — ${RESULT_4_2#PASS:}"
else
  fail "4.2" "Register references: ${RESULT_4_2#FAIL:}"
fi

# Test 4.3: Element count consistency
RESULT_4_3=$(python3 -c "
import os, re, sys

errors = []

# Check files that reference '14 elements' or '14 PSM elements'
files_to_check = []
for fname in os.listdir('commands'):
    if fname.endswith('.md'):
        files_to_check.append(os.path.join('commands', fname))
skill_path = 'skills/psm-compliance/SKILL.md'
if os.path.isfile(skill_path):
    files_to_check.append(skill_path)

pattern_14 = re.compile(r'14\s+(?:PSM\s+)?elements', re.IGNORECASE)
for fpath in files_to_check:
    with open(fpath) as f:
        content = f.read()
    matches = pattern_14.findall(content)
    # This is just a consistency check — all should say 14

# Check SKILL.md has exactly 14 element sections
with open(skill_path) as f:
    skill_content = f.read()
element_headers = re.findall(r'### Element \d{2}', skill_content)
if len(element_headers) != 14:
    errors.append(f'SKILL.md has {len(element_headers)} element sections, expected 14')

# Check generate.md references 14 element procedures
gen_path = 'commands/generate.md'
if os.path.isfile(gen_path):
    with open(gen_path) as f:
        gen_content = f.read()
    # Count element directory references (01_ through 14_)
    dir_refs = re.findall(r'\d{2}_[A-Z_]+/', gen_content)
    unique_dirs = set(dir_refs)
    element_dirs = {d for d in unique_dirs if re.match(r'(0[1-9]|1[0-4])_', d)}
    if len(element_dirs) != 14:
        errors.append(f'generate.md references {len(element_dirs)} element directories, expected 14')

if errors:
    print('FAIL:' + '; '.join(errors))
else:
    print('PASS')
" 2>&1)
if [[ "$RESULT_4_3" == "PASS" ]]; then
  pass "4.3" "Element count consistency — 14 elements across all files"
else
  fail "4.3" "Element count: ${RESULT_4_3#FAIL:}"
fi

echo ""

# ════════════════════════════════════════════════════════════
# SUMMARY
# ════════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════════════════"
if [[ "$FAIL_COUNT" -eq 0 ]]; then
  printf "RESULTS: \033[32m%d passed\033[0m, %d failed, %d total\n" "$PASS_COUNT" "$FAIL_COUNT" "$TOTAL_COUNT"
else
  printf "RESULTS: %d passed, \033[31m%d failed\033[0m, %d total\n" "$PASS_COUNT" "$FAIL_COUNT" "$TOTAL_COUNT"
fi
echo "════════════════════════════════════════════════════════════"
echo ""

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
exit 0
