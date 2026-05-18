# Installation Guide

> **This is the `with-memory-bank` branch.** It adds a 14th skill
> (`using-memory-bank`) and a second always-loaded rule
> (`.clinerules/02-memory-bank.md`) that implements the Cline
> Memory Bank pattern. Use this branch if your sessions hit context
> compaction and the agent forgets progress mid-task. See "Memory Bank
> (this branch only)" section below.

## Prerequisites

- One of:
  - macOS / Linux with Bash 4+
  - Windows 10/11 with PowerShell 5.1 (built-in)
- Git
- Cline VSCode extension installed

## Install

The installer assumes this repo lives at `<workspace>/superpower-custom/`
where `<workspace>` is the VSCode workspace root that Cline reads.

```bash
cd <workspace>
./superpower-custom/install.sh
```

After install, the following symlinks exist:

```
<workspace>/.clinerules/00-bootstrap.md             → superpower-custom/rules/00-bootstrap.md
<workspace>/.clinerules/workflows/brainstorm.md     → superpower-custom/workflows/brainstorm.md
<workspace>/.clinerules/workflows/write-plan.md     → superpower-custom/workflows/write-plan.md
<workspace>/.clinerules/workflows/execute-plan.md   → superpower-custom/workflows/execute-plan.md
<workspace>/.cline/skills/<skill-name>              → superpower-custom/skills/<skill-name>/
                                                       (one symlink per skill, 13 total)
```

## Verify

```bash
./superpower-custom/verify-install.sh
```

Expected: `OK: 17 symlinks installed (1 rule + 3 workflows + 13 skills)`.

## Uninstall

```bash
./superpower-custom/uninstall.sh
```

Removes symlinks only. Source code in `superpower-custom/` is untouched.

## How updates work

Symlinks point at source files, so editing anything under `superpower-custom/`
takes effect the next time Cline reads the file. No re-install needed.

## Open Cline in this workspace

After install, restart your Cline VSCode session (or open the workspace
folder in VSCode). On the first turn Cline reads `.clinerules/00-bootstrap.md`
and loads `using-superpowers` via `use_skill`.

## Windows

PowerShell 5.1 (built into Windows 10/11) — no install needed.

### Install

From the workspace root:

```powershell
.\superpower-custom\install.ps1
```

If PowerShell blocks script execution, allow once for this session:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### Verify / Uninstall

```powershell
.\superpower-custom\verify-install.ps1
.\superpower-custom\uninstall.ps1
```

### How Windows install differs from macOS/Linux

To avoid requiring Developer Mode or admin, the Windows installer uses:

- **Junctions** for the 13 skill folders → live updates, edits to
  any file inside a skill folder are picked up immediately.
- **Copies** for `00-bootstrap.md` and the 3 workflow files → after
  editing those source files, **re-run `install.ps1`** so the copies
  refresh. `verify-install.ps1` flags stale copies with `STALE COPY:`.

### Git Bash on Windows

`install.sh` also works under Git Bash, but `ln -s` requires Developer
Mode and the `MSYS=winsymlinks:nativestrict` environment variable.
Prefer `install.ps1` unless you already have that set up.

### Limitations

- Source folder `superpower-custom/` and the target workspace must be
  on the same Windows drive (junctions cannot cross drives).
- `install.bat` (cmd.exe only) is not provided — PowerShell is required.

## Memory Bank (this branch only)

This branch adds two things on top of `main`:

- **A 14th skill** `using-memory-bank/` — explains the pattern, ships
  6 template files at `skills/using-memory-bank/templates/`.
- **A 2nd always-loaded rule** `.clinerules/02-memory-bank.md` — tells
  the agent to read `<workspace>/memory-bank/` (6 files) at the start
  of every session and after any context compaction.

### What is the Memory Bank?

A folder `<workspace>/memory-bank/` containing 6 markdown files that
capture persistent project state:

```
memory-bank/
├── projectbrief.md     ← what / scope (rarely changes)
├── productContext.md   ← why / users / UX goals (rarely)
├── systemPatterns.md   ← architecture (changes when arch changes)
├── techContext.md      ← stack / setup (changes when deps change)
├── activeContext.md    ← current focus (every session)
└── progress.md         ← done / pending / blockers (every task)
```

Because Cline's working memory resets between sessions and compresses
within long ones, these files are the agent's **only continuity** across
those boundaries. The always-loaded rule ensures the agent reads them
on every turn, so after a context compaction the agent recovers state
by re-reading instead of guessing.

### Switch and install

```bash
# macOS / Linux
git checkout with-memory-bank
./superpower-custom/install.sh

# Windows
git checkout with-memory-bank
.\superpower-custom\install.ps1
```

Verify expects **19 items** on this branch (vs. 17 on `main`):
`OK: 19 symlinks installed (1 bootstrap rule + 1 memory-bank rule + 3 workflows + 14 skills)`.

### Initialize the Memory Bank for your project

After install, ask Cline (in any conversation):

```
initialize memory bank
```

