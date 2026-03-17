---
name: test
description: Validate generated PSM program against audit-ready checklist
---

# TEST — Validate PSM Program Against 12-Point Audit-Ready Checklist

This command validates a generated PSM program by running the 12-point audit-ready checklist defined in the build specification (CLAUDE.md, Section 4.1). Run this after `/process-safety:generate` completes.

<!-- NOTE: This command should be registered in marketplace.json for the process-safety plugin. -->

---

## PRE-FLIGHT

1. **Check for PSM_PROGRAM directory.** Look for `PSM_PROGRAM/` in the current working directory.
   - If it does not exist, tell the user:
     > No PSM program found. Run `/process-safety:generate` first.
   - Then stop. Do not proceed with any checks.

2. **Read state file.** Read `.claude/process-safety.local.json` from the project root.
   - Extract `company.name` and `company.doc_prefix` (or derive the prefix from the company name).
   - If the state file does not exist, warn: "No state file found. I'll validate the program structure but cannot confirm company-specific naming." Use fallback prefix detection from filenames.

3. **Announce:** Display this message before starting checks:
   ```
   Running validation against 12-point audit-ready checklist...
   ```

4. **Initialize a results array.** Track each check as: check number, check name, result (PASS / WARN / FAIL / SKIP), and detail string.

---

## CHECK 1: Requirement Coverage

- Find the compliance crosswalk file by globbing `PSM_PROGRAM/00_MASTER/*Compliance_Crosswalk*` or `PSM_PROGRAM/00_MASTER/*compliance_crosswalk*`.
- If not found: **FAIL** — "No compliance crosswalk found."
- If found, read the file and count occurrences of these status codes in table rows:
  - `COMPLETE`
  - `PARTIAL`
  - `GAP`
  - `NEEDS COMPANY INPUT` (also match `NEEDS TOBE INPUT` as equivalent)
  - `NOT APPLICABLE`
- **PASS** if zero GAP entries. NEEDS COMPANY INPUT is acceptable and expected for a newly generated program.
- **WARN** if any GAP entries exist. List each GAP entry with its clause reference.
- Report: `"Requirement coverage: X COMPLETE, Y PARTIAL, Z NEEDS INPUT, W GAP"`

---

## CHECK 2: Clause Traceability

- In the same crosswalk file, extract all distinct CFR paragraph references matching the pattern `1910.119\([a-z]\)` and deeper sub-references like `1910.119\([a-z]\)\([0-9]+\)`.
- Count unique top-level and sub-paragraph references.
- **PASS** if >= 80 distinct clause references (the full standard has approximately 84 addressable paragraphs).
- **FAIL** if < 80. Identify which top-level sections `(a)` through `(p)` are missing or under-represented.
- Report: `"Clause traceability: N/84 clauses mapped"`

---

## CHECK 3: Ownership

- Read each element procedure file — one file from each of the 14 element folders (`01_*` through `14_*` under `PSM_PROGRAM/`).
- For each file, search for a section header containing "Roles" or "Responsibilities" (case-insensitive).
- Check that the section is not empty — it should contain at least one named role or function (e.g., "PSM Coordinator", "Operations Manager", "Facility Manager").
- **PASS** if all 14 element procedures have non-empty role assignments.
- **FAIL** if any are missing. List which element numbers and names lack ownership sections.
- Report: `"Ownership: N/14 elements have role assignments"`

---

## CHECK 4: Frequency

Search across all files in `PSM_PROGRAM/` for these five required frequencies:

| Frequency Item | Search Patterns |
|---|---|
| PHA revalidation | `5 years`, `five years`, `every 5`, `5-year` |
| Training refresher | `3 years`, `three years`, `every 3`, `3-year` (in training context) |
| Compliance audit | `3 years`, `three years`, `every 3`, `3-year` (in audit context) |
| Operating procedure certification | `annual`, `every year`, `yearly`, `12 months` (in procedures context) |
| MI inspection | `RAGAGEP`, `manufacturer`, `API`, `ASME`, `NBIC`, or other defined frequency |

- **PASS** if all 5 frequencies are found somewhere in the document set.
- **FAIL** if any are missing. List which frequencies are not defined.
- Report: `"Frequency: N/5 required frequencies defined"`

