#!/usr/bin/env bash
# Test for install.sh — at this stage we only have install.sh itself, no rule/workflow/skill files yet.
# The test asserts install.sh runs cleanly, creates the target directories, and produces
# no broken symlinks. Task 6 will extend this test with bootstrap/workflow assertions.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
WORKSPACE="$(dirname "$REPO_DIR")"

fail() { echo "FAIL: $1" >&2; exit 1; }

# Setup: run install
"$REPO_DIR/install.sh" >/dev/null

# Assert target dirs were created
[ -d "$WORKSPACE/.clinerules" ] || fail ".clinerules dir not created"
[ -d "$WORKSPACE/.clinerules/workflows" ] || fail ".clinerules/workflows dir not created"
[ -d "$WORKSPACE/.cline/skills" ] || fail ".cline/skills dir not created"

# Any symlinks already created must resolve (no broken links)
for link in "$WORKSPACE/.clinerules/00-bootstrap.md" \
            "$WORKSPACE/.clinerules/workflows/"*.md \
            "$WORKSPACE/.cline/skills/"*; do
  [ -e "$link" ] 2>/dev/null || [ ! -L "$link" ] || fail "broken symlink: $link"
done

echo "PASS: install.sh test"
