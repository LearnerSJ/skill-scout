# Publish Checklist — skill-scout

## Must-do before submitting to marketplace

### Repo hygiene
- [ ] Create public GitHub repo `skill-scout` (or similar)
- [ ] Add `LICENSE` (MIT recommended)
- [ ] Add `README.md` — distinct from `SKILL.md`. Cover: what it does, install, usage, privacy, screenshots.
- [ ] Tag `claude-skill`, `claude-code` topics on the GitHub repo so it shows up in marketplace search

### Portability
- [x] Scripts use `$(dirname "$0")` — no hardcoded user paths
- [x] `analyze.py` checks both `~/.claude/skills/` and `~/.agents/skills/`
- [x] `install.sh` auto-detects its own location and writes correct hook paths
- [ ] Test install via `npx skills add <your-repo>` end-to-end on clean machine
- [ ] Document `jq` + `python3` as prereqs in README

### Quality
- [ ] Replace raw keyword freq with TF-IDF or bigram extraction (current "top words" = stopword noise)
- [ ] Cache GitHub search results (per keyword, 24h TTL) — avoid rate limits
- [ ] Handle GitHub 403/rate-limit gracefully — show clear message, suggest token
- [ ] Add `data/.gitignore` so `usage.jsonl` never ends up in a repo
- [ ] Redact obvious secrets from logged prompts (regex strip `sk-*`, `ghp_*`, `AKIA*`, etc.)
- [ ] Add opt-out: `data/disabled` sentinel file → all hooks exit immediately

### Tests
- [ ] `tests/test_analyze.py` — feed sample log, assert output shape
- [ ] `tests/test_log_prompt.sh` — pipe sample JSON, assert log appended
- [ ] `tests/test_session_check.sh` — empty log = silent, full log = JSON output
- [ ] CI: GitHub Actions running tests on macOS + Linux

### Security review
- [x] No `eval`, no `subprocess` shell=True, no curl piped to shell
- [x] Network calls only to `api.github.com` (predictable, rate-limited)
- [ ] Snyk + Socket scan via skills.sh (auto on first install)
- [ ] Document data collection clearly — prompt content stays local, never transmitted

### Marketplace metadata
- [ ] SKILL.md frontmatter `description` ≤200 chars, lists trigger phrases
- [ ] Screenshots / demo gif in README
- [ ] Tag risk level — this skill writes to settings.json, reads all prompts → call that out

## Nice-to-haves

- [ ] `/skill-scout install` command (instead of separate bash script)
- [ ] `/skill-scout pause` / `resume` toggles
- [ ] Tool-use pattern analysis (not just prompt keywords) — read session transcripts
- [ ] Suggestion explainability — show which prompts matched which keyword
- [ ] Local TUI for browsing/dismissing suggestions

## Submission

1. Push to GitHub with all of "Must-do" checked
2. Open PR / submit to https://skills.sh listing (or equivalent registry)
3. Verify `npx skills add <repo> --skill skill-scout` works on a clean machine
4. Announce once stable
