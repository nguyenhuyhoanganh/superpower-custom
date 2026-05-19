---
name: creating-skills
description: Use when the user asks to create a new Cline skill, capture a recurring workflow as a reusable skill, or says "make this into a skill" — covers when a skill is worth creating, folder layout, SKILL.md frontmatter, description-writing for discoverability, and installation.
---

# Creating Cline Skills

A skill is a markdown document Cline loads on demand via `use_skill` to perform a specific task with embedded discipline, process, or domain knowledge. Use this skill when the user wants to turn a workflow into a reusable, agent-invokable skill.

## When to create a skill (and when not to)

Create a skill when the work is:

- **Repeatable** — the same procedure will be needed again, in different conversations
- **Disciplined** — there is a right way and a wrong way, and the agent will drift without explicit guardrails (TDD, debugging, code review)
- **Knowledge-heavy** — it bakes in expert knowledge the agent would otherwise re-derive (framework conventions, deployment rituals, project-specific anti-patterns)

Do **NOT** create a skill for:

- One-off tasks (just do them inline)
- Pure reference material (a regular markdown doc in the repo is fine)
- Generic coding tasks the agent already handles (don't wrap routine edits in ceremony)

If unsure, ask the user one question: **"Will you want to use this again, or is this a one-time thing?"** If the answer is "one-time", do the work, don't create a skill.

## Where skills live

```
<workspace>/.cline/skills/<skill-name>/
├── SKILL.md             ← required
└── <supporting-file>.md ← optional: prompt templates, reference docs, long examples
```

In this project the **source** of every skill is `superpower-custom/skills/<name>/`. The installer (`install.sh` on macOS/Linux, `install.ps1` on Windows) symlinks or junctions each source folder into `<workspace>/.cline/skills/<name>/`.

**Always create new skills in the source folder.** Never edit the copy under `.cline/skills/` directly — on macOS/Linux it is a symlink (so your edit hits the source anyway), and on Windows it is a copy that the next install will overwrite.

## Naming

- Folder name and `name:` field in frontmatter: identical kebab-case strings
- Prefer verb-based names for action skills: `writing-plans`, `creating-skills`, `debugging-systematically`
- Noun names are fine for reference-only skills: `testing-anti-patterns`
- Keep it under ~30 characters
- Do not prefix with the project name

## SKILL.md format

```markdown
---
name: <kebab-case-name>
description: <one or two sentences — see the next section>
---

# <Human-readable title>

<Body content>
```

Only two frontmatter fields. The body is regular markdown — headings, lists, code blocks, tables.

## The description field (most important part)

Cline decides whether to invoke a skill by reading its description. A bad description means the skill never fires.

A good description states two things:

1. **The trigger** — what the user says, asks for, or is doing that should cause invocation
2. **The scope** — what the skill covers (and implicitly what it does not)

Good examples:

> Use when the user asks to create a new Cline skill or capture a workflow as a reusable skill — covers folder layout, SKILL.md frontmatter, and installation.

> Use before writing code for any non-trivial change. Enforces RED-GREEN-REFACTOR: write a failing test, watch it fail, write minimal code to pass, refactor.

Bad examples:

> A skill for testing. ← no trigger, no scope
> This skill helps with code. ← fires for literally everything
> TDD ← too terse; agent cannot tell when to use it

**Rule of thumb:** if you removed the description and showed only the title, could another agent guess when to invoke? If yes, the title is doing the work the description should do — rewrite the description to be specific.

## Body structure

There is no fixed template, but most action skills benefit from this shape:

1. **One-paragraph overview** — what the skill does, when to invoke
2. **When to use / when NOT to use** — guard against over-application
3. **The process** — numbered or bulleted steps. Concrete: file paths, commands, expected output
4. **Anti-patterns** — common ways the agent goes wrong, with the corrected behavior (a table works well)
5. **Example walkthrough** — one realistic end-to-end scenario (optional but high value)

Reference-only skills (no procedure, just knowledge) can skip steps 3 and 5.

A skill longer than ~300 lines is usually doing too much — split it, or move bulk content to a supporting file.

## Writing style

- **Imperative voice.** "Run X", "Write the failing test." Not "you should consider running X."
- **Concrete over abstract.** Exact commands, exact paths, exact strings the agent will type or see.
- **Show, do not tell.** Code blocks with realistic examples beat prose descriptions every time.
- **No filler.** Every paragraph should teach something the agent does not already know from its base training.
- **Name anti-patterns explicitly.** "Do not X" lands better than hoping the agent infers it.

## Process — from user request to installed skill

### Step 1: Confirm it should be a skill

Ask: "Will you want to use this again?" If no, do the task inline and stop.

### Step 2: Clarify the trigger and scope (one question at a time)

- What event or user-request should make me invoke this?
- What is the discipline, process, or knowledge it should encode?
- What goes wrong without it?

If the answer to the last question is vague, the skill is probably not worth creating yet — wait until there is a real pain point.

### Step 3: Check for overlap

```bash
ls superpower-custom/skills/
```

If an existing skill covers part of the territory, extend it instead of creating a new one. Fragmented knowledge is harder to invoke correctly.

### Step 4: Choose a name and create the folder

```
superpower-custom/skills/<kebab-case-name>/SKILL.md
```

### Step 5: Draft SKILL.md

Write the frontmatter first — **especially the description**, because that is what determines whether the skill ever gets used. Then write the body following the structure guidance above.

### Step 6: Self-review

Read your draft as a fresh agent would, with no memory of this conversation:

- Does the description make the trigger obvious?
- Are the steps concrete enough to follow without guessing?
- Have you given concrete examples for anything ambiguous?
- Could any section be shorter? Cut filler.
- Have you marked anti-patterns explicitly?

Fix issues inline; no need to re-review.

### Step 7: Install

```bash
cd <workspace>
./superpower-custom/install.sh        # macOS / Linux / Git Bash
# or
.\superpower-custom\install.ps1       # Windows PowerShell
```

The installer auto-discovers every folder under `superpower-custom/skills/` — no editing of the script needed.

### Step 8: Verify

```bash
./superpower-custom/verify-install.sh
```

Confirm the new skill appears in the count.

### Step 9: Smoke-test

In a fresh Cline turn, describe a situation matching your trigger and confirm Cline invokes `use_skill <name>` (or at least mentions the skill). If it does not fire, the description is wrong — rewrite it to be more specific about the trigger.

## Anti-patterns

| Anti-pattern | What to do instead |
|---|---|
| Description that says what the skill *is* | Describe when to *use* it — the trigger and scope |
| One giant wall of prose | Use headings, numbered steps, tables, code blocks |
| Explains general programming concepts | Skip it — the agent already knows. Skills are for project-specific or discipline-enforcing content |
| Duplicates an existing skill | Extend the existing skill; do not fragment knowledge |
| 20+ steps with no structure | Split into multiple skills, or factor reference material into supporting `.md` files |
| Editing the symlinked copy under `.cline/skills/` | Always edit the source in `superpower-custom/skills/` |
| Vague verbs ("handle", "manage", "deal with") | Use concrete verbs ("write", "run", "verify", "commit") |
| Conditional logic the agent has to puzzle out | Numbered steps with explicit "if X, then Y" branches |

## Supporting files (optional)

If a skill needs long reference material, prompt templates, or examples that would bloat SKILL.md, put them in sibling files:

```
skills/my-skill/
├── SKILL.md
├── prompt-template.md
└── reference-patterns.md
```

In SKILL.md, refer to them with their basename — the agent will Read them on demand. Examples in this project: `skills/subagent-driven-development/researcher-prompt.md`, `skills/test-driven-development/testing-anti-patterns.md`.

Keep SKILL.md itself short and procedural; push depth into supporting files.

## Example walkthrough

**User:** "I keep telling you to update CHANGELOG.md whenever you bump a version in package.json. Make that a skill."

**Step 1 — confirm:** "Will this come up again?" → "Yes, every release."

**Step 2 — clarify trigger:** "Trigger fires on any `version:` change in `package.json`, correct?" → "Yes."

**Step 3 — check overlap:** `ls superpower-custom/skills/` shows no changelog-related skill.

**Step 4 — name and location:** `superpower-custom/skills/updating-changelog/SKILL.md`

**Step 5 — draft:**

```markdown
---
name: updating-changelog
description: Use whenever changing the `version` field in `package.json` or preparing a release commit — ensures CHANGELOG.md gains a matching entry in Keep-a-Changelog format before the commit lands.
---

# Updating the Changelog

When `version` in `package.json` changes, `CHANGELOG.md` must gain a matching
`## [<version>] - <YYYY-MM-DD>` section in the same commit.

## Process

1. Read the proposed new version from the staged `package.json` change.
2. Open `CHANGELOG.md` and locate `## [Unreleased]`.
3. Rename `## [Unreleased]` to `## [<new-version>] - <today>` and insert a
   fresh empty `## [Unreleased]` section above it.
4. Verify each bullet under the new version matches a commit since the last
   release. Add any missing entries.
5. Stage both files in one commit: `git add package.json CHANGELOG.md`.

## Anti-patterns

- Bumping version without touching CHANGELOG → release CI fails.
- Leaving stale "Unreleased" bullets that do not match commits → confuses users.
```

**Step 6 — self-review:** Description names the trigger (`version` change) and scope (CHANGELOG entry). Steps are concrete. Ship it.

**Step 7-8 — install and verify:**

```bash
./superpower-custom/install.sh
./superpower-custom/verify-install.sh
```

**Step 9 — smoke-test:** Next session, edit `package.json` version. Cline should now invoke `updating-changelog` automatically.
