# Changelog

All notable changes to Skill Scout will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- TF-IDF or bigram keyword extraction (replace raw frequency)
- Secret redaction in logged prompts (`sk-*`, `ghp_*`, `AKIA*` patterns)
- 24-hour cache for marketplace search results
- Tool-use pattern analysis
- Test suite
- Community marketplace submission

## [1.1.0] - 2026-06-29

### Added
- `/skill-scout status` — show mode, logging state, prompt count, last analysis
- `/skill-scout daily` — enable daily auto-prompt mode via SessionStart hook
- `/skill-scout manual` — explicit manual mode with 14-day auto interval
- `/skill-scout off` — disable hooks while preserving data
- `/skill-scout scan` — alias for default analyzer trigger
- System-message and task-notification filtering in analyzer (reduces keyword noise)

### Changed
- SKILL.md now documents full command routing for all 8 commands
- Unified command surface (analysis + mode control + setup/data)

## [1.0.0] - 2026-05-28

### Added
- Initial release
- Passive prompt logging via `UserPromptSubmit` hook
- `scripts/analyze.py` for pattern detection and marketplace querying
- `scripts/install.sh` for automated hook setup
- `/skill-scout` — run analyzer
- `/skill-scout install` — wire up hooks
- `/skill-scout clear` — reset usage log
- Local-only data storage in `data/usage.jsonl`
- Filters out already-installed skills before suggesting

[Unreleased]: https://github.com/LearnerSJ/skill-scout/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/LearnerSJ/skill-scout/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/LearnerSJ/skill-scout/releases/tag/v1.0.0
