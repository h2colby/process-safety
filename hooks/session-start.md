---
name: session-start
description: Detects existing PSM projects and shows brief status on session start
event: session-start
---

# Session Start — PSM Project Detection

On session start, check if `.claude/process-safety.local.json` exists in the current working directory.

## If the file exists and generation is complete:

Display a brief one-line status:

```
⚙ PSM Program: [company name] — [audit_readiness_pct]% audit ready | [gaps_open] gaps open | Next: [next_priority]
```

Read the values from the state file:
- `company_name` for the company name
- `audit_readiness_pct` for the audit readiness percentage
- `gaps_open` for the count of open gaps
- `next_priority` for the next recommended action

## If the file exists but generation is NOT complete:

Display:

```
⚙ PSM Program: In progress — run /process-safety:status for details or /process-safety:generate to continue
```

Determine this state when the file exists, `generation_complete` is false or absent, and `screening_complete` is true with generation started (i.e., documents exist in `PSM_PROGRAM/`).

## If the file exists but only screening is complete:

Display:

```
⚙ PSM Screening complete — run /process-safety:generate to build your program
```

Determine this state when `screening_complete` is true but no generation has begun.

## If the file does NOT exist:

Do nothing. Do not show any message. The user may not be using this plugin.

## Rules

- Keep it minimal — one line maximum. Do not overwhelm the session start.
- Do not prompt for input or ask questions.
- Do not run any commands or modify any files.
- Read the state file silently and display only the appropriate status line.
