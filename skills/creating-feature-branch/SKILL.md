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
