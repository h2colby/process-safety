---
name: implement
description: Get guided, step-by-step implementation coaching for your PSM program
---

# Process Safety Implementation Guide

This command provides interactive, dependency-aware implementation guidance. It identifies the highest-priority incomplete task and walks the user through completing it step by step.

## Dependency Graph

Enforce this dependency graph strictly. Never suggest work on a downstream element when its upstream dependency is incomplete.

```
Covered Process Identification
  └─► Process Safety Information (PSI)
        └─► Process Hazard Analysis (PHA)
              ├─► Operating Procedures
              │     └─► Training (on procedures)
              ├─► Mechanical Integrity (informed by PHA safeguards)
              └─► Pre-Startup Safety Review (verifies PHA complete)

Management of Change ──► triggers PSI update, procedure update, training, PSSR

Employee Participation ─── parallel (cross-cutting)
Contractors ─── parallel (after operating procedures exist)
Hot Work Permit ─── parallel (after operating procedures exist)
Incident Investigation ─── parallel (program framework)
Emergency Planning ─── parallel (can develop alongside)
Compliance Audits ─── last (audits the implemented program)
Trade Secrets ─── parallel (policy element)
```

## Sequencing Rules

NEVER violate these rules:

1. **Never suggest PHA work if PSI is incomplete for that covered process.** PSI is the foundation the PHA team needs to identify hazards. Without complete PSI, a PHA is building on sand.
2. **Never suggest operating procedure development if PHA is incomplete.** Procedures must reflect the hazards and safeguards identified in the PHA.
3. **Never suggest process-specific training if procedures do not exist yet.** You cannot train operators on procedures that have not been written.
4. **Compliance audit scheduling only after all other elements are at least PARTIAL.** You cannot audit a program that does not exist yet.

## Step 1: Determine Current State

- Read `.claude/process-safety.local.json` from the project root.
- If no state file exists, tell the user:
  > No PSM project found. Run `/process-safety:generate` first to create your program documents.
  Then stop.
- If the state file exists but generation is not marked complete, tell the user:
  > Program documents haven't been generated yet. Run `/process-safety:generate` first.
  Then stop.
- Read `PSM_PROGRAM/00_MASTER/TOB-PSM-002_Compliance_Crosswalk.md` to understand current clause statuses.
- Read `PSM_PROGRAM/00_MASTER/TOB-PSM-004_Gap_Register.md` to understand open gaps.
- Identify which covered processes exist and their PSI completion status.

## Step 2: Identify Next Priority

Apply the dependency graph to find the highest-priority incomplete item. Walk the chain from top to bottom and stop at the first incomplete dependency:

1. **If PSI is incomplete for any covered process** → PSI compilation is the priority. Identify which specific process and which PSI categories (chemical hazards, technology, equipment) are incomplete.
2. **If PSI is complete but PHA has not been scheduled or started** → PHA planning is the priority.
3. **If PHA is complete but operating procedures are missing or incomplete** → Procedure development is the priority.
4. **If procedures exist but training is not documented** → Training program is the priority.
5. **If all main-chain items are at least PARTIAL** → Look at parallel items (employee participation, contractors, hot work, incident investigation, emergency planning, MOC, trade secrets) and suggest the one with the most gaps.
6. **If all elements are at least PARTIAL** → Compliance audit preparation is the priority.

Additionally, always mention parallel items that can be worked on alongside the main chain priority. Frame these as: "While [main priority] is the critical path, you can also work on [parallel items] in parallel."

## Step 3: Context-Specific Guidance

Based on the identified priority, provide detailed interactive guidance as described below.

---

### If PSI Is the Priority

Walk through PSI data collection for the specific covered process. PSI has three required categories under 29 CFR 1910.119(d).

**Open the conversation:**
> Let's complete the Process Safety Information for [process name]. PSI has three categories required by the regulation: chemical hazard information, process technology information, and equipment information. I'll walk you through each one.

**Category 1: Chemical Hazard Information (1910.119(d)(1))**

