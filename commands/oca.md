---
name: oca
description: Calculate offsite consequence analysis — distance to endpoint for worst-case and alternative release scenarios
---

You are executing the `/process-safety:oca` command. This command calculates offsite consequence analysis (OCA) for EPA RMP compliance, replacing EPA's RMP*Comp tool. You will determine the distance to endpoint for worst-case and/or alternative release scenarios per 40 CFR 68.22-68.28.

---

## PRE-FLIGHT CHECKS

Before starting the interactive workflow, perform these checks:

### Step 1: Check for state file

Read `.claude/process-safety.local.json` in the current working directory.

- **If the file exists and has a `screening` or `chemicals` section with identified chemicals:**
  Display the chemicals found and offer to run OCA for them:
  ```
  Found [N] regulated chemicals from screening:
    - [Chemical 1] (CAS [number]) — [quantity] lbs — [toxic/flammable/both]
    - [Chemical 2] ...

  Run OCA for these chemicals? Or specify a different chemical?
  ```
  If the user wants to proceed with screened chemicals, iterate through each one using the workflow below.

- **If the file does not exist or has no chemicals:**
  Tell the user: "No screened chemicals found. I'll need you to provide the chemical name (or CAS number) and maximum quantity."

### Step 2: Check for existing OCA results

If the state file has an `oca.scenarios` array with entries, warn the user:
```
OCA results already exist for: [chemical list]. Re-running will overwrite these results. Proceed?
```

### Step 3: Check for required data files

Verify these files exist in the plugin's `data/` directory:
- `data/chemical-properties.json`
- `data/toxic-endpoints.json`
- `data/oca-distance-tables.json`

If `chemical-properties.json` or `toxic-endpoints.json` do not exist, warn:
```
Required data files not found. OCA calculations require chemical property data.
I can still proceed if you provide physical properties manually, or I can
attempt to fetch them from PubChem.
```

If `oca-distance-tables.json` does not exist, warn:
```
EPA distance lookup tables not found. I can still calculate flammable scenarios
(TNT-equivalent method) but toxic distance lookups require the reference tables.
```

---

## INTERACTIVE WORKFLOW

Walk the user through each input, one at a time. Do not dump all questions at once. Confirm each answer before moving on.

### Input 1: Chemical Identification

Ask: "What chemical do you want to analyze?"

Accept any of:
- Chemical name (fuzzy match against `data/chemical-properties.json`)
- CAS number (exact match)
- Common synonym or trade name

If no match is found in the data files:
1. Ask the user for the CAS number
2. Attempt a WebFetch from PubChem: `https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/[chemical]/JSON`
3. If WebFetch fails, ask the user to provide: molecular weight, boiling point (C), vapor pressure at 25C (mmHg), liquid density (lb/cu ft), and whether the chemical is flammable
4. If the chemical is toxic, also ask for the toxic endpoint (mg/L) from 40 CFR 68 Appendix A

After identifying the chemical, display its properties:
```
Chemical: [Name] (CAS [number])
  Molecular weight: [MW] g/mol
  Boiling point: [BP]°C
  State at ambient temp: [gas/liquid/liquefied gas]
  Vapor pressure (25°C): [VP] mmHg
  Liquid density: [density] lb/cu ft
  Toxic endpoint: [X] mg/L (if applicable)
  Heat of combustion: [X] BTU/lb (if applicable)
  Hazard class: [toxic / flammable / both]
```

**Dual-hazard determination:** If a chemical appears in BOTH the toxic endpoints list AND has `flammable: true` in chemical properties (e.g., ethylene oxide CAS 75-21-8), flag it:
```
NOTE: [Chemical] is a DUAL-HAZARD substance — regulated as both toxic and
flammable under RMP. EPA requires separate worst-case scenarios for EACH
hazard class. I will run both calculations.
```

### Input 2: Maximum Quantity

Ask: "What is the maximum quantity in the largest single vessel or interconnected piping that could be involved in a release? (in pounds)"

Validate:
- Must be a positive number
- If quantity seems implausibly large for the chemical (e.g., > 1,000,000 lbs for most chemicals), warn:
  ```
  You entered [X] lbs. This is unusually large for [chemical]. Typical maximum
  inventories range from [typical range]. Please verify this is correct.
  ```
  Do NOT block the calculation — the user may have a valid reason.

### Input 3: Release Type

