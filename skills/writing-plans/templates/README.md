# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL — Use `subagent-driven-development` (recommended) or `executing-plans` to implement this plan task-by-task. This is a **multi-file plan**: read this README first, then open the `task-NN-<slug>.md` file for the current task only. Steps use checkbox (`- [ ]`) syntax.

**Goal:** [One sentence describing what this builds.]

**Architecture:** [2-3 sentences about the approach.]

**Tech Stack:** [Key technologies / libraries.]

**Files:**
- Create: `path/a`, `path/b`
- Modify: `path/c`, `path/d`
- Test: `tests/path/...`

---

## Tasks

Execute in order. Each task has its own file in this folder.

1. [Task 01 — `<slug>`](task-01-<slug>.md) — [One-line summary of what this task delivers]
2. [Task 02 — `<slug>`](task-02-<slug>.md) — [...]
3. [Task 03 — `<slug>`](task-03-<slug>.md) — [...]
4. ...

## Dependencies

If tasks must be run strictly in order, say so:

> Tasks must be executed strictly in order — each builds on the data structures or interfaces introduced in the previous one.

If some tasks can run in parallel or in any order, name the independent groups:

> Tasks 1-3 must precede 4-7 (they introduce the schema). Tasks 4, 5, 6, 7 are independent of each other once the schema is in place.

## Notes for the executor

- Read the relevant `task-NN-<slug>.md` and execute it in full before opening the next.
- Do **NOT** load all task files into context up front — that defeats the multi-file structure.
- If a task feels too long or unclear, raise it to the user. Do not shortcut to coding from the spec.
- After the final task, invoke `finishing-a-development-branch`.
