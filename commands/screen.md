---
name: screen
description: Determine if OSHA PSM and/or EPA RMP apply to your facility
---

You are executing the **process-safety:screen** command. This command walks the user through a structured regulatory applicability screening to determine whether OSHA PSM (29 CFR 1910.119) and/or EPA RMP (40 CFR Part 68) apply to their facility.

Do NOT skip steps. Do NOT rush to a conclusion. Work through each step interactively, one at a time. Wait for user responses before proceeding.

---

## STEP 1: CHEMICAL IDENTIFICATION

Ask the user:

> **What chemicals do you handle, store, or process at your facility?**
> You can use common names — I'll match them to the regulatory lists. You can also provide CAS numbers directly if you have them.

Accept natural-language input. Users may say things like "ammonia", "chlorine gas", "hydrogen", "propane", "we have 15,000 lbs of anhydrous ammonia", or provide CAS numbers directly.

If the user provides quantities in the same message as chemical names, capture both and skip the quantity question for those chemicals in Step 2.

If the user says they already know they are PSM/RMP covered, acknowledge it but explain: "I'll still run through the chemical identification so we can populate your project data for downstream program generation. This only takes a minute."

### Matching chemicals to regulatory lists

Read both data files:
- `process-safety/data/appendix-a.json` — OSHA PSM Appendix A (Highly Hazardous Chemicals)
- `process-safety/data/rmp-chemicals.json` — EPA RMP regulated substances (toxic and flammable tables)

For each chemical the user provides, match it against both lists using **fuzzy matching logic**:

1. **Normalize** the user input: lowercase, strip leading/trailing whitespace, remove parenthetical qualifiers for initial matching.
2. **Exact match** first: compare normalized input against normalized chemical names in both lists.
3. **Substring match**: if no exact match, check if the user's input is a substring of any listed chemical name, or vice versa. For example:
   - "ammonia" should match "Ammonia, Anhydrous", "Ammonia solutions (>44% ammonia by weight)", "Ammonia (anhydrous)", and "Ammonia (conc 20% or greater)"
   - "chlorine" should match "Chlorine", "Chlorine Dioxide", "Chlorine Pentafluoride", "Chlorine Trifluoride", "Chlorine Monoxide" — present all matches and ask the user to confirm which specific chemical(s) they mean
   - "hydrogen" should match "Hydrogen", "Hydrogen Chloride", "Hydrogen Fluoride", "Hydrogen Selenide", "Hydrogen Sulfide" — present all matches and ask the user to confirm
   - "HF" or "hydrofluoric acid" should match "Hydrogen Fluoride / Hydrofluoric Acid (conc 50% or greater)"
4. **CAS number match**: if the user provides a CAS number, match directly against the `cas` field in both lists.
5. **Multiple matches**: if a chemical name matches multiple entries (e.g., "ammonia" matches both anhydrous and solution forms), present all matches to the user and ask which specific form(s) they have.

**If a chemical cannot be matched** after the above steps, ask the user: "I couldn't find [chemical] in the OSHA or EPA regulated lists. Can you provide the CAS number, or clarify the specific chemical name?"

**If a chemical still cannot be matched** after the user attempts to clarify, report it as:
> "[Chemical] was not found in OSHA Appendix A or the EPA RMP regulated substance list. **This does not guarantee the chemical is unregulated.** Category 1 flammable gases and flammable liquids with a flash point below 100 degrees F (37.8 degrees C) are subject to the PSM flammable catch-all threshold of 10,000 lbs even if not specifically listed in Appendix A. Consult a qualified professional if uncertain."

Include the chemical in the screening with a `REQUIRES CAS VERIFICATION` flag.

---

## STEP 2: QUANTITY DETERMINATION

For each matched chemical (where quantities were not already provided in Step 1), ask:

> **What is the maximum quantity of [chemical name] you have on-site at any one time?** (in pounds — approximations are fine, this is a screening, not an inventory audit)

