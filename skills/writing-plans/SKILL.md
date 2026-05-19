---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write implementation plans that drive disciplined execution without bloating the agent's context. The plan is a **contract** (file paths + test code + verification + commit points), not a **script** (every line of implementation code). Code that the engineer can derive from a good spec stays in the spec, not in the plan.

Assume the executor is a skilled developer with no project context. Assume they will be tempted to "just code from the spec" if the plan ever feels too long — write the plan so that temptation never reaches them.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run on a clean feature branch (created by the brainstorming skill via creating-feature-branch).

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md` (single file) or `docs/superpowers/plans/YYYY-MM-DD-<feature-name>/` (multi-file folder).
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## Single-file vs multi-file format

Count the tasks before you start writing.

| Task count | Format | Layout |
|---|---|---|
| ≤ 6 tasks | **Single file** | `docs/superpowers/plans/YYYY-MM-DD-<name>.md` |
| > 6 tasks | **Multi-file folder** | `docs/superpowers/plans/YYYY-MM-DD-<name>/README.md` + `task-NN-<name>.md` |

The multi-file form lets the executor (and any Cline-style single-context agent) load one task at a time instead of carrying the whole plan in context every turn. The README is the index; each task lives in its own file.

If the count is borderline (5-7 tasks), prefer single file when tasks are tightly coupled, multi-file when they are independent.

## File Structure

Before defining tasks, map out which source files will be created or modified and what each is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file has one clear responsibility.
- Smaller, focused files beat large files that do too much.
- Files that change together live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. Restructure only when a file you must modify has grown unwieldy.

This structure informs task decomposition. Each task produces self-contained changes that make sense independently.

## Bite-Sized Task Granularity

Each step is one action (2-5 minutes):

- "Write the failing test" — step
- "Run it to make sure it fails" — step
- "Implement the minimal code to make the test pass" — step
- "Run the tests and make sure they pass" — step
- "Commit" — step

## Slim code heuristic — keep vs cut

The plan is not the place to re-derive design or paste obvious boilerplate. Code in the plan must earn its tokens.

**KEEP full code in the plan when it is the contract:**
- Test code — the test *is* the contract; show it in full
- Type / interface / API signatures the engineer must match
- Exact output formats the engineer must produce (JSON shape, CSV header, file layout)
- Non-obvious patterns or gotchas the engineer would otherwise get wrong
- Exact shell commands and expected output for verification
- Exact commit messages and `git` invocations

**CUT code from the plan and replace with a one-line description + spec reference when it is derivable:**
- "Minimal implementation to make the test pass" — the test already specifies behavior
- Trivial getters / setters, constructors, default initializers
- Boilerplate scaffolding the engineer writes daily
- Code that simply re-states what is in the spec — link to spec §X.Y instead
- Step-by-step prose translation of the test ("loop through array and apply X")

**Example.** Step 3 (Implement):

Bad — bloated:

````markdown
- [ ] Step 3: Write minimal implementation

```python
def function(input):
    return expected
```
````

Good — slim:

```markdown
- [ ] Step 3: Implement `function` to satisfy the test.
      Algorithm in spec §3.2. Keep it pure (no side effects, no I/O).
```

Reference: see [references/slim-code-heuristic.md](references/slim-code-heuristic.md) for the full keep/cut matrix and worked examples.

## Plan formats

### Single-file plan header

Every single-file plan starts with this header (template at [templates/single-file.md](templates/single-file.md)):

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Files:**
- Create: `path/a`, `path/b`
- Modify: `path/c`, `path/d`

---
```

### Multi-file plan layout

```
docs/superpowers/plans/YYYY-MM-DD-<name>/
├── README.md              ← index (template: templates/README.md)
├── task-01-<slug>.md
├── task-02-<slug>.md
└── ...
```

- `README.md` contains the same header (Goal / Architecture / Tech Stack / Files) **plus a task list** (one line per task, linking to `task-NN-<slug>.md`).
- Each `task-NN-<slug>.md` contains only its own task — same structure as a single-file task block.
- Templates: [templates/README.md](templates/README.md) and [templates/task.md](templates/task.md).

The executor reads `README.md` first to get oriented, then opens `task-NN-<slug>.md` for the task it is currently working on.

## Task Structure (applies to single-file tasks and individual task-NN files)

````markdown
### Task N: [Component Name]

**Goal:** [One sentence]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Implement `function`**

Algorithm in spec §3.2. Match the test's input/output exactly.
Keep pure: no I/O, no shared state.

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature (task N)"
```
````

Notice: full test code in Step 1 (it is the contract); description + spec reference in Step 3 (the implementation is derivable from the test).

## No Empty Placeholders

These are **plan failures** — never write them:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the test code — the engineer may read tasks out of order)
- Step that says "implement X" without naming the function and pointing at the spec section
- References to types, functions, or methods not defined in any task or spec

A slim plan ≠ a vague plan. Cutting code requires a precise pointer (spec § / file:line / test name) so the engineer cannot guess wrong.

## Remember

- Exact file paths always
- Test code in full (it is the contract); implementation code only when non-obvious
- Exact commands with expected output
- Exact commit messages
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. Run yourself — not a subagent.

1. **Spec coverage:** skim each section / requirement in the spec. Can you point to a task that implements it? List any gaps.
2. **Placeholder scan:** any "TBD", vague handling, missing code that is the contract (test code, signatures)? Fix.
3. **Type consistency:** types, method signatures, property names match across tasks? `clearLayers()` in Task 3 and `clearFullLayers()` in Task 7 is a bug.
4. **Slim review:** any implementation code block that just re-states the test? Cut it and replace with the description + spec reference. Conversely, any cut step that lacks a precise pointer to the spec / test / file? Restore the pointer.
5. **Size sanity:** if multi-file, is every `task-NN.md` under ~150 lines? If not, split it or move detail to spec.

Fix inline. No re-review — just fix and move on.

## Execution Handoff

After saving the plan, offer execution choice:

> Plan complete and saved to `<path>`. Two execution options:
> 1. **Subagent-Driven (recommended)** — dispatch a fresh subagent for research / review per task, main agent implements, two-stage review
> 2. **Inline Execution** — execute tasks in this session with checkpoints, no subagents
>
> Which approach?

**If Subagent-Driven chosen:** REQUIRED SUB-SKILL → `subagent-driven-development`.

**If Inline Execution chosen:** REQUIRED SUB-SKILL → `executing-plans`.
