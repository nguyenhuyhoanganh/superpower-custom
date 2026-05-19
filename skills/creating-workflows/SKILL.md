---
name: creating-workflows
description: Creates new Cline workflows (.clinerules/workflows/*.md) invoked via slash commands for repeatable multi-step procedures. Covers file location, slash command invocation with arguments, structuring sequential steps, the workflows-vs-rules decision, and best practices for procedural automation.
---

# Creating Cline Workflows

A Cline workflow is a markdown file under `.clinerules/workflows/` that the user invokes with a slash command (`/<filename>`). Cline wraps the file's contents in `<explicit_instructions>` and injects them into that specific message. The workflow runs once, completes its sequence, and disappears from context on the next turn.

Use this skill when the user wants to capture a repeatable procedure — PR review, deploy steps, release cut, branch finishing, etc. — as a one-shot reusable command.

## When a workflow is the right tool

| Need | Use |
|---|---|
| "When I say `/Y`, do step 1, 2, 3" (procedural, multi-step, on-demand) | **Workflow** |
| "Always behave like X" (continuous, every message) | **Rule** — see `creating-rules` |
| "When I ask about Z, follow specialized expert procedure" | **Skill** — see `creating-skills` |
| "On event E, inject context or block a tool" | **Hook** — see `creating-hooks` |

Workflows consume tokens **only when invoked**. Rules consume tokens **every message**. If the procedure is "first I do X, then Y, then Z," prefer a workflow over a rule. See [Stop adding rules when you need workflows](https://cline.bot/blog/stop-adding-rules-when-you-need-workflows).

## Anatomy

```
<workspace>/.clinerules/workflows/
├── pr-review.md
├── cut-release.md
├── deploy.md
└── brainstorm.md
```

- Workspace workflows: `.clinerules/workflows/*.md`
- Global workflows: `~/Documents/Cline/Workflows/*.md`
- Workspace workflows **override** globals with the same filename

## Invocation

In a Cline chat, type `/` to see available workflows. Invoke:

```
/pr-review          # filename without extension
/pr-review.md       # with extension — both work
```

Anything typed after the command becomes part of the user message — workflows read it as arguments:

```
/cut-release v1.2.0
```

```markdown
# cut-release.md

The user has invoked /cut-release. If they passed an argument (a version
number like v1.2.0), use it as the target version; otherwise ask.
```

## File format

Plain markdown. Optional XML tags help structure intent and let the agent parse the workflow more reliably:

```markdown
# PR Review

<task_objective>
Review the current branch's PR against main and post structured feedback.
</task_objective>

<detailed_sequence_of_steps>

1. Run `gh pr view` to get the PR metadata.
2. Run `gh pr diff` to read the changes.
3. For each changed file, assess:
   - Correctness
   - Tests
   - Style consistency with the project
4. Build a feedback list grouped by file.
5. Post the review via `gh pr review --comment --body-file <file>`.

</detailed_sequence_of_steps>
```

XML tags are conventions, not required — the agent reads plain markdown too. Use them once the workflow is long enough that explicit structure helps.

## Naming

- **kebab-case**, `.md` extension: `cut-release.md`, `pr-review.md`, `db-migrate.md`
- **Verb-based** for actions: `deploy.md`, `seed-data.md`
- Match the slash command the user will type — `/cut-release` ⇒ `cut-release.md`
- Avoid collisions with built-in slash commands (`/newtask`, `/smol`, `/newrule`, `/deep-planning`, `/explain-changes`, `/reportbug`)

## Writing workflows

### Lead with the objective

State what done looks like. The agent can then choose tactics:

```markdown
<task_objective>
Cut a tagged release on the current branch, push the tag, and post the
release notes to #releases on Slack.
</task_objective>
```

### High-level steps, not micromanaged tool calls

Cline interprets intent. Write steps like a runbook for a competent colleague:

```markdown
1. Confirm the working tree is clean; abort if not.
2. Read the current version from `package.json`.
3. Ask the user for the new version (semver bump). If passed as an
   argument to /cut-release, use that.
4. Update `package.json`, commit, and tag `v<new-version>`.
5. Push the branch and the tag.
6. Generate release notes from `git log <prev-tag>..HEAD`.
7. Post notes to #releases.
```

Step 4 doesn't list "use the Edit tool then `execute_command git commit`" — the agent already knows. Specify tools only when the choice matters.

### Include decision points

When a step branches, name the branches:

```markdown
3. If the working tree is dirty:
   - Show the dirty files
   - Ask the user whether to stash, commit, or abort
   - Do not proceed until the tree is clean
```

### Reference real tools and artifacts

Cline has built-in tools (`read_file`, `search_files`, `execute_command`) and may have MCP servers configured. Mention them when the choice matters:

```markdown
2. Use `search_files` to find all `TODO(release-blocker)` comments.
3. Use `execute_command` to run `git log` for the release-notes section.
4. If a Slack MCP server is configured, post via that; otherwise print the
   notes for the user to paste manually.
```

A workflow can refer to other artifacts by relative path:

```markdown
4. Read `.clinerules/01-engineering.md` for the project's commit-message format.
5. Run `scripts/release/notes.sh` to assemble the changelog draft.
```

### Stop conditions and rollback

If the workflow can leave the project in a half-applied state, name the safe abort points and how to roll back:

```markdown
5. If `git push --tags` fails: do not run step 6.
   Roll back with: `git tag -d v<new-version>` and revert the version commit.
```

## Anti-patterns

| Anti-pattern | What to do instead |
|---|---|
| Workflow that just states a behavior ("always lint") | Make it a **rule** in `.clinerules/` |
| Single-step workflow ("run `npm test`") | Not worth a workflow — agent already handles |
| Workflow with no objective, only numbered steps | Lead with `<task_objective>` so agent can adapt |
| Hardcoded paths, secrets, machine-specific config | Use args, env vars, or workspace-relative paths |
| 30-step workflow with no structure | Split into smaller workflows that call each other |
| Filler prose ("Cline is an AI assistant that...") | Cut — agent already knows itself |
| Reimplementing a built-in slash command | Don't duplicate `/newtask`, `/smol`, `/deep-planning` |
| Workflow forgets the rollback path | Name safe abort points and how to undo |
| Workflow name collides with `/newrule`, `/smol`, etc. | Pick a distinct name |

## Process

The user wants a procedure captured as a slash command.

### 1. Decide: workflow, rule, skill, or hook?

If always-on → rule. If event-triggered → hook. If specialized expert knowledge invoked by topic → skill. If "when I say `/X`, do Y" → workflow. Proceed.

### 2. Pick a slash command name

kebab-case verb. Test by saying it: `/cut-release` ✓, `/release-cutter` ✗. Check for collisions with built-in commands.

### 3. Pick the file path

`.clinerules/workflows/<name>.md`.

### 4. Write the objective

One paragraph in `<task_objective>` describing the done state.

### 5. Write the steps

Numbered, high-level, with branches and tool hints where helpful. Stay under ~40 lines for most workflows; split if longer.

### 6. Handle arguments

If the user will pass arguments (`/cut-release v1.2.0`), say so explicitly in the workflow body and tell the agent how to read them from the user message.

### 7. Add stop / rollback guidance

If the workflow can leave the project mid-state, name the safe abort points and how to undo.

### 8. Self-review

- Could a colleague follow these steps without asking?
- Any step that's just "Cline already does this"? Cut.
- Any decision point left implicit? Name the branches.
- Any hardcoded path / config? Replace with arg or env var.
- Does the name collide with anything?

### 9. Tell the user how to invoke

```
/<name>             # or /<name>.md
/<name> <args>
```

## Example walkthrough

**User:** "Make me a workflow `/cut-release` that bumps the version, tags, pushes, and posts a release note."

**1. Workflow** ✓ (procedural).

**2. Name:** `cut-release` ⇒ file `cut-release.md`.

**3. Path:** `.clinerules/workflows/cut-release.md`.

**4-5. Draft:**

```markdown
# Cut Release

<task_objective>
Cut a tagged release on the current branch, push the tag, and post release notes.
</task_objective>

<detailed_sequence_of_steps>

1. Confirm the working tree is clean. Abort if not.
2. Read the current version from `package.json`.
3. Determine the new version:
   - If the user passed an argument to `/cut-release`, use it
   - Otherwise ask the user for the semver bump (patch/minor/major)
4. Update `package.json` and `CHANGELOG.md`; commit with message
   `chore(release): v<new-version>`.
5. Run `git tag v<new-version>` and `git push --follow-tags`.
6. Generate release notes from `git log v<prev>..HEAD --oneline`.
7. Post the notes to #releases via the Slack MCP server if available;
   otherwise print them for the user to paste.

</detailed_sequence_of_steps>

<rollback>
If step 5 fails after the commit lands, undo with:
  git tag -d v<new-version>
  git reset --hard HEAD~1
</rollback>
```

**6. Arguments:** handled in step 3.

**7. Rollback:** included.

**8. Self-review:** objective ✓, steps high-level ✓, decision point in step 3 ✓, rollback ✓.

**9. Invoke:** `/cut-release` or `/cut-release v1.2.0`.