Accept approximate values. If the user provides quantities in other units (kg, tons, gallons), convert to pounds. Common conversions:
- 1 kg = 2.205 lbs
- 1 short ton = 2,000 lbs
- For liquids given in gallons, ask for the specific gravity or note that conversion requires density data

If the user has multiple chemicals, present them as a list and let them provide all quantities at once.

---

## STEP 3: PSM APPLICABILITY CHECK

For each chemical, apply **both** of the following PSM coverage pathways:

### Pathway A: Appendix A Listed Chemical
- Is the chemical listed in OSHA Appendix A (`appendix-a.json`)?
- Does the user's maximum on-site quantity **meet or exceed** the Threshold Quantity (TQ) listed in Appendix A?
- If YES to both: **PSM applies for this chemical under the Appendix A pathway.**

### Pathway B: Flammable Catch-All (10,000 lb threshold)
- Is the chemical a **Category 1 flammable gas** OR a **flammable liquid with a flash point below 100 degrees F (37.8 degrees C)**?
- Is the **total on-site quantity** of such flammables **10,000 lbs or greater**?
- If YES to both: **PSM applies under the flammable catch-all provision.**
- NOTE: The 10,000 lb threshold is an aggregate — it applies to the total quantity of all flammable materials in a process, not per-chemical.
- Chemicals listed in the `flammable_substances` array of `rmp-chemicals.json` are generally Category 1 flammable gases or flammable liquids. Use that list as a reference, but note that many common flammable liquids (gasoline, naphtha, toluene, xylene, etc.) may also qualify even if not on the RMP list.

### Exclusions Check

After determining that a PSM threshold is met, ask whether any of the following **exclusions** apply. Present them one at a time or as a checklist:

> Before I finalize the PSM determination, I need to check whether any exclusions apply. Do any of the following describe your facility or the chemical's use?
>
> 1. **Retail facility** — The chemical is handled in a retail establishment (e.g., a store selling propane tanks to consumers).
> 2. **Oil or gas well drilling or servicing** — The chemical is used solely in oil/gas well drilling or servicing operations.
> 3. **Normally unoccupied remote facility** — The facility is normally unoccupied and is inspected at least once per week by an operator.
> 4. **Workplace consumption fuel** — A hydrocarbon fuel (propane, natural gas, etc.) used solely for workplace consumption as a fuel (heating, vehicles, generators) and not connected to a process involving a highly hazardous chemical.
> 5. **Atmospheric storage of flammable liquid** — A flammable liquid stored in atmospheric tanks or transferred through pipes and which is kept below its normal boiling point without benefit of chilling or refrigeration.

If any exclusion applies, note it and explain its effect on the applicability determination. An exclusion may negate PSM coverage for a specific chemical or use case but not necessarily for the entire facility.

---

## STEP 4: RMP APPLICABILITY CHECK

For each chemical, check against **both tables** in `rmp-chemicals.json`:
- `toxic_substances` (Table 1)
- `flammable_substances` (Table 2)

If the chemical is listed in either table AND the user's maximum on-site quantity **meets or exceeds** the RMP Threshold Quantity: **RMP applies for this chemical.**

Note: RMP and PSM threshold quantities can differ for the same chemical. Always check both independently.

If RMP applies for at least one chemical, proceed to Step 5.

---

## STEP 5: RMP PROGRAM LEVEL DETERMINATION

If RMP applies, determine the appropriate Program Level for each covered process. Apply this logic **in order** (Program 3 first, then Program 1, then Program 2 as the default):

### Program 3 (most stringent — check first)
A covered process falls under Program 3 if **either** of the following is true:
- The process is **also subject to OSHA PSM** (29 CFR 1910.119), OR
- The facility's SIC code falls within one of these ranges: **2611-2899, 2911, 3011-3099, 4612, 4613, 4619, 5171**

Ask the user:
> **What is your facility's SIC code or NAICS code?** (If you don't know, I can help determine it from your industry description.)

