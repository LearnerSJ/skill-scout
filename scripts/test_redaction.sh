#!/usr/bin/env bash
# test_redaction.sh v1.2.1 - Verify redact_secrets.sh works correctly
#
# Test fixtures are assembled at runtime to avoid triggering GitHub's
# secret scanner (which would otherwise flag the literal patterns).
#
# Run BEFORE deploying log_prompt.sh changes.
# Usage: bash test_redaction.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/redact_secrets.sh"

passed=0
failed=0
total=0

run_test() {
  local name="$1"
  local input="$2"
  local should_contain="$3"
  local should_not_contain="$4"

  total=$((total + 1))
  local output
  output=$(echo "$input" | redact_secrets)

  local ok=true

  if [ -n "$should_contain" ] && ! echo "$output" | grep -q "$should_contain"; then
    ok=false
  fi

  if [ -n "$should_not_contain" ] && echo "$output" | grep -qF "$should_not_contain"; then
    ok=false
  fi

  if $ok; then
    echo "PASS: $name"
    passed=$((passed + 1))
  else
    echo "FAIL: $name"
    echo "  Input:    $input"
    echo "  Output:   $output"
    echo "  Expected to contain:     $should_contain"
    echo "  Expected NOT to contain: $should_not_contain"
    failed=$((failed + 1))
  fi
}

# ====================================================================
# Build fake test fixtures at runtime.
# These strings are constructed via concatenation so the literal
# patterns never appear in this source file (avoids GitHub secret
# scanner false positives on test fixtures).
# ====================================================================

# Anthropic key fixture
ANT_PREFIX="sk-"
ANT_PREFIX="${ANT_PREFIX}ant-api03-"
ANT_BODY="AAAABBBBCCCCDDDDEEEEFFFFGGGGHHHHIIIIJJJJ"
ANTHROPIC_FAKE="${ANT_PREFIX}${ANT_BODY}"

# OpenAI key fixtures
OAI_PREFIX="sk-"
OAI_BODY="AbCdEfGhIjKlMnOpQrStUvWxYz1234567890ABCD"
OAI_LEGACY_FAKE="${OAI_PREFIX}${OAI_BODY}"

OAI_PROJ_PREFIX="sk-"
OAI_PROJ_PREFIX="${OAI_PROJ_PREFIX}proj-"
OAI_PROJ_FAKE="${OAI_PROJ_PREFIX}AbCdEfGhIjKlMnOpQrStUvWxYz1234567890"

# GitHub classic token
GH_PREFIX="ghp_"
GH_BODY="AbCdEfGhIjKlMnOpQrStUvWxYz12345678AB"
GH_CLASSIC_FAKE="${GH_PREFIX}${GH_BODY}"

# GitHub fine-grained token
GH_PAT_PREFIX="github_pat_"
GH_PAT_FAKE="${GH_PAT_PREFIX}11ABCDEFGHIJKLMNOP_abcdefghijklmnop"

# AWS keys
AWS_KEY_PREFIX="AKIA"
AWS_KEY_FAKE="${AWS_KEY_PREFIX}IOSFODNN7EXAMPLE"
AWS_SECRET_FAKE="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

# Slack token - split to avoid scanner
SLACK_PREFIX="xox"
SLACK_PREFIX="${SLACK_PREFIX}b-"
SLACK_FAKE="${SLACK_PREFIX}1234567890-abcdefghijklmnop"

# Google API key
GOOGLE_PREFIX="AI"
GOOGLE_PREFIX="${GOOGLE_PREFIX}za"
GOOGLE_FAKE="${GOOGLE_PREFIX}SyAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAaAa"

# Stripe key - split to avoid scanner
STRIPE_PREFIX="sk_"
STRIPE_PREFIX="${STRIPE_PREFIX}live_"
STRIPE_FAKE="${STRIPE_PREFIX}AbCdEfGhIjKlMnOpQrStUvWx"

# JWT
JWT_HEADER="eyJ"
JWT_HEADER="${JWT_HEADER}hbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
JWT_PAYLOAD="eyJ"
JWT_PAYLOAD="${JWT_PAYLOAD}zdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIn0"
JWT_SIG="SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
JWT_FAKE="${JWT_HEADER}.${JWT_PAYLOAD}.${JWT_SIG}"

