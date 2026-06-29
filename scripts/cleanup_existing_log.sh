#!/usr/bin/env bash
# cleanup_existing_log.sh - One-time cleanup of historical usage.jsonl
#
# Applies the same redaction patterns to your existing 256+ logged prompts.
# Creates a backup first - safe to run.
#
# Usage:
#   bash cleanup_existing_log.sh
#
# What it does:
#   1. Backs up data/usage.jsonl to data/usage.jsonl.pre-redaction.bak
#   2. Reads each line, applies redaction, writes back to data/usage.jsonl
#   3. Reports how many entries had secrets redacted

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="$SCRIPT_DIR/../data/usage.jsonl"
BACKUP="$LOG.pre-redaction.bak"

if [ ! -f "$LOG" ]; then
  echo "No log file found at $LOG - nothing to clean"
  exit 0
fi

# Source the redaction helper
source "$SCRIPT_DIR/redact_secrets.sh"

# Backup
cp "$LOG" "$BACKUP"
echo "Backup created at: $BACKUP"

original_lines=$(wc -l < "$LOG")
echo "Original entries: $original_lines"

# Process each line
tmp=$(mktemp)
redacted_count=0
unchanged_count=0
failed_count=0

while IFS= read -r line; do
  redacted=$(echo "$line" | redact_secrets)

  if [ -z "$redacted" ]; then
    # Redaction failed - drop this entry
    failed_count=$((failed_count + 1))
    continue
  fi

  if [ "$line" != "$redacted" ]; then
    redacted_count=$((redacted_count + 1))
  else
    unchanged_count=$((unchanged_count + 1))
  fi

  echo "$redacted" >> "$tmp"
done < "$LOG"

# Replace original with cleaned version
mv "$tmp" "$LOG"

echo
echo "Cleanup complete:"
echo "  Entries scanned:   $original_lines"
echo "  Had secrets:       $redacted_count"
echo "  No changes needed: $unchanged_count"
echo "  Failed/dropped:    $failed_count"
echo
echo "Original backed up at: $BACKUP"
echo "Cleaned version at:    $LOG"
echo
echo "If everything looks right, you can delete the backup with:"
echo "  rm $BACKUP"
echo
echo "If something went wrong, restore the original with:"
echo "  mv $BACKUP $LOG"
