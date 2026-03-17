#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
PASS=0; FAIL=0
pass() { echo "  [PASS] $1"; ((PASS++)) || true; }
fail() { echo "  [FAIL] $1"; ((FAIL++)) || true; }

echo "EDGE CASE: Corrupt/Missing State Recovery"
echo "============================================"

TMPDIR=$(mktemp -d -t psm-edge-state-XXXXXX)
trap "rm -rf $TMPDIR" EXIT

# Test: read on missing file exits non-zero
cd "$TMPDIR"
if ! bash "$PLUGIN_DIR/scripts/state-manager.sh" read 2>/dev/null; then
    pass "state-manager read exits non-zero when state file missing"
else
    fail "state-manager read should fail when no state file exists"
fi

# Test: init creates file from scratch
if bash "$PLUGIN_DIR/scripts/state-manager.sh" init 2>/dev/null; then
    if [ -f ".claude/process-safety.local.json" ]; then
        pass "state-manager init creates state file from scratch"
    else
        fail "state-manager init ran but didn't create file"
    fi
else
    fail "state-manager init failed"
fi

# Test: corrupt JSON in state file — update should handle or fail gracefully
echo "NOT VALID JSON {{{" > .claude/process-safety.local.json
if ! bash "$PLUGIN_DIR/scripts/state-manager.sh" read 2>/dev/null; then
    pass "state-manager read rejects corrupt JSON"
else
    # If it somehow succeeds, check what it returned
    fail "state-manager read didn't detect corrupt JSON"
fi

# Test: reinit after corruption
rm .claude/process-safety.local.json
if bash "$PLUGIN_DIR/scripts/state-manager.sh" init 2>/dev/null && [ -f ".claude/process-safety.local.json" ]; then
    if python3 -c "import json; json.load(open('.claude/process-safety.local.json'))" 2>/dev/null; then
        pass "state-manager init recovers from deleted state file"
    else
        fail "Recreated state file is not valid JSON"
    fi
else
    fail "state-manager init failed after file deletion"
fi

cd ->/dev/null

echo ""; echo "RESULTS: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