The agent will load the `using-memory-bank` skill, then:
1. Ask you for a project brief (a few sentences about the project)
2. Create `<workspace>/memory-bank/` with 6 files seeded from the templates
3. Fill what it can derive from the codebase
4. Commit the folder to git

After that, the agent automatically reads `memory-bank/` at the start
of every session and updates it as it works.

### Useful commands during work

| You say | Agent does |
|---|---|
| `initialize memory bank` | Set up `memory-bank/` from templates + project brief |
| `follow your custom instructions` | Re-read all 6 files, report current state, continue |
| `resume` | Same as above (shorter) |
| `update memory bank` | Full review and rewrite of all 6 files |
| (nothing, just start a session) | Agent reads `memory-bank/` automatically per the rule |

### When to switch to this branch

Pick `with-memory-bank` when:
- Long-running tasks span multiple Cline sessions
- You hit "context compaction" and the agent loses progress
- You want the agent to "just know" the project state after coming back
  the next day

Pick another branch otherwise — Memory Bank adds maintenance overhead
(the agent has to update files) and ~500–2000 tokens per turn for the
re-reads.

### Switching back to main

```bash
./superpower-custom/uninstall.sh    # or .\superpower-custom\uninstall.ps1
git checkout main
./superpower-custom/install.sh      # or .\superpower-custom\install.ps1
```

Always uninstall before switching, so `02-memory-bank.md` and the
`using-memory-bank` skill symlinks are cleaned up. `main`'s installer
doesn't know about them. Your `memory-bank/` folder content is YOUR
project state — keep it; it stays in your workspace.

## Manual Installation (no scripts)

If you cannot run `install.sh` / `install.ps1` (restricted environment,
permission errors, or debugging), copy the files manually. The end state
is exactly the same as what the scripts produce.

### Source → target mapping

`<workspace>` is the VSCode workspace folder (the parent of `superpower-custom/`).

| Copy from (in `superpower-custom/`) | Copy to (under `<workspace>/`) |
|---|---|
| `rules/00-bootstrap.md` | `.clinerules/00-bootstrap.md` |
| `rules/02-memory-bank.md` (this branch only) | `.clinerules/02-memory-bank.md` |
| `workflows/brainstorm.md` | `.clinerules/workflows/brainstorm.md` |
| `workflows/write-plan.md` | `.clinerules/workflows/write-plan.md` |
| `workflows/execute-plan.md` | `.clinerules/workflows/execute-plan.md` |
| Each subfolder of `skills/` (entire folder) | `.cline/skills/<same-name>/` |

On `main` branch the `02-memory-bank.md` row is absent and skill count
is **13** (no `using-memory-bank/`).

There are **13 skill folders** to copy:

```
using-superpowers/             brainstorming/
writing-plans/                 executing-plans/
test-driven-development/       systematic-debugging/
verification-before-completion/  requesting-code-review/
receiving-code-review/         dispatching-parallel-agents/
subagent-driven-development/   creating-feature-branch/
finishing-a-development-branch/
```

Each skill folder contains a `SKILL.md` plus zero or more supporting files
(prompt templates, reference docs). Copy the **entire folder** — don't
cherry-pick files.

### Target layout (after manual copy)

```
<workspace>/
├── superpower-custom/                ← keep as-is (source)
├── .clinerules/
│   ├── 00-bootstrap.md
│   └── workflows/
│       ├── brainstorm.md
│       ├── write-plan.md
│       └── execute-plan.md
└── .cline/
    └── skills/
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
        │   ├── researcher-prompt.md
        │   ├── spec-reviewer-prompt.md
        │   └── code-quality-reviewer-prompt.md
        ├── creating-feature-branch/
        │   └── SKILL.md
        └── finishing-a-development-branch/
            └── SKILL.md
```

Total: 1 rule + 3 workflow files + 13 skill folders.

### Quick verify (manual)

**macOS / Linux / Git Bash:**

```bash
test -f .clinerules/00-bootstrap.md && echo "bootstrap OK" || echo "MISSING bootstrap"
echo "workflows: $(ls .clinerules/workflows/*.md 2>/dev/null | wc -l) (expect 3)"
echo "skills:    $(ls -d .cline/skills/*/ 2>/dev/null | wc -l) (expect 13)"
```

**Windows PowerShell:**

```powershell
if (Test-Path .clinerules\00-bootstrap.md) { "bootstrap OK" } else { "MISSING bootstrap" }
"workflows: $((Get-ChildItem .clinerules\workflows\*.md).Count) (expect 3)"
"skills:    $((Get-ChildItem .cline\skills -Directory).Count) (expect 13)"
```

### Trade-offs vs running the install script

- **No live update.** Edits to source files in `superpower-custom/` do not
  propagate to `.clinerules/` and `.cline/skills/`. Re-copy after editing.
- **No `verify-install` health check.** You verify by comparing trees yourself
  (e.g. `diff -r superpower-custom/skills/<name>/ .cline/skills/<name>/`).
- **Same end result for Cline.** Once the files are in place, Cline reads them
  the same way regardless of whether they got there by script or by hand.
