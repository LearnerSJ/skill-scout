# Contributing to Skill Scout

Thanks for your interest in contributing. This document outlines how to propose changes.

## Before you start

1. Check [PUBLISH.md](./PUBLISH.md) — it lists known gaps and priorities
2. Search [open issues](https://github.com/LearnerSJ/skill-scout/issues) — your idea may already be tracked
3. For non-trivial changes, **open an issue first** to discuss the approach before writing code

## Principles

These are non-negotiable:

1. **Privacy first.** Prompt content stays local. Marketplace queries send only extracted keywords, never raw prompts.
2. **Approval required.** The skill never installs, modifies hooks, or publishes anything without explicit user consent.
3. **Anti-noise.** Filter system messages, task notifications, and tool-use boilerplate so suggestions reflect real intent.
4. **Self-aware.** Always check `~/.claude/skills/` and `~/.agents/skills/` before suggesting installs — never recommend something the user already has.

## Development setup

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/skill-scout.git
cd skill-scout

# Install for local testing
ln -s "$(pwd)" ~/.claude/skills/skill-scout-dev
~/.claude/skills/skill-scout-dev/scripts/install.sh

# Restart Claude Code, then verify
# /skill-scout status
```

## Testing changes

Before submitting a PR, test on a clean Claude Code session:

1. Run `/skill-scout status` — confirms basic discovery works
2. Run `/skill-scout scan` — confirms analyzer runs end-to-end
3. Toggle modes (`daily`, `manual`, `off`) — confirms settings.json edits are correct
4. Check that `data/usage.jsonl` is still gitignored after your changes

## Code style

- **Shell scripts**: `set -euo pipefail` at the top, use `$(dirname "$0")` for portable paths
- **Python**: Standard library only where possible; add to a `requirements.txt` if new deps are needed
- **No external network calls** other than to documented marketplace APIs
- **No `eval`, no `subprocess shell=True`, no curl-piped-to-shell** — security review will reject these

## Pull request checklist

- [ ] Privacy guarantees intact (no new external transmission of prompt content)
- [ ] Approval gate preserved (no silent installs or modifications)
- [ ] Tested on clean Claude Code session
- [ ] `data/usage.jsonl` still excluded by `.gitignore`
- [ ] README and/or CHANGELOG updated if behavior changes
- [ ] No new external dependencies without discussion

## Reporting issues

When opening an issue, please include:

- Claude Code version (`claude --version`)
- OS (macOS / Linux distribution)
- Output of `/skill-scout status`
- Steps to reproduce
- Expected vs actual behavior

## Questions

Open a [Discussion](https://github.com/LearnerSJ/skill-scout/discussions) for general questions, or an issue for bugs and feature requests.
