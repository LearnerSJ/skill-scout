# Skill Scout

> A Claude Code skill that watches how you actually use Claude Code, then recommends skills from the marketplace that match your real workflow — not generic suggestions.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skill-blueviolet)](https://claude.ai/code)
[![Status](https://img.shields.io/badge/status-beta-orange)]()

## What it does

Skill Scout passively logs your prompts to Claude Code, periodically analyzes recurring patterns, and suggests installable skills from the skills.sh marketplace that match what you actually do. It never auto-installs anything — every suggestion requires your explicit approval.

Think of it as a personal recommendation engine for Claude Code skills, driven by your real usage rather than generic popularity.

## Why use it

Most skill discovery happens by accident — you stumble across a skill in a marketplace, install it, then forget about it. Skill Scout flips this around:

- **Data-driven**: Recommends based on what you've actually been doing for the past N days
- **Privacy-first**: All logs stay local, nothing is transmitted
- **Anti-noise**: Filters system messages and task notifications so you get signal, not boilerplate
- **Approval-gated**: Never installs, modifies, or publishes anything without explicit consent
- **Self-aware**: Filters out skills you've already installed before suggesting

## Quick start

```bash
# Clone the repo
git clone https://github.com/LearnerSJ/skill-scout.git ~/.claude/skills/skill-scout

# Run the installer (wires up the logging hooks)
~/.claude/skills/skill-scout/scripts/install.sh

# Restart Claude Code, then verify:
# /skill-scout status
```

## Commands

### Analysis
| Command | What it does |
|---------|--------------|
| `/skill-scout` or `/skill-scout scan` | Run analyzer on logged prompts, show skill suggestions, await approval |
| `/skill-scout status` | Show mode, logging state, prompt count, log window, last analysis, data location and size |

### Mode control
| Command | What it does |
|---------|--------------|
| `/skill-scout daily` | Auto-prompt once per day (SessionStart hook with `--daily-prompt`) |
| `/skill-scout manual` | Analyzer only runs when triggered; logging stays active (14-day auto interval) |
| `/skill-scout off` | Disable both hooks, stop logging — preserves existing data |

### Setup / data
| Command | What it does |
|---------|--------------|
| `/skill-scout install` | Wire up the logging and SessionStart hooks |
| `/skill-scout clear` | Truncate the usage log (asks for confirmation first) |

## How it works

1. **Log hook** — A `UserPromptSubmit` hook appends each prompt to `data/usage.jsonl` (local file, never transmitted)
2. **Analyzer** — `/skill-scout scan` invokes `scripts/analyze.py` which:
   - Reads recent prompts from the log
   - Extracts recurring intents (keywords, tool patterns)
   - Queries the skills.sh marketplace search API for matches
   - Filters out skills already installed in `~/.agents/skills/` and `~/.claude/skills/`
   - Returns top suggestions with rationale
3. **Approval** — Claude presents suggestions, you approve each one, Claude runs `npx skills add` to install

## Privacy

**All data stays local.**

- Prompts are logged only to `~/.claude/skills/skill-scout/data/usage.jsonl`
- No telemetry, no external transmission of prompt content
- The marketplace search API receives only keyword queries (e.g., `python`, `pdf`, `schema`) — never raw prompts
- `/skill-scout off` stops collection while preserving history
- `/skill-scout clear` permanently deletes the log

**Recommended:** Add the included `.gitignore` rules so `data/usage.jsonl` is never committed to any repo.

## Requirements

- Claude Code v2.0+ (slash command and hook support required)
- `jq` (for JSON manipulation): `brew install jq`
- `python3` (for the analyzer): typically pre-installed on macOS/Linux
- macOS or Linux (Windows untested)

## Installation modes

Skill Scout supports two operating modes:

### Daily mode
The SessionStart hook checks once per day whether today's analysis has run. If not, it prompts you. Best for users who want gentle nudges without explicit triggering.

```
/skill-scout daily
```

### Manual mode
The logging hook stays active but the analyzer only runs when you ask. Best for users who want full control over when analysis happens.

```
/skill-scout manual
```

### Off
Both hooks are disabled. Existing data is preserved but no new prompts are logged. Re-enable with `/skill-scout install`.

```
/skill-scout off
```

## Configuration

Configuration lives in `~/.claude/settings.json` under the `hooks` section. The installer manages this for you, but if you need to edit manually:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/skills/skill-scout/scripts/log_prompt.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/skills/skill-scout/scripts/session_check.sh"
          }
        ]
      }
    ]
  }
}
```

## Folder structure

```
skill-scout/
├── SKILL.md                    # Main skill definition with command routing
├── PUBLISH.md                  # Pre-publication checklist (for maintainers)
├── README.md                   # This file
├── LICENSE                     # MIT
├── .gitignore                  # Excludes data/ from commits
├── scripts/
│   ├── install.sh              # Wires up hooks in ~/.claude/settings.json
│   ├── log_prompt.sh           # Hook that appends prompts to usage.jsonl
│   ├── session_check.sh        # SessionStart hook for daily mode
│   └── analyze.py              # Pattern detection + marketplace query
└── data/                       # Created on first run
    └── usage.jsonl             # Local prompt log (gitignored)
```

## Troubleshooting

### Slash commands not recognized

Make sure Claude Code is restarted after install:

```bash
exit
claude
```

Then verify the skill loads:

```bash
ls ~/.claude/skills/skill-scout/SKILL.md
```

### "Hooks not firing"

Check that hooks are registered in your settings:

```bash
grep -A 3 "skill-scout" ~/.claude/settings.json
```

If empty, re-run the installer:

```bash
bash ~/.claude/skills/skill-scout/scripts/install.sh
```

### "Analyzer returns noisy suggestions"

The analyzer's keyword extraction can be dominated by harness boilerplate (task notifications, system messages). Run `/skill-scout scan` and ask Claude to patch the filter — see the PUBLISH.md checklist for known issues.

### "Permission denied"

Make sure the scripts are executable:

```bash
chmod +x ~/.claude/skills/skill-scout/scripts/*.sh
```

## Roadmap

See [PUBLISH.md](./PUBLISH.md) for the full checklist. Highlights:

- [ ] Replace raw keyword frequency with TF-IDF or bigram extraction
- [ ] Cache marketplace search results (24h TTL)
- [ ] Add secret redaction in logged prompts (strip `sk-*`, `ghp_*`, `AKIA*`)
- [ ] Tool-use pattern analysis (not just prompt keywords)
- [ ] Suggestion explainability (show which prompts matched which keyword)
- [ ] Tests (analyze.py, log_prompt.sh, session_check.sh)
- [ ] Submit to Anthropic's community marketplace

## Contributing

Contributions welcome. Before opening a PR:

1. Check the [PUBLISH.md](./PUBLISH.md) checklist for known gaps
2. Open an issue first for non-trivial changes
3. Test on a clean machine (no existing skill-scout install)
4. Keep the privacy guarantees intact — no external transmission of prompt content

## License

MIT — see [LICENSE](./LICENSE).

## Author

Built by [Sullabh Jhamb](https://github.com/LearnerSJ).

If you find this useful, a GitHub star helps with discovery. Issues and feedback welcome.

## Acknowledgments

- Inspired by the broader Claude Code skills ecosystem
- Marketplace integration via [skills.sh](https://skills.sh)
- Built and tested with Claude Code

---

**Status:** Beta. Works reliably as a personal tool. Pre-publication checklist in PUBLISH.md before community marketplace submission.