Determine the release type from `data/chemical-properties.json` based on `state_at_ambient`:
- If `state_at_ambient` is `"gas"`: release type is **gas** (entire quantity released as gas)
- If `state_at_ambient` is `"liquid"`: release type is **liquid** (pool evaporation model)
- If boiling point is below ambient temperature but chemical is stored as refrigerated liquid: release type is **refrigerated liquefied gas**

Confirm with the user:
```
Based on [chemical]'s properties (boiling point [X]°C), the release type is: [type].
Is this correct, or is the chemical stored differently at your facility?
```

### Input 4: Containment

Ask: "Is the area around the vessel/pipe diked or contained?"

- **If diked:** Ask: "What is the diked area in square feet?"
- **If undiked:** Note that the pool will spread to 1 cm (0.39 inches) depth for liquid releases.
- **If gas release:** Note that containment does not apply to gas releases (skip this for gases).

For refrigerated liquefied gases with containment:
- If diked area results in pool depth > 1 cm: model as liquid pool evaporation at boiling point
- If undiked or pool depth <= 1 cm: treat as gas release (quantity / 10 minutes)

### Input 5: Topography

Ask: "Is the area surrounding your facility urban or rural?"

Provide guidance:
```
Urban = buildings, structures, and terrain features that create turbulent mixing
  (cities, dense suburbs, industrial parks with many structures)
Rural = flat open terrain with few obstructions
  (farmland, open industrial sites, coastal areas)

Urban dispersion produces SHORTER distances (more mixing).
```

### Input 6: Temperature and Humidity

Ask: "What temperature and humidity should I use for the analysis?"

Offer defaults:
```
EPA defaults: 77°F (25°C), 50% relative humidity.

For worst-case scenarios, EPA recommends using the highest daily maximum
temperature from the past 3 years and average humidity. If you don't have
this data, the defaults are acceptable.
```

Accept user values or defaults.

### Input 7: Scenario Type

Ask: "Which scenario type? (worst-case or alternative)"

Explain the difference:
```
Worst-case: Maximum quantity, fastest release, most conservative weather
  (wind 1.5 m/s, stability class F). No credit for active mitigation.
  REQUIRED for RMP submission.

Alternative: More realistic scenario (partial release, typical weather,
  can credit mitigation). Also REQUIRED for RMP — you need at least one
  of each type.
```

### Input 8: Alternative Scenario Parameters (if alternative selected)

If the user selected alternative scenario, collect additional inputs:

**Wind speed:**
Ask: "What wind speed? (default: 3.0 m/s)"
Accept user value or default.

**Stability class:**
Ask: "Atmospheric stability class? (default: D)"
Provide guidance:
```
A = extremely unstable (sunny, light winds)
B = moderately unstable
C = slightly unstable
D = neutral (default — overcast or moderate wind)
E = slightly stable
F = moderately stable (worst-case default — nighttime, light winds)
```

**Release quantity:**
Ask: "Is the release quantity the same as worst-case ([X] lbs), or a smaller amount? For alternative scenarios, you can model a partial release (e.g., largest pipe segment, single valve failure)."

**Active mitigation:**
Ask: "Are there any active mitigation systems that would reduce the release?"

Present the options:
```
Available active mitigation credits (alternative scenarios only):
  1. Water sprays/deluge on toxic gas — 55% reduction in release rate
  2. Water curtain — 25% reduction in endpoint distance
  3. Scrubber/absorber on vent — 90% reduction in release rate
  4. Excess flow valve / automatic shutoff — limits release to pipe inventory
  5. Other (you provide the reduction factor and documented basis)
  6. None

Which apply? (enter numbers, or 'none')
```

For each selected mitigation, confirm the reduction factor. For "Other," require the user to specify the factor and the engineering basis.

---

## CALCULATION LOGIC

After collecting all inputs, perform the calculations below. Show your work step by step so the user can verify.

### TOXIC WORST-CASE SCENARIO

#### Step 1: Determine Release Rate

**For toxic gases (state_at_ambient = "gas"):**
```
release_rate_lbs_per_min = quantity_lbs / 10
release_duration_min = 10
```
The entire quantity is released as gas over 10 minutes.

**For refrigerated liquefied gases:**
- If uncontained (no dike) OR if pool depth would be <= 1 cm:
  ```
  release_rate_lbs_per_min = quantity_lbs / 10
  release_duration_min = 10
  ```
  Treat as gas release.

