# Windows Support — Design Spec

**Date:** 2026-05-19
**Author:** brainstorming session
**Status:** Draft — pending user approval before plan phase

## 1. Goal

Add Windows support to the superpower-custom installer by shipping a
parallel set of PowerShell scripts (`install.ps1`, `uninstall.ps1`,
`verify-install.ps1`) that mirror the existing bash scripts. Existing
macOS/Linux bash workflow stays untouched.

## 2. Constraints

### 2.1 Symlink permissions on Windows

Creating a true symbolic link on Windows requires either Administrator
privileges or Developer Mode. Both are friction. To avoid forcing either:

- **Skill folders** (13 directories) use **junctions** — equivalent to
  symlinks for directories, do NOT require admin or Developer Mode.
- **Files** (bootstrap rule + 3 workflows) are **copied** — no junction
  support for files. Trade-off: edit-then-reinstall instead of live update.

### 2.2 PowerShell version

Target **PowerShell 5.1** (built into every Windows 10/11). Avoids
requiring users to install PowerShell 7+. Modern features (e.g.
ternary operator, null-conditional) not used.

### 2.3 Repo layout unchanged

Source folder structure stays the same. Both `.sh` and `.ps1` scripts
live side-by-side in `superpower-custom/` root. No `windows/` or
`unix/` subfolders.

### 2.4 No bash tests for PowerShell

Skip Pester / shell-equivalent tests for the PowerShell scripts in v1.
`verify-install.ps1` doubles as a manual smoke test (user runs it after
install to confirm everything resolves).

## 3. Strategy

### 3.1 Link mapping

| Resource | Source | Target | Method |
|---|---|---|---|
| Bootstrap rule | `rules/00-bootstrap.md` | `.clinerules/00-bootstrap.md` | Copy |
| 3 workflow files | `workflows/*.md` | `.clinerules/workflows/*.md` | Copy |
| 13 skill folders | `skills/<name>/` | `.cline/skills/<name>` | Junction |

### 3.2 Implications for users

- **Skill content edits** (any file inside a skill folder) — junction
  is live; Cline sees the change on next read.
- **Bootstrap rule edits** or **workflow file edits** — user MUST re-run
  `install.ps1` to overwrite the copy. Document this clearly in
  INSTALL.md and at script output time.

### 3.3 Script behavior parity with bash

Each `.ps1` mirrors the corresponding `.sh`:

- Same source/target detection logic (script directory = source root,
  parent = workspace).
- Idempotent: re-running cleans previous state and re-applies.
- Same output style and exit codes:
  - `install.ps1` exit 0 on success; prints summary of what was created.
  - `uninstall.ps1` exit 0; prints "Removed N items, source kept at X".
  - `verify-install.ps1` exit 0 if everything OK, exit 1 with `FAIL:`
    listing of problems otherwise.

## 4. File changes

```
NEW:    superpower-custom/install.ps1
NEW:    superpower-custom/uninstall.ps1
NEW:    superpower-custom/verify-install.ps1
MODIFY: superpower-custom/INSTALL.md  (add Windows section)
MODIFY: superpower-custom/README.md   (one-liner about Windows support)
```

No changes to: `install.sh`, `uninstall.sh`, `verify-install.sh`, tests,
skills, workflows, rules, docs/specs/plans.

## 5. install.ps1 behavior

```
1. Resolve $SourceDir = script's own folder.
2. Resolve $Workspace = parent of $SourceDir.
3. Create target directories if missing:
   - $Workspace\.clinerules
   - $Workspace\.clinerules\workflows
   - $Workspace\.cline\skills
4. Bootstrap: if rules\00-bootstrap.md exists, Copy-Item -Force to
   .clinerules\00-bootstrap.md.
5. Workflows: for each in {brainstorm, write-plan, execute-plan},
   if workflows\<name>.md exists, Copy-Item -Force to
   .clinerules\workflows\<name>.md.
6. Skills: for each directory in skills\*, if a junction or other
   item already exists at .cline\skills\<name>, remove it first;
   create New-Item -ItemType Junction.
7. Print summary:
   "Installed superpower-custom into <Workspace>"
   "  Rules:     <RulesDir>"
   "  Workflows: <WorkflowsDir>"
   "  Skills:    <SkillsDir> (<N> linked)"
   "Note: bootstrap and workflow files are COPIES on Windows."
   "      Re-run install.ps1 after editing those source files."
```

## 6. uninstall.ps1 behavior

```
1. Resolve $SourceDir, $Workspace (same as install).
2. Remove copies (only if they ARE files we'd have installed —
   match against source filename, no readlink check needed):
   - $Workspace\.clinerules\00-bootstrap.md       (if exists)
   - $Workspace\.clinerules\workflows\brainstorm.md
   - $Workspace\.clinerules\workflows\write-plan.md
   - $Workspace\.clinerules\workflows\execute-plan.md
3. Remove junctions in $Workspace\.cline\skills only if they point
   into $SourceDir\skills\.
4. Track count of removed items; print
   "Removed N items. Source kept at <SourceDir>."
```

