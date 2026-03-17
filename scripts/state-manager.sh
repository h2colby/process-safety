#!/usr/bin/env bash
set -euo pipefail

STATE_DIR=".claude"
STATE_FILE=".claude/process-safety.local.json"

usage() {
  cat <<'USAGE'
Usage: state-manager.sh <subcommand>

Subcommands:
  init      Create empty state file at .claude/process-safety.local.json
  read      Output current state JSON to stdout
  update    Deep-merge a JSON patch from stdin into the state (requires jq)
  status    Print human-readable status summary
USAGE
  exit 1
}

cmd_init() {
  if [[ -f "$STATE_FILE" ]]; then
    echo "WARNING: $STATE_FILE already exists. Not overwriting." >&2
    return 0
  fi

  mkdir -p "$STATE_DIR"

  cat > "$STATE_FILE" <<'JSON'
{
  "version": 1,
  "company": {
    "name": "",
    "state": "",
    "facility_locations": []
  },
  "screening": {
    "completed": false,
    "date": null,
    "psm_applicable": null,
    "rmp_applicable": null,
    "rmp_program_level": null
  },
  "chemicals": [],
  "processes": [],
  "roles": {},
  "generation": {
    "completed": false,
    "date": null,
    "document_count": 0
  },
  "implementation": {
    "phase": null,
    "audit_readiness_pct": 0,
    "gaps_open": 0,
    "gaps_critical": 0,
    "next_priority": null
  }
}
JSON

  echo "Initialized state file at $STATE_FILE"
}

cmd_read() {
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "ERROR: State file not found at $STATE_FILE. Run 'init' first." >&2
    exit 1
  fi
  if ! python3 -c "import json; json.load(open('$STATE_FILE'))" 2>/dev/null; then
    echo "ERROR: State file at $STATE_FILE contains invalid JSON." >&2
    exit 1
  fi
  cat "$STATE_FILE"
}

cmd_update() {
  if ! command -v jq &>/dev/null; then
    echo "ERROR: jq is required for the update command but was not found." >&2
    exit 1
  fi

  if [[ ! -f "$STATE_FILE" ]]; then
    echo "ERROR: State file not found at $STATE_FILE. Run 'init' first." >&2
    exit 1
  fi

  local patch
  patch="$(cat)"

  if [[ -z "$patch" ]]; then
    echo "ERROR: No JSON patch provided on stdin." >&2
    exit 1
  fi

  local merged
  merged="$(jq -s '.[0] as $base | .[1] as $patch | $base * $patch' "$STATE_FILE" <(echo "$patch"))"

  echo "$merged" > "$STATE_FILE"
  echo "State updated."
}

# Helper: read a jq expression from the state file, return raw output
_jq() {
  jq -r "$1" "$STATE_FILE"
}

cmd_status() {
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "ERROR: State file not found at $STATE_FILE. Run 'init' first." >&2
    exit 1
  fi

  if ! command -v jq &>/dev/null; then
    echo "ERROR: jq is required for the status command but was not found." >&2
    exit 1
  fi

  local company_name screening_completed screening_date
  local psm_applicable rmp_applicable rmp_level
  local chem_count proc_count
  local gen_completed gen_date gen_docs
  local impl_phase impl_readiness impl_gaps impl_critical impl_next

  company_name="$(_jq '.company.name // empty')"
  screening_completed="$(_jq '.screening.completed')"
  screening_date="$(_jq '.screening.date // empty')"
  psm_applicable="$(_jq '.screening.psm_applicable // empty')"
  rmp_applicable="$(_jq '.screening.rmp_applicable // empty')"
  rmp_level="$(_jq '.screening.rmp_program_level // empty')"
  chem_count="$(_jq '.chemicals | length')"
  proc_count="$(_jq '.processes | length')"
  gen_completed="$(_jq '.generation.completed')"
  gen_date="$(_jq '.generation.date // empty')"
  gen_docs="$(_jq '.generation.document_count')"
  impl_phase="$(_jq '.implementation.phase // empty')"
  impl_readiness="$(_jq '.implementation.audit_readiness_pct')"
  impl_gaps="$(_jq '.implementation.gaps_open')"
  impl_critical="$(_jq '.implementation.gaps_critical')"
  impl_next="$(_jq '.implementation.next_priority // empty')"

  echo "PROCESS SAFETY — Status"
  echo "========================"

  # Company
  if [[ -n "$company_name" ]]; then
    echo "Company:     $company_name"
  else
    echo "Company:     Not started"
  fi

  # Screening
  if [[ "$screening_completed" == "true" ]]; then
    echo "Screening:   COMPLETE (${screening_date:-unknown date})"
  else
    echo "Screening:   Pending"
  fi

  # PSM
  if [[ -n "$psm_applicable" ]]; then
    if [[ "$psm_applicable" == "true" ]]; then
      echo "  PSM:       Applicable"
    else
      echo "  PSM:       Not Applicable"
    fi
  else
    echo "  PSM:       Pending"
  fi

  # RMP
  if [[ -n "$rmp_applicable" ]]; then
    if [[ "$rmp_applicable" == "true" ]]; then
      if [[ -n "$rmp_level" ]]; then
        echo "  RMP:       Applicable (Program Level $rmp_level)"
      else
        echo "  RMP:       Applicable"
      fi
    else
      echo "  RMP:       Not Applicable"
    fi
  else
    echo "  RMP:       Pending"
  fi

  # Chemicals and Processes
  echo "Chemicals:   $chem_count tracked"
  echo "Processes:   $proc_count covered"

  # Generation
  if [[ "$gen_completed" == "true" ]]; then
    echo "Generation:  COMPLETE ($gen_docs documents)"
  elif [[ "$gen_docs" -gt 0 ]]; then
    echo "Generation:  IN PROGRESS ($gen_docs documents)"
  else
    echo "Generation:  Not started"
  fi

  # Implementation
  echo "Implementation:"
  if [[ -n "$impl_phase" ]]; then
    echo "  Phase:     $impl_phase"
  else
    echo "  Phase:     Not started"
  fi
  echo "  Readiness: ${impl_readiness}%"
  echo "  Gaps:      $impl_gaps open ($impl_critical critical)"
  if [[ -n "$impl_next" ]]; then
    echo "  Next:      $impl_next"
  else
    echo "  Next:      Pending"
  fi
}

# --- Main dispatch ---

if [[ $# -lt 1 ]]; then
  usage
fi

case "$1" in
  init)   cmd_init   ;;
  read)   cmd_read   ;;
  update) cmd_update ;;
  status) cmd_status ;;
  *)
    echo "ERROR: Unknown subcommand '$1'" >&2
    usage
    ;;
esac