- If contained in a dike AND pool depth > 1 cm:
  Model as liquid pool evaporation at the chemical's boiling point.
  ```
  pool_area_m2 = diked_area_sqft / 10.764
  T_K = boiling_point_C + 273.15
  QR_g_per_min = 1.4 * (U ^ 0.78) * (MW ^ (2/3)) * pool_area_m2 * VP_at_BP / (82.05 * T_K)
  release_rate_lbs_per_min = QR_g_per_min / 453.6
  release_duration_min = quantity_lbs / release_rate_lbs_per_min
  ```
  Where VP_at_BP is the vapor pressure at the boiling point (760 mmHg by definition).

**For toxic liquids (state_at_ambient = "liquid"):**

Total quantity spills instantaneously to form a pool.

If **undiked**:
```
pool_area_sqft = quantity_lbs / liquid_density_lb_per_cuft / 0.0328
pool_area_m2 = pool_area_sqft / 10.764
```
The 0.0328 factor represents the 1 cm (0.01 m = 0.0328 ft) pool depth.

If **diked**:
```
pool_area_m2 = diked_area_sqft / 10.764
```
Use the diked area directly.

Then calculate evaporation rate:
```
U = 1.5  (m/s, for worst-case)
T_K = temperature_F_to_K  (default: 298.15 K = 77°F = 25°C)
VP = vapor_pressure_mmHg_at_temperature

QR_g_per_min = 1.4 * (U ^ 0.78) * (MW ^ (2/3)) * pool_area_m2 * VP / (82.05 * T_K)
release_rate_lbs_per_min = QR_g_per_min / 453.6
release_duration_min = quantity_lbs / release_rate_lbs_per_min
```

**Temperature conversion helper:**
```
T_K = (temperature_F - 32) * 5/9 + 273.15
```

Display the intermediate values:
```
Pool area: [X] sq ft = [X] m²
Wind speed: [X] m/s
Temperature: [X]°F = [X] K
Vapor pressure: [X] mmHg
Evaporation rate: [X] g/min = [X] lbs/min
Release duration: [X] minutes
```

#### Step 2: Look Up Distance to Toxic Endpoint

Read `data/oca-distance-tables.json`.

**Chemical-specific tables:** Ammonia (CAS 7664-41-7), chlorine (CAS 7782-50-5), and sulfur dioxide (CAS 7446-09-5) have their own dedicated lookup tables in the data file. If the chemical is one of these, use the chemical-specific table directly.

**Generic tables for all other toxic chemicals:**
1. Read the chemical's toxic endpoint from `data/toxic-endpoints.json`
2. Find the generic distance table whose endpoint range includes the chemical's endpoint value
3. The tables are organized by endpoint ranges (e.g., 0.001-0.01 mg/L, 0.01-0.1 mg/L, etc.)

**Table lookup procedure:**
1. Take the calculated `release_rate_lbs_per_min`
2. Round DOWN to the nearest release rate entry in the table (do NOT interpolate — per EPA/RMP*Comp methodology, always round down to the next lower table entry)
3. Read the distance value for the applicable topography column (urban or rural)
4. The distance is in miles

**Distance clamping:**
- If calculated distance < 0.1 miles: report as **0.1 miles**
- If calculated distance > 25 miles: report as **25 miles**

Display:
```
Release rate (rounded for table): [X] lbs/min
Toxic endpoint: [X] mg/L
Table used: [chemical-specific / generic endpoint range X-Y mg/L]
Topography: [urban/rural]

DISTANCE TO TOXIC ENDPOINT: [X.X] miles ([X] feet)
```

### FLAMMABLE WORST-CASE SCENARIO

#### Step 1: Determine Quantity in Vapor Cloud

**For flammable gases, or liquid under pressure, or refrigerated gas with pool <= 1 cm:**
```
mass_in_cloud_lbs = quantity_lbs
```
Entire quantity participates in the vapor cloud explosion (VCE).

**For flammable liquids or refrigerated gas in containment with pool > 1 cm:**
```
mass_in_cloud_lbs = release_rate_lbs_per_min * 10
```
Only the quantity volatilized in 10 minutes participates.

#### Step 2: TNT-Equivalent Calculation (Vapor Cloud Explosion)

```
yield_factor = 0.10
heat_TNT_BTU_per_lb = 1943
heat_combustion = [from data/chemical-properties.json, field: heat_combustion_BTU_per_lb]

W_TNT = (yield_factor * mass_in_cloud_lbs * heat_combustion) / heat_TNT_BTU_per_lb
```