## 7. verify-install.ps1 behavior

```
1. Resolve $SourceDir, $Workspace.
2. Counter $problems = 0.
3. For each file expected (bootstrap + 3 workflows):
   - If source exists but target missing → MISSING file: <path>; $problems++
   - If source exists and target exists but contents differ →
     STALE COPY: <path> (run install.ps1 to refresh); $problems++
4. For each skill folder in $SourceDir\skills\*:
   - Target = $Workspace\.cline\skills\<name>
   - If not a junction (or missing) → MISSING junction: <path>; $problems++
   - If junction target ≠ $SourceDir\skills\<name> → WRONG TARGET; $problems++
   - If junction resolves but SKILL.md not inside → SKILL.md missing; $problems++
5. Skill-count = number of valid junctions; total = 1 + 3 + skill-count.
6. If $problems = 0:
   Print "OK: <total> items installed (1 rule + 3 workflows + <N> skills, mixed copy+junction)"
   Exit 0
   Else:
   Print "FAIL: $problems problem(s) found"
   Exit 1
```

The "STALE COPY" check uses a hash comparison (Get-FileHash) — if user
edited source after installing, the copy is out of date. This is
user-visible behavior unique to the Windows install (bash side is
symlink, no concept of stale).

## 8. INSTALL.md update

Add this section to INSTALL.md after the existing "Install" section:

```markdown
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
  refresh. `verify-install.ps1` flags stale copies.

### Git Bash on Windows

`install.sh` also works under Git Bash, but `ln -s` requires Developer
Mode and the `MSYS=winsymlinks:nativestrict` environment variable.
Prefer `install.ps1` unless you already have that set up.
```

## 9. README.md update

Add to the top-level README, in the Install section, after the existing
bash command:

```markdown
**Windows (PowerShell):**

```powershell
.\superpower-custom\install.ps1
```

See [INSTALL.md](INSTALL.md) for details on the Windows-specific
copy + junction strategy.
```

## 10. Testing strategy

### Tier 1 — manual smoke test on Windows

User with a Windows machine runs in this order:

1. `.\install.ps1` — expect output "Installed ... (13 linked)" and the
   "Re-run after editing" note.
2. `.\verify-install.ps1` — expect "OK: 17 items installed".
3. Open `superpower-custom\skills\brainstorming\SKILL.md`, append a test
   line, save. Open `..\.cline\skills\brainstorming\SKILL.md` and confirm
   the line is there (proves junction is live). Revert.
4. Open `superpower-custom\rules\00-bootstrap.md`, append a test line,
   save. Run `verify-install.ps1` — expect "STALE COPY" flag. Run
   `install.ps1` again. Run `verify-install.ps1` — expect "OK". Revert.
5. `.\uninstall.ps1` — expect "Removed N items".
6. `.\verify-install.ps1` — expect FAIL (missing files).
7. `.\install.ps1` once more to leave system in installed state.

### Tier 2 — bash side regression

On macOS/Linux: re-run `bash tests/test-install.sh`,
`bash tests/test-uninstall.sh`, `bash tests/test-verify-install.sh`.
All three must still PASS. The PowerShell scripts must not affect
bash behavior.

## 11. Risks and open questions

| # | Item | Plan |
|---|---|---|
| 1 | Junction across drives | Junctions cannot cross drives. Document assumption: `superpower-custom/` and the target workspace must be on the same drive. Most users open the repo as a VSCode workspace folder — same drive by default. |
| 2 | Existing junctions left from a prior install pointing elsewhere | install.ps1 always removes existing junction before recreating. uninstall.ps1 checks the junction's target before removing — only removes ours. |
| 3 | PowerShell execution policy blocks scripts | Document `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`. Don't try to bypass automatically. |
| 4 | Hash comparison performance | 4 small markdown files — Get-FileHash is fast enough. No concern. |
| 5 | User edits a workflow file expecting live update | verify-install.ps1 flags "STALE COPY"; install.ps1 output reminds users at install time. Acceptable friction for v1. |

## 12. Out of scope (v1)

- `install.bat` (cmd-only) — PowerShell suffices; cmd cannot do junctions cleanly.
- PowerShell unit tests (Pester) — manual verification is enough for v1.
- Auto-elevate to admin if Developer Mode not detected — would require
  privilege prompt; design avoids this entirely by not using symlinks.
- Bash-side detection of Windows / Git Bash — `install.sh` stays
  Unix-focused; Windows users use `install.ps1`.

## 13. Success criteria

1. `install.ps1` runs without error on a fresh Windows 10/11 machine
   without admin or Developer Mode.
2. `verify-install.ps1` reports "OK: 17 items installed".
3. Edit-test of a skill file shows up live in `.cline\skills\<name>\SKILL.md`.
4. Edit-test of a workflow file is detected as STALE by verify-install.ps1
   and fixed by re-running install.ps1.
5. `uninstall.ps1` cleanly removes all installed items, leaves `superpower-custom\`
   source intact.
6. Bash tests on macOS/Linux still PASS unchanged.