# Bearer fake
BEARER_FAKE="abc123def456ghi789jkl012mno345pqr"

# Private key block
PK_BEGIN="-----BEGIN RSA PRIVATE KEY-----"
PK_END="-----END RSA PRIVATE KEY-----"
PK_BLOCK="${PK_BEGIN}\nMIIEpAIBAAKCAQEA1234567890\n${PK_END}"

echo "Running redaction tests..."
echo

# ====================================================================
# Tests
# ====================================================================

run_test "Anthropic API key" \
  "My key is ${ANTHROPIC_FAKE} here" \
  "REDACTED_ANTHROPIC_KEY" \
  "${ANT_BODY}"

run_test "OpenAI legacy API key" \
  "export OPENAI_KEY=${OAI_LEGACY_FAKE}" \
  "REDACTED_OPENAI_KEY" \
  "${OAI_BODY}"

run_test "OpenAI project API key" \
  "Using ${OAI_PROJ_FAKE}" \
  "REDACTED_OPENAI_KEY" \
  "AbCdEfGhIjKlMnOpQrSt"

run_test "GitHub personal access token (classic)" \
  "GH_TOKEN=${GH_CLASSIC_FAKE}" \
  "REDACTED_GITHUB_TOKEN" \
  "${GH_BODY}"

run_test "GitHub fine-grained token" \
  "Token: ${GH_PAT_FAKE}" \
  "REDACTED_GITHUB_TOKEN" \
  "11ABCDEFGHIJKLMNOP"

run_test "AWS access key ID" \
  "AWS_ACCESS_KEY_ID=${AWS_KEY_FAKE}" \
  "REDACTED_AWS_KEY_ID" \
  "${AWS_KEY_FAKE}"

run_test "AWS secret access key" \
  "aws_secret_access_key=${AWS_SECRET_FAKE}" \
  "REDACTED_AWS_SECRET" \
  "${AWS_SECRET_FAKE}"

run_test "Slack bot token" \
  "Webhook: ${SLACK_FAKE}" \
  "REDACTED_SLACK_TOKEN" \
  "1234567890-abcdef"

run_test "Google API key" \
  "key: ${GOOGLE_FAKE}" \
  "REDACTED_GOOGLE_KEY" \
  "SyAaAaAaAaAaAa"

run_test "Stripe secret key" \
  "STRIPE_KEY=${STRIPE_FAKE}" \
  "REDACTED_STRIPE_KEY" \
  "AbCdEfGhIjKlMnOp"

run_test "JWT token" \
  "Authorization: ${JWT_FAKE}" \
  "REDACTED_JWT" \
  "${JWT_HEADER}"

run_test "Bearer token in Authorization header" \
  "curl -H 'Authorization: Bearer ${BEARER_FAKE}' api.example.com" \
  "REDACTED_BEARER" \
  "${BEARER_FAKE}"

run_test "Generic password assignment" \
  "password=MySuperSecret123!" \
  "REDACTED" \
  "MySuperSecret123"

run_test "API_KEY assignment" \
  "API_KEY: secretvalue12345abcdef" \
  "REDACTED" \
  "secretvalue12345abcdef"

run_test "RSA private key block" \
  "${PK_BLOCK}" \
  "REDACTED_PRIVATE_KEY" \
  "MIIEpAIBAAKCAQEA"

run_test "Credit card number with dashes" \
  "Card: 4111-1111-1111-1111" \
  "REDACTED_POSSIBLE_CC" \
  "4111-1111-1111-1111"

run_test "Normal text - not redacted" \
  "Please help me debug this CashRecon Agent architecture" \
  "" \
  "REDACTED"

run_test "Code with variable names - not redacted" \
  "let api_url = 'https://api.example.com/v1/users'" \
  "" \
  "REDACTED"

run_test "Plugin name with sk- but not a key (too short)" \
  "Look at sk-helper plugin" \
  "" \
  "REDACTED"

echo
echo "─────────────────────────────────────"
echo "Results: $passed passed, $failed failed, $total total"

if [ $failed -gt 0 ]; then
  echo "FAILED - do not deploy yet"
  exit 1
else
  echo "All tests passed - safe to deploy"
  exit 0
fi
