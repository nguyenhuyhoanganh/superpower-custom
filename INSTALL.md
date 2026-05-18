# Installation Guide

> **This is the `inline-superpowers` branch.** It adds a second
> always-loaded rule `.clinerules/01-using-superpowers.md` that contains
> the full `using-superpowers` skill content. Token-expensive (~1000 tokens
> per turn) but guarantees the agent sees the skills system every turn.
> If you are on `main`, only the short bootstrap rule is loaded.

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

## Inline-superpowers rule (this branch only)

This branch adds one extra symlink/copy beyond `main`:

```
<workspace>/.clinerules/01-using-superpowers.md
    →  superpower-custom/skills/using-superpowers/SKILL.md
```

Cline reads every `.md` file under `.clinerules/` and appends it to the
system prompt on every turn. So putting the skill content there means
the agent sees the full `using-superpowers` skill on every turn —
guaranteed, with no reliance on `use_skill` discovery.

### When to switch to this branch

Default behavior (`main` branch) loads only the short bootstrap rule
and trusts the agent to call `use_skill('using-superpowers')` itself.
Switch to `inline-superpowers` if you notice:

- Agent ignores `using-superpowers` even with `with-hooks` enabled
- Agent forgets the skills system mid-conversation
- You want the strongest guarantee at the cost of ~1000 tokens per turn

This is the most aggressive fallback. Try `main` first, then `with-hooks`,
then this branch.

### Switch and install

```bash
# macOS / Linux
git checkout inline-superpowers
./superpower-custom/install.sh

# Windows
git checkout inline-superpowers
.\superpower-custom\install.ps1
```

Verify expects **18 items** on this branch (vs. 17 on `main`):
`OK: 18 symlinks installed (1 rule + 1 inline-skill-rule + 3 workflows + 13 skills)`.

### Switching back to main

```bash
./superpower-custom/uninstall.sh    # or .\superpower-custom\uninstall.ps1
git checkout main
./superpower-custom/install.sh      # or .\superpower-custom\install.ps1
```

Always uninstall before switching, so `01-using-superpowers.md` is
cleaned up. `main` branch's installer doesn't know about it.

### Trade-off vs `with-hooks`

| Aspect | `with-hooks` | `inline-superpowers` |
|---|---|---|
| Mechanism | Hook script injects content at task start | Rule file appended to system prompt every turn |
| Token cost | One injection per task | ~1000 tokens × every turn |
| Reliability | Depends on Cline VSCode firing TaskStart hook | Depends on Cline reading `.clinerules/*.md` (well-supported) |
| Visibility | Hidden in hook output | Visible in system prompt |

Pick `with-hooks` first; pick `inline-superpowers` only if hooks don't
fire or you want guaranteed every-turn visibility.

## Manual Installation (no scripts)

If you cannot run `install.sh` / `install.ps1` (restricted environment,
permission errors, or debugging), copy the files manually. The end state
is exactly the same as what the scripts produce.

### Source → target mapping

`<workspace>` is the VSCode workspace folder (the parent of `superpower-custom/`).

| Copy from (in `superpower-custom/`) | Copy to (under `<workspace>/`) |
|---|---|
| `rules/00-bootstrap.md` | `.clinerules/00-bootstrap.md` |
| `skills/using-superpowers/SKILL.md` (this branch only) | `.clinerules/01-using-superpowers.md` |
| `workflows/brainstorm.md` | `.clinerules/workflows/brainstorm.md` |
| `workflows/write-plan.md` | `.clinerules/workflows/write-plan.md` |
| `workflows/execute-plan.md` | `.clinerules/workflows/execute-plan.md` |
| Each subfolder of `skills/` (entire folder) | `.cline/skills/<same-name>/` |

On `main` branch the `01-using-superpowers.md` row is absent — skip it.

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
