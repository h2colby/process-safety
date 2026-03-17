---
name: generate
description: Generate a complete, audit-ready PSM program document set
---

# GENERATE — Complete PSM Program Document Set

You are generating a full, audit-ready Process Safety Management program. This is the largest single operation in the plugin. You will collect company-specific data through a guided intake, then produce a 41-document package.

---

## STEP 0: PRE-FLIGHT CHECKS

Before starting intake, perform these checks silently:

1. **Check for state file.** Read `.claude/process-safety.local.json` in the current working directory.
   - If the file does not exist, run `bash process-safety/scripts/state-manager.sh init` to create it. Then proceed with intake from scratch.
   - If the file exists, read it and check for prior screening data.

2. **Check for prior screening.** If `screening.completed` is `true` in the state file:
   - Greet the user and confirm: "I found your screening results from [date]. Your facility was determined to be [PSM applicable / not applicable]. I'll use the chemical and process data from screening to pre-populate your program. Let me collect the remaining information I need."
   - Pre-populate intake fields from state: `company.name`, `company.state`, `company.facility_locations`, `chemicals`, `processes`.
   - Skip any intake question where the answer is already in state.

3. **Check for prior generation.** If `generation.completed` is `true`:
   - Warn the user: "A PSM program was already generated on [date] with [N] documents. Re-generating will overwrite the existing document set. Do you want to proceed?"
   - Only continue if the user confirms.

4. **Check for PSM_PROGRAM directory.** If the directory already exists in the working directory:
   - Mention it: "I see an existing PSM_PROGRAM directory. I'll overwrite files as needed during generation."

---

## STEP 1: INTAKE QUESTIONNAIRE

Conduct the intake **one topic at a time**. Do not dump all questions at once. Be conversational but efficient. After each topic, summarize what you captured before moving to the next.

If prior screening data exists, acknowledge what you already have and only ask for what is missing.

### 1.1 Company Basics (required — cannot skip)

Ask for:
- Company name (if not in state)
- Headquarters / facility location(s) and state(s) (if not in state)
- Brief description of what the company does (1-2 sentences)

Derive a **document prefix** from the company name. Use a 2-4 letter abbreviation. Examples:
- "Tobe Energy" -> `TOB` or `TE`
- "Acme Chemical" -> `ACM`
- "Pacific Northwest LNG" -> `PNW`

Confirm the prefix with the user: "I'll use [PREFIX] as the document prefix throughout the program (e.g., [PREFIX]-PSM-001). Does that work?"

### 1.2 Organization (can provide org chart or roster to skip)

Ask: "How many people work at your facility? This helps me size the program appropriately."

Then map PSM functions to real people or roles. Explain the consolidation logic for small companies:

**For companies with < 10 people:**
Say: "In a [N]-person company, it's normal for one or two people to cover multiple PSM roles. Here's what I'd suggest — tell me if this works or if you want to adjust:"
- PSM Program Manager (overall accountability) — suggest CEO/founder
- PSM Coordinator (day-to-day management) — suggest operations lead or same as above
- Operations Manager — suggest lead operator or engineer
- Maintenance/Engineering Manager — suggest lead engineer
- Training Coordinator — suggest PSM Coordinator (same person)
- Records Manager — suggest PSM Coordinator (same person)

**For companies with 10-50 people:**
Ask the user to assign each role, but note that combining PSM Coordinator + Training Coordinator + Records Manager is common.

**For companies with 50+ people:**
Ask the user to assign each role individually. Also ask about department structure.

### 1.3 Covered Processes (can provide list to skip)

If screening data includes processes, confirm: "From your screening, I have these processes: [list]. Is this still accurate? Any changes?"

If no prior data, ask: "Describe each process that handles PSM-covered chemicals. For each one I need:"
- Process name and brief description
- Location within facility
- Chemicals involved
- Key equipment categories (vessels, piping, compressors, heat exchangers, relief devices, instrumentation)

Assign process IDs: CP-001, CP-002, etc.

### 1.4 Chemical Inventory (pre-populated from screening if available)

If screening data includes chemicals, confirm: "From your screening, I have these chemicals with their quantities: [table]. Are these maximum intended inventories accurate?"

