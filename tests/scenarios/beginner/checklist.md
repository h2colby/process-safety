# Test Scenario 1: Beginner — Ammonia, Single Process, 3-Person Company

## Context
- User: startup founder, no PSM knowledge
- Chemical: anhydrous ammonia, 15,000 lbs max on-site
- Process: single ammonia refrigeration system
- Company: 3 employees (CEO, lead engineer, operator)
- No existing documentation (greenfield)

## Pre-Test Setup
1. Run `bash tests/scenarios/beginner/setup.sh` to create clean test environment
2. `cd` into the test directory shown in the output

## Step 1: Help Command
- [ ] Run `/process-safety:help`
- [ ] Verify ASCII banner displays
- [ ] Verify command table shows all 5 commands
- [ ] Verify "Start here" suggests `/process-safety:screen`
- [ ] Verify disclaimer appears

## Step 2: Screen Command
- [ ] Run `/process-safety:screen`
- [ ] When asked about chemicals, enter: "We handle anhydrous ammonia"
- [ ] When asked about quantity, enter: "About 15,000 pounds max on site"
- [ ] When asked about exclusions, confirm none apply
- [ ] When asked about RMP questions, answer: no prior releases, SIC code is manufacturing (confirm with your actual SIC)
- [ ] Verify screening report is generated at `PSM_PROGRAM/00_MASTER/screening-report.md`
- [ ] Verify report says PSM APPLICABLE (ammonia is in Appendix A, TQ is 10,000 lbs, you have 15,000)
- [ ] Verify report says RMP APPLICABLE (ammonia is in RMP toxic list at 10,000 lbs)
- [ ] Verify RMP Program Level is 3 (PSM-covered = Program 3)
- [ ] Run `bash tests/scenarios/beginner/verify-screen.sh` and confirm all checks pass

## Step 3: Generate Command
- [ ] Run `/process-safety:generate`
- [ ] When asked about company: name = "TestCo", location = "Houston, TX"
- [ ] When asked about organization: 3 people — CEO (John) is PSM Program Manager + PSM Coordinator, Lead Engineer (Jane) is Operations + Maintenance Manager, Operator (Bob) is the operations team
- [ ] When asked about covered processes: single process — "Ammonia Refrigeration System", CP-001
- [ ] When asked about chemicals: confirm ammonia from screening (15,000 lbs, CAS 7664-41-7)
- [ ] When asked about equipment: pressure vessels, piping, compressors, relief devices, controls/instrumentation
- [ ] When asked about emergency response: "We coordinate with the local fire department, we don't have our own HAZMAT team"
- [ ] When asked about existing documentation: "Nothing — we're starting from scratch"
- [ ] Verify all 41 documents are generated
- [ ] Run `bash tests/scenarios/beginner/verify-generate.sh` and confirm all checks pass

## Step 4: Status Command
- [ ] Run `/process-safety:status`
- [ ] Verify dashboard shows company name "TestCo"
- [ ] Verify screening shows COMPLETE
- [ ] Verify generation shows COMPLETE with 41 documents
- [ ] Verify audit readiness percentage is shown
- [ ] Verify gaps count is shown
- [ ] Verify next priority suggests PSI work

## Step 5: Implement Command
- [ ] Run `/process-safety:implement`
- [ ] Verify it identifies PSI as the highest priority (not PHA, not procedures)
- [ ] Verify it starts walking through PSI data collection for the ammonia refrigeration system
- [ ] Verify it asks about SDS, process flow diagrams, operating limits, P&IDs, relief systems
- [ ] Run `bash tests/scenarios/beginner/verify-implement.sh` to check dependency enforcement

## Step 6: Test Command
- [ ] Run `/process-safety:test`
- [ ] Verify 12-point checklist runs
- [ ] Verify validation report is saved
- [ ] Review any FAIL items — these indicate issues in the generation

## Post-Test Cleanup
- [ ] Delete the test directory, or keep it for inspection
