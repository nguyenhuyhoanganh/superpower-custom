#!/usr/bin/env bash
# Test for verify-install.sh — smoke test: script runs without error after install.
# Real verification (1+3+13=17 symlinks) happens in Task 20 after all source files exist.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
WORKSPACE="$(dirname "$REPO_DIR")"

fail() { echo "FAIL: $1" >&2; exit 1; }

# Script must exist and be executable
[ -x "$REPO_DIR/verify-install.sh" ] || fail "verify-install.sh not executable"

# Install (idempotent) then verify
"$REPO_DIR/install.sh" >/dev/null
"$REPO_DIR/verify-install.sh" >/dev/null || fail "verify-install.sh failed unexpectedly"

# Detect a real problem: create a broken skill symlink, verify should now fail
mkdir -p "$WORKSPACE/.cline/skills"
broken_link="$WORKSPACE/.cline/skills/__broken_test__"
ln -sfn "$REPO_DIR/nonexistent-skill" "$broken_link"
if "$REPO_DIR/verify-install.sh" >/dev/null 2>&1; then
  rm -f "$broken_link"
  fail "verify-install passed despite broken symlink"
fi
rm -f "$broken_link"

echo "PASS: verify-install.sh test"
