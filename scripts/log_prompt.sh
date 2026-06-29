#!/usr/bin/env bash
# UserPromptSubmit hook: append prompt + timestamp to usage log.
# Hook input arrives on stdin as JSON: {"prompt": "...", "session_id": "...", ...}

set -euo pipefail
LOG_DIR="$(dirname "$0")/../data"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/usage.jsonl"

# Read stdin, add timestamp, append.
input=$(cat)
ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Compact one-line record. Trust hook JSON is valid.
printf '{"ts":"%s","payload":%s}\n' "$ts" "$input" >> "$LOG"

# Cap log at last 2000 lines.
if [ "$(wc -l < "$LOG")" -gt 2000 ]; then
  tail -n 2000 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

exit 0