If `heat_combustion_BTU_per_lb` is null or missing in the data file:
1. Attempt WebFetch from PubChem to find heat of combustion
2. If not available, ask the user: "Heat of combustion for [chemical] is not in my data. What is the heat of combustion in BTU/lb?"

#### Step 3: Distance to 1 psi Overpressure

```
d_feet = 55.7 * (W_TNT ^ (1/3))
d_miles = d_feet / 5280
```

Display:
```
Mass in vapor cloud: [X] lbs
Heat of combustion: [X] BTU/lb
TNT equivalent: [X] lbs TNT
VCE distance to 1 psi: [X] feet = [X.XX] miles
```

#### Step 4: BLEVE Fireball Distance (Liquefied Flammable Gases Only)

For liquefied flammable gases (propane, butane, isobutane, etc. — chemicals that are gas at ambient temperature but stored as liquids under pressure), also calculate the fireball distance.

**IMPORTANT: The EPA BLEVE formula uses metric units (mass in kg, diameter in meters).**

```
mass_kg = mass_in_cloud_lbs / 2.205
D_fireball_meters = 5.25 * (mass_kg ^ 0.397)          # fireball DIAMETER in meters
d_5kw_meters = 1.4 * (D_fireball_meters / 2)           # distance to 5 kW/m² endpoint
d_5kw_feet = d_5kw_meters * 3.281
d_5kw_miles = d_5kw_feet / 5280
```

The 1.4 multiplier on the radius accounts for the view factor and atmospheric transmissivity to find the distance where radiant heat drops to 5 kW/m² (the EPA flammable endpoint for fires).

Display:
```
BLEVE fireball distance (5 kW/m²): [X] feet = [X.XX] miles
BLEVE lethal distance (40 kW/m²): [X] feet = [X.XX] miles
```

#### Step 5: Determine Reported Distance

If BOTH VCE and BLEVE distances were calculated:
```
reported_distance = max(d_vce_miles, d_fireball_miles)
```

Report the greater distance as the worst-case flammable distance. Clearly state which scenario governs:
```
VCE distance: [X.XX] miles
BLEVE fireball distance: [X.XX] miles
GOVERNING SCENARIO: [VCE / BLEVE fireball]

DISTANCE TO FLAMMABLE ENDPOINT: [X.X] miles ([X] feet)
```

Apply distance clamping (0.1 to 25 miles) to the final reported distance.

### DUAL-HAZARD CHEMICALS

If the chemical is flagged as both toxic and flammable:
1. Run the FULL toxic worst-case calculation (Steps 1-2 of toxic section)
2. Run the FULL flammable worst-case calculation (Steps 1-5 of flammable section)
3. Report BOTH distances with clear labels
4. Do NOT pick the larger one and discard the other — EPA requires both

Display:
```
DUAL-HAZARD ANALYSIS: [Chemical] is regulated as both toxic and flammable.

TOXIC WORST-CASE:
  Distance to toxic endpoint ([X] mg/L): [X.X] miles ([X] feet)

FLAMMABLE WORST-CASE:
  Distance to flammable endpoint (1 psi): [X.X] miles ([X] feet)

Both scenarios must be reported in the RMP submission.
```

### ALTERNATIVE RELEASE SCENARIOS

Use the same calculation framework as worst-case, but with user-specified parameters:

**Differences from worst-case:**
- Wind speed: user-specified (default 3.0 m/s instead of 1.5 m/s)
- Stability class: user-specified (default D instead of F)
- Release quantity: can be partial (user-specified)
- Active mitigation can be credited

**Applying active mitigation reductions:**

After calculating the base release rate or distance, apply mitigation factors:

| Mitigation | How to Apply |
|---|---|
| Water sprays/deluge (55%) | `adjusted_release_rate = release_rate * (1 - 0.55)` = release_rate * 0.45 |
| Water curtain (25%) | `adjusted_distance = distance * (1 - 0.25)` = distance * 0.75 |
| Scrubber/absorber (90%) | `adjusted_release_rate = release_rate * (1 - 0.90)` = release_rate * 0.10 |
| Excess flow valve / shutoff | `adjusted_quantity = pipe_inventory_lbs` (user provides pipe inventory) |
| Other | `adjusted_value = value * (1 - user_factor)` |

Apply release-rate reductions BEFORE the distance lookup. Apply distance reductions AFTER the lookup.