---

## CHECK 5: Evidence

- For each of the 14 element procedure files, search for a section header containing "Records" or "Evidence" (case-insensitive).
- Within that section, check for specific form or register references matching patterns like `FRM-`, `REG-`, or the company prefix followed by a form/register designator.
- **PASS** if all 14 elements have evidence sections with specific artifact references.
- **FAIL** if any lack specific evidence references. List which elements are missing.
- Report: `"Evidence: N/14 elements have specific evidence references"`

---

## CHECK 6: Document Control

- For each substantive file in `PSM_PROGRAM/` (skip README files, stubs under 10 lines, and the validation report itself), check for these header block fields:
  - **Document number:** A pattern like `XXX-PSM-###`, `XX-FRM-###`, `XX-REG-###`, or similar controlled number.
  - **Revision:** Pattern like `R0`, `Rev`, `Revision`.
  - **Date:** Any date pattern (YYYY-MM-DD, Month DD YYYY, etc.).
  - **Owner:** A line containing "Owner" with a value.
- **PASS** if all substantive documents have complete header blocks.
- **FAIL** if any are missing. List which files lack which header fields.
- Report: `"Document control: N/M documents have complete headers"`

---

## CHECK 7: Cross-Reference Integrity

- Extract all internal document references across all files in `PSM_PROGRAM/`. Match patterns like:
  - `[PREFIX]-PSM-###`
  - `[PREFIX]-FRM-###`
  - `[PREFIX]-REG-###`
  - `[PREFIX]-PRC-###`
  - `[PREFIX]-TPL-###`
  - Any other `[PREFIX]-XXX-###` pattern
- Build a set of all unique references found.
- For each reference, check that a file exists in `PSM_PROGRAM/` whose name or content contains that document number.
- **PASS** if all references resolve to existing files.
- **FAIL** if any are broken. List each broken reference and which file contains it.
- Report: `"Cross-references: N total references, M broken"`

---

## CHECK 8: Gap Visibility

- Check that a gap register file exists in `PSM_PROGRAM/00_MASTER/` (glob for `*Gap_Register*` or `*gap_register*`).
- If not found: **FAIL** — "No gap register found."
- If found, check that it contains at least one gap entry row in a table (a brand new program should always have gaps — if there are zero, something is wrong).
- Check that each gap entry has at minimum: Gap ID, Description, Severity, and Status.
- **PASS** if gap register exists with properly structured entries.
- **FAIL** if missing, empty, or entries lack required fields.
- Report: `"Gap register: N open gaps (H high, M medium, L low)"`

---

## CHECK 9: Legacy Cleanup

Search all files in `PSM_PROGRAM/` for contamination from example companies or unresolved placeholders:

**Example company names to flag** (only flag if they do NOT match the actual company name from the state file):
- `Tobe Energy`
- `Acme`
- `Example Corp`
- `Sample Company`
- `XYZ Corp`
- `ABC Industries`
- `ACME`

**Unresolved placeholder patterns to flag:**
- `[COMPANY]`
- `[INSERT`
- `<COMPANY`
- `[FACILITY`
- `[YOUR`
- `TBD` (only flag if more than 10 instances — a few TBDs are acceptable for items awaiting company input)

- **PASS** if no stray example-company names and no unresolved placeholders are found.
- **FAIL** if any are found. List each occurrence with file path and the matching text.
- Report: `"Legacy cleanup: N issues found"` or `"Legacy cleanup: Clean"`

---

## CHECK 10: Implementation Support

- Scan all element procedure files for form references (patterns like `FRM-###` or `[PREFIX]-FRM-###`).
- Check that each referenced form exists as a file in `PSM_PROGRAM/90_FORMS/`.
- Scan all element procedure files for register references (patterns like `REG-###` or `[PREFIX]-REG-###`).
- Check that each referenced register exists as a file in `PSM_PROGRAM/92_REGISTERS/`.
- **PASS** if all referenced forms and registers exist as actual files.
- **FAIL** if any are missing. List what is referenced but does not have a corresponding file.
- Report: `"Implementation support: N/M forms exist, P/Q registers exist"`

---

## CHECK 11: Review Quality

