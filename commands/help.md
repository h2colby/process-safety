---
name: help
description: Plugin overview, PSM basics, and command reference
---

Display the following help screen directly to the user. Do not read files, do not run commands — just output the formatted content below.

---

First, display this ASCII banner exactly as shown:

```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║  ██████╗ ██████╗  ██████╗  ██████╗███████╗███████╗███████╗ ║
║  ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔════╝██╔════╝██╔════╝ ║
║  ██████╔╝██████╔╝██║   ██║██║     █████╗  ███████╗███████╗ ║
║  ██╔═══╝ ██╔══██╗██║   ██║██║     ██╔══╝  ╚════██║╚════██║ ║
║  ██║     ██║  ██║╚██████╔╝╚██████╗███████╗███████║███████║ ║
║  ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚══════╝╚══════╝╚══════╝ ║
║                                                            ║
║  ███████╗ █████╗ ███████╗███████╗████████╗██╗   ██╗        ║
║  ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝╚██╗ ██╔╝        ║
║  ███████╗███████║█████╗  █████╗     ██║    ╚████╔╝         ║
║  ╚════██║██╔══██║██╔══╝  ██╔══╝     ██║     ╚██╔╝          ║
║  ███████║██║  ██║██║     ███████╗   ██║      ██║           ║
║  ╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝   ╚═╝      ╚═╝           ║
║                                                            ║
║  v0.1.0 — Federal process safety compliance toolkit        ║
╚════════════════════════════════════════════════════════════╝
```

---

Then display the following sections:

## WHAT IS PSM?

Process Safety Management (PSM) is a federal OSHA regulation (29 CFR 1910.119) that requires facilities handling highly hazardous chemicals above certain threshold quantities to maintain a comprehensive safety program. It exists because catastrophic chemical releases — explosions, toxic clouds, fires — can kill workers and surrounding communities. If your facility is covered and you don't have a compliant program, OSHA can issue citations with penalties exceeding $150,000 per violation, and willful violations can trigger criminal referral. PSM is not optional guidance; it is enforceable law.

## WHAT THIS PLUGIN DOES

This plugin provides three core workflows for building and maintaining a PSM compliance program:

**Screen** — Answer a series of questions about your facility, chemicals, and processes to determine whether OSHA PSM (29 CFR 1910.119) and/or EPA Risk Management Program (40 CFR Part 68) regulations apply to you. Get a clear applicability determination with the reasoning behind it.

**Generate** — Once screening confirms you are covered, generate a complete, audit-ready PSM program tailored to your company. This produces up to 41 controlled documents: a master manual, element procedures, compliance crosswalk, gap register, forms, templates, and registers — all with your company name, roles, and facility data.

**Implement** — After your program is generated, get step-by-step guidance on making it real. The plugin tracks your progress across all 14 PSM elements, identifies the next highest-priority task, and walks you through completing it with evidence an auditor would accept.

## COMMAND REFERENCE

| Command | What it does |
|---|---|
| `/process-safety:screen` | Determine if OSHA PSM and/or EPA RMP apply to your facility |
| `/process-safety:generate` | Generate a complete 41-document PSM program with your company data |
| `/process-safety:status` | View implementation progress and audit readiness dashboard |
| `/process-safety:implement` | Get step-by-step guidance on the next highest-priority task |
| `/process-safety:oca` | Calculate offsite consequence analysis (distance to endpoint) for RMP |
| `/process-safety:rmp` | Generate RMP data package for EPA CDX submission (9 documents) |
| `/process-safety:help` | Show this help screen |

## START HERE

Check for the existence of the file `.claude/process-safety.local.json` in the current working directory.

- **If the file does not exist:** Tell the user: "No project state found. Run `/process-safety:screen` to determine if PSM applies to your facility."
- **If the file exists**, read it and check the `phase` field:
  - If `phase` is `"screening"` or `"screened"`: Tell the user: "Screening is complete. Run `/process-safety:generate` to build your PSM program."
  - If `phase` is `"generating"` or `"generated"`: Tell the user: "Your PSM program has been generated. Run `/process-safety:status` to see your dashboard, or `/process-safety:implement` to start working through implementation tasks."
  - If `phase` is `"implementing"`: Tell the user: "Implementation is in progress. Run `/process-safety:status` to check progress, or `/process-safety:implement` to continue with your next task."
  - For any other value or if the field is missing: Tell the user: "Run `/process-safety:screen` to get started."

## DISCLAIMER

> **This tool helps build PSM program documentation. It does not replace qualified process safety professionals, licensed engineers, or legal counsel. Always verify regulatory applicability with competent authority.**
