#!/usr/bin/env bash
# Verify symlinks installed by install.sh exist and resolve. Exits non-zero on any problem.
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(dirname "$SOURCE_DIR")"

RULES_DIR="$WORKSPACE/.clinerules"
WORKFLOWS_DIR="$RULES_DIR/workflows"
HOOKS_DIR="$RULES_DIR/hooks"
SKILLS_DIR="$WORKSPACE/.cline/skills"

problems=0
# Check that, if the source file exists, the symlink exists and resolves.
# Skips checks for source files that don't exist yet (staged install).
check_link() {
  local source_path="$1"
  local link_path="$2"
  if [ ! -e "$source_path" ]; then
    return  # source doesn't exist; install.sh would have skipped it
  fi
  if [ ! -L "$link_path" ]; then
    echo "MISSING symlink: $link_path"
    problems=$((problems + 1))
    return
  fi
  if [ ! -e "$link_path" ]; then
    echo "BROKEN symlink (target missing): $link_path -> $(readlink "$link_path")"
    problems=$((problems + 1))
  fi
}

# Bootstrap
check_link "$SOURCE_DIR/rules/00-bootstrap.md" "$RULES_DIR/00-bootstrap.md"

# Workflows
for wf in brainstorm write-plan execute-plan; do
  check_link "$SOURCE_DIR/workflows/$wf.md" "$WORKFLOWS_DIR/$wf.md"
done

# Hooks folder symlink (with-hooks branch)
hooks_present=0
if [ -d "$SOURCE_DIR/hooks" ]; then
  if [ ! -L "$HOOKS_DIR" ]; then
    echo "MISSING symlink: $HOOKS_DIR"
    problems=$((problems + 1))
  elif [ ! -e "$HOOKS_DIR" ]; then
    echo "BROKEN symlink (target missing): $HOOKS_DIR -> $(readlink "$HOOKS_DIR")"
    problems=$((problems + 1))
  else
    for hook in TaskStart TaskStart.ps1; do
      if [ ! -f "$HOOKS_DIR/$hook" ]; then
        echo "Hook script missing: $HOOKS_DIR/$hook"
        problems=$((problems + 1))
      fi
    done
    hooks_present=1
  fi
fi

# Skills — count and verify SKILL.md exists in each
if [ -d "$SKILLS_DIR" ]; then
  for link in "$SKILLS_DIR"/*; do
    [ -L "$link" ] || continue
    if [ ! -e "$link" ]; then
      echo "BROKEN skill symlink: $link"
      problems=$((problems + 1))
      continue
    fi
    if [ ! -f "$link/SKILL.md" ]; then
      echo "SKILL.md missing in: $link"
      problems=$((problems + 1))
    fi
  done
fi

skill_count=$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
total=$((1 + 3 + hooks_present + skill_count))

if [ "$problems" -eq 0 ]; then
  echo "OK: $total symlinks installed (1 rule + 3 workflows + $hooks_present hooks + $skill_count skills)"
  exit 0
else
  echo "FAIL: $problems problem(s) found"
  exit 1
fi