- Check for a self-review report in `PSM_PROGRAM/00_MASTER/` (glob for `*Self_Review*`, `*self_review*`, `*Self-Review*`, `*self-review*`).
- If not found: **FAIL** — "No self-review report found."
- If found, check that it has substantive content: at least 20 non-empty lines.
- **PASS** if self-review report exists with substantive content.
- **WARN** if the file exists but appears to be a stub (fewer than 20 non-empty lines).
- Report: `"Review quality: Self-review report found (N lines)"` or `"Review quality: No self-review report"`

---

## CHECK 12: Publication Readiness

- **Naming consistency:** Check that files within each folder share a consistent naming prefix. Files in `01_*` through `14_*` should use the company document prefix. Files in `90_FORMS/` should use a form numbering pattern. Files in `92_REGISTERS/` should use a register numbering pattern.
- **Document register:** Check that a document register file exists in `PSM_PROGRAM/00_MASTER/` (glob for `*Document_Register*` or `*document_register*`).
- **File naming pattern:** Check that all substantive files follow a pattern like `PREFIX-TYPE-###_Descriptive_Name.md` (allow reasonable variations).
- **PASS** if naming is consistent and the document register exists.
- **FAIL** if naming is inconsistent or the register is missing. List specific issues.
- Report: `"Publication readiness: [consistent/inconsistent] naming, document register [found/missing]"`

---

## CHECK 13: OCA Reports (Conditional)

- Read the state file (`.claude/process-safety.local.json`). Check whether the `oca` section exists and contains at least one scenario entry.
- **If no `oca` section or no scenarios:** **SKIP** — "No OCA data in state file. Skipping OCA validation."
- If OCA data exists, for each scenario in `oca.scenarios`:
  - Check that a corresponding OCA report file exists in `PSM_PROGRAM/93_REFERENCE/OCA/`. Match by chemical name or CAS number in the filename.
  - Read each report file and verify it contains these required fields (as section headers or table entries): `chemical`, `quantity`, `distance`, `endpoint`, `methodology`.
- **PASS** if all scenario reports exist and each contains all five required fields.
- **FAIL** if any scenario is missing a report file or any report is missing required fields. List which scenarios/fields are deficient.
- Report: `"OCA reports: N/M scenarios have complete reports"` or `"OCA reports: Skipped — no OCA data"`

---

## CHECK 14: RMP Package (Conditional)

- Check whether the directory `PSM_PROGRAM/95_RMP/` exists.
- **If the directory does not exist:** **SKIP** — "No 95_RMP/ directory found. Skipping RMP validation."
- If the directory exists, perform these checks:
  1. **Document count:** Glob for files matching `*RMP-00[1-9]*` in `PSM_PROGRAM/95_RMP/`. Verify all 9 RMP documents exist.
  2. **Document numbering:** Verify each RMP document filename includes the company prefix from the state file (e.g., `ACM-RMP-001`, not bare `RMP-001`). Read `company.doc_prefix` or derive it from `company.name`.
  3. **Certification document:** Find the file matching `*RMP-008*`. Read it and verify it contains a signature block (search for patterns like `Signature`, `Certif`, `Owner/Operator`, `Date:`).
  4. **Submission checklist:** Find the file matching `*RMP-009*`. Read it and verify it contains pre-filled Y/N/N/A answers (search for patterns like `| Y |`, `| N |`, `| N/A |`, `[Y]`, `[N]`, `[N/A]`).
- **PASS** if all four sub-checks pass.
- **FAIL** if any sub-check fails. List which sub-checks failed and why.
- Report: `"RMP package: N/9 documents, naming [correct/incorrect], certification [valid/missing], checklist [pre-filled/incomplete]"` or `"RMP package: Skipped — no 95_RMP/ directory"`

---

## OUTPUT: Validation Report

After all 12 checks complete, do the following:

### 1. Save the Report

Write a validation report to `PSM_PROGRAM/00_MASTER/validation-report.md` with this structure:

```markdown
# PSM PROGRAM VALIDATION REPORT

**Date:** [current date]
**Company:** [company name from state file]
**Validated by:** process-safety plugin v0.1.0

---

## RESULTS SUMMARY

| # | Check | Result | Details |
|---|---|---|---|
| 1 | Requirement Coverage | [PASS/WARN/FAIL] | [detail string] |
| 2 | Clause Traceability | [PASS/FAIL] | [detail string] |
| 3 | Ownership | [PASS/FAIL] | [detail string] |
| 4 | Frequency | [PASS/FAIL] | [detail string] |
| 5 | Evidence | [PASS/FAIL] | [detail string] |
| 6 | Document Control | [PASS/FAIL] | [detail string] |
| 7 | Cross-Reference Integrity | [PASS/FAIL] | [detail string] |
| 8 | Gap Visibility | [PASS/FAIL] | [detail string] |
| 9 | Legacy Cleanup | [PASS/FAIL] | [detail string] |
| 10 | Implementation Support | [PASS/FAIL] | [detail string] |
| 11 | Review Quality | [PASS/WARN/FAIL] | [detail string] |
| 12 | Publication Readiness | [PASS/FAIL] | [detail string] |
| 13 | OCA Reports | [PASS/FAIL/SKIP] | [detail string] |
| 14 | RMP Package | [PASS/FAIL/SKIP] | [detail string] |

**Overall: X/12 PASS, Y WARN, Z FAIL, W SKIP** (Checks 13-14 are conditional and excluded from the core 12-point score when skipped)

## DETAILED FINDINGS

[For each WARN or FAIL, provide:]
- Check name and number
- What was expected
- What was found
- Specific files or items that need attention

## RECOMMENDATIONS

[Prioritized list of fixes, ordered by severity:]
1. [FAIL items first — these block audit readiness]
2. [WARN items second — these are acceptable but should be resolved]
3. [General improvement suggestions]
```

### 2. Display the Dashboard

Output a formatted ASCII dashboard to the user:

```
╔══════════════════════════════════════════════════════════════╗
║  PSM PROGRAM VALIDATION — 12-POINT AUDIT CHECKLIST           ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  [PASS]  1.  Requirement Coverage      X COMPLETE, Y PARTIAL ║
║  [PASS]  2.  Clause Traceability       N/84 mapped           ║
║  [PASS]  3.  Ownership                 14/14 elements        ║
║  [PASS]  4.  Frequency                 5/5 defined           ║
║  [PASS]  5.  Evidence                  14/14 elements        ║
║  [FAIL]  6.  Document Control          2 files missing hdrs  ║
║  [FAIL]  7.  Cross-Reference Integrity 3 broken refs         ║
║  [PASS]  8.  Gap Visibility            12 open gaps          ║
║  [PASS]  9.  Legacy Cleanup            Clean                 ║
║  [WARN] 10.  Implementation Support    2 forms missing       ║
║  [PASS] 11.  Review Quality            Self-review found     ║
║  [PASS] 12.  Publication Readiness     Consistent naming     ║
║  [SKIP] 13.  OCA Reports              Skipped — no OCA data ║
║  [SKIP] 14.  RMP Package              Skipped — no 95_RMP/  ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  RESULT: X/12 PASS  |  Y WARN  |  Z FAIL  |  W SKIP         ║
╚══════════════════════════════════════════════════════════════╝
```

Adapt all values to actual findings. Never display placeholder numbers.

---

## AFTER VALIDATION

1. **Update state file.** Write to `.claude/process-safety.local.json`:
   - Set `validation.last_run` to the current date.
   - Set `validation.pass_count` to the number of PASS results.
   - Set `validation.warn_count` to the number of WARN results.
   - Set `validation.fail_count` to the number of FAIL results.
   - Set `implementation.audit_readiness_pct` calculated as: `(PASS count / 12) * 100`, rounded to nearest integer.

2. **Guidance based on results:**
   - **If all 12 PASS:** Tell the user:
     > Your program passes all audit-ready checks. Run `/process-safety:implement` to begin filling in company-specific content.
   - **If some FAIL or WARN:** Tell the user:
     > N checks need attention. The validation report is saved at `PSM_PROGRAM/00_MASTER/validation-report.md` with specific findings and recommendations.
   - **If mostly FAIL:** Tell the user:
     > Multiple validation checks failed. This may indicate the program generation did not complete successfully. Consider re-running `/process-safety:generate` before attempting validation again.
