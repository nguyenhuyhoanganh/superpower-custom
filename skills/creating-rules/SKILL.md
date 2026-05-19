---
name: creating-rules
description: Creates new Cline rules (.clinerules/*.md or *.txt) when the user wants persistent, always-on behavioral guidance for a project. Covers file location, optional frontmatter for path-conditional rules, the rules-vs-workflows-vs-skills-vs-hooks decision, writing for token efficiency, and ordering with numeric prefixes.
---

# Creating Cline Rules

A Cline rule is a markdown or text file under `.clinerules/` that is appended to the system prompt on every message. Use this skill when the user wants persistent, project-wide guidance — coding conventions, architectural constraints, file-handling policies, or any "always do X" rule.

## When a rule is the right tool

Before writing a rule, confirm it is the right tool:

| Need | Use |
|---|---|
| "Always behave like X" (style, conventions, constraints) | **Rule** — always on |
| "When I say `/Y`, do step 1, 2, 3" (procedural, multi-step) | **Workflow** — see `creating-workflows` |
| "When I ask about Z, follow this specialized procedure" | **Skill** — see `creating-skills` |
| "On event E (task start, tool use), inject context or block" | **Hook** — see `creating-hooks` |

Rules drain context on every message. **Default to a workflow or skill if the guidance is procedural or task-specific.** See the archived Cline blog post: [references/stop-adding-rules-when-you-need-workflows.md](references/stop-adding-rules-when-you-need-workflows.md) — read it when the user is on the fence about which artifact to write.

## Anatomy

```
<workspace>/.clinerules/
├── 00-bootstrap.md         ← numeric prefixes set load order (optional)
├── 01-coding-style.md
├── 02-testing.md
└── components-only.md      ← may have YAML frontmatter for conditional loading
```

- Cline reads **all** `.md` and `.txt` files in `.clinerules/`
- Workspace rules merge with global rules (`~/Documents/Cline/Rules/`); workspace wins on conflict
- Numeric prefixes (`00-`, `01-`, …) order the files; they are optional but recommended when one rule must precede another
- Both Cursor (`.cursorrules`) and Windsurf (`.windsurfrules`) files are auto-detected if present — but for new rules, prefer `.clinerules/`

## File format

Plain markdown body. No frontmatter required for always-on rules.

For **path-conditional rules** (load only when relevant files are open / referenced), add YAML frontmatter:

```markdown
---
paths:
  - "src/components/**"
  - "src/hooks/**"
---

# React component rules

- Use functional components only
- ...
```

The rule activates when current files match any glob pattern. Without frontmatter, the rule is **always loaded**.

Glob syntax: `*` (non-recursive), `**` (recursive), `?` (single char), `[abc]` (sets), `{a,b}` (alternatives).

Path-conditional triggers fire on: files referenced in the user message, open editor tabs, visible files in panes, files Cline has edited, and pending operations.

## Naming and organization

- **One concern per file** — `coding-style.md`, `testing.md`, `git.md`. Easier to toggle off individually from the Cline Rules panel.
- **Numeric prefix** (`01-`, `02-`, …) when load order matters (e.g., a bootstrap rule that should come first).
- **kebab-case** filenames.
- Avoid generic names (`rules.md`, `notes.md`) — they collide and lose meaning over time.

## Writing rules

Rules add to every system prompt, so every line costs tokens on every message. Apply these guidelines:

### Be specific

| Vague | Specific |
|---|---|
| "Write clean code" | "Use camelCase for variables, PascalCase for classes" |
| "Follow conventions" | "Place tests in `__tests__/` next to the source they cover" |
| "Be careful with the DB" | "Wrap migrations in `BEGIN; ... COMMIT;`" |

### Include the why (short)

A rule with a one-line rationale survives edits better than a bare commandment. Rationale also lets the agent judge edge cases.

```markdown
- Do not modify files in `legacy/` — scheduled for removal in Q3-2026
- Run `npm run typecheck` before commits — CI fails on type errors
```

### Reference real code, not theory

Point to concrete examples in the codebase instead of describing patterns abstractly:

> Error handling: see `src/utils/errors.ts` — wrap thrown errors in `AppError` with a category.

### Keep it scannable

Use headings and bullets. The agent skims rules every turn.

```markdown
# Coding style

## Naming
- camelCase for variables and functions
- PascalCase for classes and types

## Error handling
- Throw `AppError` with category; see `src/utils/errors.ts`
- Never swallow exceptions silently
```

### Cut filler ruthlessly

The agent already knows what "function", "variable", "PR" mean. Trim:

- Bad: "When writing functions, you should consider naming them clearly using camelCase..."
- Good: "Functions: camelCase, verb-first (`fetchUser`, not `userFetcher`)"

### Avoid time-sensitive claims

"As of 2026 we use React 18" rots. Either omit the date or put legacy info under a clear `## Old patterns` heading.

## Anti-patterns

| Anti-pattern | What to do instead |
|---|---|
| Procedural rule ("To deploy: run X, then Y, then Z") | Make it a **workflow** — see `creating-workflows` |
| One mega-file `rules.md` with everything | Split by concern; one file per topic |
| Pasting an entire style guide | Link out: "See `docs/style.md`" |
| Vague rule ("write good tests") | Specific rule with example |
| Rules with no rationale | Add a one-line "why"; helps judgment on edge cases |
| Rules duplicating built-in agent behavior | Drop them — wastes tokens |
| Personal paths (`/Users/alice/...`) | Workspace-relative paths only |
| Hardcoded secrets / API keys / hostnames | Read from env vars or config files instead |

## Process

The user has stated what behavior they want enforced. Convert it into a rule file.

### 1. Decide: rule, workflow, skill, or hook?

Re-read the request. If it is procedural ("when I say X, do steps 1-2-3"), redirect to `creating-workflows`. If it is event-driven ("on task start, inject context"), redirect to `creating-hooks`. If it is expert knowledge invoked by topic, redirect to `creating-skills`. Otherwise proceed.

### 2. Pick the file path

- One concern per file: `coding-style.md`, `testing.md`, `git.md`
- Numeric prefix if load order matters
- Workspace path: `.clinerules/<name>.md`

### 3. Decide: always-on or path-conditional?

- Conventions for the whole project → always-on (no frontmatter)
- Conventions for a subdir or filetype → path-conditional (frontmatter with `paths:` globs)

### 4. Write the rule

Headings + bullets. Each bullet specific and short. Include rationale where non-obvious. Reference real code paths.

### 5. Self-review

- Could you delete any bullet without losing meaning? Delete it.
- Is anything in here the agent already knows? Cut.
- Any rule that would be better as a workflow? Move it.
- Any hardcoded personal paths or machine-specific config? Replace.
- Will this still be true in 6 months? If not, mark with rationale or move to "Old patterns".

### 6. Tell the user where it landed

`.clinerules/<name>.md`. Cline reloads rules every turn — no restart needed. The Rules panel can toggle the rule on/off without deleting the file.

## Example walkthrough

**User:** "Always run `npm run lint` and `npm run typecheck` before committing. Tests go in `__tests__/` next to source. Error responses always use `AppError`."

**1. Rule, not workflow** — three behavioral constraints, not a sequence.

**2. Path:** `.clinerules/01-engineering.md` (general engineering rules; numeric prefix in case more topical rules are added later).

**3. Always-on** — applies project-wide.

**4. Write:**

```markdown
# Engineering rules

## Pre-commit
- Run `npm run lint` and `npm run typecheck` before every commit
- Reason: CI rejects PRs that fail either

## Tests
- Place tests in a `__tests__/` folder next to the source they cover
- Example: `src/auth/login.ts` → `src/auth/__tests__/login.test.ts`

## Errors
- All error responses use `AppError` from `src/utils/errors.ts`
- Never throw bare `Error` or return raw exception messages to the client
```

**5. Self-review:** each bullet specific, rationale included where helpful, no filler, no personal paths.

**6. Path:** `.clinerules/01-engineering.md`. Active on the next Cline turn.
