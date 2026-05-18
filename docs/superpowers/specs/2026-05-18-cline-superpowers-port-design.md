# Superpowers (Custom for Cline VSCode) — Design Spec

**Date:** 2026-05-18
**Author:** brainstorming session
**Status:** Draft — pending user approval before plan phase

## 1. Goal

Port the Superpowers framework (currently designed for Claude Code / Codex /
Cursor) to work optimally with **Cline running as a VSCode extension** — a
single-agent environment with read-only subagents and no agent-team support.

The port must preserve Superpowers' core value (TDD discipline, root-cause
debugging, structured brainstorming / planning / execution workflows, code
review automation, verification before completion) while adapting to Cline's
constraints.

## 2. Constraints

### 2.1 Cline subagent capabilities

A Cline subagent can ONLY use these tools:

- `read_file` — read file contents
- `list_files` — list directory contents
- `search_files` — regex search across files
- `list_code_definition_names` — list top-level classes/functions/methods
- `execute_command` — read-only commands (`ls`, `grep`, `git log`, `git diff`, …)
- `use_skill` — load and activate a skill

A subagent CANNOT: write/edit files, run tests, commit, browse the web, use
MCP servers, or spawn nested subagents.

**Implication:** the Superpowers `subagent-driven-development` skill —
which originally dispatches a subagent to *implement* each plan task — must
be redesigned. The main agent becomes the implementer; subagents shift to
research and review roles.

### 2.2 Cline platform mechanics

- **Rules** (`.clinerules/*.md`) are appended to the system prompt on every
  turn — persistent but token-costly.
- **Skills** (`.cline/skills/<name>/SKILL.md`) load on demand via `use_skill`
  — only metadata pre-loaded, content fetched when activated.
- **Workflows** (`.clinerules/workflows/<name>.md`) are slash commands
  invoked explicitly (`/<name>`).
- **Hooks** (SDK Plugins) — support in the VSCode extension is not
  documented clearly; this design does not depend on hooks.

### 2.3 Output location

- **Source of truth:** `/Users/hoanganh/Workspace/cline-superpower/superpower-custom/`
- **Install target:** workspace-only — `.clinerules/`, `.clinerules/workflows/`,
  and `.cline/skills/` inside `/Users/hoanganh/Workspace/cline-superpower/`.

## 3. Architecture (3 layers)

```
Cline (VSCode extension)
├── Bootstrap rule (.clinerules/00-bootstrap.md)    ← always loaded (~60 words)
├── Workflows (.clinerules/workflows/)              ← /brainstorm /write-plan /execute-plan
└── Skills (.cline/skills/)                         ← 13 skills, loaded on demand
        ↓ uses (when needed)
   Cline subagent (read-only)
   roles: research, spec review, code-quality review, parallel research
```

### Subagent contract

The main agent dispatches subagents ONLY for:

1. **Research / investigation** — explore codebase context before implementing
2. **Spec compliance review** — verify implementation matches task spec
3. **Code quality review** — evaluate diffs against quality bar
4. **Parallel domain research** — multiple subagents investigating distinct
   areas concurrently

The main agent performs ALL writes, commits, and command execution. A
subagent is never asked to "do" the task — only to "look at" things and
report.

## 4. File layout

### 4.1 Source folder (`superpower-custom/`)

