#!/usr/bin/env bash
# Symlink-based installer for superpower-custom into the parent workspace.
# Idempotent: re-running updates symlinks without error.
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(dirname "$SOURCE_DIR")"

RULES_DIR="$WORKSPACE/.clinerules"
WORKFLOWS_DIR="$RULES_DIR/workflows"
SKILLS_DIR="$WORKSPACE/.cline/skills"

mkdir -p "$RULES_DIR" "$WORKFLOWS_DIR" "$SKILLS_DIR"

# 1. Bootstrap rule
if [ -f "$SOURCE_DIR/rules/00-bootstrap.md" ]; then
  ln -sfn "$SOURCE_DIR/rules/00-bootstrap.md" "$RULES_DIR/00-bootstrap.md"
fi

# 1b. Inline using-superpowers as a rule (this branch)
# Cline reads every .md under .clinerules/ on every turn, so this
# guarantees the skill content is always present in the agent's context.
inline_skill_src="$SOURCE_DIR/skills/using-superpowers/SKILL.md"
if [ -f "$inline_skill_src" ]; then
  ln -sfn "$inline_skill_src" "$RULES_DIR/01-using-superpowers.md"
fi

# 2. Workflows
for wf in brainstorm write-plan execute-plan; do
  if [ -f "$SOURCE_DIR/workflows/$wf.md" ]; then
    ln -sfn "$SOURCE_DIR/workflows/$wf.md" "$WORKFLOWS_DIR/$wf.md"
  fi
done

# 3. Skills — link every subfolder
for skill_dir in "$SOURCE_DIR/skills/"*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  ln -sfn "$skill_dir" "$SKILLS_DIR/$name"
done

# Report
echo "Installed superpower-custom into $WORKSPACE"
echo "  Rules:     $RULES_DIR"
echo "  Workflows: $WORKFLOWS_DIR"
skill_count=$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
echo "  Skills:    $SKILLS_DIR ($skill_count linked)"
