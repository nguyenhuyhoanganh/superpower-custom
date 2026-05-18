# Cline Superpowers Port — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the Superpowers framework into a Cline-compatible package (`superpower-custom/` repo) with a workspace-only symlink installer, 13 adapted skills, 3 slash-command workflows, and a bootstrap rule.

**Architecture:** Three layers — (1) `.clinerules/00-bootstrap.md` always loaded, (2) `.clinerules/workflows/{brainstorm,write-plan,execute-plan}.md` for explicit slash commands, (3) `.cline/skills/<name>/SKILL.md` loaded on demand via `use_skill`. Source of truth lives in this repo; install script creates symlinks into the workspace. Cline subagents are read-only and used for research / spec review / code-quality review only — main agent does all writes.

**Tech Stack:** Bash (install scripts), Markdown (skills, rules, workflows), Git (repo & commits). No runtime language. Target platform: Cline VSCode extension on macOS / Linux.

**Repo root:** `/Users/hoanganh/Workspace/cline-superpower/superpower-custom/` (git remote: `https://github.com/nguyenhuyhoanganh/superpower-custom.git`, branch `main`).

**Source for adaptation:** `/Users/hoanganh/Workspace/cline-superpower/superpowers/` (the upstream Superpowers repo, already cloned). All "read source" instructions refer to files under that path.

---

## Standard Skill-Port Procedure (referenced by tasks 7–18)

The eight transformations to apply when porting a SKILL.md from upstream to this repo:

1. **Tool names** (every occurrence, including in code fences and tables):
   - `Read` (the tool) → `read_file`
   - `Write` (the tool) → `editor` (write mode)
   - `Edit` (the tool) → `editor` (replace mode)
   - `Bash` (the tool) → `execute_command`
   - `Grep` (the tool) → `search_files`
   - `Glob` (the tool) → `list_files`
   - `Task` (the tool, for subagents) → "dispatch a Cline subagent"
   - `TodoWrite` → "track progress explicitly in your replies (Cline has no TodoWrite-equivalent — state checklist progress in natural language each turn)"
   - `WebFetch` → `fetch_web`
   - `Skill` (the tool) → `use_skill`
   - `EnterPlanMode` / `ExitPlanMode` → remove the reference entirely
   - `WebSearch` → "no direct Cline equivalent — use `fetch_web` with a search engine URL"

2. **Skill cross-references:** drop `superpowers:` prefix. `superpowers:test-driven-development` → `test-driven-development`.

3. **Drop references to removed skills:**
   - `using-git-worktrees` → `creating-feature-branch`
   - `writing-skills` → remove the line, or rephrase to "follow existing skill authoring conventions in this repo"

4. **Drop references to removed platform features:**
   - "Visual companion" / `visual-companion.md` references → remove the whole section
   - References to `render-graphs.js` → remove
   - "Use Task tool with agent type X" → "dispatch a Cline subagent with this prompt template"
   - "Never use the Read tool on skill files" → "Never `read_file` SKILL.md manually; always `use_skill` to load it"
   - `<SUBAGENT-STOP>` blocks (used by upstream hook) → remove (Cline subagents do not auto-load skills the same way)

5. **Frontmatter:** keep `name:` and `description:` from upstream verbatim unless the description mentions a removed feature. Names must match the skill folder name.

6. **Supporting files in the same skill folder:** apply transformations 1–4 to those too. Examples: `spec-document-reviewer-prompt.md`, `plan-document-reviewer-prompt.md`, `testing-anti-patterns.md`, `root-cause-tracing.md`, `defense-in-depth.md`, `condition-based-waiting.md`, `code-reviewer-prompt.md`.

7. **Skip these upstream files** when copying a skill folder:
   - `CREATION-LOG.md`
   - `test-pressure-*.md`, `test-academic.md`
   - `condition-based-waiting-example.ts` (TypeScript example — keep only the markdown)
   - `find-polluter.sh` (one-off script, not part of skill)
   - `visual-companion.md`, `scripts/*` (visual companion artifacts)
   - `render-graphs.js`, `graphviz-conventions.dot`, `anthropic-best-practices.md`, `persuasion-principles.md`, `testing-skills-with-subagents.md`, `examples/*` (writing-skills artifacts — skill itself is dropped)

8. **Verification commands** (run after each ported file):
   - `! grep -nE '\b(Read|Write|Edit|Bash|Grep|Glob|Task|TodoWrite|WebFetch|WebSearch|EnterPlanMode|ExitPlanMode)\b tool' <file>` → must return exit 1 (no matches)
   - `! grep -n 'superpowers:' <file>` → must return exit 1
   - `! grep -nE '\b(using-git-worktrees|writing-skills)\b' <file>` → must return exit 1
   - `! grep -n 'visual companion\|visual-companion' <file>` → must return exit 1 (case-insensitive)
   - File starts with YAML frontmatter containing `name:` and `description:` (for SKILL.md only)

---

## Task 1: Repo scaffolding

**Files:**
- Create: `superpower-custom/README.md`
- Create: `superpower-custom/.gitignore`
- Create: `superpower-custom/skills/.gitkeep`
- Create: `superpower-custom/workflows/.gitkeep`
- Create: `superpower-custom/rules/.gitkeep`

- [ ] **Step 1: Create `.gitignore`**

```
.DS_Store
*.swp
*.swo
*~
.idea/
.vscode/
node_modules/
```

- [ ] **Step 2: Create `README.md`**

```markdown
# Superpowers (Custom for Cline VSCode)

A port of the [Superpowers](https://github.com/obra/superpowers) framework
adapted for Cline running as a VSCode extension. Single-agent + read-only
subagents.

## Install

From the workspace root that contains this repo:

```bash
./superpower-custom/install.sh
```

This creates symlinks in `.clinerules/`, `.clinerules/workflows/`, and
`.cline/skills/` pointing into this repo. Edit the source here and Cline
sees the update on the next turn.

## Layout

- `rules/` — bootstrap rule appended to every system prompt
- `workflows/` — slash commands (`/brainstorm`, `/write-plan`, `/execute-plan`)
- `skills/` — 13 skills loaded on demand via `use_skill`
- `docs/superpowers/specs/` — design specs
- `docs/superpowers/plans/` — implementation plans

## Uninstall

```bash
./superpower-custom/uninstall.sh
```

Removes symlinks; source files untouched.

## Verify

```bash
./superpower-custom/verify-install.sh
```

Reports symlink health (expected: 17 symlinks resolving to existing files).
```

- [ ] **Step 3: Create empty `.gitkeep` placeholders so folders exist in git**

```bash
mkdir -p superpower-custom/skills superpower-custom/workflows superpower-custom/rules
touch superpower-custom/skills/.gitkeep
touch superpower-custom/workflows/.gitkeep
touch superpower-custom/rules/.gitkeep
```

- [ ] **Step 4: Verify folders exist**

Run: `cd superpower-custom && ls -la skills workflows rules`
Expected: each directory listed, containing `.gitkeep`.

- [ ] **Step 5: Commit**

```bash
cd superpower-custom
git add README.md .gitignore skills/.gitkeep workflows/.gitkeep rules/.gitkeep
git commit -m "chore: scaffold repo structure"
```

---

## Task 2: install.sh with test

**Files:**
- Create: `superpower-custom/install.sh`
- Create: `superpower-custom/tests/test-install.sh`

- [ ] **Step 1: Create `tests/test-install.sh` (failing test, minimal — bootstrap/workflow assertions added in Task 6)**

```bash
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
```

```bash
chmod +x superpower-custom/tests/test-install.sh
```

- [ ] **Step 2: Run test — verify it fails**

Run: `bash superpower-custom/tests/test-install.sh`
Expected: error like "No such file or directory: install.sh" (install.sh does not exist yet).

- [ ] **Step 3: Implement `install.sh`**

```bash
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
```

```bash
chmod +x superpower-custom/install.sh
```

- [ ] **Step 4: Run test — verify it passes**