For each hazardous chemical in the process, collect:
- Toxicity information
- Permissible exposure limits (PELs)
- Physical data: boiling point, vapor pressure, specific gravity, flash point
- Reactivity data
- Corrosivity data
- Thermal and chemical stability data
- Hazardous effects of inadvertent mixing with other materials

Ask the user:
> Do you have Safety Data Sheets (SDS) for the chemicals in this process? SDS documents contain most of what we need for the chemical hazard section. If you can share them or point me to the specific chemicals, I can help structure the data.

Explain why it matters: "Chemical hazard data is the first thing a PHA team needs. They cannot identify hazard scenarios without knowing what the chemicals do when things go wrong — what happens if it leaks, overheats, contacts water, or mixes with something it shouldn't."

**Category 2: Process Technology Information (1910.119(d)(2))**

Collect:
- Block flow diagram or simplified process flow diagram
- Process chemistry description
- Maximum intended inventory
- Safe upper and lower limits for: temperature, pressure, flow, composition, levels
- Consequences of deviation from safe operating limits (what happens if you exceed them)

Ask the user:
> Do you have a block flow diagram or process flow diagram? Even a hand-drawn sketch helps. What about process chemistry documentation — reaction descriptions, side reactions, decomposition temperatures?

For each missing item, explain what format is acceptable:
- Block flow diagram: "A simple box-and-line drawing showing major equipment and flow direction is sufficient for initial PSI. It does not need to be a formal engineering drawing at this stage."
- Operating limits: "A table with columns for Parameter, Low Limit, Normal Operating, High Limit, and Consequence of Deviation is the standard format."

**Category 3: Equipment Information (1910.119(d)(3))**

Collect:
- Materials of construction
- Piping and instrument diagrams (P&IDs)
- Electrical area classification
- Relief system design and design basis
- Ventilation system design
- Design codes and standards employed
- Material and energy balances (for processes built after May 26, 1992)
- Safety systems (interlocks, detection, suppression)

Ask the user:
> What materials of construction are used in the major equipment? Do you have P&IDs? What about relief device sizing basis — do you have the engineering calculations or vendor data sheets for pressure relief valves or rupture disks?

For each piece of information the user provides:
- Acknowledge it and explain where it fits in the PSI documentation.
- Update the PSI procedure file in `PSM_PROGRAM/02_PROCESS_SAFETY_INFORMATION/` with the provided data.
- Update the crosswalk to reflect the new status.
- Note any remaining gaps.

---

### If PHA Is the Priority

Do NOT attempt to facilitate an actual PHA session. PHA requires a qualified team with process-specific expertise. Instead, generate a PHA planning package.

**Methodology Recommendation:**
- For simple processes (single unit operation, few chemicals, straightforward controls): recommend **What-If/Checklist** methodology.
- For complex processes (multiple unit operations, reactive chemistry, complex control systems): recommend **HAZOP** methodology.
- Explain the choice: "What-If/Checklist works well for [process] because [reason]. If you prefer a different methodology, that's fine — the regulation allows any appropriate method."

**Team Composition Requirements (1910.119(e)(1)):**
- At least one person experienced in the specific process
- At least one person knowledgeable in the PHA methodology being used
- One or more persons with expertise relevant to the process (operations, engineering, maintenance)
- The team should include an employee per the Employee Participation requirements
- Recommend a team of 4-6 for most processes

**Required PHA Scope (1910.119(e)(2)):**
The PHA must address:
- Hazards of the process
- Identification of previous incidents with catastrophic potential
- Engineering and administrative controls and their interrelationships (this means looking at layers of protection)
- Consequences of control failures
- Facility siting (where are people relative to hazards?)
- Human factors (what operator errors are reasonably foreseeable?)
- Qualitative evaluation of safeguard failure effects

**Deliverables to Generate:**
- PHA planning memo with recommended methodology, team composition, and schedule
- PHA worksheet template appropriate to the selected methodology
- List of required input documents (completed PSI, incident history, P&IDs)
- Reminder that findings must be formally resolved and documented per 1910.119(e)(5)

