---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load the plan, review it critically, execute every task in order with verification, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support. If subagents are available, use `subagent-driven-development` instead of this skill.

## Plan format detection

Before doing anything else, identify which format the plan uses:

- **Single-file plan** — one `.md` file in `docs/superpowers/plans/`. Open it; every task is in this file.
- **Multi-file plan** — a folder in `docs/superpowers/plans/` containing `README.md` and one `task-NN-<slug>.md` per task.

For multi-file plans you **never load every task into context up front**. You read the README to orient, then open exactly the task file you are currently working on. When that task is committed and verified complete, close it (stop referencing it) and open the next.

## The Process

### Step 1: Load and review the plan

**Single-file:**
1. Read the plan file.
2. Review critically — gaps, contradictions, missing test code, unspecified file paths.
3. If concerns: raise them with the user before starting.
4. If clean: track tasks explicitly and proceed.

**Multi-file:**
1. Read `README.md` — confirm the Goal, Architecture, file list, and task list.
2. Spot-check by reading `task-01-<slug>.md` only. Verify the format matches the task template.
3. Review the README critically — same checks as single-file at the index level.
4. Do **not** read every task file. Open them one at a time when their turn comes.
5. If concerns: raise them with the user before starting.

### Step 2: Execute tasks

For each task in order:

1. (Multi-file only) Open `task-NN-<slug>.md`. Read it fully.
2. Mark the task as in-progress in your reply.
3. Follow each step exactly — the plan has bite-sized steps for a reason.
4. Run every verification (test runs, command outputs) as specified.
5. Commit when the task says to commit, with the exact message it specifies.
6. Mark the task complete.
7. (Multi-file only) Stop referencing the previous task file. Move on.

### Step 3: Complete development

After all tasks are committed and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** `finishing-a-development-branch`

## Anti-pattern — shortcutting from the spec

**STOP if you find yourself thinking any of these:**

- "The plan is too long — I'll just code from the spec directly."
- "This task is obvious — no need to follow each step."
- "I can write everything in one go and skip the per-step verification."
- "The plan says write the failing test first but I already know it will pass."
- "It's faster to do all tasks in one commit instead of one per task."

These are the failure modes this skill exists to prevent. The plan is short *because* the slim-code heuristic removed code you can derive — but it kept the **verification steps**, the **test contracts**, and the **commit boundaries** for a reason. Obvious-looking tasks have non-obvious failure modes. Per-step verification is what catches them. Per-task commits are what let the user roll back surgically.

**If the plan genuinely seems too long, has a gap, or has a contradiction, raise it to the user.** Do not improvise. Options to offer them:

- Split the plan into phases and execute one phase
- Re-scope the feature
- Re-run `writing-plans` with stricter slim-code application
- Pause and discuss the specific concern

Never silently degrade the workflow.

## When to stop and ask for help

Stop executing immediately when:

- You hit a blocker (missing dependency, test fails for an unexpected reason, instruction unclear).
- The plan has a critical gap preventing you from starting a task.
- You do not understand an instruction.
- Verification fails repeatedly on the same step.
- You feel tempted to shortcut (see the anti-pattern above).
- The plan turns out to be much longer in practice than expected — surfaces of work the plan did not name.

Ask the user. Do not guess.

## When to revisit earlier steps

Return to Step 1 (Load and review) when:

- The user updates the plan based on your feedback.
- A fundamental approach needs rethinking.

Do not force through blockers — stop and ask.

## Remember

- Review the plan critically before starting.
- Multi-file plan: read README first, then one task file at a time. Never load all tasks at once.
- Follow every step exactly — slim plan ≠ optional steps.
- Run every verification.
- Per-task commits with the exact message the plan specifies.
- Stop when blocked; never guess.
- Never start implementation on `main`/`master` without explicit user consent.

## Integration

**Required:**
- `creating-feature-branch` — set up a clean feature branch before starting.
- `writing-plans` — produced the plan you are executing.
- `finishing-a-development-branch` — close the work after all tasks complete.
