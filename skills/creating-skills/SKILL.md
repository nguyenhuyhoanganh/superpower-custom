---
name: creating-skills
description: Creates new Cline skills when the user provides source material (code, docs, scripts, references) and asks to package it as a reusable skill. Covers folder layout under .cline/skills/, SKILL.md frontmatter and body, description-writing for discoverability, progressive disclosure, bundled scripts with relative paths and safety checks, and self-review.
---

# Creating Cline Skills

A skill is a markdown document plus optional supporting files that Cline loads on demand to perform a specific task. Use this skill when the user has handed over source material and asks to package it as a reusable skill.

## Anatomy

```
.cline/skills/<skill-name>/
├── SKILL.md                ← required
├── references/             ← optional: long-form docs the agent reads for context
│   └── <topic>.md
├── templates/              ← optional: starting-point files (output templates, prompt templates, fixtures)
│   └── <template>.{md,json,yaml,txt,...}
└── scripts/                ← optional: executable helpers (.py, .js, .sh, ...)
    └── <script>.{py,js,sh}
```

Three sibling folders, each with a single purpose:

- **`references/`** — markdown the agent **reads** to gain context (API references, worked examples, advanced workflows, design notes). Pure documentation.
- **`templates/`** — files the agent or a script **uses as a starting point** and fills in (output templates, prompt skeletons, config fixtures). Any format.
- **`scripts/`** — code the agent **executes** (Python / JS / shell helpers).

Keep the skill root clean — anything beyond `SKILL.md` belongs in one of those three folders.

The folder name and the `name:` field in the frontmatter must match exactly.

## SKILL.md format

```markdown
---
name: <kebab-case-name>
description: <one or two sentences — what + when>
---

# <Human-readable title>

<Body>
```

**Frontmatter constraints:**

- `name`: ≤64 chars, lowercase letters / numbers / hyphens only, no reserved words (`anthropic`, `claude`)
- `description`: ≤1024 chars, non-empty, third-person

The body is regular markdown. Keep it under 500 lines — split into files under `references/` when it grows beyond that.

## Naming

Prefer **gerund form** (verb + -ing): `creating-skills`, `analyzing-spreadsheets`, `writing-commit-messages`. Reads naturally as "the skill that ___".

Acceptable alternatives: noun phrases (`pdf-processing`), imperative (`process-pdfs`). Be consistent within a workspace.

Avoid vague names (`helper`, `utils`, `tools`) and reserved-word prefixes (`anthropic-`, `claude-`).

## The description field — most important part

Cline picks which skill to invoke by reading descriptions. Write in **third person**, state both **what** the skill does and **when** to use it, and include the terms a user would actually say.

Good:

> Extracts text and tables from PDF files, fills forms, merges documents. Use when the user mentions PDFs, scanned documents, or form extraction.

> Generates conventional commit messages from staged diffs. Use when the user asks to commit, write a commit message, or review staged changes.

Bad:

> I can help you with PDFs. ← first-person
> A skill for code. ← no scope, no trigger
> processing ← no information

**Test:** if you deleted the description and left only the title, could a fresh Cline guess when to invoke? If yes, the description is dead weight — rewrite it.

## Body structure

Most action-skills follow this shape:

1. **One-paragraph overview** — what + when
2. **Process** — numbered steps with concrete commands, paths, expected output
3. **Templates / examples** — input/output pairs when the output format matters
4. **Anti-patterns** — common ways the agent gets it wrong, with the correction
5. **Links to `references/`** — for long reference docs and worked examples (templates live in `templates/`)

Reference-only skills (knowledge, no procedure) can skip 2 and 3.

## Progressive disclosure

When SKILL.md grows past ~500 lines, move detail into `references/` and link from SKILL.md. Cline loads each reference file only when the relevant section is reached.

```
my-skill/
├── SKILL.md                       # overview + navigation
└── references/
    ├── advanced-usage.md          # detailed workflows
    ├── api-reference.md           # method-by-method reference
    └── examples.md                # end-to-end examples
```

