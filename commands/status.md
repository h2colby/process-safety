---
name: status
description: View implementation progress and audit readiness dashboard
---

# Process Safety Status Dashboard

This command reads the project state and displays a formatted progress dashboard showing implementation progress and audit readiness.

## Step 1: Read State

- Read `.claude/process-safety.local.json` from the project root.
- If the file does not exist, tell the user:
  > No PSM project found. Run `/process-safety:screen` to get started.
  Then stop.
- Parse the JSON to extract: company name, facility location, covered processes, current phase, generation status, and any timestamps.

## Step 2: Calculate Metrics

### Audit Readiness Percentage

- Check whether `PSM_PROGRAM/00_MASTER/TOB-PSM-002_Compliance_Crosswalk.md` exists.
- If it exists, read the file and count the status values in the crosswalk table rows.
- Apply these weights:
  - `COMPLETE` = 1.0
  - `PARTIAL` = 0.5
  - `NEEDS COMPANY INPUT` or `NEEDS TOBE INPUT` = 0.25
  - `GAP` = 0
  - `NOT APPLICABLE` = exclude from total
- Formula: `(sum of weighted statuses / total applicable clauses) * 100`, rounded to nearest integer.
- Track the raw counts for each status category to display in the dashboard.

### Gap Summary

- Check whether `PSM_PROGRAM/00_MASTER/TOB-PSM-004_Gap_Register.md` exists.
- If it exists, read the file and count open gaps by severity (Critical, High, Medium, Low).
- Only count gaps whose status is NOT "Resolved" or "Closed".

### Implementation Phase

Derive the current phase from the dependency chain and what work exists:

1. **Screening** — complete if state file has screening results (covered processes identified).
2. **Program Generation** — complete if the `PSM_PROGRAM/` folder structure and core documents exist. Count the generated documents.
3. **PSI Compilation** — in progress if any PSI data has been added beyond the generated template; not started otherwise.
4. **PHA Scheduling** — in progress if PHA planning documents exist; not started if PSI is still incomplete.
5. **Operating Procedures** — in progress if any procedures have been drafted beyond templates; not started if PHA is incomplete.
6. **Training Program** — in progress if training records or curricula have been created; not started if procedures are incomplete.
7. **Full Implementation** — in progress only when all prior phases are at least partially complete.

Use these rules to assign each phase a status: COMPLETE, IN PROGRESS, or NOT STARTED.

## Step 3: Display Dashboard

Output a formatted dashboard using box-drawing characters. Adapt ALL values to the actual data found — never display placeholder numbers when real data is available.

