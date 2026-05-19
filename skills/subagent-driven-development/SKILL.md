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

## Plan format detection

Before starting, identify which format the plan uses:

- **Single-file plan** — one `.md` file. Read it once; for each task, paste the task's text into the dispatch prompts below.
- **Multi-file plan** — a folder with `README.md` + `task-NN-<slug>.md` files. Read `README.md` to orient. For each task, open exactly `task-NN-<slug>.md`, paste its content into the dispatch prompts, and stop referencing it once the task is committed.

In either case, **paste the task text into the subagent prompt** — do not make the subagent open the plan file. Read it yourself, copy the bytes the subagent needs.

## When to Use

- After `/execute-plan` and the user chose subagent-driven mode
- When tasks in the plan are mostly independent
- When you want fast iteration with automatic review checkpoints between tasks

**vs. executing-plans (single-session inline batch):**
- subagent-driven runs research and reviews via subagents (cleaner context)
- executing-plans skips subagents and uses checkpoints with the user

## The Process

For each task in the plan:

### 0. OPEN THE TASK (main agent)

For multi-file plans, open `task-NN-<slug>.md` now and read it fully. This is the
only task file you keep open during this loop iteration. For single-file plans,
locate the task block and copy its text into a local note.

### 1. RESEARCH PHASE (subagent)

Dispatch a Cline subagent using the template at `researcher-prompt.md`,
filled with:
- The full text of the task (paste it; do not make the subagent open the
  plan file or folder).
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

Update your progress tracking. (Multi-file plan: stop referencing
`task-NN-<slug>.md` from now on — it is done. Open the next task file
in the next iteration.) Move to the next task.

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