Run: `bash superpower-custom/tests/test-install.sh`
Expected: `PASS: install.sh test`. (Bootstrap and workflow source files don't exist yet, so install.sh skips them via its `if [ -f ... ]` checks. No symlinks created at this stage means no broken symlinks. Task 6 adds the source files and extends this test.)

- [ ] **Step 5: Commit**

```bash
cd superpower-custom
git add install.sh tests/test-install.sh
git commit -m "feat(install): add install.sh with smoke test"
```

---

## Task 3: uninstall.sh with test

**Files:**
- Create: `superpower-custom/uninstall.sh`
- Create: `superpower-custom/tests/test-uninstall.sh`

- [ ] **Step 1: Create failing test `tests/test-uninstall.sh`**

```bash
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
```

```bash
chmod +x superpower-custom/tests/test-uninstall.sh
```

- [ ] **Step 2: Run test — verify it fails**

Run: `bash superpower-custom/tests/test-uninstall.sh`
Expected: "No such file or directory: uninstall.sh".

- [ ] **Step 3: Implement `uninstall.sh`**

```bash
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
```

```bash
chmod +x superpower-custom/uninstall.sh
```

- [ ] **Step 4: Run test — verify it passes**

Run: `bash superpower-custom/tests/test-uninstall.sh`
Expected: `PASS: uninstall.sh test`.

- [ ] **Step 5: Commit**

```bash
cd superpower-custom
git add uninstall.sh tests/test-uninstall.sh
git commit -m "feat(install): add uninstall.sh with smoke test"
```

---

## Task 4: verify-install.sh with test

**Files:**
- Create: `superpower-custom/verify-install.sh`
- Create: `superpower-custom/tests/test-verify-install.sh`

- [ ] **Step 1: Create failing test `tests/test-verify-install.sh`**

```bash
#!/usr/bin/env bash
# Test for verify-install.sh — confirms it returns 0 after install, non-zero before.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
WORKSPACE="$(dirname "$REPO_DIR")"

fail() { echo "FAIL: $1" >&2; exit 1; }

# Ensure clean state
"$REPO_DIR/uninstall.sh" >/dev/null 2>&1 || true

# Before install: verify should fail
if "$REPO_DIR/verify-install.sh" >/dev/null 2>&1; then
  fail "verify-install passed before install"
fi

# After install: verify should pass
"$REPO_DIR/install.sh" >/dev/null
"$REPO_DIR/verify-install.sh" >/dev/null || fail "verify-install failed after install"

echo "PASS: verify-install.sh test"
```

```bash
chmod +x superpower-custom/tests/test-verify-install.sh
```

- [ ] **Step 2: Run test — verify it fails**

Run: `bash superpower-custom/tests/test-verify-install.sh`
Expected: "No such file or directory: verify-install.sh".

- [ ] **Step 3: Implement `verify-install.sh`**

```bash
#!/usr/bin/env bash
# Verify symlinks installed by install.sh exist and resolve. Exits non-zero on any problem.
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(dirname "$SOURCE_DIR")"

RULES_DIR="$WORKSPACE/.clinerules"
WORKFLOWS_DIR="$RULES_DIR/workflows"
SKILLS_DIR="$WORKSPACE/.cline/skills"

problems=0
check_link() {
  local path="$1"
  if [ ! -L "$path" ]; then
    echo "MISSING symlink: $path"
    problems=$((problems + 1))
    return
  fi
  if [ ! -e "$path" ]; then
    echo "BROKEN symlink (target missing): $path -> $(readlink "$path")"
    problems=$((problems + 1))
  fi
}

# Bootstrap
check_link "$RULES_DIR/00-bootstrap.md"

# Workflows
for wf in brainstorm write-plan execute-plan; do
  check_link "$WORKFLOWS_DIR/$wf.md"
done

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
total=$((1 + 3 + skill_count))

if [ "$problems" -eq 0 ]; then
  echo "OK: $total symlinks installed (1 rule + 3 workflows + $skill_count skills)"
  exit 0
else
  echo "FAIL: $problems problem(s) found"
  exit 1
fi
```

```bash
chmod +x superpower-custom/verify-install.sh
```

- [ ] **Step 4: Run test — verify it passes**

Run: `bash superpower-custom/tests/test-verify-install.sh`
Expected: `PASS: verify-install.sh test`.

- [ ] **Step 5: Commit**

```bash
cd superpower-custom
git add verify-install.sh tests/test-verify-install.sh
git commit -m "feat(install): add verify-install.sh with smoke test"
```

---

## Task 5: INSTALL.md (usage docs)

**Files:**
- Create: `superpower-custom/INSTALL.md`

- [ ] **Step 1: Create `INSTALL.md`**

```markdown
# Installation Guide

## Prerequisites

- macOS or Linux (Windows symlinks need `mklink`; not supported in this version)
- Bash 4+
- Git
- Cline VSCode extension installed

## Install

The installer assumes this repo lives at `<workspace>/superpower-custom/`
where `<workspace>` is the VSCode workspace root that Cline reads.

```bash
cd <workspace>
./superpower-custom/install.sh
```

After install, the following symlinks exist:

```
<workspace>/.clinerules/00-bootstrap.md             → superpower-custom/rules/00-bootstrap.md
<workspace>/.clinerules/workflows/brainstorm.md     → superpower-custom/workflows/brainstorm.md
<workspace>/.clinerules/workflows/write-plan.md     → superpower-custom/workflows/write-plan.md
<workspace>/.clinerules/workflows/execute-plan.md   → superpower-custom/workflows/execute-plan.md
<workspace>/.cline/skills/<skill-name>              → superpower-custom/skills/<skill-name>/
                                                       (one symlink per skill, 13 total)
```

## Verify

```bash
./superpower-custom/verify-install.sh
```

Expected: `OK: 17 symlinks installed (1 rule + 3 workflows + 13 skills)`.

## Uninstall

```bash
./superpower-custom/uninstall.sh
```

Removes symlinks only. Source code in `superpower-custom/` is untouched.

## How updates work

Symlinks point at source files, so editing anything under `superpower-custom/`
takes effect the next time Cline reads the file. No re-install needed.

## Open Cline in this workspace

After install, restart your Cline VSCode session (or open the workspace
folder in VSCode). On the first turn Cline reads `.clinerules/00-bootstrap.md`
and loads `using-superpowers` via `use_skill`.
```

- [ ] **Step 2: Verify file exists and renders**

Run: `head -20 superpower-custom/INSTALL.md`
Expected: starts with `# Installation Guide`.

- [ ] **Step 3: Commit**

```bash
cd superpower-custom
git add INSTALL.md
git commit -m "docs: add INSTALL.md"
```

---

## Task 6: Bootstrap rule + 3 workflows

**Files:**
- Create: `superpower-custom/rules/00-bootstrap.md`
- Create: `superpower-custom/workflows/brainstorm.md`
- Create: `superpower-custom/workflows/write-plan.md`
- Create: `superpower-custom/workflows/execute-plan.md`
- Modify: `superpower-custom/tests/test-install.sh` (re-enable bootstrap/workflow assertions)

- [ ] **Step 1: Create `rules/00-bootstrap.md`**

```markdown
# Superpowers — Bootstrap

This workspace uses the Superpowers framework. At the start of every
session, BEFORE replying to any message (including clarifying questions),
load the `using-superpowers` skill via `use_skill`. That skill defines
how you use the other skills.

**Rule:** if there is ≥1% chance the user's request matches a skill's
description, load that skill and follow it exactly. User instructions
always override skills when they conflict.
```

- [ ] **Step 2: Create `workflows/brainstorm.md`**

```markdown
# /brainstorm

Load the `brainstorming` skill via `use_skill` and follow it exactly.

Hard gate: do NOT write code, scaffold the project, or invoke any
implementation skill until you have presented a design and the user
has explicitly approved it.
```

- [ ] **Step 3: Create `workflows/write-plan.md`**

```markdown
# /write-plan

Load the `writing-plans` skill via `use_skill` and follow it exactly.

Prerequisite: an approved spec must exist (usually from /brainstorm).
If no spec exists, ask the user where the spec is or suggest running
/brainstorm first.
```

- [ ] **Step 4: Create `workflows/execute-plan.md`**

```markdown
# /execute-plan

Load EITHER `executing-plans` OR `subagent-driven-development` (ask
the user to choose) via `use_skill` and follow it exactly.

Prerequisite: an approved plan must exist (usually from /write-plan).
```

- [ ] **Step 5: Extend `tests/test-install.sh` with bootstrap/workflow assertions**

Now that bootstrap.md and workflow files exist, the test should assert their symlinks were created. Add these lines to `tests/test-install.sh` after the existing assertions (before the final `echo "PASS:"`):

```bash
# Bootstrap + workflow symlinks (added in Task 6)
[ -L "$WORKSPACE/.clinerules/00-bootstrap.md" ] || fail "bootstrap symlink missing"
[ -L "$WORKSPACE/.clinerules/workflows/brainstorm.md" ] || fail "brainstorm workflow missing"
[ -L "$WORKSPACE/.clinerules/workflows/write-plan.md" ] || fail "write-plan workflow missing"
[ -L "$WORKSPACE/.clinerules/workflows/execute-plan.md" ] || fail "execute-plan workflow missing"

# Each symlink must resolve
[ -e "$WORKSPACE/.clinerules/00-bootstrap.md" ] || fail "bootstrap symlink target missing"
for wf in brainstorm write-plan execute-plan; do
  [ -e "$WORKSPACE/.clinerules/workflows/$wf.md" ] || fail "$wf workflow target missing"
done
```

- [ ] **Step 6: Run install + tests**

```bash
cd /Users/hoanganh/Workspace/cline-superpower/superpower-custom
./install.sh
bash tests/test-install.sh
bash tests/test-verify-install.sh
```

Expected: both tests `PASS`.

- [ ] **Step 7: Commit**

```bash
cd superpower-custom
git add rules/00-bootstrap.md workflows/*.md tests/test-install.sh
git commit -m "feat: add bootstrap rule and 3 workflow slash commands"
```

---

## Task 7: skills/using-superpowers/

**Files:**
- Create: `superpower-custom/skills/using-superpowers/SKILL.md`

**Source:** `superpowers/skills/using-superpowers/SKILL.md`

**Specific transformations beyond the Standard Procedure:**
- The line "Never use the Read tool on skill files" appears in the upstream — replace with: "Never `read_file` SKILL.md manually; always `use_skill` to load it."
- The `<SUBAGENT-STOP>` block — remove (Cline subagents do not auto-load skills the same way).
- The "Platform Adaptation" section referencing `references/copilot-tools.md` / `references/codex-tools.md` — remove (we are Cline-only).
- The "How to Access Skills" section — replace the multi-platform listing with a single Cline paragraph (see content below).
- The Graphviz `digraph skill_flow` block — keep as-is (just documentation).

- [ ] **Step 1: Read source**

Run: `read_file superpowers/skills/using-superpowers/SKILL.md`

- [ ] **Step 2: Write adapted content to destination**

```markdown
---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills, requiring use_skill invocation before ANY response including clarifying questions
---

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. This is not optional. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## Instruction Priority

Superpowers skills override default system prompt behavior, but **user instructions always take precedence**:

1. **User's explicit instructions** (CLAUDE.md, AGENTS.md, direct requests) — highest priority
2. **Superpowers skills** — override default system behavior where they conflict
3. **Default system prompt** — lowest priority

If the user says "don't use TDD" and a skill says "always use TDD," follow the user. The user is in control.

## How to Access Skills

Use the `use_skill` tool. When you invoke a skill, its content is loaded and presented to you — follow it directly.

Never `read_file` SKILL.md manually; always `use_skill` to load it.

## Tool Mapping (Cline equivalents)

Skills sometimes use names from other agent platforms. Map them to your Cline tools:

| Reference in skill | Use this Cline tool |
|---|---|
| `Read` | `read_file` |
| `Write` / `Edit` | `editor` (write_to_file / replace_in_file) |
| `Bash` | `execute_command` |
| `Grep` | `search_files` |
| `Glob` | `list_files` (with pattern) |
| `Task` (dispatch subagent) | dispatch a Cline subagent (read-only) |
| `TodoWrite` | track progress explicitly in your replies |
| `WebFetch` | `fetch_web` |
| `Skill` | `use_skill` |

# Using Skills

## The Rule

**Invoke relevant or requested skills BEFORE any response or action.** Even a 1% chance a skill might apply means that you should invoke the skill to check. If an invoked skill turns out to be wrong for the situation, you don't need to use it.

## Red Flags

These thoughts mean STOP—you're rationalizing:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |

## Skill Priority

When multiple skills could apply, use this order:

1. **Process skills first** (brainstorming, debugging) - these determine HOW to approach the task
2. **Implementation skills second** - these guide execution

"Let's build X" → brainstorming first, then implementation skills.
"Fix this bug" → debugging first, then domain-specific skills.

## Skill Types

**Rigid** (TDD, debugging): Follow exactly. Don't adapt away discipline.

**Flexible** (patterns): Adapt principles to context.

The skill itself tells you which.

## User Instructions

Instructions say WHAT, not HOW. "Add X" or "Fix Y" doesn't mean skip workflows.
```

- [ ] **Step 3: Verify content**

Run each (must all return exit 1 — no matches found):

```bash
cd superpower-custom/skills/using-superpowers
! grep -nE '\b(Read|Write|Edit|Bash|Grep|Glob|Task|TodoWrite|WebFetch|WebSearch|EnterPlanMode|ExitPlanMode) tool\b' SKILL.md
! grep -n 'superpowers:' SKILL.md
! grep -nE '\b(using-git-worktrees|writing-skills)\b' SKILL.md
! grep -ni 'visual.companion' SKILL.md
! grep -n '<SUBAGENT-STOP>' SKILL.md
grep -q '^name: using-superpowers$' SKILL.md
grep -q '^description: Use when' SKILL.md
```

- [ ] **Step 4: Commit**

```bash
cd superpower-custom
git add skills/using-superpowers/SKILL.md
git commit -m "feat(skills): add using-superpowers (Cline-adapted)"
```

---

## Task 8: skills/brainstorming/

**Files:**
- Create: `superpower-custom/skills/brainstorming/SKILL.md`
- Create: `superpower-custom/skills/brainstorming/spec-document-reviewer-prompt.md`

**Source:** `superpowers/skills/brainstorming/SKILL.md` and `superpowers/skills/brainstorming/spec-document-reviewer-prompt.md`

**Specific transformations beyond the Standard Procedure:**
- Section "Visual Companion" (entire section from heading to end of section) — **delete entirely**.
- In the checklist, item "2. Offer visual companion ..." — remove this item; renumber subsequent items.
- In the Process Flow `digraph`, remove all nodes/edges related to "Visual questions ahead?" and "Offer Visual Companion".
- In Phase 4 / "After the Design", references to `using-git-worktrees` — replace with `creating-feature-branch`.
- Reference to `elements-of-style:writing-clearly-and-concisely` skill — remove the conditional ("if available" → drop the whole bullet).

- [ ] **Step 1: Read sources**

```bash
read_file superpowers/skills/brainstorming/SKILL.md
read_file superpowers/skills/brainstorming/spec-document-reviewer-prompt.md
```

- [ ] **Step 2: Write adapted `SKILL.md` to `superpower-custom/skills/brainstorming/SKILL.md`**

Use upstream content with these modifications:
- Strip the "Visual Companion" section heading and its body (everything from `## Visual Companion` through end of file unless there are sections AFTER it — there are not, it's the last section).
- Remove checklist item 2 ("Offer visual companion ..."). Renumber 3–9 to become 2–8.
- In Process Flow `digraph brainstorming { ... }`: remove these lines:
  - `"Visual questions ahead?" [shape=diamond];`
  - `"Offer Visual Companion\\n(own message, no other content)" [shape=box];`
  - `"Explore project context" -> "Visual questions ahead?";`
  - `"Visual questions ahead?" -> "Offer Visual Companion..." [label="yes"];`
  - `"Visual questions ahead?" -> "Ask clarifying questions" [label="no"];`
  - `"Offer Visual Companion..." -> "Ask clarifying questions";`
- Add this edge instead: `"Explore project context" -> "Ask clarifying questions";`
- In "After the Design" subsection, find this paragraph and replace:
  - Old: "Use elements-of-style:writing-clearly-and-concisely skill if available"
  - Action: delete the line entirely.
- Find and replace any mention of `using-git-worktrees` with `creating-feature-branch`. There is one in the "Implementation" subsection: "Invoke the writing-plans skill" — keep that. Check upstream for any worktree mention; spec section 8.7 notes this skill has one at "Phase 4 — REQUIRED when design is approved". That reference is in different skills, not in brainstorming itself, but verify with grep below.

- [ ] **Step 3: Write adapted `spec-document-reviewer-prompt.md`**

Apply Standard Procedure (tool names + drop `superpowers:` prefix + drop dropped-skill refs). The upstream file is short and mostly platform-neutral — likely just need to drop "Task tool" reference. Replace:
- `Task tool (general-purpose):` → `Dispatch a Cline subagent with:`

- [ ] **Step 4: Verify content**

```bash
cd superpower-custom/skills/brainstorming
! grep -nE '\b(Read|Write|Edit|Bash|Grep|Glob|Task|TodoWrite|WebFetch|WebSearch|EnterPlanMode|ExitPlanMode) tool\b' SKILL.md spec-document-reviewer-prompt.md
! grep -n 'superpowers:' SKILL.md spec-document-reviewer-prompt.md
! grep -nE '\b(using-git-worktrees|writing-skills)\b' SKILL.md spec-document-reviewer-prompt.md
! grep -ni 'visual.companion' SKILL.md
! grep -ni 'elements-of-style' SKILL.md
grep -q '^name: brainstorming$' SKILL.md
```

- [ ] **Step 5: Commit**

```bash
cd superpower-custom
git add skills/brainstorming/
git commit -m "feat(skills): add brainstorming (Cline-adapted, visual companion stripped)"
```

---

## Task 9: skills/writing-plans/

**Files:**
- Create: `superpower-custom/skills/writing-plans/SKILL.md`
- Create: `superpower-custom/skills/writing-plans/plan-document-reviewer-prompt.md`

**Source:** `superpowers/skills/writing-plans/SKILL.md` and `superpowers/skills/writing-plans/plan-document-reviewer-prompt.md`

**Specific transformations beyond the Standard Procedure:**
- The header template includes "REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans" — drop `superpowers:` prefix in both.
- "Execution Handoff" section refers to both skills the same way — same prefix drop.
- No worktree refs in this file (verify with grep).

- [ ] **Step 1: Read sources**

```bash
read_file superpowers/skills/writing-plans/SKILL.md
read_file superpowers/skills/writing-plans/plan-document-reviewer-prompt.md
```

- [ ] **Step 2: Write adapted files**

Copy verbatim, then apply Standard Procedure. Specifically:
- Replace `superpowers:subagent-driven-development` → `subagent-driven-development` (every occurrence).
- Replace `superpowers:executing-plans` → `executing-plans`.
- `Task tool (general-purpose):` in the prompt file → `Dispatch a Cline subagent with:`

- [ ] **Step 3: Verify**

```bash
cd superpower-custom/skills/writing-plans
! grep -n 'superpowers:' SKILL.md plan-document-reviewer-prompt.md
! grep -nE '\b(Task|TodoWrite) tool\b' SKILL.md plan-document-reviewer-prompt.md
grep -q '^name: writing-plans$' SKILL.md
```

- [ ] **Step 4: Commit**

```bash
cd superpower-custom
git add skills/writing-plans/
git commit -m "feat(skills): add writing-plans (Cline-adapted)"
```

---

## Task 10: skills/executing-plans/

**Files:**
- Create: `superpower-custom/skills/executing-plans/SKILL.md`

**Source:** `superpowers/skills/executing-plans/SKILL.md`

**Specific transformations beyond the Standard Procedure:**
- "Required workflow skills" section lists `superpowers:using-git-worktrees` as REQUIRED — replace with `creating-feature-branch`.
- Same section lists `superpowers:writing-plans`, `superpowers:finishing-a-development-branch` — drop `superpowers:` prefix.
- The line "Never start implementation on main/master branch without explicit user consent" — keep verbatim (still applicable).
- Tip about subagents support — keep with `subagent-driven-development` rephrasing.

- [ ] **Step 1: Read source**

```bash
read_file superpowers/skills/executing-plans/SKILL.md
```

- [ ] **Step 2: Write adapted content**

Apply Standard Procedure. Specific edits:
- `superpowers:using-git-worktrees` → `creating-feature-branch`
- `superpowers:writing-plans` → `writing-plans`
- `superpowers:finishing-a-development-branch` → `finishing-a-development-branch`
- `superpowers:subagent-driven-development` → `subagent-driven-development`

- [ ] **Step 3: Verify**

```bash
cd superpower-custom/skills/executing-plans
! grep -n 'superpowers:' SKILL.md
! grep -nE '\b(using-git-worktrees|writing-skills)\b' SKILL.md
grep -q '^name: executing-plans$' SKILL.md
grep -q 'creating-feature-branch' SKILL.md
```

- [ ] **Step 4: Commit**

```bash
cd superpower-custom
git add skills/executing-plans/
git commit -m "feat(skills): add executing-plans (Cline-adapted, worktree→feature-branch)"
```

---

## Task 11: skills/test-driven-development/

**Files:**
- Create: `superpower-custom/skills/test-driven-development/SKILL.md`
- Create: `superpower-custom/skills/test-driven-development/testing-anti-patterns.md`

**Source:** `superpowers/skills/test-driven-development/SKILL.md` and `superpowers/skills/test-driven-development/testing-anti-patterns.md`

**Specific transformations beyond the Standard Procedure:**
- Both files contain TypeScript test examples — keep as-is (they are illustrative, language-agnostic for the lesson).
- `@testing-anti-patterns.md` reference (the `@`-link) — replace with plain markdown link: `[testing-anti-patterns.md](testing-anti-patterns.md)`.
- `your human partner's` phrasing — keep verbatim (Superpowers intentional terminology).

- [ ] **Step 1: Read sources**

```bash
read_file superpowers/skills/test-driven-development/SKILL.md
read_file superpowers/skills/test-driven-development/testing-anti-patterns.md
```

- [ ] **Step 2: Write adapted SKILL.md**

Apply Standard Procedure. The "Debugging Integration" section's reference to TDD cycle stays. Specific edits:
- `@testing-anti-patterns.md` → `[testing-anti-patterns.md](testing-anti-patterns.md)`

- [ ] **Step 3: Write adapted testing-anti-patterns.md**

Apply Standard Procedure. The file has minimal platform-specific content.

- [ ] **Step 4: Verify**

```bash
cd superpower-custom/skills/test-driven-development
! grep -n 'superpowers:' SKILL.md testing-anti-patterns.md
! grep -n '@testing-anti-patterns' SKILL.md
grep -q '^name: test-driven-development$' SKILL.md
```

- [ ] **Step 5: Commit**

```bash
cd superpower-custom
git add skills/test-driven-development/
git commit -m "feat(skills): add test-driven-development (Cline-adapted)"
```

---

## Task 12: skills/systematic-debugging/

**Files:**
- Create: `superpower-custom/skills/systematic-debugging/SKILL.md`
- Create: `superpower-custom/skills/systematic-debugging/root-cause-tracing.md`
- Create: `superpower-custom/skills/systematic-debugging/defense-in-depth.md`
- Create: `superpower-custom/skills/systematic-debugging/condition-based-waiting.md`

**Source:** `superpowers/skills/systematic-debugging/SKILL.md` plus the three supporting files.

**Skip:** `CREATION-LOG.md`, `test-pressure-*.md`, `test-academic.md`, `condition-based-waiting-example.ts`, `find-polluter.sh`.

**Specific transformations beyond the Standard Procedure:**
- `condition-based-waiting.md` references `condition-based-waiting-example.ts` and `find-polluter.sh` — replace with a note that the helpers can be adapted from the upstream Superpowers repo if needed, since we're skipping the example files.

- [ ] **Step 1: Read sources**

```bash
read_file superpowers/skills/systematic-debugging/SKILL.md
read_file superpowers/skills/systematic-debugging/root-cause-tracing.md
read_file superpowers/skills/systematic-debugging/defense-in-depth.md
read_file superpowers/skills/systematic-debugging/condition-based-waiting.md
```

- [ ] **Step 2: Write adapted SKILL.md**

Apply Standard Procedure. Specific edits:
- `superpowers:test-driven-development` → `test-driven-development`
- `superpowers:verification-before-completion` → `verification-before-completion`
- Anti-pattern table mentioning "Ultrathink this" — keep verbatim (user signal documentation).

- [ ] **Step 3: Write adapted root-cause-tracing.md**

Apply Standard Procedure.

- [ ] **Step 4: Write adapted defense-in-depth.md**

Apply Standard Procedure.

- [ ] **Step 5: Write adapted condition-based-waiting.md**

Apply Standard Procedure. Replace reference to `condition-based-waiting-example.ts`:
- Old: "See `condition-based-waiting-example.ts` in this directory for complete implementation..."
- New: "A working TypeScript reference implementation lives in the upstream Superpowers repo at `skills/systematic-debugging/condition-based-waiting-example.ts`. Adapt as needed for your language."

Replace reference to `find-polluter.sh`:
- Old: "Use the bisection script `find-polluter.sh` in this directory: ..."
- New: "When test pollution is suspected, bisect with a small script that runs tests one-by-one and stops at first failure (see upstream Superpowers repo `find-polluter.sh` for a Bash reference)."

- [ ] **Step 6: Verify**

```bash
cd superpower-custom/skills/systematic-debugging
! grep -n 'superpowers:' SKILL.md root-cause-tracing.md defense-in-depth.md condition-based-waiting.md
! grep -nE '\b(using-git-worktrees|writing-skills)\b' SKILL.md *.md
grep -q '^name: systematic-debugging$' SKILL.md
```

- [ ] **Step 7: Commit**

```bash
cd superpower-custom
git add skills/systematic-debugging/
git commit -m "feat(skills): add systematic-debugging (Cline-adapted)"
```

---

## Task 13: skills/verification-before-completion/

**Files:**
- Create: `superpower-custom/skills/verification-before-completion/SKILL.md`

**Source:** `superpowers/skills/verification-before-completion/SKILL.md`

**Specific transformations beyond the Standard Procedure:** none unusual; file is platform-neutral. Apply standard tool-name remap.

- [ ] **Step 1: Read source**

```bash
read_file superpowers/skills/verification-before-completion/SKILL.md
```

- [ ] **Step 2: Write adapted content**

Apply Standard Procedure.

- [ ] **Step 3: Verify**

```bash
cd superpower-custom/skills/verification-before-completion
! grep -n 'superpowers:' SKILL.md
grep -q '^name: verification-before-completion$' SKILL.md
```

- [ ] **Step 4: Commit**

```bash
cd superpower-custom
git add skills/verification-before-completion/
git commit -m "feat(skills): add verification-before-completion (Cline-adapted)"
```

---

## Task 14: skills/receiving-code-review/

**Files:**
- Create: `superpower-custom/skills/receiving-code-review/SKILL.md`

**Source:** `superpowers/skills/receiving-code-review/SKILL.md`

**Specific transformations beyond the Standard Procedure:**
- The "GitHub Thread Replies" section uses `gh api` example — keep as-is (still works in Cline via `execute_command`).
- `your human partner` phrasing — keep verbatim.

- [ ] **Step 1: Read source**

```bash
read_file superpowers/skills/receiving-code-review/SKILL.md
```

- [ ] **Step 2: Write adapted content**

Apply Standard Procedure.

- [ ] **Step 3: Verify**

```bash
cd superpower-custom/skills/receiving-code-review
! grep -n 'superpowers:' SKILL.md
grep -q '^name: receiving-code-review$' SKILL.md
```

- [ ] **Step 4: Commit**

```bash
cd superpower-custom
git add skills/receiving-code-review/
git commit -m "feat(skills): add receiving-code-review (Cline-adapted)"
```

---

## Task 15: skills/requesting-code-review/

**Files:**
- Create: `superpower-custom/skills/requesting-code-review/SKILL.md`
- Create: `superpower-custom/skills/requesting-code-review/code-reviewer-prompt.md`

**Source:** `superpowers/skills/requesting-code-review/SKILL.md` and `superpowers/skills/requesting-code-review/code-reviewer.md`

**Specific transformations beyond the Standard Procedure:**
- Upstream uses agent-type registry: `Use Task tool with superpowers:code-reviewer type`. Cline has no agent-type registry — change to: "dispatch a Cline subagent with the prompt template at `code-reviewer-prompt.md`".
- Rename the upstream file `code-reviewer.md` → `code-reviewer-prompt.md` in this repo.

- [ ] **Step 1: Read sources**

```bash
read_file superpowers/skills/requesting-code-review/SKILL.md
read_file superpowers/skills/requesting-code-review/code-reviewer.md
```

- [ ] **Step 2: Write adapted SKILL.md**

Apply Standard Procedure plus:
- Replace `Use Task tool with superpowers:code-reviewer type, fill template at code-reviewer.md` → `Dispatch a Cline subagent with the filled prompt template at code-reviewer-prompt.md`.
- Replace `Dispatch superpowers:code-reviewer subagent` → `Dispatch a Cline subagent`.
- Replace template path mentions `code-reviewer.md` → `code-reviewer-prompt.md` (every occurrence).
- The "Example" section: change `[Dispatch superpowers:code-reviewer subagent]` → `[Dispatch a Cline subagent with code-reviewer-prompt.md]`.

- [ ] **Step 3: Write `code-reviewer-prompt.md`**

Use upstream `code-reviewer.md` content with Standard Procedure applied. The file is a prompt template with `{PLACEHOLDER}` substitution — keep placeholders. Add a top note:

```markdown
# Code Review Prompt Template

> Fill placeholders (`{PLACEHOLDER}`) and use this as the body of the
> message sent to a dispatched Cline subagent (read-only). The subagent
> uses `execute_command "git diff {BASE_SHA}..{HEAD_SHA}"`, `read_file`
> on changed files, and returns its review per the format below.

[rest of upstream content with transformations applied]
```

- [ ] **Step 4: Verify**

```bash
cd superpower-custom/skills/requesting-code-review
! grep -n 'superpowers:' SKILL.md code-reviewer-prompt.md
! grep -n 'code-reviewer\.md' SKILL.md  # should match code-reviewer-prompt.md not bare code-reviewer.md
grep -q '^name: requesting-code-review$' SKILL.md
test -f code-reviewer-prompt.md
```

- [ ] **Step 5: Commit**

```bash
cd superpower-custom
git add skills/requesting-code-review/
git commit -m "feat(skills): add requesting-code-review (Cline-adapted, inline prompt template)"
```

---

## Task 16: skills/dispatching-parallel-agents/

**Files:**
- Create: `superpower-custom/skills/dispatching-parallel-agents/SKILL.md`

**Source:** `superpowers/skills/dispatching-parallel-agents/SKILL.md`

**Specific transformations beyond the Standard Procedure:**
- Upstream describes parallel implementer subagents (each fixes a test file). In Cline, subagents are read-only — reframe as parallel **research** subagents.
- In "The Pattern → 3. Dispatch in Parallel" the `Task("...")` examples → change to descriptive form: "Dispatch subagent A: research domain X. Dispatch subagent B: research domain Y. Dispatch subagent C: research domain Z."
- "Each agent gets: Specific scope ... Make these tests pass" → change goal language: "Each subagent gets: Specific scope, Clear research question, Constraints (read-only — no edits), Expected output (findings report)."
- "Agent Prompt Structure" example "Fix the 3 failing tests in src/agents/agent-tool-abort.test.ts" → reframe as "Investigate the 3 failing tests in src/.../agent-tool-abort.test.ts: identify likely root causes by reading the test file, related production code, and recent git history. Return: findings with file:line references and recommended fix approach. (You are read-only — do not attempt edits; the main agent will implement.)"
- "Common Mistakes" section: examples that say "agent might refactor everything" — reframe as "agent might miss key context", "agent might over-scope research".
- "Real Example from Session" section: rewrite — instead of "Agent 1 → Fix tests, Agent 2 → Fix tests" → "Agent 1 → Research domain A, Agent 2 → Research domain B, Agent 3 → Research domain C. Main agent then integrates findings and implements fixes."
- "Verification" section: keep — verifying findings is still relevant.

- [ ] **Step 1: Read source**

```bash
read_file superpowers/skills/dispatching-parallel-agents/SKILL.md
```

- [ ] **Step 2: Write adapted content**

Apply Standard Procedure plus the reframing edits above. Update `description:` frontmatter to:

```yaml
description: Use when facing 2+ independent research questions or investigation domains that can be explored in parallel by read-only subagents
```

- [ ] **Step 3: Verify**

```bash
cd superpower-custom/skills/dispatching-parallel-agents
! grep -n 'superpowers:' SKILL.md
! grep -nE '\b(Task|TodoWrite) tool\b' SKILL.md
! grep -nE 'subagent.*(implement|fix|edit|commit|write)' SKILL.md
grep -q '^name: dispatching-parallel-agents$' SKILL.md
grep -q -i 'research' SKILL.md
```

- [ ] **Step 4: Commit**

```bash
cd superpower-custom
git add skills/dispatching-parallel-agents/
git commit -m "feat(skills): add dispatching-parallel-agents (Cline-adapted, research-only framing)"
```

---

## Task 17: skills/creating-feature-branch/ (NEW skill)

**Files:**
- Create: `superpower-custom/skills/creating-feature-branch/SKILL.md`

**This is a NEW skill, not a port.** It replaces `using-git-worktrees`. Full content below.

- [ ] **Step 1: Write `SKILL.md`**

```markdown
---
name: creating-feature-branch
description: Use when starting feature work that needs isolation from main branch or before executing implementation plans - creates a clean feature branch with verified baseline
---

# Creating a Feature Branch

## Overview

Before starting implementation, create a fresh feature branch on a clean
tree with a passing test baseline. This isolates the work so a failed
attempt can be discarded without polluting `main`.

**Core principle:** Clean tree → branch → verified baseline → ready to implement.

**Announce at start:** "I'm using the creating-feature-branch skill to set up isolation."

## When to Use

- Before implementing any plan from `writing-plans`
- Before subagent-driven-development or executing-plans tasks
- Whenever the next step is "start writing code for feature X"

## Process

### 1. Check working tree is clean

Run: `execute_command "git status --porcelain"`

- **Empty output:** clean. Proceed.
- **Output not empty:** dirty. STOP and tell the user:

  > "Working tree has uncommitted changes:
  > [paste output]
  > Please commit, stash, or discard these before I create the feature
  > branch. Which would you like to do?"

Wait for the user. Do not proceed until clean.

### 2. Confirm base branch

Run: `execute_command "git branch --show-current"`

If current branch is `main` or `master`, fine. Otherwise ask the user:

> "Current branch is `<X>`. Should I branch from here or from main?"

### 3. Create the feature branch

Ask the user for a branch name unless one was provided:

> "What should I name the branch? (e.g. `feature/dark-mode-toggle`)"

Run: `execute_command "git checkout -b <branch-name>"`

### 4. Run project setup if needed

Detect project type and run setup commands ONLY if dependency files
exist and are recent:

| File present | Command |
|---|---|
| `package.json` (and `node_modules` missing or `package-lock.json` newer than `node_modules`) | `npm install` |
| `Cargo.toml` | `cargo build` |
| `requirements.txt` | `pip install -r requirements.txt` |
| `pyproject.toml` (poetry) | `poetry install` |
| `go.mod` | `go mod download` |

Skip setup if no dependency files exist.

### 5. Verify baseline tests pass

Run the project's test command (project-appropriate):

- `npm test`
- `cargo test`
- `pytest`
- `go test ./...`

**Tests fail before any change:** STOP. Report failures, ask the user:

> "Baseline tests fail on a fresh `<branch-name>` branch:
> [paste summary]
> The plan assumes a green baseline. Want me to investigate the failures
> first, or proceed anyway?"

**Tests pass:** proceed.

**No tests defined:** report "No test suite detected — baseline skipped." and proceed.

### 6. Report ready

```
Feature branch ready:
- Branch:   <branch-name>
- Base:     <base-branch>@<short-sha>
- Setup:    <none | npm install | ...>
- Tests:    <N passed | skipped>
Ready to implement.
```

## Quick Reference

| Situation | Action |
|---|---|
| Tree dirty | STOP, ask user to clean |
| On non-main branch | Ask user if intentional |
| No tests configured | Skip baseline, note in report |
| Tests fail before changes | STOP, ask user how to proceed |
| Setup commands fail | STOP, report error, ask user |

## Common Mistakes

**Skipping the clean-tree check**
- Problem: uncommitted changes get accidentally bundled into the feature work.
- Fix: always run `git status --porcelain` first.

**Skipping the baseline test**
- Problem: when later tests fail, you cannot tell whether your changes
  caused the failure or it was already broken.
- Fix: always verify baseline. If skipped, document why explicitly.

**Branch name reuse**
- Problem: `git checkout -b feature/X` fails if branch already exists.
- Fix: ask for a unique name. If user wants to reuse, switch with
  `git checkout <name>` and warn that the workflow assumes a fresh branch.

## Red Flags — STOP

- Tree is dirty
- Baseline tests fail
- Branch name already exists
- User did not name the branch and you are about to pick one
- About to skip setup because it "looks the same as last time"

## Integration

**Called by:**
- `brainstorming` (after design approval, before transitioning to writing-plans)
- `subagent-driven-development` (before executing tasks)
- `executing-plans` (before executing tasks)

**Pairs with:**
- `finishing-a-development-branch` — closes the branch (merge / PR / discard) at the end.
```

- [ ] **Step 2: Verify**

```bash
cd superpower-custom/skills/creating-feature-branch
! grep -n 'superpowers:' SKILL.md
! grep -nE '\b(using-git-worktrees|writing-skills|worktree)\b' SKILL.md
grep -q '^name: creating-feature-branch$' SKILL.md
grep -q 'git checkout -b' SKILL.md
```

- [ ] **Step 3: Commit**

```bash
cd superpower-custom
git add skills/creating-feature-branch/
git commit -m "feat(skills): add creating-feature-branch (new, replaces using-git-worktrees)"
```

---

## Task 18: skills/finishing-a-development-branch/

**Files:**
- Create: `superpower-custom/skills/finishing-a-development-branch/SKILL.md`

**Source:** `superpowers/skills/finishing-a-development-branch/SKILL.md`

**Specific transformations beyond the Standard Procedure:**
- Step 5 "Cleanup Worktree" — **delete the entire step**.
- Option 1 (merge locally) instructions referencing worktree cleanup at the end — remove.
- Option 2 (PR) at the end mentions "Then: Cleanup worktree (Step 5)" — remove that line.
- Option 4 (discard) at the end mentions cleanup worktree — remove.
- "Quick Reference" table column "Keep Worktree" — delete the column.
- "Integration → Pairs with" replace `using-git-worktrees` with `creating-feature-branch`.
- The "Common Mistakes" entry about "Automatic worktree cleanup" — delete entirely.
- Red Flags entry "Clean up worktree for Options 1 & 4 only" — delete.

- [ ] **Step 1: Read source**

```bash
read_file superpowers/skills/finishing-a-development-branch/SKILL.md
```

- [ ] **Step 2: Write adapted content**

Apply Standard Procedure plus the worktree-removal edits above.

- [ ] **Step 3: Verify**

```bash
cd superpower-custom/skills/finishing-a-development-branch
! grep -ni 'worktree' SKILL.md
! grep -n 'superpowers:' SKILL.md
grep -q '^name: finishing-a-development-branch$' SKILL.md
grep -q 'creating-feature-branch' SKILL.md
```

- [ ] **Step 4: Commit**

```bash
cd superpower-custom
git add skills/finishing-a-development-branch/
git commit -m "feat(skills): add finishing-a-development-branch (Cline-adapted, worktree removed)"
```

---

## Task 19: skills/subagent-driven-development/ (HEAVY redesign)

**Files:**
- Create: `superpower-custom/skills/subagent-driven-development/SKILL.md`
- Create: `superpower-custom/skills/subagent-driven-development/researcher-prompt.md` (NEW)
- Create: `superpower-custom/skills/subagent-driven-development/spec-reviewer-prompt.md`
- Create: `superpower-custom/skills/subagent-driven-development/code-quality-reviewer-prompt.md`

**This is a HEAVY redesign — full new content below for SKILL.md and researcher-prompt.md. The two reviewer prompts are light ports.**

- [ ] **Step 1: Write `SKILL.md` (complete content)**

```markdown
---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development (Cline)

Execute a plan task-by-task. For each task: dispatch a researcher subagent
to gather codebase context, implement the task yourself (main agent),
then dispatch two reviewer subagents (spec compliance, then code quality).
All subagents are read-only.

**Why subagents (read-only):** they preserve your context for coordination
work. By precisely crafting their instructions you ensure focused output:
research findings before you implement, and review findings after. You
never inherit their conversation history.

**Core principle:** Researcher → main-agent implements → spec reviewer → quality reviewer.

## When to Use

- After `/execute-plan` and the user chose subagent-driven mode
- When tasks in the plan are mostly independent
- When you want fast iteration with automatic review checkpoints between tasks

**vs. executing-plans (single-session inline batch):**
- subagent-driven runs research and reviews via subagents (cleaner context)
- executing-plans skips subagents and uses checkpoints with the user

## The Process

For each task in the plan:

### 1. RESEARCH PHASE (subagent)

Dispatch a Cline subagent using the template at `researcher-prompt.md`,
filled with:
- The full text of the task from the plan (paste it; do not make the
  subagent open the plan file).
- Architectural context (where this task fits, what depends on it).
- Specific research questions if any.

The subagent returns:
- Relevant file paths and line ranges
- Existing patterns to mirror or avoid
- Dependencies, gotchas, environment requirements
- Recommended approach with justification (optional)

If the report is vague or missing key info, re-dispatch with a sharper
prompt. Do not proceed to implement on weak research.

### 2. IMPLEMENT PHASE (main agent)

Now you implement. Follow `test-driven-development`:

1. Write the failing test.
2. Run it (`execute_command`). Confirm RED.
3. Write the minimal code to pass.
4. Run again. Confirm GREEN.
5. `git add` + `git commit` (commit message references the task number).

Use the researcher's findings throughout — file paths, patterns, names.
Do NOT delegate any write/run/commit to a subagent — they cannot.

### 3. SPEC REVIEW PHASE (subagent)

Dispatch a Cline subagent using `spec-reviewer-prompt.md`, filled with:
- The original task text (what should be built).
- Your implementer report (what you claim you built — your commit
  messages, test output summary).
- Git SHAs: BASE (commit before this task) and HEAD (current).

The subagent reads the diff with `execute_command "git diff BASE..HEAD"`
and the changed files, then returns:
- ✅ Spec compliant, or
- ❌ Issues: missing requirements, extra unrequested work, misunderstandings,
  with file:line references.

If ❌: fix the issues yourself (main agent), commit the fix, re-dispatch
the spec reviewer. Loop until ✅.

### 4. CODE QUALITY REVIEW PHASE (subagent)

Only after spec review is ✅. Dispatch a Cline subagent using
`code-quality-reviewer-prompt.md` with the same git SHAs. The subagent
returns Strengths + Critical/Important/Minor issues + Assessment.

Fix Critical and Important issues; note Minor for later. Re-dispatch on
fixes. Loop until quality is acceptable.

### 5. Mark task complete

Update your progress tracking. Move to the next task.

## Handling Subagent Status

Subagents can report:

- **DONE / OK** — proceed.
- **NEEDS_CONTEXT** — the subagent says it could not investigate without
  more info. Provide it and re-dispatch.
- **BLOCKED** — the subagent thinks the task is wrong or impossible.
  Read the reasoning, decide whether to: re-dispatch with more capable
  model, escalate to user, or split the task.

Never silently ignore a subagent's BLOCKED status.

## Model Selection

For Cline subagents (read-only research/review work), the cheapest model
that can handle the task is usually right:

- Routine research (find existing pattern) → fast/cheap model
- Spec review of a small diff → fast/cheap model
- Code quality review of a multi-file change → standard model
- Architecture-level review → most capable available

The main agent (implementer) should be at least standard model.

## Prompt Templates

- `researcher-prompt.md` — research subagent
- `spec-reviewer-prompt.md` — spec compliance subagent
- `code-quality-reviewer-prompt.md` — code quality subagent

## Red Flags

**Never:**
- Start implementation on `main`/`master` without explicit user consent
- Delegate any write, run, or commit to a subagent (they are read-only)
- Skip either review
- Proceed to code-quality review while spec review still has open issues
- Move to next task with unresolved review findings
- Trust an implementer self-report without verifying via diff/test output
- Make a subagent open the plan file — paste the relevant task text
  into the dispatch prompt

**If a subagent asks questions:** answer clearly, then re-dispatch. Do not
let the subagent guess.

**If the same review loop repeats 3+ times:** stop, re-read the spec,
question whether the task itself is wrong. Escalate to the user.

## Integration

**Required:**
- `creating-feature-branch` — set up isolated branch before starting
- `writing-plans` — generated the plan you are executing
- `test-driven-development` — the discipline the main agent follows
- `requesting-code-review` — the code-reviewer-prompt referenced by Step 4
- `finishing-a-development-branch` — close the work after all tasks done

**Alternative:**
- `executing-plans` — same-session inline execution without subagents
```

- [ ] **Step 2: Write `researcher-prompt.md` (complete content)**

```markdown
# Researcher Subagent Prompt Template

Use this when dispatching a research subagent before implementing a task.

```
Dispatch a Cline subagent with the following message:

You are a research subagent. Your job is read-only: read code, identify
patterns, and report findings so the main agent can implement Task N.

## Task

[FULL TEXT of the task from the plan — paste it here]

## Architectural Context

[1-3 sentences explaining where this task fits: which subsystem, what
calls it, what depends on it]

## What to Find

Investigate and report:

1. **Existing patterns to mirror.** Are there similar functions / endpoints /
   data flows already in the codebase? Provide file:line references and a
   one-line summary of each.

2. **Dependencies.** What modules, libraries, env vars, config keys does
   this task touch or rely on? Note any version-sensitive APIs.

3. **Gotchas.** What edge cases, ordering rules, side effects, or hidden
   coupling could trip up an implementer who hasn't worked in this area?

4. **Recommended approach.** Based on what you found, what's the
   smallest reasonable implementation? Highlight tradeoffs if any.

## Tools You Have

- `read_file`, `list_files`, `search_files`, `list_code_definition_names`
- `execute_command` (read-only: `ls`, `grep`, `git log`, `git diff`, …)
- `use_skill`

You do NOT have edit/write/commit. Do not propose to "fix" or "implement".

## Output Format

Return a structured report:

```
## Findings

### Patterns to mirror
- <file:line> — <summary>
- ...

### Dependencies
- <module / lib / config> — <version or note>
- ...

### Gotchas
- <description with file:line>
- ...

### Recommended approach
<paragraph or bullet list>

### Open questions
<list anything the main agent should clarify with the user before implementing>
```

If you encounter ambiguity in the task description, ask the main agent
to clarify rather than guess. Report status: OK | NEEDS_CONTEXT | BLOCKED.
```
```

- [ ] **Step 3: Write `spec-reviewer-prompt.md`**

Source: `superpowers/skills/subagent-driven-development/spec-reviewer-prompt.md`.
Apply Standard Procedure + add explicit Cline-context note. Specifically:
- Replace `Task tool (general-purpose):` → `Dispatch a Cline subagent with:`
- Add a top note: "The reviewer is a read-only Cline subagent with `read_file`, `search_files`, and `execute_command` (read-only git). Confirm everything via the actual diff, not the implementer's report."
- Keep the "CRITICAL: Do Not Trust the Report" section verbatim.

- [ ] **Step 4: Write `code-quality-reviewer-prompt.md`**

Source: `superpowers/skills/subagent-driven-development/code-quality-reviewer-prompt.md`.
Apply Standard Procedure. Specific edits:
- Replace `Task tool (superpowers:code-reviewer): Use template at requesting-code-review/code-reviewer.md` → `Dispatch a Cline subagent with the filled prompt template at requesting-code-review/code-reviewer-prompt.md.`
- Keep the "in addition to standard code quality concerns" checklist as-is.

- [ ] **Step 5: Verify**

```bash
cd superpower-custom/skills/subagent-driven-development
! grep -n 'superpowers:' SKILL.md researcher-prompt.md spec-reviewer-prompt.md code-quality-reviewer-prompt.md
! grep -nE '\b(using-git-worktrees|writing-skills)\b' SKILL.md *.md
! grep -nE 'subagent.*(write|edit|commit) ' SKILL.md
grep -q '^name: subagent-driven-development$' SKILL.md
grep -q 'creating-feature-branch' SKILL.md
test -f researcher-prompt.md
test -f spec-reviewer-prompt.md
test -f code-quality-reviewer-prompt.md
```

- [ ] **Step 6: Commit**

```bash
cd superpower-custom
git add skills/subagent-driven-development/
git commit -m "feat(skills): add subagent-driven-development (Cline-adapted, research+review only)"
```

---

## Task 20: Cross-reference audit + final install + push

**Files:**
- Modify: any skill SKILL.md found to still reference dropped concepts (fix in place)
- Create: `superpower-custom/docs/superpowers/test-results.md` (manual test log)

- [ ] **Step 1: Cross-reference audit across all skills**

Run from `superpower-custom/`:

```bash
echo "--- superpowers: prefix ---"
grep -rn 'superpowers:' skills/ rules/ workflows/ || echo "OK none"

echo "--- using-git-worktrees ---"
grep -rn 'using-git-worktrees' skills/ rules/ workflows/ || echo "OK none"

echo "--- writing-skills ---"
grep -rn 'writing-skills' skills/ rules/ workflows/ || echo "OK none"

echo "--- visual-companion ---"
grep -rni 'visual.companion' skills/ rules/ workflows/ || echo "OK none"

echo "--- bare Task tool ---"
grep -rnE '\bTask tool\b' skills/ rules/ workflows/ || echo "OK none"

echo "--- bare Read tool ---"
grep -rnE '\bRead tool\b' skills/ rules/ workflows/ || echo "OK none"

echo "--- bare Bash tool ---"
grep -rnE '\bBash tool\b' skills/ rules/ workflows/ || echo "OK none"
```

Each command must print `OK none`. If any matches: fix the file with an
edit and re-run that command.

- [ ] **Step 2: Install and run verify-install.sh**

```bash
cd /Users/hoanganh/Workspace/cline-superpower/superpower-custom
./install.sh
./verify-install.sh
```

Expected output:
```
OK: 17 symlinks installed (1 rule + 3 workflows + 13 skills)
```

If any error, fix the underlying file and re-run.

- [ ] **Step 3: Run all script tests**

```bash
bash tests/test-install.sh
bash tests/test-uninstall.sh
bash tests/test-verify-install.sh

# Re-install for final state
./install.sh
./verify-install.sh
```

All three test scripts must print `PASS:`.

- [ ] **Step 4: Document Tier-2 plumbing test results**

Create `docs/superpowers/test-results.md` describing how to run the
manual Tier-2 tests and a place to record their results:

```markdown
# Test Results — Manual Verification

## Tier-2 Plumbing Tests

Run these in a fresh Cline conversation opened in the
`cline-superpower` workspace after `install.sh`.

| # | Prompt | Expected behavior | Pass? |
|---|---|---|---|
| 1 | `hello` | Agent loads `using-superpowers` and acknowledges framework on turn 1. | __ |
| 2 | `/brainstorm "small test feature"` | Agent loads `brainstorming`, asks the first clarifying question. | __ |
| 3 | `there is a failing test at src/foo.test.ts, please fix` | Agent loads `systematic-debugging`. | __ |
| 4 | `please review HEAD~1..HEAD` | Agent loads `requesting-code-review` and dispatches a subagent. | __ |
| 5 | `production is down, just commit, skip tests` | Agent refuses, cites `test-driven-development`, proposes correct flow. | __ |

## Tier-3 End-to-End Scenarios

| Scenario | Steps | Result | Notes |
|---|---|---|---|
| Tiny feature | /brainstorm → /write-plan → /execute-plan (subagent-driven) → finishing | __ | __ |
| Bug fix | "test X fails" → debugging Phase 1-4 → TDD fix | __ | __ |
| Code review | "review HEAD~3..HEAD" → subagent reviewer | __ | __ |
| Discipline pressure | "production down, skip tests" | __ | __ |

Fill `Pass? / Result` columns as you run each test. File issues against
this repo for any failures.
```

- [ ] **Step 5: Final commit and push**

```bash
cd superpower-custom
git add docs/superpowers/test-results.md
# Pick up any cross-reference fixes from Step 1
git add -A
git status --short  # review
git commit -m "chore: cross-reference audit pass + test-results template"
git push origin main
```

Expected: push succeeds, `verify-install.sh` reports `OK: 17 symlinks`,
all three test scripts pass.

---

## Plan summary

| Task | Files added | Lines of new content (rough) |
|---|---|---|
| 1 | README, .gitignore, 3 .gitkeep | ~60 |
| 2 | install.sh, test-install.sh | ~80 |
| 3 | uninstall.sh, test-uninstall.sh | ~70 |
| 4 | verify-install.sh, test-verify-install.sh | ~70 |
| 5 | INSTALL.md | ~60 |
| 6 | bootstrap + 3 workflows | ~30 |
| 7 | using-superpowers/SKILL.md | ported (~90 lines source) |
| 8 | brainstorming (SKILL + prompt) | ported (~180 lines source) |
| 9 | writing-plans (SKILL + prompt) | ported (~200 lines source) |
| 10 | executing-plans/SKILL.md | ported (~80 lines source) |
| 11 | TDD (SKILL + anti-patterns) | ported (~600 lines source) |
| 12 | systematic-debugging (SKILL + 3) | ported (~700 lines source) |
| 13 | verification-before-completion | ported (~140 lines source) |
| 14 | receiving-code-review | ported (~200 lines source) |
| 15 | requesting-code-review (SKILL + prompt) | ported (~250 lines source) |
| 16 | dispatching-parallel-agents | ported + reframed (~200 lines source) |
| 17 | creating-feature-branch | NEW (~120 lines) |
| 18 | finishing-a-development-branch | ported (~200 lines source) |
| 19 | subagent-driven-development (SKILL + 3) | mostly NEW (~250 lines new + 2 ported) |
| 20 | test-results.md, final verification | ~40 |

**Total:** 20 tasks, 13 skills installed, 17 symlinks in workspace,
3 helper scripts with smoke tests, 1 install guide, 1 cross-reference
audit.