If the user does not know their SIC code, ask them to briefly describe their primary business activity and attempt to identify the SIC code. If uncertain, note it as `REQUIRES SIC VERIFICATION`.

### Program 1 (least stringent — eligibility requirements)
A covered process qualifies for Program 1 only if **all three** of the following are true:
1. The facility has **not had an accidental release** of a regulated substance with offsite consequences in the past 5 years.
2. The **worst-case release analysis** shows no impact on any public receptor (residence, school, hospital, park, recreation area, etc.).
3. Emergency response is **coordinated with local agencies** (i.e., the facility does not maintain its own emergency response capability but relies on local fire/HAZMAT).

Ask the user:
> 1. **Has your facility had an accidental chemical release with offsite consequences in the past 5 years?** (An "offsite consequence" means deaths, injuries, significant property damage, evacuations, sheltering in place, or environmental damage beyond the facility boundary.)
> 2. **Have you conducted a worst-case release scenario analysis?** If so, did it show potential impact on any public receptor (homes, schools, hospitals, parks) within the impact zone?
> 3. **Does your facility rely on local emergency responders (fire department, HAZMAT team) rather than maintaining its own on-site emergency response team?**

### Program 2 (default)
If a covered process does not qualify for Program 1 and does not trigger Program 3, it falls under **Program 2**.

Present the determination clearly:
> Based on [reasoning], your covered process(es) fall under **RMP Program Level [1/2/3]**.

---

## STEP 6: PUBCHEM DATA ENRICHMENT (OPTIONAL)

For each identified chemical, attempt to fetch supplemental physical property data from PubChem using WebFetch.

**URL pattern:**
```
https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/{chemical_name}/property/MolecularFormula,MolecularWeight,IUPACName,ExactMass/JSON
```

URL-encode the chemical name. Use the canonical name from the regulatory list, not the user's informal name.

- If WebFetch **succeeds**: extract MolecularFormula, MolecularWeight, and IUPACName. Store these for the screening report.
- If WebFetch **fails** or is unavailable: note "PubChem data unavailable" and **continue without blocking**. The screening does NOT depend on PubChem data.

Do not attempt more than 5 PubChem lookups. If the user has more than 5 chemicals, prioritize chemicals that triggered PSM or RMP applicability.

---

## STEP 7: GENERATE SCREENING REPORT

After completing all screening steps, generate a formatted screening report.

First, ensure the output directory exists:
```bash
mkdir -p PSM_PROGRAM/00_MASTER
```

Then write the report to `PSM_PROGRAM/00_MASTER/screening-report.md` using the following template. Fill in ALL bracketed fields with actual screening results. Do not leave template placeholders in the final output.