For toxic alternative scenarios using the lookup tables:
1. Calculate the base release rate
2. Apply any release-rate mitigation factors
3. Round the adjusted release rate DOWN to the nearest table entry
4. Look up the distance
5. Apply any distance mitigation factors (e.g., water curtain)

For flammable alternative scenarios:
1. Apply quantity reductions (excess flow valve) to the mass
2. Apply release-rate reductions to the evaporation rate (if liquid)
3. Calculate TNT equivalent with adjusted mass
4. Calculate distance
5. Apply any distance reductions

**Wind speed adjustment for liquid evaporation:**
In the evaporation formula, use the alternative wind speed instead of 1.5 m/s:
```
QR_g_per_min = 1.4 * (U_alt ^ 0.78) * (MW ^ (2/3)) * pool_area_m2 * VP / (82.05 * T_K)
```
Note: Higher wind speed increases evaporation rate but also increases atmospheric dispersion (shorter distances in lookup tables). The net effect depends on the specific scenario.

---

## OUTPUT

### OCA Report File

After completing the calculation, generate an OCA report as a Markdown file. Save it to:
```
PSM_PROGRAM/93_REFERENCE/OCA/OCA_[Chemical_Name]_[Scenario_Type].md
```

If the directory does not exist, create it.

Use this report template:

```markdown
# OFFSITE CONSEQUENCE ANALYSIS — [CHEMICAL NAME]

**Document Number:** [CO]-OCA-[NNN]
**Date:** [current date]
**Scenario:** [Worst-Case Release / Alternative Release]
**Prepared by:** AI Agent (process-safety plugin)
**Status:** DRAFT — Requires facility review

---

## INPUT PARAMETERS

| Parameter | Value |
|---|---|
| Chemical | [name] (CAS [number]) |
| Maximum quantity | [X] lbs |
| Release type | [gas / liquid / liquefied gas] |
| Containment | [undiked / diked — X sq ft] |
| Topography | [urban / rural] |
| Temperature | [X]°F ([X]°C / [X] K) |
| Relative humidity | [X]% |
| Wind speed | [X] m/s |
| Atmospheric stability class | [F / D / etc.] |
| Passive mitigation | [none / description] |
| Active mitigation | [none / description with reduction factors] |

## RELEASE RATE CALCULATION

[Show the full calculation with intermediate values, matching the step-by-step
calculations performed above. Include all formulas used and numeric values.]

## DISTANCE TO ENDPOINT

| Result | Value |
|---|---|
| Endpoint | [toxic: X mg/L basis / flammable: 1 psi overpressure / BLEVE: 5 kW/m²] |
| Calculation method | [EPA table lookup / TNT-equivalent / BLEVE fireball] |
| Release rate (for table lookup) | [X] lbs/min |
| Table entry used | [X] lbs/min (rounded down from [X]) |
| **Distance to endpoint** | **[X.X] miles ([X,XXX] feet)** |

## PUBLIC RECEPTORS (to be determined)

| Receptor Type | Within Distance? | Details |
|---|---|---|
| Estimated residential population | `REQUIRES COMPANY INPUT` | |
| Schools | `REQUIRES COMPANY INPUT` | |
| Hospitals / medical facilities | `REQUIRES COMPANY INPUT` | |
| Commercial / office / industrial | `REQUIRES COMPANY INPUT` | |
| Parks / recreation areas | `REQUIRES COMPANY INPUT` | |
| Major roads / highways | `REQUIRES COMPANY INPUT` | |

## ENVIRONMENTAL RECEPTORS (to be determined)

| Receptor Type | Within Distance? | Details |
|---|---|---|
| National / state parks | `REQUIRES COMPANY INPUT` | |
| Wildlife refuges / preserves | `REQUIRES COMPANY INPUT` | |
| Waterways / wetlands | `REQUIRES COMPANY INPUT` | |
| Drinking water intakes | `REQUIRES COMPANY INPUT` | |
| Other sensitive areas | `REQUIRES COMPANY INPUT` | |

## METHODOLOGY STATEMENT

This offsite consequence analysis was performed using the EPA simplified methodology
as described in the EPA Risk Management Program Guidance for Offsite Consequence
Analysis (EPA 550-B-99-009) and 40 CFR Part 68 Subpart B.

[For toxic:] Distance to endpoint was determined using [chemical-specific /
generic] EPA reference tables, indexed by release rate and toxic endpoint
concentration. No interpolation was performed per EPA methodology — the release
rate was rounded down to the nearest table entry.

[For flammable VCE:] Distance to the 1 psi overpressure endpoint was calculated
using the TNT-equivalent method with a 10% yield factor per EPA requirements.

[For BLEVE:] Distance to the 5 kW/m² thermal radiation endpoint was calculated
using the EPA fireball model.

Parameters per 40 CFR 68.[22/25/28] for [worst-case / alternative] release scenarios.

## LIMITATIONS AND NOTES

- This analysis uses simplified EPA methods. More refined dispersion modeling
  (ALOHA, PHAST, etc.) may produce different results.
- Public and environmental receptor data must be populated by the facility.
- Results should be reviewed by qualified process safety personnel.
- [If defaults used:] Default temperature (77°F) and humidity (50%) were used.
  For improved accuracy, use the highest daily maximum temperature from the past
  3 years and average humidity for your facility location.
```