In SKILL.md, link with the relative path:

```markdown
**Advanced workflows:** see [references/advanced-usage.md](references/advanced-usage.md)
**API reference:**       see [references/api-reference.md](references/api-reference.md)
**Examples:**            see [references/examples.md](references/examples.md)
```

Keep links **one level deep** — `SKILL.md → references/a.md`. Do not chain `SKILL.md → references/a.md → references/b.md → references/c.md`; Cline may preview nested files partially and miss content.

For reference files longer than ~100 lines, put a table of contents at the top so Cline sees the full scope on a partial read.

## Writing style

- **Third person.** "Generates commit messages..." — not "I generate..." or "You can use this to..."
- **Imperative in the body.** "Run X", "Open the file", "Verify the output."
- **Concrete over abstract.** Exact commands, exact paths, exact strings.
- **No filler.** Only include context Cline does not already have. "PDF is a document format..." is filler.
- **Consistent terminology.** Pick one word (`field`, `endpoint`, `extract`) and use it throughout.
- **No time-sensitive claims.** "As of 2026..." rots. Put legacy info under an explicit "Old patterns" subheading.

## Portability

A skill must run on **any machine, for any user**, not just the author's. This rules out anything tied to one environment:

- **No personal absolute paths.** `/Users/alice/...`, `/home/bob/...`, `C:\Users\hoanganh\...` — all forbidden, in SKILL.md and inside scripts.
- **No author-specific tools as hard requirements.** If a step needs `jq`, `gh`, `rg`, or a specific Python version, state the dependency at the top of SKILL.md and fail with a clear message when it is missing.
- **No OS-only assumptions.** If a step works only on macOS / only on Windows, say so and provide the alternative — or ship parallel scripts (`tag.sh` + `tag.ps1`).
- **No machine-specific config baked in.** API keys, hostnames, usernames, project IDs: read them from env vars or arguments, never hardcode.
- **No reliance on `cwd` being the project root** unless the skill explicitly states "run from the project root". When in doubt, resolve paths from the script's own location (see below).

Test mentally: "If I emailed this skill folder to a colleague with a fresh checkout, would it work without edits?" If no, fix it.

## Bundled scripts

Skills can ship executable helpers (Python, JavaScript, shell). Cline runs them via `execute_command`. These rules keep them portable and safe.

### Forward slashes, paths relative to the skill folder

In SKILL.md, reference scripts relative to the skill folder root:

```bash
# good
python scripts/extract.py input.pdf

# bad — absolute, breaks the moment the skill is copied elsewhere
python /Users/alice/workspace/.cline/skills/my-skill/scripts/extract.py input.pdf
```

Use forward slashes on every platform — backslashes break on Unix, forward slashes work everywhere.

### Inside scripts, resolve paths from the script's own location

Hardcoded absolute paths make scripts unusable when the skill is copied to another workspace. Resolve from the script's location:

```python
# Python — read a starter file from templates/ next to the skill root
from pathlib import Path
SCRIPT_DIR = Path(__file__).resolve().parent
TEMPLATE = SCRIPT_DIR.parent / "templates" / "report.md"
```

```bash
# Bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$SCRIPT_DIR/../templates/report.md"
```

```javascript
// Node
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
const TEMPLATE = join(SCRIPT_DIR, '..', 'templates', 'report.md');
```

### Stay inside the workspace

Scripts must not modify, delete, or create files outside the current workspace. Before any destructive operation (write, delete, rename), verify the resolved target path is inside the workspace. Use `pathlib` so the check works identically on Windows, macOS, and Linux:

```python
from pathlib import Path

def assert_in_workspace(target_path: str, workspace: Path | None = None) -> Path:
    workspace = (workspace or Path.cwd()).resolve()
    target = Path(target_path).resolve()
    if target != workspace and workspace not in target.parents:
        raise SystemExit(f"refusing to write outside workspace: {target}")
    return target
```