If no prior data, collect per-process:
- Chemical name
- CAS number (look it up if user doesn't know it — use the data files in `process-safety/data/appendix-a.json` and `process-safety/data/rmp-chemicals.json`)
- Maximum intended inventory (amount and units)
- Physical state at process conditions

**Expert skip provision:** If the user came directly to generate without screening, perform an inline threshold check here. Read the Appendix A data from `process-safety/data/appendix-a.json` and verify that at least one chemical exceeds its PSM threshold quantity. If none do, warn the user: "Based on the quantities you've provided, none of your chemicals appear to exceed PSM threshold quantities. You may not need a PSM program. Consider running `/process-safety:screen` for a formal determination. Do you want to proceed anyway?"

### 1.5 Equipment Categories (can provide list to skip)

Ask: "Which of these equipment types are present in your covered processes?" Present as a checklist:
- [ ] Pressure vessels
- [ ] Storage tanks
- [ ] Piping systems (process piping)
- [ ] Relief devices (PSVs, rupture disks)
- [ ] Controls and instrumentation (DCS, PLC, SIS)
- [ ] Rotating equipment (compressors, pumps)
- [ ] Heat exchangers
- [ ] Electrical classification / equipment in classified areas

This scopes the Mechanical Integrity program.

### 1.6 Emergency Response Determination

Ask: "Does your facility respond to chemical emergencies with your own personnel, or do you rely entirely on external responders (fire department, HAZMAT team, mutual aid)?"

- **Own responders** -> Full Emergency Response Plan per 29 CFR 1910.120 and 1910.38
- **External only** -> Coordination-only emergency action plan per 29 CFR 1910.38

This materially changes the content of Element 12.

### 1.7 Existing Documentation (skip if greenfield)

Ask: "What PSM-related documentation do you already have? This helps me calibrate the gap register. Check all that apply:"
- [ ] P&IDs or process flow diagrams
- [ ] Operating procedures / SOPs
- [ ] Previous PHAs or HAZOP studies
- [ ] Training records
- [ ] Equipment inspection records
- [ ] Chemical SDSs / inventory records
- [ ] Emergency response plan
- [ ] MOC forms or process
- [ ] Anything else relevant

For each item that exists, the gap register will mark the corresponding item as PARTIAL instead of GAP.

### 1.8 Intake Summary

After collecting all data, present a complete summary table and ask for confirmation:

```
INTAKE SUMMARY
==============
Company:          [name]
Document Prefix:  [PREFIX]
Location:         [city, state]
Description:      [what they do]
Employees:        [N]
Covered Processes: [N] — [list names]
Chemicals:        [N] — [list names with quantities]
Equipment Types:  [list]
Emergency Response: [Own / External]
Existing Docs:    [list or "None — greenfield"]

Role Assignments:
  PSM Program Manager:  [name/role]
  PSM Coordinator:      [name/role]
  Operations Manager:   [name/role]
  Maint/Eng Manager:    [name/role]
  Training Coordinator: [name/role]
  Records Manager:      [name/role]

Does this look correct? I'll generate your complete PSM program from this data.
```

Only proceed to generation after the user confirms.

---

## STEP 2: DIRECTORY STRUCTURE

Create the full directory tree under `PSM_PROGRAM/` in the current working directory:

```bash
mkdir -p PSM_PROGRAM/{00_MASTER,01_EMPLOYEE_PARTICIPATION,02_PROCESS_SAFETY_INFORMATION,03_PROCESS_HAZARD_ANALYSIS,04_OPERATING_PROCEDURES,05_TRAINING,06_CONTRACTORS,07_PSSR,08_MECHANICAL_INTEGRITY,09_HOT_WORK,10_MOC,11_INCIDENT_INVESTIGATION,12_EMERGENCY_RESPONSE,13_COMPLIANCE_AUDITS,14_TRADE_SECRETS,90_FORMS,91_TEMPLATES,92_REGISTERS,93_REFERENCE,95_RMP,99_PUBLICATION}
```

Confirm to the user: "Directory structure created. Now generating documents..."

> **Note:** The `95_RMP/` directory is populated by the `/process-safety:rmp` command, which generates the 9-document RMP data package. Run `/process-safety:oca` first to complete Offsite Consequence Analysis before generating the RMP package.

---

## STEP 3: DOCUMENT GENERATION

Generate ALL 41 documents. Use the company name, prefix, roles, chemicals, processes, and equipment from intake throughout. Never use "Tobe Energy" or "TE-" unless that IS the user's company.

Every document must have this controlled header block at the top:

```markdown
# [DOCUMENT TITLE]

| Field | Value |
|---|---|
| **Company** | [Company Name] |
| **Document Number** | [PREFIX]-XXX-NNN |
| **Revision** | R0 |
| **Effective Date** | [today's date] |
| **Owner** | [assigned role from intake] |
| **Approver** | [PSM Program Manager from intake] |
| **Classification** | CONTROLLED DOCUMENT |

## REVISION HISTORY

| Rev | Date | Description | Author | Reviewer | Approver |
|---|---|---|---|---|---|
| R0 | [today's date] | Initial issue — generated by Process Safety plugin | AI Agent | REQUIRES COMPANY REVIEW | [PSM Program Manager] |
```

### 3.1 Master Documents — `00_MASTER/`

Generate these files:

**[PREFIX]-PSM-001_Master_PSM_Manual.md**
The top-level program manual. Must include:
- Program purpose and regulatory basis (29 CFR 1910.119)
- Applicability statement — which processes are covered and why (use intake data)
- Definitions of key terms
- Program governance — who owns the program, review cadence, management commitment
- Organizational roles matrix — full table using the role assignments from intake
- Summary of all 14 PSM elements with 2-3 paragraph descriptions of how each applies at [Company]
- Document architecture — how the document set is organized, numbering convention
- Implementation plan — phased approach starting with PSI compilation
- Program review requirements — annual management review, 3-year compliance audit cycle
- References — 29 CFR 1910.119, applicable RAGAGEP standards

**[PREFIX]-PSM-002_Compliance_Crosswalk.md**
Clause-by-clause mapping covering ALL paragraphs of 29 CFR 1910.119. The crosswalk must include every regulatory subparagraph. Format as a table:

| CFR Clause | Requirement Summary | Company Document | Owner | Evidence | Status |
|---|---|---|---|---|---|

Use these status codes:
- `COMPLETE` — requirement addressed and evidence path defined
- `PARTIAL` — draft exists but evidence or ownership incomplete
- `GAP` — requirement not yet satisfied
- `NEEDS COMPANY INPUT` — waiting on company-specific information
- `NOT APPLICABLE` — with rationale

The crosswalk must cover at minimum these sections (with all sub-paragraphs):
- 1910.119(a) — Applicability
- 1910.119(c) — Employee Participation
- 1910.119(d) — Process Safety Information (d)(1)-(3) with all sub-items
- 1910.119(e) — Process Hazard Analysis (e)(1)-(7)
- 1910.119(f) — Operating Procedures (f)(1)-(4)
- 1910.119(g) — Training (g)(1)-(3)
- 1910.119(h) — Contractors (h)(1)-(3)
- 1910.119(i) — Pre-Startup Safety Review
- 1910.119(j) — Mechanical Integrity (j)(1)-(7)
- 1910.119(k) — Hot Work Permit
- 1910.119(l) — Management of Change (l)(1)-(5)
- 1910.119(m) — Incident Investigation (m)(1)-(7)
- 1910.119(n) — Emergency Planning and Response
- 1910.119(o) — Compliance Audits (o)(1)-(4)
- 1910.119(p) — Trade Secrets

Mark each clause status based on what was generated and what remains as a gap. Most element procedures will be COMPLETE or PARTIAL. Evidence artifacts (actual training records, actual PHA reports, actual P&IDs) will be GAP or NEEDS COMPANY INPUT.

**[PREFIX]-PSM-003_Document_Register.md**
A controlled register listing every document in the PSM program:

| Doc Number | Title | Type | Location | Rev | Date | Owner | Status |
|---|---|---|---|---|---|---|---|

List all 41 documents. Type = Manual / Procedure / Form / Register / Report.

**[PREFIX]-PSM-004_Gap_Register.md**
All open gaps identified during generation. Pre-classify severity based on intake:

| Gap ID | Element | Description | Source Trigger | Severity | Required Input | Proposed Resolution | Owner | Status |
|---|---|---|---|---|---|---|---|---|

Pre-populate with known gaps based on intake:
- If user said no P&IDs -> GAP-001: "No P&IDs available for covered processes" — Severity: CRITICAL
- If user said no PHAs -> GAP for PHA element — Severity: CRITICAL
- If user said no procedures -> GAP for operating procedures — Severity: HIGH
- Every process needs PSI compiled (MSDS/SDS, P&IDs, electrical classification, relief system design basis, ventilation, material/energy balances, equipment design specs) — generate a gap for each missing PSI category
- PHA has not been performed for any process — always a gap for new programs
- Training has not been verified for any employee — always a gap
- MI inspection baseline does not exist — always a gap for new programs
- No contractor qualification records exist — gap if user didn't mention them
- Emergency response plan needs facility-specific details — always PARTIAL at generation time

**screening-report.md**
- If screening data exists in state, generate a brief summary: "Screening was completed on [date]. PSM: [applicable/not]. RMP: [applicable/not]. See `.claude/process-safety.local.json` for full screening data."
- If no screening was done, write: "Formal screening was not performed prior to program generation. PSM applicability was confirmed during intake based on chemical inventory review."

**[PREFIX]-PSM-006_Self_Review_Report.md** — Generated in Step 4 (self-review phase). Create a placeholder now and fill it after all documents are generated.

**[PREFIX]-PSM-007_Audit_Simulation_Report.md** — Generated in Step 4 (self-review phase). Create a placeholder now and fill it after all documents are generated.

### 3.2 Element Procedures — Directories `01/` through `14/`

Generate one procedure per element. Use the document numbers below, replacing the prefix:

| Directory | File | Doc Number |
|---|---|---|
| `01_EMPLOYEE_PARTICIPATION/` | `[PREFIX]-EP-001_Employee_Participation.md` | [PREFIX]-EP-001 |
| `02_PROCESS_SAFETY_INFORMATION/` | `[PREFIX]-PSI-001_Process_Safety_Information.md` | [PREFIX]-PSI-001 |
| `03_PROCESS_HAZARD_ANALYSIS/` | `[PREFIX]-PHA-001_Process_Hazard_Analysis.md` | [PREFIX]-PHA-001 |
| `04_OPERATING_PROCEDURES/` | `[PREFIX]-OP-001_Operating_Procedures.md` | [PREFIX]-OP-001 |
| `05_TRAINING/` | `[PREFIX]-TRN-001_Training.md` | [PREFIX]-TRN-001 |
| `06_CONTRACTORS/` | `[PREFIX]-CON-001_Contractors.md` | [PREFIX]-CON-001 |
| `07_PSSR/` | `[PREFIX]-PSSR-001_Pre_Startup_Safety_Review.md` | [PREFIX]-PSSR-001 |
| `08_MECHANICAL_INTEGRITY/` | `[PREFIX]-MI-001_Mechanical_Integrity.md` | [PREFIX]-MI-001 |
| `09_HOT_WORK/` | `[PREFIX]-HW-001_Hot_Work_Permit.md` | [PREFIX]-HW-001 |
| `10_MOC/` | `[PREFIX]-MOC-001_Management_of_Change.md` | [PREFIX]-MOC-001 |
| `11_INCIDENT_INVESTIGATION/` | `[PREFIX]-II-001_Incident_Investigation.md` | [PREFIX]-II-001 |
| `12_EMERGENCY_RESPONSE/` | `[PREFIX]-ERP-001_Emergency_Planning_Response.md` | [PREFIX]-ERP-001 |
| `13_COMPLIANCE_AUDITS/` | `[PREFIX]-CA-001_Compliance_Audits.md` | [PREFIX]-CA-001 |
| `14_TRADE_SECRETS/` | `[PREFIX]-TS-001_Trade_Secrets.md` | [PREFIX]-TS-001 |

**Each element procedure MUST include ALL of these sections:**

1. **PURPOSE** — Why this element exists, in 2-3 sentences. Reference the CFR paragraph.

2. **SCOPE** — What this element covers at [Company]. Be specific to the user's facility and processes.

3. **REGULATORY BASIS** — Cite the exact 29 CFR 1910.119 paragraph(s).

4. **DEFINITIONS** — Key terms used in this procedure.

5. **ROLES AND RESPONSIBILITIES** — Table format using the role assignments from intake:
   | Role | Responsibility |
   |---|---|
   Use the actual names/titles from intake.

6. **REQUIREMENTS** — The operative procedure. This is the meat. Write step-by-step requirements that satisfy each sub-paragraph of the CFR for this element. Use numbered steps. Be specific about what must happen, who does it, and what record is produced.

7. **INPUTS** — What source information or preconditions are needed before this element can function.

8. **OUTPUTS** — What records, decisions, approvals, or documents result from executing this element.

9. **INTERFACES** — Which other PSM elements this one connects to, and how. Use a table:
   | Related Element | Interface Description |
   |---|---|

10. **RECORDS AND EVIDENCE** — Specific forms, registers, and records that prove implementation. Reference the actual form numbers from the Forms section:
    | Record | Form/Register | Retention | Location |
    |---|---|---|---|

11. **REVIEW CADENCE** — How often this element is reviewed or revalidated. Be specific:
    - PHA: revalidated at least every 5 years
    - Operating procedures: certified as current annually
    - Compliance audits: at least every 3 years
    - Training: initial before assignment, refresher every 3 years
    - MI: per applicable RAGAGEP (reference specific codes where possible)

12. **AUDIT CHECKPOINTS** — What an auditor will ask for and verify. Write these as questions:
    - "Show me evidence of [specific thing]"
    - "How do you ensure [specific requirement]?"
    - "Where are [specific records] maintained?"

**Element-Specific Content Requirements:**

**Element 01 — Employee Participation:**
- Written plan for employee participation
- Employee access to PHAs, PSI, operating procedures, incident investigation reports
- Consultation mechanisms (safety committees, toolbox talks, suggestion systems)
- Documentation of employee involvement in PHA teams

**Element 02 — PSI:**
- Three categories: chemical hazards, process technology, equipment
- Chemical hazards: toxicity, PELs, physical data, reactivity, corrosivity, thermal/chemical stability, hazardous decomposition effects
- Process technology: block flow or process flow diagram, process chemistry, max intended inventory, safe operating limits, consequence of deviations
- Equipment: materials of construction, P&IDs, electrical classification, relief system design basis, ventilation design, design codes/standards, material/energy balances
- Populate chemical data from intake. For each chemical the user listed, include its hazard data.
- Flag every PSI sub-category that requires compilation as a gap.

**Element 03 — PHA:**
- Methodology selection (HAZOP for complex processes, What-If/Checklist for simpler processes)
- Team composition requirements (process engineer, operator, maintenance, facilitator, subject matter experts)
- Documentation requirements per 1910.119(e)(3) — hazards, previous incidents, controls, consequences, facility siting, human factors
- Recommendation resolution and tracking — reference Action Item Register
- Revalidation every 5 years
- PHA must address facility siting, human factors, and a qualitative range of possible safety/health effects
- Generate a PHA schedule entry for each covered process from intake

**Element 04 — Operating Procedures:**
- Must cover: initial startup, normal operations, temporary operations, emergency operations, normal shutdown, emergency shutdown, startup after turnaround/emergency
- Must include operating limits (consequences of deviation), safety/health considerations (properties/hazards, exposure controls, quality control for feedstocks, PPE, special hazard controls)
- Annual certification that procedures are current and accurate
- Procedure update triggered by MOC, incident investigation, or PHA recommendation
- Safe work practices referenced (lockout/tagout, confined space, opening process equipment)

**Element 05 — Training:**
- Initial training before assignment to a covered process
- Refresher training at least every 3 years
- Training must cover: operating procedures, safe work practices, emergency operations, process-specific hazards
- Means of verification: written test, oral exam, practical demonstration, or observation
- Individual training records with identity, date, means of verification
- Reference Training Matrix register for requirements by role

**Element 06 — Contractors:**
- Employer responsibilities: evaluate contractor safety, inform contractors of hazards, explain emergency plan, audit contractor safety, maintain injury/illness log
- Contractor responsibilities: train employees for the work, document training, ensure employees understand safe work practices, follow facility safety rules
- Contractor qualification and selection criteria
- Pre-job safety briefing requirements
- Contractor performance evaluation

**Element 07 — PSSR:**
- Required before introducing HHCs into a new or modified process
- PSSR must confirm: construction/equipment matches design specs, safety/operating/maintenance/emergency procedures are in place, PHA recommendations resolved, modified procedures address the change, training completed, MOC requirements satisfied
- Generate PSSR checklist as a form

**Element 08 — Mechanical Integrity:**
- Covers: pressure vessels, storage tanks, piping, relief devices, controls/instrumentation, rotating equipment (scope based on intake equipment list)
- Written procedures for maintaining ongoing integrity
- Inspection and testing per RAGAGEP (reference applicable codes: ASME, API 510, API 570, API 653, API 580/581, NFPA 70, ISA 84)
- Equipment deficiency correction
- Quality assurance for new equipment and spare parts

**Element 09 — Hot Work:**
- Hot work permit required for operations involving spark, flame, or heat-producing activities on or near covered processes
- Permit must comply with 29 CFR 1910.252(a)
- Permit fields: date, work description, fire prevention measures, authorization, monitoring requirements
- Generate Hot Work Permit form

**Element 10 — MOC:**
- Covers changes to: process chemicals, technology, equipment, procedures, and changes to facilities that affect a covered process
- Does NOT cover "replacement in kind"
- Must address: technical basis, safety/health impact, modifications to operating procedures, time period for change, authorization requirements
- Employees and contractors must be informed/trained before startup
- Operating procedures and PSI must be updated
- Generate MOC Request Form

**Element 11 — Incident Investigation:**
- Investigation required for each incident that resulted in or could reasonably have resulted in a catastrophic release
- Initiate within 48 hours
- Team includes at least one person knowledgeable in the process, a contract employee if involved, and other subject matter experts as needed
- Report must include: date, description, factors contributing, recommendations
- Findings addressed and resolved, documented in action item register
- Report reviewed with all affected personnel
- Reports retained for 5 years

**Element 12 — Emergency Planning and Response:**
- Content varies based on intake question 1.6:
  - If OWN RESPONDERS: Full emergency response plan per 1910.120(q) — alarm systems, evacuation routes, response procedures, medical treatment, PPE, training for responders, coordination with external agencies
  - If EXTERNAL ONLY: Emergency action plan per 1910.38 — evacuation procedures, reporting procedures, alarm systems, employee roles, coordination with external responders, emergency contact list
- In either case: facility-specific evacuation routes, assembly points, emergency contact numbers, chemical-specific response data, communication procedures

**Element 13 — Compliance Audits:**
- Audit at least every 3 years
- Audit must verify compliance with the requirements of 1910.119
- Audit conducted by at least one person knowledgeable in the process
- Audit report documenting findings
- Employer must promptly determine and document appropriate response to each finding
- Employer must document deficiency correction
- Most recent two audit reports retained
- Generate Compliance Audit Checklist and Audit Report forms

**Element 14 — Trade Secrets:**
- Must make PSI available to persons responsible for PHA, operating procedures, incident investigation, emergency response, and compliance audits
- May require confidentiality agreements
- Must not prevent access needed for compliance with 1910.119
- Information must be available to employees and designated representatives per 1910.1200

### 3.3 Forms — `90_FORMS/`

Generate 13 forms. Each form must have:
- Controlled header block
- Clear field labels with blank spaces or checkboxes for completion
- Instructions for completing the form
- Signature/approval blocks where appropriate
- Form number in header

| Form | File Name | Key Fields |
|---|---|---|
| [PREFIX]-FRM-001 | `[PREFIX]-FRM-001_MOC_Request_Form.md` | Change description, technical basis, safety/health impact, procedure modifications needed, time period, permanent/temporary, authorization signatures, affected personnel notification, training requirements |
| [PREFIX]-FRM-002 | `[PREFIX]-FRM-002_PSSR_Checklist.md` | Construction verification, safety procedure verification, operating procedure verification, maintenance procedure verification, emergency procedure verification, PHA resolution verification, training verification, MOC completion, authorization |
| [PREFIX]-FRM-003 | `[PREFIX]-FRM-003_Hot_Work_Permit.md` | Date/time, location, work description, fire prevention measures (sprinklers, fire watch, extinguishers, combustible removal), atmospheric testing, authorization, permit expiration, monitoring requirements |
| [PREFIX]-FRM-004 | `[PREFIX]-FRM-004_Incident_Investigation_Report.md` | Incident date/time/location, description, persons involved, immediate causes, root causes, contributing factors, recommendations, corrective actions, review signatures, distribution list |
| [PREFIX]-FRM-005 | `[PREFIX]-FRM-005_Training_Record.md` | Employee name, ID, job title, training date, course/topic, trainer, means of verification (written/oral/practical), score/result, employee signature, trainer signature, next refresher date |
| [PREFIX]-FRM-006 | `[PREFIX]-FRM-006_Contractor_Qualification.md` | Contractor company, scope of work, safety program verification, EMR/TRIR, OSHA 300 log, training documentation, substance abuse program, safety performance history, qualification determination, evaluator signature |
| [PREFIX]-FRM-007 | `[PREFIX]-FRM-007_Compliance_Audit_Checklist.md` | Organized by all 14 PSM elements, each with 3-8 specific audit questions, compliance status (Compliant/Non-Compliant/Partial/N-A), evidence reviewed, findings, auditor notes |
| [PREFIX]-FRM-008 | `[PREFIX]-FRM-008_Action_Item_Tracking.md` | Action item ID, source (PHA/audit/incident/MOC), finding description, recommendation, assigned owner, priority (Critical/High/Medium/Low), due date, completion date, verification, status (Open/In Progress/Closed/Overdue) |
| [PREFIX]-FRM-009 | `[PREFIX]-FRM-009_MI_Inspection_Record.md` | Equipment ID, equipment description, inspection type (internal/external/testing), applicable code/standard, inspection date, next due date, inspector name/qualifications, findings, condition assessment, deficiencies, corrective actions, attachments |
| [PREFIX]-FRM-010 | `[PREFIX]-FRM-010_Employee_Participation_Log.md` | Date, activity type (PHA team/safety meeting/procedure review/suggestion/consultation), participants, topic/description, outcomes/actions, follow-up required |
| [PREFIX]-FRM-011 | `[PREFIX]-FRM-011_OP_Annual_Certification.md` | Procedure number, procedure title, process area, review date, reviewer, changes needed (Y/N), change description, certification statement, reviewer signature, operations manager signature |
| [PREFIX]-FRM-012 | `[PREFIX]-FRM-012_Emergency_Drill_Record.md` | Drill date, drill type (tabletop/functional/full-scale), scenario description, participants, response time, objectives met (Y/N), deficiencies observed, corrective actions, evaluator, next drill date |
| [PREFIX]-FRM-013 | `[PREFIX]-FRM-013_Compliance_Audit_Report.md` | Audit date, audit scope, audit team, methodology, executive summary, findings by element (finding ID, element, description, severity, recommendation, owner, due date), audit conclusion, corrective action plan, auditor signatures |

### 3.4 Registers — `92_REGISTERS/`

Generate 7 registers. Pre-populate with intake data where available.

| Register | File Name | Content |
|---|---|---|
| [PREFIX]-REG-001 | `[PREFIX]-REG-001_Covered_Process_Register.md` | Table with: Process ID, Process Name, Location, Chemicals, Max Inventory, Threshold Quantity, Coverage Basis, PHA Status, PSI Status. Pre-populate from intake processes. |
| [PREFIX]-REG-002 | `[PREFIX]-REG-002_Chemical_Inventory_Register.md` | Table with: Chemical Name, CAS Number, Process(es), Max Intended Inventory, TQ (PSM), TQ (RMP), Physical State, Primary Hazards, SDS on File (Y/N). Pre-populate from intake chemicals. |
| [PREFIX]-REG-003 | `[PREFIX]-REG-003_Equipment_Register.md` | Table with: Equipment ID, Description, Type, Process, Design Code, Inspection Frequency, Last Inspection, Next Due, Status. Pre-populate equipment types from intake — use placeholder IDs (e.g., PV-001, TK-001). |
| [PREFIX]-REG-004 | `[PREFIX]-REG-004_PHA_Schedule_Register.md` | Table with: PHA ID, Process, Methodology, Initial PHA Date, Last Revalidation, Next Revalidation Due, Status, Team Lead. One entry per covered process. All initial dates = `REQUIRES COMPANY INPUT`. |
| [PREFIX]-REG-005 | `[PREFIX]-REG-005_Training_Matrix.md` | Table with roles from intake as rows, training topics as columns (PSM overview, process-specific hazards, operating procedures, emergency response, MOC awareness, hot work, contractor safety). Mark required training per role with X. |
| [PREFIX]-REG-006 | `[PREFIX]-REG-006_Contractor_Register.md` | Table with: Contractor Name, Scope of Work, Qualification Date, EMR, Qualification Status, Next Review Date. Pre-populate with `REQUIRES COMPANY INPUT` entries. |
| [PREFIX]-REG-007 | `[PREFIX]-REG-007_Action_Item_Register.md` | Table with: Item ID, Source, Element, Description, Owner, Priority, Date Opened, Due Date, Status, Closure Date, Verification. Pre-populate with action items from the gap register — each critical/high gap should have a corresponding action item. |

### 3.5 Reference and Publication — `93_REFERENCE/` and `99_PUBLICATION/`

**`93_REFERENCE/`** — Create a `README.md` with:
- Purpose of this directory: "Store reference materials including CFR text, RAGAGEP standards, OSHA guidance documents, SDSs, and other supporting references."
- List of recommended references to obtain and file here.

**`99_PUBLICATION/`** — Create a `README.md` with:
- Purpose: "Final publication-ready versions of controlled documents."
- Publication checklist: naming convention, revision status, approval signatures, formatting verification, distribution list.

---

## STEP 4: SELF-REVIEW AND AUDIT SIMULATION

After ALL documents are generated, perform the self-review.

### 4.1 Self-Review (12-Point Checklist)

Run through each check and record Pass/Fail/Partial:

1. **Requirement coverage** — Scan the crosswalk for any GAP status items. Note count.
2. **Clause traceability** — Verify the crosswalk covers all 1910.119 paragraphs (a) through (p).
3. **Ownership** — Verify every element procedure has roles assigned from intake.
4. **Frequency** — Verify PHA (5yr), training (3yr initial + refresher), audits (3yr), procedures (annual cert), MI (per RAGAGEP) are all specified.
5. **Evidence** — Verify every element procedure's Records section references specific forms/registers.
6. **Document control** — Verify all 41 documents have header blocks with doc number, rev, date.
7. **Cross-reference integrity** — Verify all form numbers (FRM-001 through FRM-013) and register numbers (REG-001 through REG-007) referenced in procedures actually exist as files.
8. **Gap visibility** — Verify gap register exists and has entries.
9. **Legacy cleanup** — Verify no "Tobe Energy" or example company names appear (unless that IS the company). Verify no placeholder prefixes survive.
10. **Implementation support** — Verify all 13 forms and 7 registers exist as files.
11. **Review quality** — This self-review satisfies this criterion.
12. **Publication readiness** — Verify document numbering is consistent and header blocks are complete.

Write the results to `[PREFIX]-PSM-006_Self_Review_Report.md` in `00_MASTER/`.

### 4.2 Audit Simulation

Simulate an external auditor asking evidence questions. For each of the 14 elements, ask:

- "Show me the procedure." -> Does the procedure file exist?
- "Show me the evidence of implementation." -> Is there a form/register for capturing evidence?
- "Who is responsible?" -> Is an owner assigned?
- "How often is this reviewed?" -> Is a frequency specified?
- "Show me your most recent [record]." -> The record won't exist yet (this is a new program), but is the mechanism in place to create it?

Rate each element: READY (procedure + forms + registers in place), PARTIAL (procedure exists but evidence mechanisms incomplete), NOT READY (missing critical components).

Calculate an overall audit readiness percentage: count of READY elements / 14.

Write results to `[PREFIX]-PSM-007_Audit_Simulation_Report.md` in `00_MASTER/`.

---

## STEP 5: STATE UPDATE

After all documents are generated and reviewed, update `.claude/process-safety.local.json` using the state manager script:

```bash
echo '{
  "company": {
    "name": "[company name]",
    "state": "[state]",
    "facility_locations": ["[location]"]
  },
  "processes": [array of process objects from intake],
  "chemicals": [array of chemical objects from intake],
  "roles": {
    "psm_program_manager": "[name/role]",
    "psm_coordinator": "[name/role]",
    "operations_manager": "[name/role]",
    "maintenance_engineering_manager": "[name/role]",
    "training_coordinator": "[name/role]",
    "records_manager": "[name/role]"
  },
  "generation": {
    "completed": true,
    "date": "[today]",
    "document_count": 41,
    "document_prefix": "[PREFIX]"
  },
  "implementation": {
    "phase": "psi_compilation",
    "audit_readiness_pct": [calculated from audit simulation],
    "gaps_open": [count from gap register],
    "gaps_critical": [critical count from gap register],
    "next_priority": "Complete Process Safety Information for [first process name]"
  }
}' | bash process-safety/scripts/state-manager.sh update
```

---

## STEP 6: COMPLETION REPORT

After everything is done, present a completion summary to the user:

```
PSM PROGRAM GENERATION COMPLETE
================================
Company:           [name]
Document Prefix:   [PREFIX]
Documents Created: 41
  - Master documents: 7
  - Element procedures: 14
  - Forms: 13
  - Registers: 7

Self-Review Results:
  [Pass/Fail summary of 12 checks]

Audit Simulation:
  Audit Readiness: [X]%
  Elements READY: [N]/14
  Elements PARTIAL: [N]/14

Gap Register:
  Total gaps: [N]
  Critical: [N]
  High: [N]
  Medium: [N]
  Low: [N]

NEXT STEPS:
1. Review the Gap Register at PSM_PROGRAM/00_MASTER/[PREFIX]-PSM-004_Gap_Register.md
2. Begin PSI compilation for your covered processes
3. Run /process-safety:implement to get step-by-step guidance on closing gaps

Your first implementation priority is: [next_priority from state]
```

---

## CRITICAL RULES — READ THESE

1. **Generate ALL 41 documents.** Do not skip documents. Do not ask "should I continue?" after 5 documents. Generate the entire set. This is the core value of the command.

2. **Use company-specific data everywhere.** Every document must use the company name, prefix, roles, chemicals, and processes from intake. No generic placeholders where real data was provided.

3. **No hallucinated facility facts.** If the user didn't tell you something, mark it `REQUIRES COMPANY INPUT`. Do not invent equipment tag numbers, building names, chemical quantities, or personnel names that weren't provided.

4. **Smart gap classification.** Use intake responses to pre-classify gaps. Missing P&IDs = CRITICAL. Missing PHAs = CRITICAL. Missing procedures = HIGH. Missing training records = HIGH. No contractor records = MEDIUM.

5. **Cross-reference integrity.** Every form and register referenced in a procedure must actually exist as a generated file. Every document referenced in the crosswalk must exist. Check this during self-review.

6. **Startup-appropriate.** For small companies, don't create bureaucratic overhead that a 5-person team can't maintain. Consolidate where sensible. But don't skip regulatory requirements — simplify the execution, not the coverage.

7. **Write real content.** Element procedures must have substantive requirements sections with actual steps, not one-line summaries. The procedures need enough detail that someone could follow them. This is an operating system for process safety, not a table of contents.

8. **Forms must be usable.** Forms need actual fields, checkboxes, signature blocks — not just descriptions of what a form should contain. Someone should be able to print (or digitally fill) these forms.

9. **The crosswalk is the backbone.** The compliance crosswalk must cover every regulatory sub-paragraph. It is the single most important document for audit readiness. Do not shortcut it.

10. **Update state when done.** The state file must reflect the completed generation so that `/process-safety:status` and `/process-safety:implement` work correctly.
