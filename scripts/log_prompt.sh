#!/usr/bin/env bash
# UserPromptSubmit hook: append prompt + timestamp to usage log.
# Hook input arrives on stdin as JSON: {"prompt": "...", "session_id": "...", ...}
#
# v1.2.0 - Adds secret redaction before logging.
# All sensitive patterns (API keys, tokens, credentials) are stripped from the
# prompt text before being written to data/usage.jsonl.
# See redact_secrets.sh for the full pattern list.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../data"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/usage.jsonl"

# Source the redaction helper
# shellcheck source=./redact_secrets.sh
source "$SCRIPT_DIR/redact_secrets.sh"

# Read stdin
input=$(cat)
ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Apply redaction to the entire JSON payload before logging.
# We redact the raw JSON string - this catches secrets in prompt text, session
# metadata, environment context, or any other field that may have been included.
# The JSON structure stays valid because redaction only replaces values, not braces/quotes.
redacted_input=$(echo "$input" | redact_secrets)

# Fail-safe: if redaction somehow produced empty output, drop this entry rather
# than write the unredacted original. Better to lose one prompt than leak a secret.
if [ -z "$redacted_input" ]; then
  printf '{"ts":"%s","payload":{"prompt":"[REDACTION_FAILED_ENTRY_DROPPED]"},"redaction_status":"failed"}\n' "$ts" >> "$LOG"
  exit 0
fi

# Track whether anything was redacted (for audit purposes)
if [ "$input" != "$redacted_input" ]; then
  redaction_status="applied"
else
  redaction_status="none"
fi

# Compact one-line record with redaction status flag.
printf '{"ts":"%s","payload":%s,"redaction_status":"%s"}\n' "$ts" "$redacted_input" "$redaction_status" >> "$LOG"

# Cap log at last 2000 lines.
if [ "$(wc -l < "$LOG")" -gt 2000 ]; then
  tail -n 2000 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

exit 0
