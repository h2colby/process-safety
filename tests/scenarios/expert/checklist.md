# Test Scenario 2: Expert — H2 + NH3, Skip Screening, 2 Processes

## Context
- User: experienced PSM professional
- Chemicals: hydrogen (10,000 lbs) + anhydrous ammonia (15,000 lbs)
- Processes: H2 production unit + NH3 refrigeration system
- Company: 12 employees with defined org structure
- Some existing documentation (P&IDs exist, no formal procedures)

## Pre-Test Setup
1. Run `bash tests/scenarios/expert/setup.sh`
2. `cd` into the test directory

## Step 1: Skip to Generate
- [ ] Run `/process-safety:generate` directly (no /screen first)
- [ ] When asked about company: "HydroChem Inc", Dallas TX
- [ ] Organization: PSM Program Manager = VP Operations (Sarah), PSM Coordinator = Safety Engineer (Mike), Operations Manager = Plant Manager (Tom), Maintenance Manager = Maintenance Lead (Carlos), Training Coordinator = Safety Engineer (Mike), Records Manager = Admin (Lisa)
- [ ] Covered processes:
  - CP-001: "H2 Production Unit" — hydrogen, 10,000 lbs, SMR + PSA process
  - CP-002: "NH3 Refrigeration System" — anhydrous ammonia, 15,000 lbs
- [ ] Equipment: pressure vessels, piping, compressors, heat exchangers, relief devices, controls, rotating equipment, electrical
- [ ] Emergency response: "We have a trained emergency response team on-site"
- [ ] Existing docs: "We have P&IDs for both processes and a general safety manual, but no formal PSM procedures"
- [ ] Verify inline threshold verification runs (should confirm both H2 and NH3 trigger PSM)
- [ ] Verify all 41 documents generated
- [ ] Run `bash tests/scenarios/expert/verify-generate.sh` and confirm

## Step 2: Verify Two-Process Handling
- [ ] Check covered process register has 2 entries (CP-001, CP-002)
- [ ] Check chemical inventory register has both hydrogen and ammonia
- [ ] Check PHA schedule register has entries for both processes
- [ ] Check gap register accounts for existing P&IDs (P&ID gaps should be lower severity since they exist)

## Step 3: Status
- [ ] Run `/process-safety:status`
- [ ] Verify 2 covered processes shown
- [ ] Verify existing docs reflected in lower gap count

## Post-Test
- [ ] Delete test directory or keep for inspection