Equivalents in other languages:

```javascript
// Node
import { resolve, relative } from 'node:path';
function assertInWorkspace(target, workspace = process.cwd()) {
  const rel = relative(resolve(workspace), resolve(target));
  if (rel.startsWith('..') || resolve(target) === resolve(workspace) + '..') {
    throw new Error(`refusing to write outside workspace: ${target}`);
  }
}
```

```bash
# Bash (works on macOS BSD + Linux GNU + Git Bash on Windows)
assert_in_workspace() {
  local target ws
  target="$(cd "$(dirname "$1")" 2>/dev/null && pwd)/$(basename "$1")"
  ws="$(pwd)"
  case "$target" in
    "$ws"|"$ws"/*) ;;
    *) echo "refusing to write outside workspace: $target" >&2; exit 1 ;;
  esac
}
```

Never run `rm -rf`, `git reset --hard`, package installs, or network calls without an explicit user instruction in the skill body.

### Handle errors instead of punting

Scripts solve problems they encounter; they do not crash and leave Cline to guess:

```python
# good
def read_config(path):
    try:
        return json.loads(Path(path).read_text())
    except FileNotFoundError:
        print(f"{path} missing; using defaults")
        return DEFAULT_CONFIG
    except json.JSONDecodeError as e:
        raise SystemExit(f"{path} is not valid JSON: {e}")

# bad — punts to the agent
def read_config(path):
    return json.loads(open(path).read())
```

No magic numbers — every non-obvious constant gets a comment explaining the value:

```python
# 30s covers slow networks; tighten if responses are usually <5s
REQUEST_TIMEOUT = 30
```

### Ship a test transcript

For every script the skill ships, document a known-good run: input, command, expected output. This is the agent-readable equivalent of a unit test and lets a later reader verify the script still behaves the same.

Format inside SKILL.md (or in `references/TEST_TRANSCRIPT.md` for longer cases):

````markdown
### Test transcript: scripts/extract.py

Input: `tests/fixtures/sample.pdf` (3-page invoice, EN)

```bash
$ python scripts/extract.py tests/fixtures/sample.pdf
Extracted 3 pages, 412 tokens.
Wrote: tests/fixtures/sample.txt
```

Expected: exit 0; `sample.txt` first line is `Invoice #1042`.
````

Run the transcript once when authoring. Re-run after any script edit. If the output drifts, fix the script or update the transcript — never let them diverge silently.

### Safety checklist before shipping a script

- [ ] No personal / absolute paths inside the script (`/Users/...`, `C:\...`)
- [ ] All file operations confined to the workspace
- [ ] External tool dependencies (`jq`, `gh`, etc.) documented and checked at startup
- [ ] Forward slashes everywhere; cross-platform path resolution (pathlib / `dirname`)
- [ ] Errors handled with helpful messages, not stack traces
- [ ] No magic numbers without a comment
- [ ] No network calls / package installs / destructive shell commands without explicit user opt-in
- [ ] Test transcript runs and matches documented output

## Anti-patterns

| Anti-pattern | What to do instead |
|---|---|
| Description that names what the skill *is* | Describe when to *invoke* it — trigger + scope |
| First-person description ("I can help...") | Third-person ("Generates...", "Extracts...") |
| Walls of prose | Headings, numbered steps, tables, code blocks |
| Explaining general programming concepts | Skip — Cline already knows |
| Duplicating an existing skill | Extend the existing skill; do not fragment knowledge |
| 20+ unstructured steps | Split into multiple skills, or factor depth into `references/` |
| Templates mixed into `references/` | Read-only docs → `references/`; fill-in starter files → `templates/` |
| Vague verbs ("handle", "manage", "deal with") | Concrete verbs ("write", "validate", "commit") |
| Backslashes in paths | Forward slashes everywhere |
| Multiple library choices presented as equals | Pick one default; mention alternatives only when meaningful |
| Time-sensitive claims | Mark legacy info under an "Old patterns" subheading |
| Hardcoded absolute paths in scripts | Resolve from `__file__` / `$(dirname "$0")` / `import.meta.url` |
| Personal paths (`/Users/alice/...`, `C:\Users\bob\...`) | Workspace-relative paths or env-driven config |
| OS-only step with no alternative | State the requirement, or ship parallel `.sh` + `.ps1` |
| Hardcoded API keys, hostnames, project IDs | Read from env vars or script arguments |