### Console Display

After saving the report, display a formatted summary to the user:

```
╔══════════════════════════════════════════════════════════════╗
║  OFFSITE CONSEQUENCE ANALYSIS — RESULT                      ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Chemical:    [Name] (CAS [number])                          ║
║  Scenario:    [Worst-Case / Alternative]                     ║
║  Quantity:    [X] lbs                                        ║
║  Release rate: [X] lbs/min                                   ║
║  Endpoint:    [description]                                  ║
║                                                              ║
║  ┌──────────────────────────────────────────────────────┐    ║
║  │  DISTANCE TO ENDPOINT:  [X.X] miles  ([X,XXX] ft)   │    ║
║  └──────────────────────────────────────────────────────┘    ║
║                                                              ║
║  Method: [table lookup / TNT-equivalent / BLEVE fireball]    ║
║  Topography: [urban/rural]                                   ║
║  Wind: [X] m/s, Stability: [class]                           ║
║                                                              ║
║  Report saved: PSM_PROGRAM/93_REFERENCE/OCA/[filename]       ║
╚══════════════════════════════════════════════════════════════╝
```

For dual-hazard chemicals, display both results:
```
╔══════════════════════════════════════════════════════════════╗
║  DUAL-HAZARD OCA — [Chemical Name]                          ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  TOXIC WORST-CASE:                                           ║
║  ┌──────────────────────────────────────────────────────┐    ║
║  │  Distance to [X] mg/L:  [X.X] miles  ([X,XXX] ft)   │    ║
║  └──────────────────────────────────────────────────────┘    ║
║                                                              ║
║  FLAMMABLE WORST-CASE:                                       ║
║  ┌──────────────────────────────────────────────────────┐    ║
║  │  Distance to 1 psi:     [X.X] miles  ([X,XXX] ft)   │    ║
║  └──────────────────────────────────────────────────────┘    ║
║                                                              ║
║  Both scenarios required for RMP submission.                 ║
╚══════════════════════════════════════════════════════════════╝
```

### State File Update

After completing the calculation, update `.claude/process-safety.local.json`:

Read the current state file, then add or update the `oca` section:

```json
{
  "oca": {
    "completed": true,
    "scenarios": [
      {
        "chemical": "[Chemical Name]",
        "cas": "[CAS Number]",
        "scenario_type": "worst_case",
        "hazard_class": "toxic",
        "quantity_lbs": [X],
        "release_rate_lbs_per_min": [X],
        "distance_miles": [X.X],
        "distance_feet": [X],
        "endpoint": "[description]",
        "topography": "[urban/rural]",
        "mitigation": "[none/description]",
        "date": "[YYYY-MM-DD]",
        "report_file": "PSM_PROGRAM/93_REFERENCE/OCA/[filename]"
      }
    ]
  }
}
```

For dual-hazard chemicals, add TWO entries to the scenarios array — one for toxic, one for flammable.

Set `oca.completed` to `true` only after at least one worst-case scenario has been calculated. If the user runs additional scenarios later, append to the array (do not overwrite previous entries for different chemicals).

---

## ERROR HANDLING

Handle these situations gracefully:

### Chemical not found in data files
```
"[Chemical] is not in my chemical properties database. Please provide the
CAS number so I can search more precisely, or I can look it up from PubChem."
```
Attempt WebFetch from PubChem: `https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/[name]/JSON`
If WebFetch returns data, extract molecular weight and other properties. If it fails, collect properties manually from the user.