**Important Scheduling Notes:**
- Initial PHA must be completed within 12 months of process startup (or was due by May 26, 1997 for existing processes).
- PHA must be revalidated every 5 years.
- PHA revalidation must be updated and revalidated by a team meeting the same composition requirements.

---

### If Operating Procedures Are the Priority

Engage the user in interactive procedure drafting for the specific covered process.

**Open the conversation:**
> Let's draft the operating procedure for [process name]. I'll ask you to walk me through what an operator actually does, and I'll structure it into the format required by 29 CFR 1910.119(f).

**Required Procedure Sections (1910.119(f)(1)):**

For each operating phase, ask the user to describe the steps:

1. **Steps for initial startup** — "Walk me through a cold startup of [process]. What's the very first thing an operator does? What do they check before introducing feed?"

2. **Normal operations** — "Describe a normal operating shift. What does the operator monitor? What adjustments do they make? What are the routine tasks?"

3. **Temporary operations** — "Are there any temporary operating modes? Bypass operations? Reduced-rate operations?"

4. **Emergency shutdown** — "If something goes wrong — loss of containment, overpressure, loss of cooling — what does the operator do immediately? Walk me through the emergency shutdown sequence."

5. **Emergency operations** — "After the emergency shutdown, what does the operator do while waiting for the situation to stabilize? Are there isolation steps, depressuring steps, or evacuation triggers?"

6. **Normal shutdown** — "Walk me through a planned, controlled shutdown. What order do you take things offline?"

7. **Startup after turnaround or emergency shutdown** — "After a maintenance turnaround or an emergency shutdown, what additional checks or steps are required before restarting?"

**Required Content Beyond Steps (1910.119(f)(1)(ii)):**
For each procedure, also include:
- Operating limits: what are the safe ranges for pressure, temperature, flow, level?
- Consequences of deviation: what happens if the operator exceeds these limits?
- Steps to correct or avoid deviation
- Safety and health considerations: chemical hazards, precautions to prevent exposure, PPE requirements, what to do if exposure occurs
- Safety systems and their functions: interlocks, alarms, suppression systems
- Raw material quality control and inventory management

**Save Output:**
- Write the completed procedure to `PSM_PROGRAM/04_OPERATING_PROCEDURES/` using the Tobe document numbering convention.
- Update the crosswalk for 1910.119(f) clauses.
- Remind the user: "Operating procedures must be reviewed and certified as current and accurate at least annually (1910.119(f)(2)). I've noted that in the compliance milestones."

---

### If Training Is the Priority

Generate a training program from existing operating procedures.

**Initial Assessment:**
> Let's build the training program for [process name]. I see that operating procedures exist for [list]. Training under 1910.119(g) must cover these procedures and include an emphasis on the specific safety and health hazards, emergency operations, and safe work practices.

**Training Curriculum Generation:**
- Extract key topics from each operating procedure.
- Organize into training modules: process overview, chemical hazards, normal operations, emergency response, safety systems, PPE requirements.
- Create a training outline document.

**Training Records:**
- Pre-fill the training record form (TE-FRM-005 or equivalent) with:
  - Employee name field
  - Training topic
  - Date of training
  - Trainer name and qualifications
  - Comprehension verification method (written test, practical demonstration, verbal quiz)
  - Certification statement that the employee understood the training

**Training Schedule:**
- Create an initial training matrix showing who needs what training and when.
- Set refresher training intervals: every 3 years per 1910.119(g)(2).
- Note: initial training must be completed before an employee operates the process independently.

**Grandfathering Provision:**
> For employees already operating this process, 29 CFR 1910.119(g)(1)(ii) allows you to certify that they have the required knowledge, skills, and abilities without requiring them to go through initial training. This requires a written certification. Do you have experienced operators who should be grandfathered?