```markdown
# PROCESS SAFETY APPLICABILITY SCREENING REPORT

**Document Number:** TOB-PSM-SCR-001
**Revision:** R0
**Date:** [today's date in YYYY-MM-DD format]
**Facility:** [company name if known, or "REQUIRES COMPANY INPUT"]
**Screened by:** AI-assisted screening via process-safety plugin
**Classification:** Internal Working Document

---

## 1.0 SCREENING SUMMARY

| Regulation | Applicable? | Basis |
|---|---|---|
| OSHA PSM (29 CFR 1910.119) | [YES / NO] | [e.g., "Ammonia, Anhydrous exceeds Appendix A TQ of 10,000 lbs" or "No listed chemicals above TQ"] |
| EPA RMP (40 CFR Part 68) | [YES / NO] | [e.g., "Ammonia (anhydrous) exceeds RMP TQ of 10,000 lbs" or "No listed chemicals above TQ"] |
| RMP Program Level | [1 / 2 / 3 / N/A] | [e.g., "Process subject to OSHA PSM — Program 3 applies" or "N/A — RMP not applicable"] |

## 2.0 CHEMICAL SCREENING DETAIL

| Chemical | CAS | Max Qty (lbs) | PSM Appendix A TQ | PSM Triggered? | RMP TQ | RMP Triggered? |
|---|---|---|---|---|---|---|
| [chemical name] | [CAS] | [qty] | [TQ or "Not listed"] | [YES / NO] | [TQ or "Not listed"] | [YES / NO] |

[Repeat for each chemical screened]

[If flammable catch-all applies, add a row or note:]
> **Flammable catch-all:** Total on-site flammable inventory of [X] lbs meets the 10,000 lb PSM threshold for Category 1 flammable gases and flammable liquids (flash point < 100 deg F).

## 3.0 PUBCHEM SUPPLEMENTAL DATA

[If PubChem data was retrieved:]

| Chemical | Molecular Formula | Molecular Weight | IUPAC Name |
|---|---|---|---|
| [name] | [formula] | [weight] | [IUPAC] |

[If PubChem data was not retrieved:]
> PubChem data enrichment was not performed or was unavailable for this screening.

## 4.0 APPLICABLE EXCLUSIONS

[If any exclusions were claimed:]

| Exclusion | Claimed? | Chemical / Use Case | Effect |
|---|---|---|---|
| Retail facility | [YES / NO] | [details] | [effect on determination] |
| Oil/gas well drilling or servicing | [YES / NO] | [details] | [effect on determination] |
| Normally unoccupied remote facility | [YES / NO] | [details] | [effect on determination] |
| Workplace consumption fuel | [YES / NO] | [details] | [effect on determination] |
| Atmospheric flammable liquid storage | [YES / NO] | [details] | [effect on determination] |

[If no exclusions apply:]
> No exclusions were claimed during this screening.

## 5.0 WHAT THIS MEANS

[Generate a plain-language explanation tailored to the screening results. Use the guidance below but adapt to the specific outcome.]

**If PSM applies:**
> Your facility is subject to OSHA's Process Safety Management standard (29 CFR 1910.119). This requires implementation of a comprehensive safety management program covering 14 elements:
>
> 1. Employee Participation
> 2. Process Safety Information (PSI)
> 3. Process Hazard Analysis (PHA)
> 4. Operating Procedures
> 5. Training
> 6. Contractors
> 7. Pre-Startup Safety Review (PSSR)
> 8. Mechanical Integrity (MI)
> 9. Hot Work Permit
> 10. Management of Change (MOC)
> 11. Incident Investigation
> 12. Emergency Planning and Response
> 13. Compliance Audits
> 14. Trade Secrets
>
> OSHA can inspect for PSM compliance at any time. Penalties for willful violations can exceed $150,000 per violation, and repeated non-compliance can trigger criminal referral.

**If RMP applies:**
> Your facility is also subject to EPA's Risk Management Program rule (40 CFR Part 68). This requires:
>
> - Conducting a worst-case release analysis and (for Program 2/3) alternative release scenario analysis
> - Implementing a prevention program (Program 2: streamlined; Program 3: equivalent to PSM's 14 elements)
> - Developing an emergency response program (or coordinating with local responders)
> - Submitting a Risk Management Plan (RMP) to EPA via RMP*eSubmit
> - Reviewing and updating the RMP at least every 5 years
>
> As a **Program [level]** facility, your specific obligations include: [tailor to program level].

**If neither applies:**
> Based on the chemicals and quantities reported, your facility does not appear to trigger OSHA PSM or EPA RMP at this time. However, this screening is based on the information you provided. If your chemical inventory changes, you should re-screen. Additionally, state or local regulations may impose additional requirements not covered by this federal screening.

## 6.0 NEXT STEPS

[If PSM and/or RMP applies:]
> Run `/process-safety:generate` to build your compliance program. The generator will use the chemical and facility data from this screening to produce a tailored, audit-ready document set.

[If neither applies:]
> No federal PSM or RMP program is required based on current screening data. If your operations or inventory change, re-run `/process-safety:screen` to reassess. Consider whether state-level process safety or chemical safety regulations apply to your facility.

## 7.0 ASSUMPTIONS AND LIMITATIONS

- Quantities are based on user-reported maximum on-site inventory, not verified physical audit.
- Chemical matching was performed against published OSHA Appendix A and EPA 40 CFR 68.130 lists current as of the data file dates.
- This screening does not address state or local regulations, which may impose additional or lower thresholds.
- Flammable catch-all assessment requires knowledge of chemical classification (Category 1 flammable gas, flash point) that may not be fully verified in this screening.
- [Add any chemical-specific caveats, e.g., "Ammonia solution concentration was reported as >44% by user but not analytically verified."]

## 8.0 DISCLAIMER

**This screening is based on information provided and published regulatory chemical lists. It does not constitute legal advice or a definitive regulatory determination. Verify applicability with qualified process safety professionals and/or legal counsel before relying on these results for compliance purposes.**
```