```
superpower-custom/
├── README.md
├── INSTALL.md
├── install.sh                       # symlink-based installer
├── uninstall.sh
├── verify-install.sh
│
├── rules/
│   └── 00-bootstrap.md              # ~60 words, ALWAYS loaded
│
├── workflows/
│   ├── brainstorm.md                # /brainstorm
│   ├── write-plan.md                # /write-plan
│   └── execute-plan.md              # /execute-plan
│
└── skills/                          # 13 skills
    ├── using-superpowers/
    │   └── SKILL.md
    ├── brainstorming/
    │   ├── SKILL.md
    │   └── spec-document-reviewer-prompt.md
    ├── writing-plans/
    │   ├── SKILL.md
    │   └── plan-document-reviewer-prompt.md
    ├── executing-plans/
    │   └── SKILL.md
    ├── test-driven-development/
    │   ├── SKILL.md
    │   └── testing-anti-patterns.md
    ├── systematic-debugging/
    │   ├── SKILL.md
    │   ├── root-cause-tracing.md
    │   ├── defense-in-depth.md
    │   └── condition-based-waiting.md
    ├── verification-before-completion/
    │   └── SKILL.md
    ├── requesting-code-review/
    │   ├── SKILL.md
    │   └── code-reviewer-prompt.md
    ├── receiving-code-review/
    │   └── SKILL.md
    ├── dispatching-parallel-agents/
    │   └── SKILL.md
    ├── subagent-driven-development/
    │   ├── SKILL.md
    │   ├── researcher-prompt.md          # NEW
    │   ├── spec-reviewer-prompt.md
    │   └── code-quality-reviewer-prompt.md
    ├── creating-feature-branch/          # NEW — replaces using-git-worktrees
    │   └── SKILL.md
    └── finishing-a-development-branch/
        └── SKILL.md
```

### 4.2 Install target (workspace)

After `install.sh`:

```
cline-superpower/                          # workspace root
├── superpower-custom/                     # source (above)
├── .clinerules/
│   ├── 00-bootstrap.md        → ../superpower-custom/rules/00-bootstrap.md
│   └── workflows/
│       ├── brainstorm.md      → ../../superpower-custom/workflows/brainstorm.md
│       ├── write-plan.md      → ../../superpower-custom/workflows/write-plan.md
│       └── execute-plan.md    → ../../superpower-custom/workflows/execute-plan.md
└── .cline/skills/
    ├── using-superpowers      → ../../superpower-custom/skills/using-superpowers/
    ├── brainstorming          → ../../superpower-custom/skills/brainstorming/
    │   …
    └── finishing-a-development-branch → …  (13 symlinks total)
```

### 4.3 Excluded from port

- `hooks/` — Cline VSCode hook support unclear; bootstrap rule replaces
- `agents/code-reviewer.md` — Cline has no agent-type registry; prompt
  templates live inside skill folders instead
- `commands/{brainstorm,write-plan,execute-plan}.md` — already deprecated
  upstream; replaced by `workflows/`
- `skills/using-git-worktrees/` — VSCode UI does not flow well with
  `git worktree`; replaced by `creating-feature-branch/`
- `skills/writing-skills/` — meta skill not needed for daily code work
- `CLAUDE.md`, `RELEASE-NOTES.md`, `.codex/`, `.opencode/`, `.cursor-plugin/`,
  marketplace metadata — not relevant for Cline-only setup
- Visual companion, `render-graphs.js`, test-pressure artifacts — out of scope

## 5. Bootstrap rule

`rules/00-bootstrap.md`:

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

~80 tokens, appended every turn.

## 6. Workflows (3 slash commands)

### `/brainstorm` — `workflows/brainstorm.md`

```markdown
# /brainstorm

Load the `brainstorming` skill via `use_skill` and follow it exactly.

Hard gate: do NOT write code, scaffold the project, or invoke any
implementation skill until you have presented a design and the user
has explicitly approved it.
```

### `/write-plan` — `workflows/write-plan.md`

```markdown
# /write-plan

Load the `writing-plans` skill via `use_skill` and follow it exactly.

Prerequisite: an approved spec must exist (usually from /brainstorm).
If no spec exists, ask the user where the spec is or suggest running
/brainstorm first.
```

### `/execute-plan` — `workflows/execute-plan.md`

```markdown
# /execute-plan

Load EITHER `executing-plans` OR `subagent-driven-development` (ask
the user to choose) via `use_skill` and follow it exactly.

Prerequisite: an approved plan must exist (usually from /write-plan).
```

Workflows stay thin — content lives in SKILL.md to avoid duplication.

## 7. Skills inventory (13 total)