```
╔══════════════════════════════════════════════════════════════╗
║  PROCESS SAFETY — IMPLEMENTATION STATUS                      ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Company:           [company name from state]                ║
║  Facility:          [facility location from state]           ║
║  Covered Processes: [count from state]                       ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  PHASE STATUS                                                ║
║                                                              ║
║  [■] Screening          COMPLETE  [date]                     ║
║  [■] Program Generation COMPLETE  [date]  ([N] docs)         ║
║  [□] PSI Compilation    IN PROGRESS                          ║
║  [ ] PHA Scheduling     NOT STARTED                          ║
║  [ ] Operating Procedures NOT STARTED                        ║
║  [ ] Training Program   NOT STARTED                          ║
║  [ ] Full Implementation NOT STARTED                         ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  AUDIT READINESS                                             ║
║                                                              ║
║  [progress bar]  [percentage]%                               ║
║                                                              ║
║  Clauses: [N]/[total] COMPLETE | [N] PARTIAL |               ║
║           [N] NEEDS INPUT | [N] GAP                          ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  GAPS                                                        ║
║                                                              ║
║  Critical: [N]    High: [N]    Medium: [N]    Low: [N]       ║
║  Total: [N] open                                             ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  OCA STATUS                                                    ║
║                                                              ║
║  [■/□/ ] Worst-case scenarios    [N] chemicals analyzed        ║
║  [■/□/ ] Alternative scenarios   [N] completed                 ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  RMP PREPARATION                                               ║
║                                                              ║
║  [■/□/ ] RMP Data Package        [N/9] documents               ║
║  [■/□/ ] Submission Checklist    [N]% pre-filled               ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  NEXT PRIORITY                                               ║
║                                                              ║
║  → [description of next priority action]                     ║
║    Run /process-safety:[appropriate command] to get started   ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  COMPLIANCE MILESTONES                                       ║
║                                                              ║
║  PHA initial study:    Due within 12 months of startup       ║
║  PHA revalidation:     Every 5 years                         ║
║  Compliance audit:     Every 3 years                         ║
║  Training refresher:   Every 3 years                         ║
║  Procedure review:     Annual certification                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

### Progress Bar Rendering

Build the progress bar from the audit readiness percentage:
- Total bar width: 20 characters.
- Filled characters: `round(percentage / 5)` using `█`.
- Empty characters: remaining slots using `░`.
- Example at 34%: `███████░░░░░░░░░░░░░  34%`

### Checkbox Rendering

- `[■]` for COMPLETE phases
- `[□]` for IN PROGRESS phases
- `[ ]` for NOT STARTED phases

### Next Priority Logic

Determine the next priority based on the dependency chain:
1. If screening not done → suggest `/process-safety:screen`
2. If generation not done → suggest `/process-safety:generate`
3. If PSI incomplete for any covered process → suggest `/process-safety:implement`
4. If PSI complete but PHA not started → suggest `/process-safety:implement`
5. If PHA complete but procedures missing → suggest `/process-safety:implement`
6. Continue down the chain following the same dependency order used in the implement command.

### OCA Status Logic

Read the `oca` section from the state file (`.claude/process-safety.local.json`):
- If the `oca` section does not exist in state, display "Not started" for both rows.
- If it exists, count scenarios: tally entries where `type` is `"worst_case"` separately from entries where `type` is `"alternative"`.
- Worst-case checkbox: `[■]` if all chemicals in state have a worst-case scenario, `[□]` if some do, `[ ]` if none.
- Alternative checkbox: `[■]` if all chemicals have an alternative scenario, `[□]` if some do, `[ ]` if none.
- Display the count of analyzed chemicals for worst-case and the count of completed scenarios for alternative.

### RMP Preparation Logic

Read the `rmp` section from the state file:
- If the `rmp` section does not exist in state, display "Not started" for both rows.
- If it exists, count documents in the `rmp.documents` array (out of 9 total RMP documents).
- RMP Data Package checkbox: `[■]` if 9/9, `[□]` if 1-8, `[ ]` if 0.
- For the submission checklist: if `rmp.submission_checklist` exists in state, calculate the percentage of items that are pre-filled (have a value other than `REQUIRES COMPANY INPUT`) vs total items. Display as `[N]%`. Checkbox: `[■]` if 100%, `[□]` if >0%, `[ ]` if 0% or checklist does not exist.

### Simplified View (Pre-Generation)

If the crosswalk and gap register do not exist yet (program generation has not been run), display a simplified dashboard:

```
╔══════════════════════════════════════════════════════════════╗
║  PROCESS SAFETY — IMPLEMENTATION STATUS                      ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Company:           [company name from state]                ║
║  Facility:          [facility location from state]           ║
║  Covered Processes: [count from state]                       ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  PHASE STATUS                                                ║
║                                                              ║
║  [■] Screening          COMPLETE  [date]                     ║
║  [ ] Program Generation NOT STARTED                          ║
║  [ ] PSI Compilation    NOT STARTED                          ║
║  [ ] PHA Scheduling     NOT STARTED                          ║
║  [ ] Operating Procedures NOT STARTED                        ║
║  [ ] Training Program   NOT STARTED                          ║
║  [ ] Full Implementation NOT STARTED                         ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  NEXT PRIORITY                                               ║
║                                                              ║
║  → Generate PSM program documents                            ║
║    Run /process-safety:generate to build your program        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

This simplified view omits the Audit Readiness, Gaps, and Compliance Milestones sections since there is no data to populate them yet.
