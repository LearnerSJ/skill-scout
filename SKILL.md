---
name: skill-scout
description: Passively logs user prompts and tool calls, periodically analyzes patterns, suggests installable skills from skills.sh marketplace. Trigger /skill-scout to review suggestions and approve installs. Supports mode control via /skill-scout [daily|manual|off|scan|status|install|clear]. Auto-triggers on "what skills should I install", "scout skills", "/skill-scout".
---

# skill-scout

Watches how you actually use Claude Code and recommends skills that match your real workflow.

## How it works

1. Log hook - UserPromptSubmit hook appends each prompt to data/usage.jsonl
2. Analyzer - /skill-scout or /skill-scout scan invokes scripts/analyze.py which reads recent prompts, extracts recurring intents, queries skills.sh marketplace, filters already-installed skills, returns top suggestions
3. Approval - Claude presents suggestions; user approves; Claude runs npx skills add

## Commands

### Original analysis commands
- /skill-scout - analyze recent usage, show suggestions
- /skill-scout install - wire up the logging hook
- /skill-scout clear - reset usage log

### Mode control commands
- /skill-scout scan - run analyzer now (alias for /skill-scout)
- /skill-scout status - show mode, last analysis date, log size, config
- /skill-scout daily - enable daily auto-prompt mode
- /skill-scout manual - switch to manual mode (analyzer only when triggered)
- /skill-scout off - disable logging hook (preserves existing data)

## Mode Routing

When user invokes /skill-scout with an argument, route as follows:

**scan or no argument**: Run scripts/analyze.py against data/usage.jsonl. Present suggestions to user, await approval.

**status**: Display table with Mode, Logging hook state, Prompts logged count, Log window dates, Last analysis date, Data location, Data size. Read from data file and ~/.claude/settings.json.

**daily**: Update ~/.claude/settings.json to ensure SessionStart hook calls scripts/session_check.sh with --daily-prompt flag. Confirm: "Daily mode enabled. You will be prompted once per day."

**manual**: Update ~/.claude/settings.json to remove --daily-prompt flag from SessionStart hook. Keep UserPromptSubmit logging active. Confirm: "Manual mode enabled."

**off**: Remove UserPromptSubmit and SessionStart hooks from ~/.claude/settings.json. Preserve data/usage.jsonl. Confirm: "Skill Scout disabled. Logging stopped, existing data preserved. Use /skill-scout install to re-enable."

**install**: Original behavior. Write UserPromptSubmit and SessionStart hooks to ~/.claude/settings.json. Run scripts/install.sh.

**clear**: Original behavior. Truncate data/usage.jsonl. Ask for confirmation first.

## Privacy

All data local at ~/.claude/skills/skill-scout/data/usage.jsonl. No telemetry. Skill never auto-installs - always asks first. /skill-scout off stops collection but preserves history. /skill-scout clear deletes the log entirely.