---

## STEP 8: UPDATE STATE FILE

After generating the screening report, update the project state file.

First, initialize the state file if it does not already exist:
```bash
bash process-safety/scripts/state-manager.sh init
```

Then build a JSON patch and pipe it to the state manager's update command. The patch must include:

```json
{
  "company": {
    "name": "[company name if provided, otherwise empty string]"
  },
  "screening": {
    "completed": true,
    "date": "[today's date YYYY-MM-DD]",
    "psm_applicable": [true or false],
    "rmp_applicable": [true or false],
    "rmp_program_level": [1, 2, 3, or null]
  },
  "chemicals": [
    {
      "name": "[canonical chemical name from regulatory list]",
      "cas": "[CAS number]",
      "max_qty_lbs": [number],
      "psm_listed": [true or false],
      "psm_tq_lbs": [number or null],
      "psm_triggered": [true or false],
      "rmp_listed": [true or false],
      "rmp_tq_lbs": [number or null],
      "rmp_triggered": [true or false],
      "rmp_basis": ["toxic", "flammable", or null],
      "notes": "[any flags like REQUIRES CAS VERIFICATION, or exclusion notes]"
    }
  ]
}
```

Run the update:
```bash
echo '<json_patch>' | bash process-safety/scripts/state-manager.sh update
```

After the update, confirm to the user:
> Screening complete. State file updated. Run `/process-safety:generate` to build your PSM program.

---

## ERROR HANDLING

### Chemical name cannot be matched
If a chemical cannot be matched after attempting fuzzy matching AND the user cannot provide a CAS number:
- Include the chemical in the screening report with a `REQUIRES CAS VERIFICATION` flag
- In the chemicals array of the state update, set `psm_listed` and `rmp_listed` to `false` and add a note
- Warn the user: "This chemical could not be verified against regulatory lists. Manual verification is recommended before finalizing your applicability determination."

### WebFetch fails
If PubChem lookups fail (network error, timeout, tool unavailable):
- Note "PubChem data unavailable" in the report
- Continue the screening without interruption
- Do NOT retry more than once per chemical

### Contradictory information
If the user provides information that contradicts itself (e.g., "we have 5,000 lbs of ammonia" then later "actually we have 50,000 lbs"):
- Flag the contradiction explicitly: "You previously reported [X] lbs but now report [Y] lbs. Which quantity should I use for the screening?"
- Do NOT finalize the screening until contradictions are resolved
- Use the most recent confirmed value

### Missing output directory
If `PSM_PROGRAM/00_MASTER/` does not exist, create it before writing the report. Use `mkdir -p`.

---

## INTERACTION STYLE

- Be direct and technical. This is a regulatory screening, not a sales pitch.
- Use plain language to explain regulatory concepts when needed, but do not oversimplify.
- Present screening results clearly with tables where possible.
- When asking questions, number them and make them specific.
- If the user seems uncertain about a chemical or quantity, remind them this is a screening-level assessment and approximations are acceptable.
- Do NOT volunteer legal conclusions. Always include the disclaimer that this does not constitute legal advice.
