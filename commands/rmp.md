---
name: rmp
description: Generate RMP data package for EPA submission — all fields required by 40 CFR 68.150-68.185
---

# RMP — Risk Management Plan Data Package Generator

You are generating a complete RMP data package for EPA CDX submission. This command produces 9 controlled documents that map field-by-field to the EPA's electronic submission requirements under 40 CFR Part 68. The user will use these documents as their field-by-field guide when entering data into EPA's CDX system.

---

## STEP 0: PRE-FLIGHT CHECKS

Before starting intake, perform these checks silently:

1. **Check for state file.** Read `.claude/process-safety.local.json` in the current working directory.
   - If the file does not exist: stop and tell the user: "No project state found. You need to complete screening and PSM program generation before creating an RMP package. Run `/process-safety:screen` to get started."
   - If the file exists, proceed to check prerequisites.

2. **Check screening completed.** If `screening.completed` is not `true` in the state file:
   - Stop and tell the user: "You need to complete chemical screening first. Run `/process-safety:screen` to determine if OSHA PSM and EPA RMP apply to your facility."

3. **Check PSM generation completed.** If `generation.completed` is not `true` in the state file:
   - Stop and tell the user: "You need to generate your PSM program first. The RMP prevention program references your PSM element procedures. Run `/process-safety:generate` to build your PSM program."

4. **Check OCA completed.** If `oca.completed` is not `true` and `oca.scenarios` does not have at least one entry:
   - Stop and tell the user: "You need to complete at least worst-case offsite consequence analysis before generating the RMP package. Run `/process-safety:oca` to calculate your worst-case and alternative release scenarios."

5. **Check for existing RMP directory.** If `PSM_PROGRAM/95_RMP/` already exists:
   - Warn the user: "An RMP data package already exists in PSM_PROGRAM/95_RMP/. Re-generating will overwrite the existing documents. Do you want to proceed?"
   - Only continue if the user confirms.

6. **Note Program 3 scope.** Display: "This command supports Program 3 facilities (which includes most PSM-covered facilities). If your facility is Program 1 or 2, the generated package may include elements not required for your program level."

7. **Gather existing state data.** Read the full state file and extract:
   - Company name, prefix, facility locations, state
   - Chemical inventory with CAS numbers and quantities
   - Covered processes
   - Role assignments
   - OCA scenario results (worst-case distances, chemicals, endpoints)
   - Employee count
   - Emergency response determination
   - Any previously collected RMP data

---

## STEP 1: RMP INTAKE QUESTIONNAIRE

Conduct the intake **one topic at a time**. Do not dump all questions at once. Be conversational but efficient. After each topic, summarize what you captured before moving to the next.

Pre-populate from state data wherever possible. Only ask for information not already captured.

---

### Topic 1: Facility Registration Details

Collect the following registration data required by 40 CFR 68.160:

**Facility Coordinates:**
Ask: "What are your facility's latitude and longitude coordinates? If you don't know them, give me your street address and I can help estimate them."
- If user provides an address, use it to estimate coordinates and confirm with the user.
- Format: decimal degrees (e.g., 29.7604 N, -95.3698 W)

**DUNS Number:**
Ask: "What is your facility's DUNS number? This is a 9-digit identifier used by the federal government. If you don't have one, you can skip this — but EPA may require it for CDX submission."
- If user skips: record as `NOT PROVIDED — may be required for CDX submission`

**Parent Company DUNS:**
Ask: "Does your facility have a parent company? If so, what is the parent company's DUNS number?"
- If no parent company or unknown: record appropriately.

**EPA Facility ID:**
Ask: "Has your facility previously submitted an RMP to EPA? If so, what is your EPA Facility ID or FRS (Facility Registry Service) number?"
- If first-time submitter: record as `FIRST-TIME SUBMITTER — EPA will assign an ID upon submission`

**Last Government Safety Inspection:**
Ask: "When was the last time a government agency conducted a safety inspection at your facility? Which agency was it (OSHA, EPA, state agency, fire marshal, etc.)?"
- If never inspected: record as `No government safety inspections to date`
- Capture: date and inspecting agency name

After collecting, summarize:
```
FACILITY REGISTRATION
=====================
Coordinates:    [lat], [long]
DUNS:           [number or NOT PROVIDED]
Parent DUNS:    [number or N/A]
EPA Facility ID: [number or FIRST-TIME SUBMITTER]
Last Inspection: [date] by [agency] (or None)
```

---

### Topic 2: NAICS Code

Ask: "What NAICS code best describes the primary activity at your covered process?"

Provide suggestions based on the company description from the state file. Common NAICS codes for PSM-covered facilities:

| NAICS | Description |
|---|---|
| 325110 | Petrochemical Manufacturing |
| 325120 | Industrial Gas Manufacturing |
| 325180 | Other Basic Inorganic Chemical Manufacturing |
| 325190 | Other Basic Organic Chemical Manufacturing |
| 325199 | All Other Basic Organic Chemical Manufacturing |
| 325211 | Plastics Material and Resin Manufacturing |
| 325311 | Nitrogenous Fertilizer Manufacturing |
| 324110 | Petroleum Refineries |
| 324199 | All Other Petroleum and Coal Products Manufacturing |
| 486210 | Pipeline Transportation of Natural Gas |
| 221210 | Natural Gas Distribution |
| 493190 | Other Warehousing and Storage (chemical storage) |

If the user is unsure, help them select based on their company description. The NAICS code should describe the covered process, not the company's overall business.

After collecting, confirm: "I'll use NAICS [code] — [description] for your RMP submission."

---

### Topic 3: Emergency Contact

Ask: "EPA requires a 24-hour emergency contact for your RMP. This person must be reachable at any time in the event of an accidental release. Who should this be?"

Collect:
- Full name
- Title
- 24-hour phone number (must be a number that is answered 24/7 — cell phone, answering service, or control room)
- Email address

If the user mentions a role from the state file (e.g., PSM Program Manager), confirm the specific person's contact details.

After collecting, summarize:
```
24-HOUR EMERGENCY CONTACT
==========================
Name:  [name]
Title: [title]
Phone: [number]
Email: [email]
```

---

### Topic 4: Employee Count Confirmation

Check the state file for employee count. If available:
Ask: "Your PSM program shows [N] employees at your facility. Is this still accurate for your RMP submission? EPA asks for the number of full-time employees at the facility."

If not available in state:
Ask: "How many full-time employees work at your facility?"

Record the confirmed count.

---

### Topic 5: 5-Year Accident History

This is required by 40 CFR 68.42. Ask carefully and clearly:

Ask: "Has your facility had any accidental chemical releases in the past 5 years that resulted in any of the following?"
- Deaths (on-site or off-site)
- Injuries (on-site or off-site)
- Significant property damage on-site
- Any known off-site impacts: evacuations, sheltering in place, environmental damage, property damage
- Off-site deaths or injuries

