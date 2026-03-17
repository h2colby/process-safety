# Getting Started with the Process Safety Plugin

**What this is:** A tool that runs inside Claude Code (Anthropic's AI coding assistant) and helps you build a complete, audit-ready OSHA PSM program and EPA RMP submission package for your facility.

**What you need before starting:**
- A Mac or Linux computer (Windows works too with WSL)
- An internet connection
- About 30 minutes for setup, then 1-2 hours for your first program generation

---

## Part 1: Install Claude Code

Claude Code is a command-line AI assistant made by Anthropic. If you've never used a terminal before, don't worry — this guide walks you through every step.

### Step 1.1: Open your terminal

**On Mac:**
- Press `Cmd + Space` to open Spotlight
- Type `Terminal` and press Enter
- A window with a text prompt will appear — this is your terminal

**On Windows:**
- You'll need WSL (Windows Subsystem for Linux) first
- Open PowerShell as Administrator and run: `wsl --install`
- Restart your computer, then open "Ubuntu" from your Start menu

**On Linux:**
- Press `Ctrl + Alt + T` or find "Terminal" in your applications

### Step 1.2: Install Node.js (required by Claude Code)

Copy and paste this into your terminal and press Enter:

```bash
curl -fsSL https://fnm.vercel.app/install | bash
```

Close and reopen your terminal, then run:

```bash
fnm install --lts
```

**Verify it worked:**
```bash
node --version
```

You should see something like `v22.x.x`. If you see "command not found", close and reopen your terminal and try again.

**If you get stuck:** Open a browser, go to https://claude.ai, and ask: "I'm trying to install Node.js on [Mac/Windows/Linux] and got this error: [paste the error]. How do I fix it?"

### Step 1.3: Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

**Verify it worked:**
```bash
claude --version
```

You should see a version number like `2.1.x`.

**If you see a permissions error on Mac/Linux**, run:
```bash
sudo npm install -g @anthropic-ai/claude-code
```
It will ask for your computer password (the one you use to log in).

### Step 1.4: Log into Claude Code

```bash
claude
```

The first time you run this, it will ask you to authenticate. Follow the prompts — it will open a browser window where you log in with your Anthropic account (or create one).

**You need one of these:**
- A Claude Pro subscription ($20/month)
- A Claude Max subscription ($100/month or $200/month — recommended for heavy use)
- An Anthropic API key with credits

Once logged in, you'll see a welcome screen with a text prompt. Type `/exit` to close it for now — we'll come back after installing the plugin.

---

## Part 2: Install the Process Safety Plugin

### Step 2.1: Create a workspace

This is where your PSM program files will live. Pick a location that makes sense for your organization.

```bash
mkdir ~/psm-program && cd ~/psm-program
```

This creates a folder called `psm-program` in your home directory and moves into it.

### Step 2.2: Start Claude Code

```bash
claude
```

### Step 2.3: Add the plugin marketplace

Inside Claude Code (you'll see the `❯` prompt), type:

```
/plugin marketplace add h2colby/process-safety
```

You should see:
```
Added marketplace: h2colby-process-safety
```

**If you see an error about "failed to parse":** The plugin may have been updated. Try:
```
/plugin marketplace remove h2colby-process-safety
/plugin marketplace add h2colby/process-safety
```

### Step 2.4: Install the plugin

```
/plugin install process-safety@h2colby-process-safety
```

You should see:
```
Installed process-safety v0.1.0
```

### Step 2.5: Restart Claude Code

The plugin only loads on startup, so you need to restart:

```
/exit
```

Then in your regular terminal:

```
cd ~/psm-program
claude
```

### Step 2.6: Verify it works

```
/process-safety:help
```

You should see an ASCII banner that says "PROCESS SAFETY" with a command reference table. If you see this, the plugin is installed and working.

**If you see "Unknown skill: process-safety:help":**
1. Make sure you restarted Claude Code (not just typed `/exit` — actually closed and reopened it)
2. Check the plugin is enabled: type `/plugin` and look for `process-safety` in the Installed tab. Toggle it on if it's off.
3. Restart Claude Code again

---

## Part 3: Your First PSM Program

### Step 3.1: Screen your facility

This determines whether OSHA PSM and/or EPA RMP regulations apply to you.

```
/process-safety:screen
```

The plugin will ask you questions. Answer in plain English — you don't need to know CAS numbers or regulatory codes. Examples of what to type:

- "We handle anhydrous ammonia, about 15,000 pounds"
- "Hydrogen gas, 10,000 lbs in our production unit"
- "We use chlorine for water treatment, maybe 3,000 pounds on site"

**What it checks:**
- Your chemicals against OSHA's list of 131 highly hazardous chemicals
- Your chemicals against EPA's list of 136 regulated substances
- Whether your quantities exceed the regulatory thresholds
- Which regulations apply and at what level

**At the end**, it generates a screening report and tells you whether you need a PSM program, an RMP, or both.

### Step 3.2: Generate your PSM program

```
/process-safety:generate
```

This walks you through a questionnaire about your company, then generates a complete 41-document PSM program. The questions come one topic at a time:

1. **Company basics** — name, location, what you do
2. **Organization** — how many people, who does what (it's fine if one person wears many hats — that's normal for startups)
3. **Covered processes** — describe your process(es) that involve the hazardous chemicals
4. **Chemical inventory** — confirm chemicals and quantities from screening
5. **Equipment** — what types of equipment you have (vessels, piping, compressors, etc.)
6. **Emergency response** — do you have your own HAZMAT team, or do you call the fire department?
7. **Existing documentation** — do you already have any P&IDs, procedures, or training records?

**After the questionnaire**, the plugin generates all 41 documents in a `PSM_PROGRAM/` folder in your workspace. This includes:
- Master PSM manual
- 14 element procedures (one for each PSM element)
- Compliance crosswalk (maps every regulation to your documents)
- Gap register (tells you exactly what's still missing)
- 13 forms (MOC, hot work permit, training records, etc.)
- 7 registers (chemical inventory, equipment list, PHA schedule, etc.)

### Step 3.3: Run OCA (if RMP applies)

If your screening showed EPA RMP applies, run the offsite consequence analysis:

```
/process-safety:oca
```

This calculates how far a worst-case chemical release could travel — the same calculation EPA's RMP*Comp tool does, but without the clunky government website. It asks about:
- Which chemical (pre-populated from screening)
- Maximum quantity in your largest vessel
- Whether you have containment (dikes, enclosures)
- Urban or rural location

**Output:** Distance to endpoint in miles — this is what goes in your RMP submission.

### Step 3.4: Generate your RMP package

```
/process-safety:rmp
```

This collects a few more data points (facility coordinates, emergency contacts, accident history) and generates the 9 documents EPA requires for an RMP submission, including a pre-filled submission checklist you can follow when entering data into EPA's CDX system.

### Step 3.5: Check your status

```
/process-safety:status
```

Shows a dashboard with your progress: what's done, what's outstanding, how close you are to audit-ready, and what to work on next.

### Step 3.6: Start implementing

```
/process-safety:implement
```

Guides you through actually making the program real — filling in Process Safety Information, planning your first PHA, writing operating procedures, setting up training records. It follows the correct sequence (PSI before PHA, PHA before procedures, etc.) so you never do work out of order.

---

## Part 4: Picking Up Where You Left Off

Your progress is saved automatically. When you come back:

```bash
cd ~/psm-program
claude
```

The plugin detects your existing project and shows a brief status. Run `/process-safety:status` to see the full dashboard, or `/process-safety:implement` to continue where you left off.

---

## Part 5: Validating Your Program

After generating, you can run the built-in quality checks:

```
/process-safety:test
```

This runs a 12-point audit-ready checklist against your generated documents and tells you exactly what passes and what needs attention. It checks things like:
- Every regulation clause has a mapped document
- Every document has proper controlled headers
- Every form reference actually exists as a file
- No placeholder company names left in the documents
- Gap register is populated and tracked

---

## Troubleshooting

### "Unknown skill: process-safety:help"

The plugin isn't loaded. Try:
1. Type `/plugin` and check if process-safety is installed and enabled
2. If not installed: `/plugin install process-safety@h2colby-process-safety`
3. If installed but not working: `/exit`, then `claude` to restart

### "command not found: claude"

Claude Code isn't installed or not in your PATH. Try:
```bash
npm install -g @anthropic-ai/claude-code
```

### "command not found: node" or "command not found: npm"

Node.js isn't installed. Go back to Step 1.2.

### "Permission denied" errors

On Mac/Linux, prefix the command with `sudo`:
```bash
sudo npm install -g @anthropic-ai/claude-code
```

### Plugin seems outdated

Update it:
```
/plugin update process-safety@h2colby-process-safety
```
Then restart Claude Code.

### Something else went wrong

Copy the error message and paste it into a regular Claude chat (https://claude.ai) or into Claude Code itself:

```
I'm trying to install the process-safety plugin for Claude Code and got this error: [paste error here]. How do I fix it?
```

AI is genuinely good at debugging installation issues. Give it the exact error text and it will usually know what's wrong.

---

## What You'll End Up With

After completing the full workflow, your `psm-program/` folder will contain:

```
PSM_PROGRAM/
  00_MASTER/          ← Master manual, crosswalk, gap register, screening report
  01-14_ELEMENTS/     ← 14 procedure documents (one per PSM element)
  90_FORMS/           ← 13 ready-to-use forms
  92_REGISTERS/       ← 7 tracking registers
  93_REFERENCE/OCA/   ← Offsite consequence analysis reports
  95_RMP/             ← 9-document EPA RMP submission package
```

This is a complete, audit-ready process safety management program and RMP submission package. The documents have your company name, your people's names, your chemicals, your processes — not generic templates.

---

## Quick Reference

| Command | What it does | When to use it |
|---|---|---|
| `/process-safety:help` | Show overview and commands | First time, or when you forget a command |
| `/process-safety:screen` | Check if PSM/RMP applies | Before anything else |
| `/process-safety:generate` | Build your 41-document program | After screening |
| `/process-safety:oca` | Calculate release distances | After generation, if RMP applies |
| `/process-safety:rmp` | Build EPA submission package | After OCA |
| `/process-safety:status` | See progress dashboard | Anytime |
| `/process-safety:implement` | Get guided next steps | When you're ready to work |
| `/process-safety:test` | Validate your program | After generation or anytime |

---

## Questions?

If you get stuck at any point, just ask Claude Code directly. Type your question in plain English:

```
I just finished screening and it says I need PSM. What should I do next?
```

```
What does "REQUIRES COMPANY INPUT" mean in my gap register?
```

```
How do I update my program after we add a new chemical?
```

Claude Code with this plugin has the full regulatory knowledge of 29 CFR 1910.119 and 40 CFR Part 68 built in. It's designed to answer process safety questions in context.
