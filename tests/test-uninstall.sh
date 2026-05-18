#!/usr/bin/env bash
# Test for uninstall.sh — verifies symlinks removed, source intact.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
WORKSPACE="$(dirname "$REPO_DIR")"

fail() { echo "FAIL: $1" >&2; exit 1; }

# Setup: install first
"$REPO_DIR/install.sh" >/dev/null

# Run uninstall
"$REPO_DIR/uninstall.sh" >/dev/null

# Assertions: workspace-side symlinks should be gone
[ ! -e "$WORKSPACE/.clinerules/00-bootstrap.md" ] || fail "bootstrap symlink not removed"
for wf in brainstorm write-plan execute-plan; do
  [ ! -e "$WORKSPACE/.clinerules/workflows/$wf.md" ] || fail "$wf workflow not removed"
done

# Skills dir should be empty (no symlinks our installer created)
remaining=$(find "$WORKSPACE/.cline/skills" -mindepth 1 -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
[ "$remaining" = "0" ] || fail "skill symlinks remain: $remaining"

# Source intact
[ -f "$REPO_DIR/install.sh" ] || fail "install.sh missing from source!"

echo "PASS: uninstall.sh test"
