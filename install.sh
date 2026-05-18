#!/usr/bin/env bash
# Symlink-based installer for superpower-custom into the parent workspace.
# Idempotent: re-running updates symlinks without error.
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(dirname "$SOURCE_DIR")"

RULES_DIR="$WORKSPACE/.clinerules"
WORKFLOWS_DIR="$RULES_DIR/workflows"
HOOKS_DIR="$RULES_DIR/hooks"
SKILLS_DIR="$WORKSPACE/.cline/skills"

mkdir -p "$RULES_DIR" "$WORKFLOWS_DIR" "$SKILLS_DIR"

# 1. Bootstrap rule
if [ -f "$SOURCE_DIR/rules/00-bootstrap.md" ]; then
  ln -sfn "$SOURCE_DIR/rules/00-bootstrap.md" "$RULES_DIR/00-bootstrap.md"
fi

# 2. Workflows
for wf in brainstorm write-plan execute-plan; do
  if [ -f "$SOURCE_DIR/workflows/$wf.md" ]; then
    ln -sfn "$SOURCE_DIR/workflows/$wf.md" "$WORKFLOWS_DIR/$wf.md"
  fi
done

# 3. Hooks — symlink the entire hooks/ folder so Cline can pick the
# right script (TaskStart for *nix, TaskStart.ps1 for Windows).
hooks_linked=0
if [ -d "$SOURCE_DIR/hooks" ]; then
  # Remove existing entry (file, dir, or symlink) before relinking.
  if [ -e "$HOOKS_DIR" ] || [ -L "$HOOKS_DIR" ]; then
    rm -rf "$HOOKS_DIR"
  fi
  ln -sfn "$SOURCE_DIR/hooks" "$HOOKS_DIR"
  hooks_linked=1
fi

# 4. Skills — link every subfolder
for skill_dir in "$SOURCE_DIR/skills/"*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  ln -sfn "$skill_dir" "$SKILLS_DIR/$name"
done

# Report
echo "Installed superpower-custom into $WORKSPACE"
echo "  Rules:     $RULES_DIR"
echo "  Workflows: $WORKFLOWS_DIR"
echo "  Hooks:     $HOOKS_DIR ($hooks_linked linked)"
skill_count=$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
echo "  Skills:    $SKILLS_DIR ($skill_count linked)"
