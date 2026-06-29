#!/usr/bin/env bash
# Auto-wire skill-scout hooks into ~/.claude/settings.json regardless of
# where this skill is installed (~/.claude/skills/, ~/.agents/skills/, etc.).

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS="$HOME/.claude/settings.json"

command -v jq >/dev/null || { echo "jq required. brew install jq"; exit 1; }
command -v python3 >/dev/null || { echo "python3 required."; exit 1; }

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

# Merge in hooks without clobbering existing entries.
tmp=$(mktemp)
jq --arg log "$SCRIPTS_DIR/log_prompt.sh" \
   --arg sess "$SCRIPTS_DIR/session_check.sh" '
  .hooks //= {}
  | .hooks.UserPromptSubmit //= []
  | .hooks.SessionStart //= []
  | .hooks.UserPromptSubmit += [{matcher: "", hooks: [{type: "command", command: $log}]}]
  | .hooks.SessionStart    += [{matcher: "", hooks: [{type: "command", command: $sess}]}]
' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"

echo "Hooks wired to $SCRIPTS_DIR"
echo "Open /hooks (UI) once to reload, or restart Claude Code."
