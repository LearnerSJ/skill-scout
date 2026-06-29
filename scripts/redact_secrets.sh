#!/usr/bin/env bash
# redact_secrets.sh v1.2.3 - Strip sensitive patterns from text before logging
#
# Usage:
#   echo "your text" | redact_secrets
#   OR (when sourced):
#   redacted=$(redact_secrets <<< "$input")
#
# Reads stdin, writes redacted text to stdout.

redact_secrets() {
  # Pass the perl script via -e flag wrapped in single quotes.
  # \x27 is used for apostrophe (single-quote) to keep the bash quoting intact.
  perl -e '
while (my $text = <STDIN>) {
  # Private key blocks
  $text =~ s/-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----/[REDACTED_PRIVATE_KEY]/g;
  $text =~ s/-----BEGIN [A-Z ]*PRIVATE KEY-----/[REDACTED_PRIVATE_KEY_HEADER]/g;

  # JWT tokens (3 base64-url segments separated by dots, starting with eyJ)
  $text =~ s/eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}/[REDACTED_JWT]/g;

  # Anthropic API keys
  $text =~ s/sk-ant-api[0-9]{2}-[A-Za-z0-9_\-]{20,}/[REDACTED_ANTHROPIC_KEY]/g;
  $text =~ s/sk-ant-[A-Za-z0-9_\-]{20,}/[REDACTED_ANTHROPIC_KEY]/g;

  # OpenAI API keys
  $text =~ s/sk-proj-[A-Za-z0-9_\-]{20,}/[REDACTED_OPENAI_KEY]/g;
  $text =~ s/sk-[A-Za-z0-9]{32,}/[REDACTED_OPENAI_KEY]/g;

  # GitHub tokens
  $text =~ s/ghp_[A-Za-z0-9]{36,}/[REDACTED_GITHUB_TOKEN]/g;
  $text =~ s/ghs_[A-Za-z0-9]{36,}/[REDACTED_GITHUB_TOKEN]/g;
  $text =~ s/gho_[A-Za-z0-9]{36,}/[REDACTED_GITHUB_TOKEN]/g;
  $text =~ s/ghu_[A-Za-z0-9]{36,}/[REDACTED_GITHUB_TOKEN]/g;
  $text =~ s/ghr_[A-Za-z0-9]{36,}/[REDACTED_GITHUB_TOKEN]/g;
  $text =~ s/github_pat_[A-Za-z0-9_]{20,}/[REDACTED_GITHUB_TOKEN]/g;

  # AWS access key IDs
  $text =~ s/\b(AKIA|ASIA)[0-9A-Z]{16}\b/[REDACTED_AWS_KEY_ID]/g;

  # AWS secret access keys
  $text =~ s/(aws_secret_access_key|AWS_SECRET_ACCESS_KEY)\s*[=:]\s*[A-Za-z0-9\/+=]{30,}/$1=[REDACTED_AWS_SECRET]/g;

  # Slack tokens
  $text =~ s/xox[abprs]-[A-Za-z0-9\-]{10,}/[REDACTED_SLACK_TOKEN]/g;

  # Google API keys
  $text =~ s/AIza[0-9A-Za-z_\-]{35}/[REDACTED_GOOGLE_KEY]/g;

  # Stripe keys
  $text =~ s/sk_live_[A-Za-z0-9]{24,}/[REDACTED_STRIPE_KEY]/g;
  $text =~ s/sk_test_[A-Za-z0-9]{24,}/[REDACTED_STRIPE_KEY]/g;
  $text =~ s/pk_live_[A-Za-z0-9]{24,}/[REDACTED_STRIPE_KEY]/g;

  # Bearer tokens
  $text =~ s/(Authorization:\s*Bearer\s+)[A-Za-z0-9_\-\.=]+/${1}[REDACTED_BEARER]/gi;
  $text =~ s/(\bBearer\s+)[A-Za-z0-9_\-\.=]{20,}/${1}[REDACTED_BEARER]/g;

  # Generic password/secret assignments (use \x22 for double-quote, \x27 for apostrophe)
  $text =~ s/(password|passwd|pwd|secret|api[_\-]?key|apikey|access[_\-]?token|auth[_\-]?token|private[_\-]?key)\s*[=:]\s*[\x22\x27]?[A-Za-z0-9_\-\.\/+=!@#\$%^&*()]{8,}[\x22\x27]?/$1=[REDACTED]/gi;

  # Credit card numbers
  $text =~ s/\b(?:\d[ \-]?){15,16}\d\b/[REDACTED_POSSIBLE_CC]/g;

  print $text;
}
'
}

# If sourced, just expose the function. If executed directly, run it on stdin.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  redact_secrets
fi