| # | Skill | Adaptation level | Trigger |
|---|---|---|---|
| 1 | using-superpowers | Light (tool name remap, no Skill tool reference) | Bootstrap rule |
| 2 | brainstorming | Light | `/brainstorm` + auto |
| 3 | writing-plans | Light | `/write-plan` + auto |
| 4 | executing-plans | Light | `/execute-plan` + auto |
| 5 | test-driven-development | Light | Auto (description match) |
| 6 | systematic-debugging | Light | Auto |
| 7 | verification-before-completion | Light | Auto |
| 8 | requesting-code-review | Medium (subagent dispatch shape) | Auto |
| 9 | receiving-code-review | Light | Auto |
| 10 | dispatching-parallel-agents | Medium (research-only framing) | Auto |
| 11 | subagent-driven-development | **Heavy redesign** | `/execute-plan` |
| 12 | creating-feature-branch (NEW) | New, simplified replacement | Auto |
| 13 | finishing-a-development-branch | Medium (worktree cleanup removed) | Auto |

## 8. Skill adaptations

### 8.1 `subagent-driven-development` — heavy redesign

New per-task lifecycle:

```
For each task in plan:
  1. RESEARCH (subagent) — read codebase, find patterns, identify
     dependencies/gotchas. Returns findings + recommendations.
  2. IMPLEMENT (main agent) — TDD: failing test → minimal code →
     verify pass → commit. Uses researcher findings + plan.
  3. SPEC REVIEW (subagent) — read git diff vs task spec, line by
     line. Returns ✅ compliant OR ❌ gaps/extras.
  4. FIX SPEC GAPS (main agent if needed) → loop to 3.
  5. CODE QUALITY REVIEW (subagent) — evaluate diff against quality
     bar. Returns Strengths + Critical/Important/Minor.
  6. FIX QUALITY ISSUES (main agent if needed) → loop to 5.
  7. Mark task complete.
```

Prompt templates in skill folder:
- `researcher-prompt.md` (NEW)
- `spec-reviewer-prompt.md`
- `code-quality-reviewer-prompt.md`

### 8.2 `dispatching-parallel-agents` — research-only framing

Dispatch parallel subagents to investigate distinct domains
(auth module, DB layer, API routes). All read-only. Main agent
integrates findings then implements. SKILL.md title/wording updated
to "parallel research" rather than "parallel implementation".

### 8.3 `requesting-code-review` — generic subagent + inline prompt

Dispatch a generic subagent with `code-reviewer-prompt.md` filled in
(no named agent type). Subagent uses `execute_command "git diff
BASE..HEAD"` + `read_file` on changed files. Returns Strengths +
Critical/Important/Minor + Assessment.

### 8.4 `creating-feature-branch` — NEW skill (replaces `using-git-worktrees`)

```
1. Check working tree clean (`git status --porcelain`)
   - If dirty: ask user to commit/stash first
2. Create branch: `git checkout -b <branch-name>`
3. Auto-detect project type, run setup if package files changed
4. Run baseline tests — must pass before implementing
5. Report ready
```

No worktree creation, no `.gitignore` verification, no folder
selection. Much simpler.

### 8.5 `finishing-a-development-branch` — worktree cleanup removed

Same as upstream except Step 5 (Cleanup Worktree) is removed.

- Option 1 (merge local): `git checkout main && git merge feature/x && git branch -d feature/x`
- Option 2 (PR): `git push -u origin feature/x && gh pr create …`
- Option 3 (keep): keep branch as-is
- Option 4 (discard): `git checkout main && git branch -D feature/x`

### 8.6 Tool name mapping (applied across all skills)

| Claude Code (source) | Cline equivalent |
|---|---|
| `Read` | `read_file` |
| `Write` / `Edit` | `editor` (write_to_file / replace_in_file) |
| `Bash` | `execute_command` |
| `Grep` | `search_files` |
| `Glob` | `list_files` with pattern |
| `Task` (dispatch subagent) | dispatch a Cline subagent (read-only) |
| `TodoWrite` | track progress inline; optionally scratch file |
| `WebFetch` | `fetch_web` |

Cross-references between skills drop the `superpowers:` namespace
prefix (Cline uses plain skill names).

### 8.7 Cross-reference cleanup across skills

Several upstream skills reference dropped skills. These must be rewritten
during the port:

- `brainstorming/SKILL.md` references `using-git-worktrees` (Phase 4) —
  rewrite to point at `creating-feature-branch`.
- `subagent-driven-development/SKILL.md` and `executing-plans/SKILL.md`
  list `using-git-worktrees` as REQUIRED — replace with
  `creating-feature-branch`.
