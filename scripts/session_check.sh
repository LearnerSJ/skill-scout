#!/usr/bin/env bash
# SessionStart hook: if log has enough data and we haven't checked recently,
# run analyzer and surface result via systemMessage.

set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$DIR/data/usage.jsonl"
LAST="$DIR/data/last_run.txt"
MIN_LINES=50
INTERVAL_DAYS=14

# Daily mode: --daily-prompt shrinks the check interval to once per day.
if [ "${1:-}" = "--daily-prompt" ]; then
  INTERVAL_DAYS=1
fi

[ -f "$LOG" ] || exit 0
lines=$(wc -l < "$LOG" | tr -d ' ')
[ "$lines" -ge "$MIN_LINES" ] || exit 0

now=$(date +%s)
if [ -f "$LAST" ]; then
  last=$(cat "$LAST")
  age_days=$(( (now - last) / 86400 ))
  [ "$age_days" -ge "$INTERVAL_DAYS" ] || exit 0
fi

echo "$now" > "$LAST"

"$DIR/scripts/analyze.py" 2>/dev/null | python3 -c '
import json, sys
try:
    result = json.load(sys.stdin)
except Exception:
    sys.exit(0)
suggestions = result.get("suggestions", [])[:5]
if not suggestions:
    sys.exit(0)
lines = ["skill-scout: based on your last " + str(result.get("prompts_analyzed", 0)) + " prompts, consider:"]
for s in suggestions:
    desc = (s.get("description") or "")[:80]
    lines.append("  - " + s["repo"] + " (" + str(s.get("stars", 0)) + "*) - " + desc)
msg = "\n".join(lines)
out = {
    "systemMessage": msg,
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": msg + "\n\nTo install: npx skills add <repo>"
    }
}
print(json.dumps(out))
'