**If the user answers NO:**
Record: "No RMP-reportable accidental releases in the past 5 years."
Note to user: "This is a valid and common answer, especially for newer facilities and startups. We'll include a formal statement in your accident history document."

**If the user answers YES:**
For each incident, collect:

| Field | Question |
|---|---|
| Date | "What date did the release occur?" |
| Time | "Approximately what time?" |
| Duration | "How long did the release last (minutes or hours)?" |
| Chemical(s) released | "Which chemical(s) were released?" |
| Estimated quantity (lbs) | "Approximately how many pounds were released?" |
| Release event type | "Was this a gas release, liquid spill, fire, explosion, or combination?" |
| Source | "What was the source? (vessel, pipe, valve, transfer hose, gasket, pump seal, etc.)" |
| Weather conditions | "Do you recall the weather conditions? (wind speed, direction, temperature — if unknown, say so)" |
| On-site impacts | "Were there any on-site injuries, deaths, or significant property damage?" |
| Known off-site impacts | "Were there any known off-site impacts? (evacuations, sheltering, injuries, environmental damage, property damage)" |
| Initiating event | "What initiated the release? (equipment failure, operator error, external event, design flaw, etc.)" |
| Contributing factors | "Were there any contributing factors? (maintenance deficiency, training gap, procedure deviation, design issue)" |
| Off-site responders notified | "Were off-site emergency responders (fire department, HAZMAT) notified?" |
| Changes made | "What operational or process changes were made as a result of this incident?" |

After collecting each incident, summarize it and ask: "Were there any other reportable releases in the past 5 years?"

---

### Topic 6: Receptors Within OCA Distance

Pull the worst-case distance from OCA state data. Present to user:

"Your worst-case scenario shows a distance to endpoint of [X] miles for [chemical]. I need to identify receptors within that radius of your facility."

**Public Receptors:**
Ask: "Within [X] miles of your facility, are there any of the following? Answer yes or no for each:"
- Residences or residential neighborhoods
- Schools (K-12, colleges, daycare centers)
- Hospitals or medical facilities
- Commercial or office buildings
- Parks or recreational areas
- Industrial or manufacturing facilities
- Government buildings
- Places of worship
- Shopping centers or retail areas

For each "yes," ask: "Approximately how many or how close?"

**Environmental Receptors:**
Ask: "Within [X] miles of your facility, are there any of the following environmental receptors?"
- Nature preserves or wildlife refuges
- National or state parks
- National or state forests
- Waterways (rivers, streams, lakes, coastal waters)
- Wetlands
- Sensitive environmental areas or endangered species habitat

For each "yes," note the type and approximate distance.

**Population Estimate:**
Ask: "Approximately how many people live or work within [X] miles of your facility? If you're unsure, you can estimate from Census data — I can help you look this up, or you can provide a rough estimate. Common approaches:"
- Use Census Bureau data (American FactFinder or data.census.gov) for block-level population
- Use a rough density estimate: urban = ~5,000/sq mi, suburban = ~1,500/sq mi, rural = ~50/sq mi
- Area of circle = pi x r^2 where r = distance to endpoint in miles

If the user provides a location type (urban/suburban/rural), help estimate:
```
Population estimate = population_density x pi x (distance_miles)^2
```

After collecting, summarize all receptors in a table format.

---

### Topic 7: Emergency Response Exercises

Ask: "Under RMP, Program 3 facilities must conduct emergency response exercises. I need to document your exercise history."

**Notification Exercise (required annually):**
Ask: "When was your last notification exercise? This tests the system for notifying emergency responders and the public. It can be as simple as a test call to your local fire department and LEPC."
- If never conducted: note as `NOT YET CONDUCTED — required annually per 68.96(a)`

**Tabletop Exercise (required annually):**
Ask: "When was your last tabletop exercise? This is a discussion-based exercise where your team walks through an accidental release scenario and discusses response actions."
- If never conducted: note as `NOT YET CONDUCTED — required annually per 68.96(a)`

**Field Exercise (required every 10 years or per LEPC schedule):**
Ask: "When was your last field exercise? This is a hands-on drill simulating an actual emergency response, ideally coordinated with local responders."
- If never conducted: note as `NOT YET CONDUCTED — required at least every 10 years per 68.96(b), or per LEPC schedule if more frequent`

**Local Coordination:**
Ask: "Have you coordinated your emergency response plan with your local fire department and Local Emergency Planning Committee (LEPC)?"
- If yes: "When was the most recent coordination meeting or plan submission?"
- If no: note as `REQUIRES COMPLETION — coordination with local fire department and LEPC is required per 68.93`

After collecting, summarize:
```
EMERGENCY RESPONSE EXERCISES
=============================
Notification:  [date or NOT YET CONDUCTED]
Tabletop:      [date or NOT YET CONDUCTED]
Field:         [date or NOT YET CONDUCTED]
LEPC Coord:    [Yes — date / No — REQUIRES COMPLETION]
Fire Dept Coord: [Yes — date / No — REQUIRES COMPLETION]
```

---

### Topic 8: Confirmation

Present a complete summary of ALL collected RMP data:

```
RMP DATA PACKAGE — INTAKE SUMMARY
===================================
Company:           [name]
Document Prefix:   [PREFIX]
Facility:          [address/location]
Coordinates:       [lat], [long]
DUNS:              [number]
Parent DUNS:       [number or N/A]
EPA Facility ID:   [number or FIRST-TIME SUBMITTER]
NAICS:             [code] — [description]
Employees (FTE):   [N]

24-Hour Emergency Contact:
  Name:  [name]
  Title: [title]
  Phone: [number]
  Email: [email]

Last Government Inspection: [date/agency or None]

5-Year Accident History:    [N incidents or "None — no reportable releases"]

Worst-Case OCA Distance:    [X] miles ([chemical])
Population within distance: ~[N]
Public receptors:           [summary]
Environmental receptors:    [summary]

Emergency Response Exercises:
  Notification: [date/status]
  Tabletop:     [date/status]
  Field:        [date/status]
  LEPC Coord:   [status]

Covered Processes: [N]
  [list with chemicals and max quantities]

Prevention Program Status: [reference to existing PSM documents]
```

Ask: "Does everything look correct? I'll generate your complete RMP data package from this data."

Only proceed to document generation after the user confirms.

---

## STEP 2: DIRECTORY STRUCTURE

Create the RMP directory:

```bash
mkdir -p PSM_PROGRAM/95_RMP
```

Confirm to the user: "RMP directory created. Now generating 9 documents..."

---

## STEP 3: DOCUMENT GENERATION

Generate ALL 9 documents in `PSM_PROGRAM/95_RMP/`. Use the document prefix from state (e.g., `TE` for Tobe Energy, `ACM` for Acme Chemical). Every document gets the standard controlled header block.

**Controlled Header Block (use on every document):**