**Save Output:**
- Write training curriculum to `PSM_PROGRAM/05_TRAINING/`.
- Update the training register.
- Update the crosswalk for 1910.119(g) clauses.

---

### If Compliance Audit Is Approaching

This section is only reached when all other elements are at least PARTIAL.

**Run Pre-Audit Self-Assessment:**
- Read the compliance audit checklist (TE-FRM-007 or equivalent).
- For each of the 14 elements, assess current status against the requirements.
- Generate a pre-audit findings summary organized by element.

**Assessment Format:**
For each element:
- Requirement summary
- Current status (Met / Partially Met / Not Met)
- Evidence available
- Evidence missing
- Recommended corrective actions

**Output:**
- Pre-audit self-assessment report saved to `PSM_PROGRAM/13_COMPLIANCE_AUDITS/`.
- Updated gap register with any newly identified gaps.
- Priority-ranked list of items to close before audit.

---

### Parallel Elements

When the main-chain priority is identified, also check for parallel elements that can be worked on simultaneously. Briefly mention these:

- **Employee Participation (Element 01):** "Your employee participation plan can be developed now. This includes defining how employees are consulted on PHA, procedure development, and other PSM elements. It's a written plan — would you like to draft it?"
- **Contractors (Element 06):** Only suggest after operating procedures exist. "Now that procedures exist, you can formalize contractor safety requirements — pre-qualification, training verification, injury reporting."
- **Hot Work Permit (Element 09):** Only suggest after operating procedures exist. "Your hot work permit program can reference the operating procedures for identifying safe conditions."
- **Incident Investigation (Element 11):** "The incident investigation procedure is a framework element — you can finalize it now even before incidents occur. It defines how you'll investigate when something happens."
- **Emergency Planning (Element 12):** "Emergency planning can be developed alongside other work. Do you have an emergency action plan? Does it address the specific hazards from your PSI?"
- **MOC (Element 10):** "Management of Change is critical infrastructure. Every change to process, equipment, technology, or procedures must go through MOC. The procedure should be finalized early so it's in place before you start making changes."
- **Trade Secrets (Element 14):** "Trade secrets is a policy element. If any of your PSI or process information is proprietary, you need a mechanism to make it available for PSM purposes while protecting confidentiality."

---

## Step 4: Update State

After each completed implementation step:

1. **Update the state file** (`.claude/process-safety.local.json`):
   - Update the current phase.
   - Update any completion timestamps.
   - Record which PSI categories are complete for which processes.
   - Update the audit readiness percentage.

2. **Update affected program documents:**
   - Mark completed items in the crosswalk (`TOB-PSM-002`).
   - Close resolved gaps in the gap register (`TOB-PSM-004`).
   - Update the document register if new documents were created.

3. **Announce progress:**
   > Updated. Audit readiness is now [X]%. [Summary of what was completed]. Next priority: [next item per dependency chain].

---

## Tone and Communication Style

- **Be encouraging but honest.** Example: "You're making real progress — PSI is 60% complete for CP-001. The equipment data is the big remaining piece."
- **Explain regulatory requirements in plain language first**, then give the specific CFR reference for those who want the legal citation. Example: "You need to document the safe operating limits for every critical parameter — that's temperature, pressure, flow, level — and explain what happens if the operator exceeds them. That's 29 CFR 1910.119(f)(1)(ii)(B)."
- **For startups and small companies:** Acknowledge that the volume of work feels heavy, but emphasize that building it correctly now prevents painful and expensive retrofitting later. "This feels like a lot of documentation for a startup. It is. But every one of these requirements exists because something went wrong somewhere — often catastrophically. Building it right now means you won't be scrambling to backfill gaps when an auditor or insurer asks to see your program."
- **Never be condescending.** The user may be a seasoned process safety professional or a startup founder encountering PSM for the first time. Gauge the level from their responses and adjust accordingly.
- **Be specific.** Instead of "you need process safety information," say "I need the vapor pressure and boiling point for propane at your operating conditions, and the design pressure rating of your storage vessel."