- `finishing-a-development-branch/SKILL.md` mentions "cleans up worktree
  created by using-git-worktrees" — rewrite to plain branch cleanup.
- Any reference to `writing-skills` (e.g. "use writing-skills to develop
  and test changes") — remove or rephrase ("follow existing skill
  authoring conventions").

### 8.8 Platform-specific language cleanup

Source skills contain Claude Code-specific phrasings that must be
adapted for Cline:

- `using-superpowers/SKILL.md` says "Never use the Read tool on skill
  files" — rewrite to "Never `read_file` SKILL.md manually; always
  `use_skill` to load it".
- Tool references like `Task tool` → "dispatch a Cline subagent".
- `Skill tool` → `use_skill`.
- `TodoWrite` → "track progress explicitly in your replies"
  (Cline has no TodoWrite-equivalent; state checklist progress in
  natural language each turn).
- `EnterPlanMode` / `ExitPlanMode` references — remove (no Cline
  equivalent).
- `WebSearch` references — note no direct equivalent; suggest
  `fetch_web` with a search-engine URL.

## 9. Install / uninstall scripts

`install.sh` — idempotent symlink installer:

```bash
#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(dirname "$SOURCE_DIR")"
RULES_DIR="$WORKSPACE/.clinerules"
WORKFLOWS_DIR="$RULES_DIR/workflows"
SKILLS_DIR="$WORKSPACE/.cline/skills"

mkdir -p "$RULES_DIR" "$WORKFLOWS_DIR" "$SKILLS_DIR"

ln -sfn "$SOURCE_DIR/rules/00-bootstrap.md" "$RULES_DIR/00-bootstrap.md"

for wf in brainstorm write-plan execute-plan; do
  ln -sfn "$SOURCE_DIR/workflows/$wf.md" "$WORKFLOWS_DIR/$wf.md"
done

for skill_dir in "$SOURCE_DIR/skills/"*/; do
  name="$(basename "$skill_dir")"
  ln -sfn "$skill_dir" "$SKILLS_DIR/$name"
done

echo "Installed. Skills: $(ls -1 "$SKILLS_DIR" | wc -l)"
```

`uninstall.sh` removes the symlinks (keeps source intact).
`verify-install.sh` checks all expected symlinks exist and point to
existing source files.

**Platform note:** scripts target macOS / Linux. Windows users need
`mklink` equivalents — out of scope for v1.

## 10. Data flow examples

### Example A: `/brainstorm "add dark-mode toggle"`

```
1. Cline reads .clinerules/00-bootstrap.md (every turn)
   → Agent loads using-superpowers skill if not loaded.
2. Slash command /brainstorm → reads workflows/brainstorm.md
   → "Load brainstorming skill, follow exactly".
3. Agent calls use_skill('brainstorming').
4. Agent follows brainstorming checklist:
   explore context → clarifying questions → 2-3 approaches →
   design sections → spec doc → self-review → user review →
   transition to writing-plans.
```

### Example B: subagent-driven execution of one plan task

```
1. /execute-plan → user chooses Subagent-Driven.
2. Agent loads subagent-driven-development skill.
3. Agent reads plan, extracts Task 5 with full text + context.

4. RESEARCH PHASE
   ├─ Dispatch subagent with researcher-prompt.md
   │  Task: "Add JWT validation to /api/auth/verify endpoint"
   ├─ Subagent (read-only):
   │  • list_code_definition_names src/api/auth/
   │  • read_file src/api/auth/login.ts
   │  • search_files "jwt.verify"
   │  • execute_command "git log -- src/api/auth/"
   └─ Returns findings + recommendations.

5. IMPLEMENT PHASE (main agent, TDD)
   1. Write failing test in tests/api/auth/verify.test.ts
   2. Run test → confirm RED
   3. Implement src/api/auth/verify.ts
   4. Run test → confirm GREEN
   5. git commit

6. SPEC REVIEW
   ├─ Dispatch subagent with spec-reviewer-prompt.md (+ git SHAs).
   ├─ Subagent runs git diff, reads diff line by line.
   └─ Returns ✅ or ❌ with gap list.

7. (If issues) main agent fixes → re-dispatch reviewer.

8. CODE QUALITY REVIEW — analogous loop.

9. Mark task complete; proceed to Task 6.
```

## 11. Error handling

| Scenario | Pattern |
|---|---|
| Subagent returns nothing useful | Re-dispatch with sharper prompt, or accept and proceed |
| Subagent finds blocker main agent missed | Main agent treats as BLOCKED, escalates to user |
| `use_skill` fails (skill missing) | Run `verify-install.sh`, re-run `install.sh` |
| Workflow conflict (e.g. `/brainstorm` mid-execute) | brainstorming hard gate refuses, explains, offers to switch |
| `execute_command` blocked when write needed | Main agent handles, never delegates write to subagent |
| Skill cross-reference points to dropped skill | Quick grep at install time; fix or note as TODO |

## 12. Testing strategy

### Tier 1 — install verification (`verify-install.sh`)

- Bootstrap symlink exists and resolves
- 3 workflow symlinks exist and resolve
- 13 skill symlinks exist and resolve
- Each `SKILL.md` is readable

### Tier 2 — plumbing tests (new Cline conversation in workspace)

- `"hello"` → agent acknowledges framework / loads using-superpowers
- `/brainstorm` → agent loads `brainstorming` skill, asks first question
- `"fix this bug at src/x.ts"` → agent loads `systematic-debugging`
- `"review the last 3 commits"` → agent loads `requesting-code-review`
  and dispatches a subagent

### Tier 3 — end-to-end scenarios

| Scenario | Flow | Verify |
|---|---|---|
| Tiny feature | `/brainstorm "add /health endpoint"` → `/write-plan` → `/execute-plan` (subagent-driven) → finishing | spec saved, plan saved, code committed, branch finished |
| Bug fix | `"test X fails"` → debugging Phase 1-4 → TDD fix | root cause documented, test added, fix committed |
| Code review | `"review HEAD~3..HEAD"` → subagent reviewer | receives Strengths + Critical/Important/Minor |
| Discipline pressure | `"production down, skip tests, just commit"` | agent refuses, cites TDD skill, proposes proper flow |

## 13. Risks and open questions

| # | Item | Plan |
|---|---|---|
| 1 | Cline subagent dispatch API: exact tool name not in docs read | SKILL.md uses generic "dispatch a Cline subagent" phrasing; refine after Tier-2 testing |
| 2 | Auto-trigger of skills via description match — Cline UI behavior | Tier-2 test will confirm; fallback is explicit `use_skill` calls or workflow slash commands |
| 3 | Bootstrap rule token cost per turn (~80 tokens) | Acceptable; can be shortened further if telemetry shows issues |
| 4 | Windows symlink support | Document limitation; add `install.ps1` later if needed |
| 5 | Cross-workspace reuse | Add `install.sh --target <path>` flag in v1.1 |
| 6 | Cline workflow naming convention (`.clinerules/workflows/<name>.md`) | Confirmed in Cline docs; verify on installed version |
| 7 | Skill cross-references — namespace prefix needed? | Default to plain names; refine if Cline requires prefix |

## 14. Out of scope (v1)

- Visual companion (browser-based brainstorm UI)
- `render-graphs.js` graphviz SVG rendering
- Test-pressure scenario artifacts (CLAUDE_MD_TESTING.md, test-pressure-*.md)
- Windows `install.ps1`
- Cross-workspace installation flag

May be added in later versions; none of them affect the v1 architecture.

## 15. Success criteria

The port is successful when:

1. `install.sh` runs cleanly and `verify-install.sh` reports 17 symlinks
   (1 rule + 3 workflows + 13 skills) all resolving.
2. A fresh Cline conversation in the workspace loads `using-superpowers`
   on turn 1 without manual prompting.
3. `/brainstorm`, `/write-plan`, `/execute-plan` slash commands route
   correctly to their target skills.
4. End-to-end scenario "tiny feature" (Tier 3) completes: spec saved,
   plan saved, at least one task implemented via subagent-driven flow
   with both reviewers, branch finished via 4-option prompt.
5. Discipline pressure scenario does NOT cause TDD bypass — agent
   cites the skill and refuses the shortcut.