```markdown
# [DOCUMENT TITLE]

| Field | Value |
|---|---|
| **Company** | [Company Name] |
| **Document Number** | [PREFIX]-RMP-NNN |
| **Revision** | R0 |
| **Effective Date** | [today's date] |
| **Owner** | [PSM Program Manager from state] |
| **Approver** | [PSM Program Manager from state] |
| **Classification** | CONTROLLED DOCUMENT |

## REVISION HISTORY

| Rev | Date | Description | Author | Reviewer | Approver |
|---|---|---|---|---|---|
| R0 | [today's date] | Initial issue — generated by Process Safety plugin | AI Agent | REQUIRES COMPANY REVIEW | [PSM Program Manager] |
```

---

### Document 1: [PREFIX]-RMP-001_Registration.md

**Regulatory Basis:** 40 CFR 68.160

This document contains all registration data fields required by 68.160 for EPA CDX submission. Structure it as a field-by-field data sheet that maps directly to the CDX electronic submission form.

**Required Fields — Facility Information:**

| CDX Field | Value |
|---|---|
| Facility Name | [from state] |
| Facility Street Address | [from intake] |
| Facility City | [from intake] |
| Facility State | [from state] |
| Facility ZIP Code | [from intake] |
| Facility County | [from intake or `REQUIRES COMPANY INPUT`] |
| Facility DUNS Number | [from intake] |
| Facility Latitude | [from intake] |
| Facility Longitude | [from intake] |
| Parent Company Name | [from intake or state] |
| Parent Company DUNS | [from intake] |

**Required Fields — Owner/Operator:**

| CDX Field | Value |
|---|---|
| Owner/Operator Name | [PSM Program Manager or company owner from state] |
| Owner/Operator Phone | [`REQUIRES COMPANY INPUT`] |
| Owner/Operator Mailing Address | [`REQUIRES COMPANY INPUT` if different from facility] |

**Required Fields — RMP Contact:**

| CDX Field | Value |
|---|---|
| RMP Contact Name | [PSM Program Manager from state] |
| RMP Contact Title | [from state] |

**Required Fields — Emergency Contact (68.160(b)(6)):**

| CDX Field | Value |
|---|---|
| 24-Hour Emergency Contact Name | [from intake Topic 3] |
| 24-Hour Emergency Contact Title | [from intake Topic 3] |
| 24-Hour Emergency Contact Phone | [from intake Topic 3] |
| 24-Hour Emergency Contact Email | [from intake Topic 3] |

**Required Fields — Facility Details:**

| CDX Field | Value |
|---|---|
| Number of Full-Time Employees | [from intake Topic 4] |
| EPA Facility Identifier | [from intake Topic 1] |
| Last Safety Inspection Date | [from intake Topic 1] |
| Last Safety Inspection Agency | [from intake Topic 1] |

**Required Fields — Per-Process Registration:**

For EACH covered process from state, include:

| CDX Field | Value |
|---|---|
| Process Description | [from state] |
| NAICS Code | [from intake Topic 2] |
| Program Level | 3 |
| Subject to 29 CFR 1910.119 (PSM) | Yes |
| Chemical Name | [from state] |
| CAS Number | [from state] |
| Maximum Quantity (lbs) | [from state] |

Repeat the per-process block for each covered process.

**Required Fields — Preparer Information:**

