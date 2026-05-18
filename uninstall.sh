#!/usr/bin/env bash
# Remove symlinks installed by install.sh. Source files untouched.
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(dirname "$SOURCE_DIR")"

RULES_DIR="$WORKSPACE/.clinerules"
WORKFLOWS_DIR="$RULES_DIR/workflows"
SKILLS_DIR="$WORKSPACE/.cline/skills"

removed=0

# Bootstrap
if [ -L "$RULES_DIR/00-bootstrap.md" ]; then
  rm "$RULES_DIR/00-bootstrap.md"
  removed=$((removed + 1))
fi

# Workflows
for wf in brainstorm write-plan execute-plan; do
  if [ -L "$WORKFLOWS_DIR/$wf.md" ]; then
    rm "$WORKFLOWS_DIR/$wf.md"
    removed=$((removed + 1))
  fi
done

# Skills — only remove symlinks (not real folders) that point into our source
if [ -d "$SKILLS_DIR" ]; then
  for link in "$SKILLS_DIR"/*; do
    [ -L "$link" ] || continue
    target="$(readlink "$link")"
    case "$target" in
      "$SOURCE_DIR"/skills/*|../*"superpower-custom/skills/"*)
        rm "$link"
        removed=$((removed + 1))
        ;;
    esac
  done
fi

echo "Removed $removed symlinks. Source kept at $SOURCE_DIR."