### Physical properties missing or incomplete
If a required property (MW, vapor pressure, density, heat of combustion) is null or missing:
1. Attempt WebFetch from PubChem using the CAS number
2. If WebFetch fails, ask the user to provide the missing value(s)
3. Document in the report that user-supplied or externally-sourced values were used

### Distance less than 0.1 miles
Report as 0.1 miles. Note in the report:
```
Calculated distance was less than 0.1 miles. Per EPA convention, the minimum
reported distance is 0.1 miles (528 feet).
```

### Distance greater than 25 miles
Report as 25 miles. Note in the report:
```
Calculated distance exceeds 25 miles. Per EPA convention, the maximum
reported distance is 25 miles.
```

### Dual-hazard chemical detected
Do NOT ask the user to choose between toxic and flammable. Run BOTH calculations automatically. Both are required for RMP submission. Clearly label each result.

### Implausibly large quantity
If the quantity exceeds what seems reasonable, warn but do not block:
```
You entered [X] lbs of [chemical]. For reference:
  - A typical rail car holds ~33,000 gallons (~[X] lbs for this chemical)
  - A large storage tank might hold [X] lbs
Please verify this quantity is correct.
```
Proceed with the calculation if the user confirms.

### No distance tables available
If `oca-distance-tables.json` is missing and the chemical is toxic:
```
EPA distance lookup tables are not available. I cannot complete the toxic
distance calculation without them. For flammable chemicals, I can still
calculate using the TNT-equivalent method.

Options:
1. Provide the table data manually
2. Use EPA's RMP*Comp tool for the toxic lookup
3. I can attempt to fetch the reference tables
```

### Release rate falls below minimum table entry
If the calculated release rate is below the smallest entry in the lookup table:
```
The calculated release rate ([X] lbs/min) is below the minimum table entry
([Y] lbs/min). The distance to endpoint is less than the minimum tabled
distance. Reporting as 0.1 miles per EPA convention.
```

### Release rate exceeds maximum table entry
If the calculated release rate exceeds the largest entry in the lookup table:
```
The calculated release rate ([X] lbs/min) exceeds the maximum table entry
([Y] lbs/min). Distance may exceed 25 miles. Reporting as 25 miles per
EPA convention.
```

---

## MULTIPLE CHEMICALS / PROCESSES

If the user has multiple covered chemicals (from screening or specified manually):

1. Ask if they want to run OCA for all chemicals or select specific ones
2. For each chemical, walk through the full workflow
3. After all chemicals are done, display a summary table:

```
╔══════════════════════════════════════════════════════════════════════╗
║  OCA SUMMARY — ALL SCENARIOS                                        ║
╠═══════════════╦══════════╦══════════╦════════════╦═══════════════════╣
║  Chemical      ║ Scenario ║ Hazard   ║ Qty (lbs)  ║ Distance (mi)    ║
╠═══════════════╬══════════╬══════════╬════════════╬═══════════════════╣
║  [Chem 1]      ║ WC       ║ Toxic    ║ [X]        ║ [X.X]            ║
║  [Chem 1]      ║ Alt      ║ Toxic    ║ [X]        ║ [X.X]            ║
║  [Chem 2]      ║ WC       ║ Flam     ║ [X]        ║ [X.X]            ║
║  [Chem 3]      ║ WC       ║ Toxic    ║ [X]        ║ [X.X]            ║
║  [Chem 3]      ║ WC       ║ Flam     ║ [X]        ║ [X.X]            ║
╚═══════════════╩══════════╩══════════╩════════════╩═══════════════════╝

Facility worst-case distance: [X.X] miles ([Chemical], [hazard class])
```

4. Identify the overall facility worst-case (the single scenario with the greatest distance to endpoint across all processes and hazard classes)

---

## NEXT STEPS GUIDANCE

After completing OCA calculations, guide the user:

```
OCA calculations complete. Next steps:

1. Review the generated reports in PSM_PROGRAM/93_REFERENCE/OCA/
2. Fill in public and environmental receptor data (marked REQUIRES COMPANY INPUT)
3. Run `/process-safety:rmp` to assemble the full RMP data package
4. You will need at least one worst-case AND one alternative scenario per
   covered process for RMP submission
```

If the user only ran worst-case scenarios, remind them:
```
NOTE: You have worst-case scenarios but no alternative scenarios yet.
EPA requires at least one alternative release scenario per covered process.
Run `/process-safety:oca` again and select "alternative" when prompted.
```
