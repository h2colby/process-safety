# process-safety

**Federal process safety compliance for hard tech startups.**

A Claude Code plugin that screens OSHA PSM and EPA RMP applicability, generates a complete audit-ready program document set, and provides guided implementation coaching. Built for operators who handle threshold quantities of highly hazardous chemicals and need a real compliance program, not a binder on a shelf.

---

## WHAT IT DOES

| Capability | Description |
|---|---|
| **Screen** | Walks through your chemical inventory against 29 CFR 1910.119 Appendix A and 40 CFR 68 substance lists. Determines whether OSHA PSM, EPA RMP, or both apply to your facility. |
| **Generate** | Produces a 41-document PSM program package: master manual, 14 element procedures, compliance crosswalk, gap register, forms, templates, and registers. All documents are numbered, revision-controlled, and audit-ready. |
| **Implement** | Step-by-step coaching through each PSM element. Tracks progress, surfaces open gaps, and prioritizes work based on regulatory risk. |

---

## QUICK START

```
# 1. Install the plugin
claude plugin install process-safety

# 2. Screen your facility for applicability
/process-safety:screen

# 3. Generate the full PSM program
/process-safety:generate
```

---

## COMMANDS

| Command | Description |
|---|---|
| `/process-safety:help` | Plugin overview, PSM/RMP basics, and full command reference |
| `/process-safety:screen` | Determine if OSHA PSM and/or EPA RMP apply to your facility |
| `/process-safety:generate` | Generate the complete audit-ready PSM program document set |
| `/process-safety:status` | View implementation progress dashboard and open gap summary |
| `/process-safety:implement` | Guided, step-by-step implementation coaching by element |

---

## WHAT GETS GENERATED

The `generate` command produces a controlled document package covering the 14 OSHA PSM elements:

```
PSM_PROGRAM/
  00_MASTER/          Master manual, compliance crosswalk, document register, gap register
  01-14_ELEMENTS/     One procedure per PSM element (employee participation through trade secrets)
  90_FORMS/           MOC forms, PSSR checklists, hot work permits, audit checklists
  91_TEMPLATES/       Incident investigation, training records, contractor verification
  92_REGISTERS/       Action tracker, document register, source register
  93_REFERENCE/       CFR text, OSHA guidance extracts
  99_PUBLICATION/     Cover pages, revision history, approval blocks
```

Each document includes: purpose, scope, roles and responsibilities, procedure steps, records/evidence requirements, review cadence, element interfaces, and regulatory references. Documents are numbered using the `TOB-PSM-XXX` scheme with full revision control.

---

## REGULATORY COVERAGE

| Regulation | Scope |
|---|---|
| **OSHA PSM** — 29 CFR 1910.119 | All 14 elements. Clause-by-clause crosswalk with traceability to generated documents. |
| **EPA RMP** — 40 CFR Part 68 | Applicability screening against listed substances and threshold quantities. Program level determination. |

Chemical screening uses the full Appendix A list (137 chemicals with threshold quantities) and the EPA RMP regulated substance tables.

---

## LIMITATIONS

- This tool generates program documentation. It does not replace engineering judgment, process hazard analysis, or facility-specific technical work.
- Generated documents require company-specific review and approval before implementation. Items needing site-specific input are marked `REQUIRES TOBE INPUT`.
- Chemical screening covers federal OSHA PSM and EPA RMP only. State-plan states, California PSM (Cal/OSHA CCR Title 8 Section 5189), and local air district rules are out of scope.
- The plugin does not perform consequence modeling, dispersion analysis, or quantitative risk assessment.
- Mechanical integrity inspection intervals, relief device sizing, and P&ID verification require qualified engineering review.

---

## LICENSE

MIT -- see [LICENSE](LICENSE).