| CDX Field | Value |
|---|---|
| RMP Preparer Name | `REQUIRES COMPANY INPUT` |
| RMP Preparer Title | `REQUIRES COMPANY INPUT` |
| RMP Preparer Phone | `REQUIRES COMPANY INPUT` |
| RMP Preparation Date | [today's date] |

---

### Document 2: [PREFIX]-RMP-002_Executive_Summary.md

**Regulatory Basis:** 40 CFR 68.155

Generate an AI-written narrative executive summary. This must be substantive — 2-3 pages — not a skeleton. The executive summary is the most-read part of an RMP and should communicate clearly to regulators, the public, and local emergency planners.

**Required Content Sections:**

**1. Facility Description:**
- Brief description of the facility and what it does (from state company description)
- Location and physical setting
- Regulated substances handled and their maximum quantities
- Number of covered processes

**2. General Accidental Release Prevention Program:**
- Overview of the PSM/RMP prevention program
- Key prevention elements: process hazard analysis, operating procedures, training, mechanical integrity, management of change, pre-startup safety review, compliance audits, incident investigation
- Safety management philosophy (reference the Master PSM Manual)
- Specific chemical-handling safety measures relevant to the regulated substances

**3. Chemical-Specific Prevention Steps:**
For each regulated substance, describe:
- How the chemical is used in the process
- Key hazards (toxic, flammable, reactive)
- Primary prevention measures (engineering controls, administrative controls, PPE)
- Detection and monitoring systems (if applicable)
- Emergency shutdown provisions

**4. Five-Year Accident History:**
- If no accidents: "There have been no RMP-reportable accidental releases at this facility in the past five years."
- If accidents occurred: brief narrative summary of each incident, consequences, and corrective actions taken. Reference [PREFIX]-RMP-005 for detailed incident data.

**5. Emergency Response Program:**
- Whether the facility responds with its own personnel or relies on external responders
- Coordination with local fire department and LEPC
- Emergency notification procedures
- Exercise program summary
- Reference to the facility's Emergency Response/Action Plan ([PREFIX]-ERP-001)

**6. Planned Changes to Improve Safety:**
- Describe any planned improvements, upgrades, or program enhancements
- Reference open action items from PHA recommendations (if any)
- Reference gap register items that are being addressed
- If no specific changes planned: "The facility will continue to implement and improve its process safety program through the mechanisms described above, including periodic PHA revalidation, compliance audits, and management of change review."

---

### Document 3: [PREFIX]-RMP-003_Worst_Case_Scenarios.md

**Regulatory Basis:** 40 CFR 68.165

Pull ALL worst-case scenario data from the OCA results in the state file. For each covered process, generate a structured worst-case scenario section.

**Per-Process Worst-Case Scenario Format:**

```markdown
## WORST-CASE SCENARIO — [Process Name]: [Chemical Name]

### Scenario Parameters

| Field | Value |
|---|---|
| Chemical Name | [name] |
| CAS Number | [CAS] |
| Physical State | [gas / liquid / liquefied gas (refrigerated)] |
| Basis of Worst Case | [Total release of largest vessel inventory as gas / Liquid pool evaporation / etc.] |
| Model/Method Used | [EPA OCA Guidance simplified method / TNT-equivalent method / BLEVE fireball method] |

### Scenario Description

[Narrative description: "Failure of the largest single vessel containing [chemical], releasing the entire inventory of [X] lbs as [gas/liquid/vapor cloud]. [For liquids: The released liquid forms an undiked/diked pool that evaporates over the release duration.] [For flammables: The vapor cloud finds an ignition source and detonates / The vessel fails catastrophically producing a BLEVE fireball.]"]

### Release Parameters

| Parameter | Value |
|---|---|
| Quantity Released | [X] lbs |
| Release Rate | [X] lbs/min |
| Release Duration | [X] minutes |
| Wind Speed | 1.5 m/s (worst-case default per 68.25) |
| Stability Class | F (worst-case default per 68.25) |
| Temperature | [X] F |
| Humidity | [X]% |
| Topography | [urban / rural] |
| Passive Mitigation Considered | [none / dike description / enclosure description] |

### Distance to Endpoint

| Endpoint | Distance |
|---|---|
| [Toxic: X mg/L / Flammable: 1 psi overpressure / BLEVE: 5 kW/m2 radiant heat] | [X.X] miles ([X] feet) |

### Receptors Within Distance

| Receptor Type | Present? | Details |
|---|---|---|
| Residences | [Y/N] | [description from intake] |
| Schools | [Y/N] | [description] |
| Hospitals | [Y/N] | [description] |
| Commercial/Industrial | [Y/N] | [description] |
| Parks/Recreation | [Y/N] | [description] |
| Environmental Receptors | [Y/N] | [description] |

Estimated population within [X.X] miles: ~[N]
```

**For dual-hazard chemicals:** Include BOTH the toxic worst-case scenario AND the flammable worst-case scenario as separate sections. Clearly label each: "WORST-CASE — TOXIC RELEASE" and "WORST-CASE — FLAMMABLE RELEASE (VCE/BLEVE)."

If the OCA state data is missing expected fields, mark them as `REQUIRES COMPLETION — Run /process-safety:oca to calculate`.

---

### Document 4: [PREFIX]-RMP-004_Alternative_Scenarios.md

**Regulatory Basis:** 40 CFR 68.170

Same structure as worst-case scenarios, with these additional fields:

**Per-Process Alternative Scenario Format:**

```markdown
## ALTERNATIVE SCENARIO — [Process Name]: [Chemical Name]

### Scenario Parameters

| Field | Value |
|---|---|
| Chemical Name | [name] |
| CAS Number | [CAS] |
| Physical State | [state] |
| Scenario Description | [e.g., "2-inch pipe rupture at flange connection", "Transfer hose failure during loading", "Valve packing leak"] |
| Model/Method Used | [EPA OCA Guidance simplified method] |

### Release Parameters

| Parameter | Value |
|---|---|
| Quantity Released | [X] lbs |
| Release Rate | [X] lbs/min |
| Release Duration | [X] minutes |
| Wind Speed | [X] m/s (alternative scenario — user specified or 3.0 m/s default) |
| Stability Class | [D or user specified] |
| Temperature | [X] F |
| Humidity | [X]% |
| Topography | [urban / rural] |
| Passive Mitigation | [description if any] |
| Active Mitigation | [description if any — e.g., "Water spray system reduces release rate by 55%"] |

### Active Mitigation Details

| Mitigation Measure | Type | Reduction | Basis |
|---|---|---|---|
| [e.g., Water spray deluge] | [Release rate reduction] | [55%] | [EPA OCA Guidance Table 4-2] |

### Distance to Endpoint

| Endpoint | Distance |
|---|---|
| [endpoint] | [X.X] miles ([X] feet) |

### Receptors Within Distance

[Same receptor table as worst-case]
```

**If no alternative scenarios exist in OCA state data:**
Generate the document with a prominent notice:

```markdown
## STATUS: REQUIRES COMPLETION

Alternative release scenarios have not yet been calculated. Per 40 CFR 68.28, at least one
alternative release scenario is required for each regulated toxic substance and each regulated
flammable substance.

**Action Required:** Run `/process-safety:oca` with alternative scenario type to complete this section.

### Suggested Alternative Scenarios

Based on your covered processes, consider the following alternative scenarios:

| Process | Chemical | Suggested Scenario | Rationale |
|---|---|---|---|
| [process from state] | [chemical] | Transfer hose failure | Common release scenario for loading/unloading |
| [process from state] | [chemical] | 2-inch pipe rupture at flange | Typical piping failure scenario |
| [process from state] | [chemical] | Valve packing leak | Common equipment failure mode |
```

---

### Document 5: [PREFIX]-RMP-005_Accident_History.md

**Regulatory Basis:** 40 CFR 68.42

**If no accidents reported in intake (Topic 5):**

Generate a formal statement:

```markdown
## 5-YEAR ACCIDENT HISTORY

### Statement

This facility has had **no RMP-reportable accidental releases** in the five-year period
preceding this RMP submission.

Per 40 CFR 68.42, reportable accidents include releases of regulated substances that resulted in:
- Deaths, injuries, or significant property damage on-site
- Known off-site deaths, injuries, evacuations, sheltering in place, property damage, or
  environmental damage

**Period Covered:** [date 5 years ago] through [today's date]
**Regulated Substances:** [list chemicals from state]
**Covered Processes:** [list processes from state]
```

**If accidents were reported:**

For each incident, generate a structured record:

```markdown
## INCIDENT [N]: [Brief Description]

### Incident Summary

| Field | Value |
|---|---|
| Date of Release | [date] |
| Time of Release | [time] |
| Release Duration | [duration] |
| Chemical(s) Released | [chemical name(s)] |
| CAS Number(s) | [CAS] |
| Estimated Quantity Released (lbs) | [quantity] |
| Release Event Type | [Gas release / Liquid spill / Fire / Explosion] |
| Release Source | [Vessel / Pipe / Valve / Transfer hose / Pump seal / Gasket / etc.] |

### Weather Conditions at Time of Release

| Condition | Value |
|---|---|
| Wind Speed | [value or "Unknown"] |
| Wind Direction | [value or "Unknown"] |
| Temperature | [value or "Unknown"] |
| Atmospheric Stability | [value or "Unknown"] |

### Consequences

**On-Site Impacts:**
| Impact Type | Details |
|---|---|
| Injuries | [number and description, or "None"] |
| Deaths | [number, or "None"] |
| Property Damage | [description and estimated cost, or "None"] |

**Off-Site Impacts:**
| Impact Type | Details |
|---|---|
| Evacuations | [number evacuated and duration, or "None"] |
| Sheltering in Place | [number and duration, or "None"] |
| Injuries | [number and description, or "None"] |
| Deaths | [number, or "None"] |
| Property Damage | [description, or "None"] |
| Environmental Damage | [description, or "None"] |

### Causes and Contributing Factors

| Category | Description |
|---|---|
| Initiating Event | [description] |
| Contributing Factors | [description] |

### Response

| Response Item | Details |
|---|---|
| Off-Site Responders Notified | [Yes/No — which agencies] |
| Emergency Response Actions | [description] |

### Corrective Actions

| Action | Description | Status |
|---|---|---|
| [Operational/process changes made as a result] | [description] | [Completed / In Progress] |
```

---

### Document 6: [PREFIX]-RMP-006_Prevention_Program.md

**Regulatory Basis:** 40 CFR 68.65-68.89

This document cross-references the existing PSM element procedures to the RMP prevention program requirements. It does NOT duplicate the PSM procedures — it maps them.

**Prevention Program Cross-Reference:**

Read the state file to determine the document prefix and check which PSM documents exist in the PSM_PROGRAM directory.

Generate the following cross-reference table:

```markdown
## RMP PREVENTION PROGRAM — PSM CROSS-REFERENCE

The RMP Program 3 prevention program requirements (40 CFR 68.65-68.87) are substantively
identical to the OSHA PSM requirements (29 CFR 1910.119). This facility's prevention program
is implemented through the PSM element procedures listed below.

| RMP Section | Requirement | CFR Reference | PSM Document | Document Title | Status |
|---|---|---|---|---|---|
| Process Safety Information | PSI compilation and maintenance | 68.65 | [PREFIX]-PSI-001 | Process Safety Information | [status] |
| Process Hazard Analysis | PHA methodology, team, documentation, resolution, revalidation | 68.67 | [PREFIX]-PHA-001 | Process Hazard Analysis | [status] |
| Operating Procedures | Written procedures for covered processes | 68.69 | [PREFIX]-OP-001 | Operating Procedures | [status] |
| Training | Initial and refresher training | 68.71 | [PREFIX]-TRN-001 | Training | [status] |
| Mechanical Integrity | Equipment inspection and maintenance | 68.73 | [PREFIX]-MI-001 | Mechanical Integrity | [status] |
| Management of Change | MOC process for changes to covered processes | 68.75 | [PREFIX]-MOC-001 | Management of Change | [status] |
| Pre-Startup Safety Review | PSSR before introducing HHCs | 68.77 | [PREFIX]-PSSR-001 | Pre-Startup Safety Review | [status] |
| Compliance Audits | 3-year audit cycle | 68.79 | [PREFIX]-CA-001 | Compliance Audits | [status] |
| Incident Investigation | Investigation of releases and near-misses | 68.81 | [PREFIX]-II-001 | Incident Investigation | [status] |
| Employee Participation | Written plan for employee participation | 68.83 | [PREFIX]-EP-001 | Employee Participation | [status] |
| Hot Work Permits | Hot work permit program | 68.85 | [PREFIX]-HW-001 | Hot Work Permit | [status] |
| Contractors | Contractor safety management | 68.87 | [PREFIX]-CON-001 | Contractors | [status] |
```

Determine status for each row:
- Check if the PSM document file exists in the PSM_PROGRAM directory
- If it exists: check the compliance crosswalk status from state or the crosswalk document
- Use these status codes: `COMPLETE` (procedure exists, evidence path defined), `PARTIAL` (procedure exists, evidence incomplete), `GAP` (procedure missing or significantly incomplete), `NEEDS COMPANY INPUT`

**Additional Section — General Provisions (68.89):**

```markdown
## GENERAL PROVISIONS (68.89)

| Requirement | Implementation | Status |
|---|---|---|
| Management system for prevention program | Master PSM Manual ([PREFIX]-PSM-001) defines governance, roles, and review cadence | [status] |
| Designation of responsible person(s) | Role assignments documented in Master PSM Manual, Section [X] | [status] |
```

---

### Document 7: [PREFIX]-RMP-007_Emergency_Response.md

**Regulatory Basis:** 40 CFR 68.90-68.95, 68.96

**Section 1: Emergency Response Program Overview**

Reference the existing Emergency Response procedure from PSM Element 12:
- Document reference: [PREFIX]-ERP-001
- Response type: [Own responders / External responders only] (from state)

**Section 2: Emergency Response Plan Reference**

```markdown
## EMERGENCY RESPONSE PLAN

The facility's emergency response plan is documented in [PREFIX]-ERP-001_Emergency_Planning_Response.md,
located in PSM_PROGRAM/12_EMERGENCY_RESPONSE/.

The plan addresses:
- Emergency recognition and initial response actions
- Evacuation procedures and assembly points
- Emergency notification procedures (internal and external)
- Chemical-specific response data for regulated substances
- Communication procedures during emergencies
- Medical treatment and first aid provisions
- [If own responders: Response team organization, PPE, decontamination, training per 1910.120(q)]
- [If external only: Coordination with external responders, employee roles limited to evacuation and notification]
```

**Section 3: Exercise Program (per 68.96)**

```markdown
## EMERGENCY RESPONSE EXERCISE PROGRAM

Per 40 CFR 68.96, the facility maintains the following exercise program:

### Notification Exercises (Required Annually)

| Exercise Date | Description | Participants | Findings | Next Due |
|---|---|---|---|---|
| [date from intake or NOT YET CONDUCTED] | [description] | [participants] | [findings or N/A] | [date + 1 year] |

### Tabletop Exercises (Required Annually)

| Exercise Date | Scenario | Participants | Lessons Learned | Next Due |
|---|---|---|---|---|
| [date from intake or NOT YET CONDUCTED] | [scenario description] | [participants] | [lessons or N/A] | [date + 1 year] |

### Field Exercises (Required Every 10 Years or Per LEPC Schedule)

| Exercise Date | Scenario | Participating Agencies | Findings | Next Due |
|---|---|---|---|---|
| [date from intake or NOT YET CONDUCTED] | [scenario description] | [agencies] | [findings or N/A] | [date + 10 years or per LEPC] |
```

If exercises have not been conducted, include a note:

```markdown
> **ACTION REQUIRED:** The following exercises have not yet been conducted and are required
> before or shortly after RMP submission:
> - [ ] Notification exercise (required annually per 68.96(a))
> - [ ] Tabletop exercise (required annually per 68.96(a))
> - [ ] Field exercise (required at least every 10 years per 68.96(b))
```

**Section 4: Coordination with Local Agencies (per 68.93)**

```markdown
## LOCAL AGENCY COORDINATION

| Agency | Contact Status | Last Coordination Date | Details |
|---|---|---|---|
| Local Fire Department | [Coordinated / NOT YET COORDINATED] | [date] | [details] |
| Local Emergency Planning Committee (LEPC) | [Coordinated / NOT YET COORDINATED] | [date] | [details] |
| State Emergency Response Commission (SERC) | [Coordinated / NOT YET COORDINATED] | [date or REQUIRES COMPANY INPUT] | [details] |
| Local Law Enforcement | [Coordinated / NOT YET COORDINATED] | [date or REQUIRES COMPANY INPUT] | [details] |
| Nearest Hospital / Medical Facility | [Coordinated / NOT YET COORDINATED] | [date or REQUIRES COMPANY INPUT] | [details] |
```

**Section 5: Notification Procedures for Accidental Releases**

```markdown
## NOTIFICATION PROCEDURES

In the event of an accidental release of a regulated substance:

### Immediate Notifications (within minutes)

| Contact | Phone | When |
|---|---|---|
| 911 / Local Fire Department | [number or REQUIRES COMPANY INPUT] | Any release with potential off-site impact |
| National Response Center (NRC) | 1-800-424-8802 | Any release exceeding RQ per 40 CFR 302 |
| State/Local Emergency Agencies | [number or REQUIRES COMPANY INPUT] | Per state EPCRA requirements |

### Follow-Up Notifications (within 24 hours)

| Contact | Method | When |
|---|---|---|
| EPA Regional Office | Phone/written | Releases exceeding RQ |
| State Environmental Agency | Per state requirements | Per state requirements |
| LEPC | Written | Per EPCRA Section 304 |

### Internal Notifications

| Contact | Method | When |
|---|---|---|
| PSM Program Manager | Phone/text | Any release from covered process |
| 24-Hour Emergency Contact | Phone | Any off-hours release |
| All affected employees | Alarm system / PA | Any release requiring evacuation or shelter |
```

**Section 6: Employee Emergency Response Training**

```markdown
## EMPLOYEE EMERGENCY RESPONSE TRAINING

| Training Topic | Frequency | Applicable Personnel | Record Location |
|---|---|---|---|
| Emergency action plan awareness | Initial hire + annual refresher | All employees | [PREFIX]-FRM-005 |
| Chemical hazard recognition | Initial + 3-year refresher | All covered process employees | [PREFIX]-FRM-005 |
| Evacuation procedures | Initial + annual drill | All employees | [PREFIX]-FRM-012 |
| Emergency notification procedures | Initial + annual | All employees | [PREFIX]-FRM-005 |
| [If own responders] HAZWOPER | Initial 40-hr + 8-hr annual | Emergency response team | [PREFIX]-FRM-005 |
| [If own responders] Chemical-specific response | Initial + annual | Emergency response team | [PREFIX]-FRM-005 |
```

---

### Document 8: [PREFIX]-RMP-008_Certification.md

**Regulatory Basis:** 40 CFR 68.185

This document contains the legally required certification statement. It must include the prescribed EPA language verbatim.

```markdown
## RMP CERTIFICATION STATEMENT

Per 40 CFR 68.185, the following certification is made:

---

**"Based on the criteria in 40 CFR 68.10, the distance to the specified endpoint for the
worst-case accidental release scenario for the following process(es) is noted below. I
certify under penalty of law that the owner or operator has complied with the requirements
of 40 CFR Part 68."**

---

### Per-Process Certification

| Process | Regulated Substance | Worst-Case Distance to Endpoint | Alternative Scenario Distance to Endpoint | Prevention Program Elements Implemented |
|---|---|---|---|---|
| [process name from state] | [chemical] | [X.X miles] | [X.X miles or REQUIRES COMPLETION] | Yes — see [PREFIX]-RMP-006 |
```

Repeat for each covered process.

```markdown
### Certification Signature

| Field | Value |
|---|---|
| Certifying Official Name | __________________________________________ |
| Title | __________________________________________ |
| Signature | __________________________________________ |
| Date | __________________________________________ |

> **NOTE:** This certification must be signed by the owner, operator, or senior official with
> management responsibility for the covered process(es). The signature carries legal weight
> under federal law (18 U.S.C. 1001). Ensure the certifying official has reviewed the RMP
> data package and is satisfied that the statements are accurate and complete.
```

---

### Document 9: [PREFIX]-RMP-009_Submission_Checklist.md

**Regulatory Basis:** All applicable subparts of 40 CFR Part 68

Generate a pre-filled version of EPA's Program Level 3 Process Checklist. For each item, determine the answer based on the existing PSM program and RMP package:

- **Y** — The PSM program or RMP package addresses this item
- **N** — This is identified as a gap
- **N/A** — Not applicable to this facility (with rationale)
- **REQUIRES COMPANY INPUT** — Cannot be auto-determined from available data

**Checklist Structure:**

```markdown
## EPA PROGRAM LEVEL 3 PROCESS CHECKLIST

Instructions: This checklist is pre-populated based on your generated PSM program and RMP
data package. Review each item. Items marked Y have been addressed in the referenced document.
Items marked REQUIRES COMPANY INPUT need your verification. Items marked N are known gaps
that should be addressed before or shortly after submission.

---

### SUBPART A — GENERAL PROVISIONS

| # | Requirement | CFR | Answer | Reference | Notes |
|---|---|---|---|---|---|
| A.1 | Has the owner/operator determined the applicability of Part 68? | 68.10 | Y | Screening results; [PREFIX]-PSM-001 | |
| A.2 | Has a worst-case release analysis been completed for each covered process? | 68.10(b) | [Y if OCA exists / N if not] | [PREFIX]-RMP-003 | |
| A.3 | Has the owner/operator determined the Program level for each covered process? | 68.10 | Y | Program Level 3 | |
| A.4 | Has the owner/operator submitted an RMP? | 68.12 | N | This package prepares for submission | |
| A.5 | Has the RMP been updated within 5 years? | 68.12(b) | [Y if re-submission / N/A if first submission] | | |
| A.6 | Does the RMP include the required registration data? | 68.12(b)(1) | Y | [PREFIX]-RMP-001 | |

### SUBPART B — HAZARD ASSESSMENT

| # | Requirement | CFR | Answer | Reference | Notes |
|---|---|---|---|---|---|
| B.1 | Has the owner/operator performed an OCA for worst-case release scenario(s)? | 68.20 | [Y/N] | [PREFIX]-RMP-003 | |
| B.2 | Does the worst-case analysis use the parameters specified in 68.22? | 68.22 | [Y/N] | [PREFIX]-RMP-003 | |
| B.3 | Has the owner/operator determined worst-case release quantity? | 68.25(a) | [Y/N] | OCA results | |
| B.4 | Was wind speed of 1.5 m/s and F stability used for worst-case? | 68.25(c) | [Y/N] | OCA parameters | |
| B.5 | Has the owner/operator considered the effect of passive mitigation? | 68.25(h) | [Y/N] | OCA results | |
| B.6 | Has the owner/operator performed an OCA for alternative release scenario(s)? | 68.28 | [Y if alt scenarios exist / N] | [PREFIX]-RMP-004 | |
| B.7 | Has the owner/operator defined the distance to the endpoint for each scenario? | 68.20(b) | [Y/N] | [PREFIX]-RMP-003, -004 | |
| B.8 | Has the owner/operator estimated the residential population within the distance to endpoint? | 68.30 | [Y if collected / REQUIRES COMPANY INPUT] | [PREFIX]-RMP-003 | |
| B.9 | Has the owner/operator identified public receptors within the distance to endpoint? | 68.30 | [Y/REQUIRES COMPANY INPUT] | [PREFIX]-RMP-003 | |
| B.10 | Has the owner/operator identified environmental receptors within the distance to endpoint? | 68.33 | [Y/REQUIRES COMPANY INPUT] | [PREFIX]-RMP-003 | |
| B.11 | Has the owner/operator documented the 5-year accident history? | 68.42 | Y | [PREFIX]-RMP-005 | |
| B.12 | Does the accident history include all required data elements per 68.42(b)? | 68.42(b) | [Y if accidents reported with full data / N/A if no accidents] | [PREFIX]-RMP-005 | |

### SUBPART D — PROGRAM 3 PREVENTION PROGRAM

| # | Requirement | CFR | Answer | Reference | Notes |
|---|---|---|---|---|---|
| D.1 | Has PSI been compiled for each covered process? | 68.65 | [status from crosswalk] | [PREFIX]-PSI-001 | |
| D.2 | Does PSI include chemical hazard information per 68.65(a)? | 68.65(a) | [status] | [PREFIX]-PSI-001 | |
| D.3 | Does PSI include process technology information per 68.65(b)? | 68.65(b) | [status] | [PREFIX]-PSI-001 | |
| D.4 | Does PSI include equipment information per 68.65(c)? | 68.65(c) | [status] | [PREFIX]-PSI-001 | |
| D.5 | Has a PHA been performed for each covered process? | 68.67(a) | [status] | [PREFIX]-PHA-001 | |
| D.6 | Does the PHA address hazards, previous incidents, controls, and consequences? | 68.67(c) | [status] | [PREFIX]-PHA-001 | |
| D.7 | Does the PHA address facility siting and human factors? | 68.67(c)(5)-(6) | [status] | [PREFIX]-PHA-001 | |
| D.8 | Is the PHA updated/revalidated at least every 5 years? | 68.67(f) | [status] | [PREFIX]-REG-004 | |
| D.9 | Are PHA findings and recommendations resolved and documented? | 68.67(e) | [status] | [PREFIX]-FRM-008 | |
| D.10 | Have written operating procedures been developed? | 68.69(a) | [status] | [PREFIX]-OP-001 | |
| D.11 | Do procedures address steps for each operating phase? | 68.69(a)(1) | [status] | [PREFIX]-OP-001 | |
| D.12 | Do procedures address operating limits and consequences of deviation? | 68.69(a)(2) | [status] | [PREFIX]-OP-001 | |
| D.13 | Do procedures address safety and health considerations? | 68.69(a)(3) | [status] | [PREFIX]-OP-001 | |
| D.14 | Are operating procedures certified as current and accurate annually? | 68.69(c) | [status] | [PREFIX]-FRM-011 | |
| D.15 | Has initial training been provided for each covered process employee? | 68.71(a) | [status] | [PREFIX]-TRN-001 | |
| D.16 | Is refresher training provided at least every 3 years? | 68.71(b) | [status] | [PREFIX]-TRN-001 | |
| D.17 | Are individual training records maintained? | 68.71(d) | [status] | [PREFIX]-FRM-005 | |
| D.18 | Are written MI procedures in place for covered equipment? | 68.73(b) | [status] | [PREFIX]-MI-001 | |
| D.19 | Is inspection/testing performed per RAGAGEP? | 68.73(d) | [status] | [PREFIX]-MI-001 | |
| D.20 | Are equipment deficiencies corrected before further use or in a safe manner? | 68.73(e) | [status] | [PREFIX]-MI-001, [PREFIX]-FRM-009 | |
| D.21 | Is there a quality assurance program for new equipment? | 68.73(f) | [status] | [PREFIX]-MI-001 | |
| D.22 | Are MOC procedures in place for changes to chemicals, technology, equipment, and procedures? | 68.75(a) | [status] | [PREFIX]-MOC-001 | |
| D.23 | Does MOC address technical basis, safety impact, procedure modifications, time period, and authorization? | 68.75(c) | [status] | [PREFIX]-MOC-001, [PREFIX]-FRM-001 | |
| D.24 | Are employees informed/trained on changes before startup? | 68.75(d) | [status] | [PREFIX]-MOC-001 | |
| D.25 | Are operating procedures and PSI updated for changes? | 68.75(e) | [status] | [PREFIX]-MOC-001 | |
| D.26 | Is a PSSR performed for new or modified facilities? | 68.77(a) | [status] | [PREFIX]-PSSR-001 | |
| D.27 | Does PSSR verify construction, procedures, PHA resolution, training, and MOC? | 68.77(b) | [status] | [PREFIX]-FRM-002 | |
| D.28 | Are compliance audits performed at least every 3 years? | 68.79(a) | [status] | [PREFIX]-CA-001 | |
| D.29 | Is the audit conducted by at least one person knowledgeable in the process? | 68.79(b) | [status] | [PREFIX]-CA-001 | |
| D.30 | Are audit findings documented and corrected? | 68.79(c)-(d) | [status] | [PREFIX]-FRM-013, [PREFIX]-FRM-008 | |
| D.31 | Is each incident resulting in or potentially resulting in a catastrophic release investigated? | 68.81(a) | [status] | [PREFIX]-II-001 | |
| D.32 | Is investigation initiated within 48 hours? | 68.81(b) | [status] | [PREFIX]-II-001 | |
| D.33 | Does the investigation report include date, description, causes, and recommendations? | 68.81(d) | [status] | [PREFIX]-FRM-004 | |
| D.34 | Are investigation findings resolved and documented? | 68.81(e) | [status] | [PREFIX]-FRM-008 | |
| D.35 | Is there a written plan for employee participation? | 68.83(a) | [status] | [PREFIX]-EP-001 | |
| D.36 | Do employees have access to PHAs, PSI, procedures, and investigation reports? | 68.83(b) | [status] | [PREFIX]-EP-001 | |
| D.37 | Are hot work permits issued for operations on or near covered processes? | 68.85 | [status] | [PREFIX]-HW-001, [PREFIX]-FRM-003 | |
| D.38 | Has the employer evaluated contractor safety performance? | 68.87(b)(1) | [status] | [PREFIX]-CON-001 | |
| D.39 | Has the employer informed contractors of known hazards? | 68.87(b)(2) | [status] | [PREFIX]-CON-001 | |
| D.40 | Does the employer maintain a contractor injury/illness log? | 68.87(b)(5) | [status] | [PREFIX]-CON-001, [PREFIX]-REG-006 | |

### SUBPART E — EMERGENCY RESPONSE

| # | Requirement | CFR | Answer | Reference | Notes |
|---|---|---|---|---|---|
| E.1 | Does the facility have an emergency response program? | 68.90 | Y | [PREFIX]-ERP-001, [PREFIX]-RMP-007 | |
| E.2 | Does the emergency response plan include procedures for informing the public and local agencies? | 68.93(a) | [status] | [PREFIX]-RMP-007 | |
| E.3 | Is the emergency response plan coordinated with local agencies? | 68.93(b) | [status from intake Topic 7] | [PREFIX]-RMP-007 | |
| E.4 | Has the facility conducted a notification exercise within the past year? | 68.96(a) | [status from intake Topic 7] | [PREFIX]-RMP-007 | |
| E.5 | Has the facility conducted a tabletop exercise within the past year? | 68.96(a) | [status from intake Topic 7] | [PREFIX]-RMP-007 | |
| E.6 | Has the facility conducted a field exercise within the required timeframe? | 68.96(b) | [status from intake Topic 7] | [PREFIX]-RMP-007 | |

### SUBPART G — RISK MANAGEMENT PLAN

| # | Requirement | CFR | Answer | Reference | Notes |
|---|---|---|---|---|---|
| G.1 | Does the RMP include registration data per 68.160? | 68.160 | Y | [PREFIX]-RMP-001 | |
| G.2 | Does the RMP include an executive summary per 68.155? | 68.155 | Y | [PREFIX]-RMP-002 | |
| G.3 | Does the RMP include worst-case release analysis data per 68.165? | 68.165 | [Y/N] | [PREFIX]-RMP-003 | |
| G.4 | Does the RMP include alternative release scenario data per 68.170? | 68.170 | [Y/N] | [PREFIX]-RMP-004 | |
| G.5 | Does the RMP include 5-year accident history per 68.42/68.168? | 68.168 | Y | [PREFIX]-RMP-005 | |
| G.6 | Does the RMP include prevention program data per 68.170? | 68.170 | Y | [PREFIX]-RMP-006 | |
| G.7 | Does the RMP include emergency response data per 68.180? | 68.180 | Y | [PREFIX]-RMP-007 | |
| G.8 | Does the RMP include the certification per 68.185? | 68.185 | Y | [PREFIX]-RMP-008 | |
| G.9 | Has the RMP been certified by the owner/operator? | 68.185 | REQUIRES COMPANY INPUT | [PREFIX]-RMP-008 | Signature required |
| G.10 | Is the RMP submitted to EPA within required timeframe? | 68.150 | N | Submission pending | |

---

### CHECKLIST SUMMARY

| Category | Total Items | Y | N | N/A | REQUIRES COMPANY INPUT |
|---|---|---|---|---|---|
| Subpart A — General | [count] | [count] | [count] | [count] | [count] |
| Subpart B — Hazard Assessment | [count] | [count] | [count] | [count] | [count] |
| Subpart D — Prevention Program | [count] | [count] | [count] | [count] | [count] |
| Subpart E — Emergency Response | [count] | [count] | [count] | [count] | [count] |
| Subpart G — Risk Management Plan | [count] | [count] | [count] | [count] | [count] |
| **TOTAL** | **[count]** | **[count]** | **[count]** | **[count]** | **[count]** |
```

Count all items and fill in the summary table. The actual counts will vary based on the state of the PSM program and RMP data.

---

## STEP 4: STATE UPDATE

After all 9 documents are generated, update the state file using the state manager script:

```bash
echo '{
  "rmp": {
    "completed": true,
    "date": "[today'\''s date, YYYY-MM-DD format]",
    "document_count": 9,
    "submission_ready": [true if no N answers and no critical REQUIRES COMPANY INPUT items in checklist, false otherwise]
  }
}' | bash process-safety/scripts/state-manager.sh update
```

Set `submission_ready` to `true` only if:
- All 9 documents are generated
- The submission checklist has no items marked `N` (all gaps resolved)
- Alternative scenarios have been completed
- The certification document is ready for signature

Otherwise set `submission_ready` to `false` and note what remains.

---

## STEP 5: COMPLETION REPORT

Present the following summary to the user:

```
RMP DATA PACKAGE GENERATION COMPLETE
======================================
Company:           [name]
Document Prefix:   [PREFIX]
Documents Created: 9
  - [PREFIX]-RMP-001  Registration Data
  - [PREFIX]-RMP-002  Executive Summary
  - [PREFIX]-RMP-003  Worst-Case Scenarios
  - [PREFIX]-RMP-004  Alternative Scenarios
  - [PREFIX]-RMP-005  Accident History
  - [PREFIX]-RMP-006  Prevention Program Cross-Reference
  - [PREFIX]-RMP-007  Emergency Response Program
  - [PREFIX]-RMP-008  Certification Statement
  - [PREFIX]-RMP-009  Submission Checklist

Location: PSM_PROGRAM/95_RMP/

Submission Checklist Summary:
  Total items:              [N]
  Addressed (Y):            [N]
  Gaps (N):                 [N]
  Not Applicable (N/A):     [N]
  Require Company Input:    [N]

Submission Ready: [YES / NO — [reason if no]]

NEXT STEPS:
1. Review all 9 documents in PSM_PROGRAM/95_RMP/
2. Complete any items marked REQUIRES COMPANY INPUT
3. [If alternative scenarios missing] Run /process-safety:oca with alternative scenarios
4. Have the certifying official review and sign [PREFIX]-RMP-008
5. Use the Submission Checklist ([PREFIX]-RMP-009) as your field-by-field guide when
   entering data into EPA's CDX system at https://cdx.epa.gov/
6. Submit electronically through EPA's RMP*eSubmit portal

When ready to submit to EPA CDX, the Submission Checklist maps each item
to the corresponding CDX field for direct transcription.
```

---

## CRITICAL RULES — READ THESE

1. **Generate ALL 9 documents.** Do not skip any document. Do not ask "should I continue?" partway through. Generate the complete set.

2. **Use company-specific data everywhere.** Every document must use the company name, prefix, roles, chemicals, and processes from state and intake. No generic placeholders where real data was provided.

3. **No hallucinated facility facts.** If the user didn't provide something and it's not in the state file, mark it `REQUIRES COMPANY INPUT`. Do not invent coordinates, DUNS numbers, inspector names, or receptor details.

4. **Pull OCA data from state.** The worst-case and alternative scenario parameters and results come from the OCA calculations stored in the state file. Reference them accurately — do not recalculate or modify OCA results.

5. **Cross-reference PSM documents, don't duplicate.** The prevention program document (RMP-006) references existing PSM element procedures by document number. It does not copy their content.

6. **The certification language is prescribed.** Use the exact language from 40 CFR 68.185. Do not paraphrase or soften the certification statement.

7. **The checklist must be honest.** Pre-fill Y only for items that are genuinely addressed. Mark N for real gaps. Mark REQUIRES COMPANY INPUT for items that depend on implementation evidence the plugin cannot verify. Do not inflate readiness.

8. **Receptor data depends on user input.** Population estimates, public receptors, and environmental receptors come from the intake questionnaire. If the user could not provide them, mark as `REQUIRES COMPANY INPUT` — do not fabricate receptor data.

9. **Alternative scenarios may not exist yet.** If the user only ran worst-case OCA, the alternative scenario document should clearly state what's missing and guide the user to complete it via `/process-safety:oca`.

10. **This is a data package, not a submission.** The plugin generates the documents that the user transcribes into EPA's CDX electronic submission system. It does not submit to EPA directly. Make this clear in the completion report.