## Process — from user direction to written skill

The user has already handed over source material and asked for a skill. Do not ask whether it should be a skill — they have decided.

### 1. Restate the trigger in one sentence

Silently complete: "This skill should fire when the user ___." If that sentence is unclear, ask one short clarifying question. Otherwise proceed.

### 2. Pick a name

Gerund-form, kebab-case, ≤64 chars. Example: `migrating-legacy-routes`, not `legacy-route-migrator-tool`.

### 3. Check for overlap

List existing skills in `.cline/skills/` using whichever tool Cline has available on this platform (`list_files`, `ls`, `Get-ChildItem`). If a related skill exists, prefer extending it (add a section in SKILL.md or a new file under its `references/`) over creating a near-duplicate.

### 4. Lay out the folder

Create `.cline/skills/<name>/SKILL.md`. Add `references/`, `templates/`, and `scripts/` only when actually needed — do not pre-create empty folders.

### 5. Write the frontmatter first

Especially the description. If it does not name the trigger and scope, rewrite before going further. The body will not save a vague description.

### 6. Draft the body

Follow the body structure section above. Stay under 500 lines.

### 7. If shipping scripts, follow the script rules

Relative paths, workspace-bounded, error-handled, test transcript included.

### 8. Self-review

Read the draft as a fresh Cline session would, with no memory of this conversation:

- Could a different agent invoke this from the description alone?
- Are the steps concrete enough to follow without inferring?
- Would the skill work for a colleague on a different OS with a fresh checkout? (No personal paths, no hidden tool requirements, no hardcoded config.)
- Is anything in here Cline already knows? Cut it.
- Could any section be shorter?
- Are anti-patterns marked explicitly, not just implied?

Fix issues inline. Done.

### 9. Tell the user what to do next

Confirm the file path. Suggest a fresh Cline turn that matches the trigger phrasing, so the user can verify invocation.

## Example walkthrough

**User:** "I've shown you our git-tagging convention (date-version-suffix) and the release-checklist.md. Make me a skill that walks through cutting a release."

**1. Trigger:** "User says 'cut a release', 'tag a release', or 'prepare release'."

**2. Name:** `cutting-releases`

**3. Overlap:** `ls .cline/skills/` — no existing release skill.

**4. Layout:**

```
.cline/skills/cutting-releases/
├── SKILL.md
└── scripts/
    └── tag.sh
```

**5. Frontmatter:**

```yaml
---
name: cutting-releases
description: Cuts a tagged release following the date-version-suffix convention. Use when the user asks to cut, tag, or prepare a release, or to ship a new version.
---
```

**6. Body:** procedure pulled from `release-checklist.md`, condensed into 5 numbered steps with the exact `git` commands.

**7. Script `scripts/tag.sh`:**
- Resolves paths from `$(dirname "$0")`
- Refuses to run outside a git repo
- Aborts if the working tree is dirty
- Prints the planned tag and waits for `y` before pushing

Test transcript: runs against `tests/fixtures/repo-clean/`, prints `would tag: 2026-05-19-v1.2.0`, exits 0 on `n`.

**8. Self-review:** description names trigger ✓, steps concrete ✓, no filler ✓.

**9. Next step:** "Skill at `.cline/skills/cutting-releases/`. Next time you say 'cut a release', Cline should invoke it."
