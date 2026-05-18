# Windows Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship 3 PowerShell scripts (install/uninstall/verify) so Windows users can install superpower-custom natively without admin or Developer Mode.

**Architecture:** Mixed strategy — `New-Item -ItemType Junction` for the 13 skill folders (no permission needed), `Copy-Item -Force` for the 4 small files (bootstrap + 3 workflows). Verify script uses `Get-FileHash` to flag stale copies. PowerShell 5.1 syntax (built into every Windows 10/11). Bash scripts on macOS/Linux are untouched.

**Tech Stack:** PowerShell 5.1, Windows 10/11 NTFS junctions. Source is in this repo at `superpower-custom/` (current working folder).

**Repo root:** `/Users/hoanganh/Workspace/cline-superpower/superpower-custom/` (git remote: `https://github.com/nguyenhuyhoanganh/superpower-custom.git`, branch `main`).

---

## Pre-task notes

- All paths in scripts use `\` (Windows) — Join-Path handles this on Windows; the literal `\` works in PowerShell string literals.
- All script files must be saved with **CRLF line endings is NOT required** — PowerShell 5.1 reads LF fine on Windows. Save with LF for consistency with the rest of the repo. The `.gitignore` does not need changes.
- Verification on this Mac dev machine cannot actually RUN the .ps1 (no Windows). Each task verifies by:
  - File exists with the expected hash-bang-free content
  - `grep` for required cmdlets confirms structure
  - Manual Windows smoke test is the user's responsibility (documented in spec Tier-1).

---

## Task 1: install.ps1

**Files:**
- Create: `superpower-custom/install.ps1`

- [ ] **Step 1: Write `install.ps1`**

```powershell
#!/usr/bin/env pwsh
# PowerShell installer for superpower-custom. Mixed strategy:
#   - Junction for the 13 skill folders (no admin / Developer Mode needed)
#   - Copy for bootstrap + 3 workflow files (junctions don't work on files)
# Idempotent: re-running refreshes copies and rebuilds junctions.
$ErrorActionPreference = 'Stop'

$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Workspace = Split-Path -Parent $SourceDir

$RulesDir     = Join-Path $Workspace '.clinerules'
$WorkflowsDir = Join-Path $RulesDir 'workflows'
$SkillsDir    = Join-Path (Join-Path $Workspace '.cline') 'skills'

New-Item -ItemType Directory -Force -Path $RulesDir, $WorkflowsDir, $SkillsDir | Out-Null

# 1. Bootstrap rule (copy)
$bootstrapSource = Join-Path $SourceDir 'rules\00-bootstrap.md'
if (Test-Path $bootstrapSource) {
    Copy-Item -Force $bootstrapSource (Join-Path $RulesDir '00-bootstrap.md')
}

# 2. Workflows (copy)
foreach ($wf in 'brainstorm', 'write-plan', 'execute-plan') {
    $src = Join-Path $SourceDir "workflows\$wf.md"
    if (Test-Path $src) {
        Copy-Item -Force $src (Join-Path $WorkflowsDir "$wf.md")
    }
}

# 3. Skills (junction)
$skillCount = 0
$skillsSourceDir = Join-Path $SourceDir 'skills'
if (Test-Path $skillsSourceDir) {
    Get-ChildItem -Path $skillsSourceDir -Directory | ForEach-Object {
        $target = Join-Path $SkillsDir $_.Name
        if (Test-Path $target) {
            Remove-Item -Force -Recurse $target
        }
        New-Item -ItemType Junction -Path $target -Target $_.FullName | Out-Null
        $skillCount++
    }
}

Write-Host "Installed superpower-custom into $Workspace"
Write-Host "  Rules:     $RulesDir"
Write-Host "  Workflows: $WorkflowsDir"
Write-Host "  Skills:    $SkillsDir ($skillCount linked)"
Write-Host ""
Write-Host "Note: bootstrap and workflow files are COPIES on Windows."
Write-Host "      Re-run install.ps1 after editing those source files."
```

- [ ] **Step 2: Verify file exists and contains required cmdlets**

Run:
```bash
test -f superpower-custom/install.ps1
grep -q 'New-Item -ItemType Junction' superpower-custom/install.ps1
grep -q 'Copy-Item -Force' superpower-custom/install.ps1
grep -q 'Re-run install.ps1 after editing' superpower-custom/install.ps1
```

All four commands must exit 0.

- [ ] **Step 3: Commit**

```bash
cd superpower-custom
git add install.ps1
git commit -m "feat(install): add Windows install.ps1 (junction+copy)"
```

---

## Task 2: uninstall.ps1

**Files:**
- Create: `superpower-custom/uninstall.ps1`

- [ ] **Step 1: Write `uninstall.ps1`**

```powershell
#!/usr/bin/env pwsh
# Remove items installed by install.ps1. Source folder untouched.
# Junctions are only removed if their target points into our $SourceDir.
$ErrorActionPreference = 'Stop'

$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Workspace = Split-Path -Parent $SourceDir

$RulesDir     = Join-Path $Workspace '.clinerules'
$WorkflowsDir = Join-Path $RulesDir 'workflows'
$SkillsDir    = Join-Path (Join-Path $Workspace '.cline') 'skills'

$removed = 0

# Bootstrap
$bootstrap = Join-Path $RulesDir '00-bootstrap.md'
if (Test-Path $bootstrap) {
    Remove-Item -Force $bootstrap
    $removed++
}

# Workflows
foreach ($wf in 'brainstorm', 'write-plan', 'execute-plan') {
    $p = Join-Path $WorkflowsDir "$wf.md"
    if (Test-Path $p) {
        Remove-Item -Force $p
        $removed++
    }
}

# Skills: only remove junctions whose target is inside our source
if (Test-Path $SkillsDir) {
    $expectedPrefix = (Resolve-Path (Join-Path $SourceDir 'skills')).Path
    Get-ChildItem -Path $SkillsDir -Force | Where-Object {
        $_.LinkType -eq 'Junction'
    } | ForEach-Object {
        $target = $_.Target | Select-Object -First 1
        if ($target -and $target.StartsWith($expectedPrefix)) {
            Remove-Item -Force $_.FullName
            $removed++
        }
    }
}

Write-Host "Removed $removed items. Source kept at $SourceDir."
```

- [ ] **Step 2: Verify file exists and contains required cmdlets**

Run:
```bash
test -f superpower-custom/uninstall.ps1
grep -q "LinkType -eq 'Junction'" superpower-custom/uninstall.ps1
grep -q 'StartsWith($expectedPrefix)' superpower-custom/uninstall.ps1
grep -q 'Source kept at' superpower-custom/uninstall.ps1
```

All must exit 0.

- [ ] **Step 3: Commit**

```bash
cd superpower-custom
git add uninstall.ps1
git commit -m "feat(install): add Windows uninstall.ps1"
```

---

## Task 3: verify-install.ps1

**Files:**
- Create: `superpower-custom/verify-install.ps1`

- [ ] **Step 1: Write `verify-install.ps1`**

```powershell
#!/usr/bin/env pwsh
# Verify install.ps1 result: files copied (and not stale), junctions resolve.
# Exits 0 if OK, 1 with problem list otherwise.
$ErrorActionPreference = 'Stop'

$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Workspace = Split-Path -Parent $SourceDir

$RulesDir     = Join-Path $Workspace '.clinerules'
$WorkflowsDir = Join-Path $RulesDir 'workflows'
$SkillsDir    = Join-Path (Join-Path $Workspace '.cline') 'skills'

$script:problems = 0

function Test-FileCopy {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target
    )
    if (-not (Test-Path $Source)) { return }  # Skip if source missing (staged install)
    if (-not (Test-Path $Target)) {
        Write-Host "MISSING file: $Target"
        $script:problems++
        return
    }
    $srcHash = (Get-FileHash $Source).Hash
    $dstHash = (Get-FileHash $Target).Hash
    if ($srcHash -ne $dstHash) {
        Write-Host "STALE COPY: $Target (run install.ps1 to refresh)"
        $script:problems++
    }
}

# Bootstrap
Test-FileCopy -Source (Join-Path $SourceDir 'rules\00-bootstrap.md') -Target (Join-Path $RulesDir '00-bootstrap.md')

# Workflows
foreach ($wf in 'brainstorm', 'write-plan', 'execute-plan') {
    Test-FileCopy -Source (Join-Path $SourceDir "workflows\$wf.md") -Target (Join-Path $WorkflowsDir "$wf.md")
}

# Skills
$skillCount = 0
$skillsSourceDir = Join-Path $SourceDir 'skills'
if (Test-Path $skillsSourceDir) {
    Get-ChildItem -Path $skillsSourceDir -Directory | ForEach-Object {
        $sourceFull = $_.FullName
        $target = Join-Path $SkillsDir $_.Name
        if (-not (Test-Path $target)) {
            Write-Host "MISSING junction: $target"
            $script:problems++
            return
        }
        $item = Get-Item $target -Force
        if ($item.LinkType -ne 'Junction') {
            Write-Host "NOT A JUNCTION: $target"
            $script:problems++
            return
        }
        $actualTarget = $item.Target | Select-Object -First 1
        if ($actualTarget -ne $sourceFull) {
            Write-Host "WRONG TARGET: $target -> $actualTarget (expected $sourceFull)"
            $script:problems++
            return
        }
        $skillMd = Join-Path $target 'SKILL.md'
        if (-not (Test-Path $skillMd)) {
            Write-Host "SKILL.md missing in: $target"
            $script:problems++
            return
        }
        $skillCount++
    }
}

$total = 1 + 3 + $skillCount
if ($script:problems -eq 0) {
    Write-Host "OK: $total items installed (1 rule + 3 workflows + $skillCount skills, mixed copy+junction)"
    exit 0
} else {
    Write-Host "FAIL: $($script:problems) problem(s) found"
    exit 1
}
```

- [ ] **Step 2: Verify file exists and contains required checks**

Run:
```bash
test -f superpower-custom/verify-install.ps1
grep -q 'Get-FileHash' superpower-custom/verify-install.ps1
grep -q 'STALE COPY' superpower-custom/verify-install.ps1
grep -q 'WRONG TARGET' superpower-custom/verify-install.ps1
grep -q "LinkType -ne 'Junction'" superpower-custom/verify-install.ps1
grep -q 'OK: ' superpower-custom/verify-install.ps1
grep -q 'FAIL: ' superpower-custom/verify-install.ps1
```

All must exit 0.

- [ ] **Step 3: Commit**

```bash
cd superpower-custom
git add verify-install.ps1
git commit -m "feat(install): add Windows verify-install.ps1 with stale-copy detection"
```

---

## Task 4: Update INSTALL.md (add Windows section)

**Files:**
- Modify: `superpower-custom/INSTALL.md`

- [ ] **Step 1: Append Windows section to INSTALL.md**

Append this content to the end of `superpower-custom/INSTALL.md` (after the existing "Open Cline in this workspace" section):

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
  refresh. `verify-install.ps1` flags stale copies with `STALE COPY:`.

### Git Bash on Windows

`install.sh` also works under Git Bash, but `ln -s` requires Developer
Mode and the `MSYS=winsymlinks:nativestrict` environment variable.
Prefer `install.ps1` unless you already have that set up.

### Limitations

- Source folder `superpower-custom/` and the target workspace must be
  on the same Windows drive (junctions cannot cross drives).
- `install.bat` (cmd.exe only) is not provided — PowerShell is required.
```

- [ ] **Step 2: Verify the new section is in place**

Run:
```bash
grep -q '^## Windows$' superpower-custom/INSTALL.md
grep -q 'Set-ExecutionPolicy' superpower-custom/INSTALL.md
grep -q 'cannot cross drives' superpower-custom/INSTALL.md
grep -q 'STALE COPY' superpower-custom/INSTALL.md
```

All must exit 0.

- [ ] **Step 3: Commit (with README update — Task 5 combines docs)**

(Defer commit until Task 5; both .md files commit together.)

---

## Task 5: Update README.md + commit docs

**Files:**
- Modify: `superpower-custom/README.md`

- [ ] **Step 1: Update the Install section in `README.md`**

Find the existing "## Install" section, which currently reads:

```markdown
## Install

From the workspace root that contains this repo:

```bash
./superpower-custom/install.sh
```

This creates symlinks in `.clinerules/`, `.clinerules/workflows/`, and
`.cline/skills/` pointing into this repo. Edit the source here and Cline
sees the update on the next turn.
```

Replace it with:

```markdown
## Install

From the workspace root that contains this repo:

**macOS / Linux (bash):**

```bash
./superpower-custom/install.sh
```

**Windows (PowerShell):**

```powershell
.\superpower-custom\install.ps1
```

The macOS/Linux installer uses symlinks, so edits to source files are
picked up live. The Windows installer uses junctions for skill folders
(live update) plus file copies for the bootstrap rule and 3 workflows
(re-run install after editing source). See [INSTALL.md](INSTALL.md) for
the full Windows-specific notes.
```

- [ ] **Step 2: Verify README change**

Run:
```bash
grep -q 'Windows (PowerShell):' superpower-custom/README.md
grep -q 'install.ps1' superpower-custom/README.md
grep -q 'macOS / Linux (bash):' superpower-custom/README.md
```

All must exit 0.

- [ ] **Step 3: Commit both docs together**

```bash
cd superpower-custom
git add INSTALL.md README.md
git commit -m "docs: document Windows install path"
```

---

## Task 6: Final sanity check + push

**Files:** none modified; verification only.

- [ ] **Step 1: Re-run bash regression**

```bash
cd superpower-custom
./uninstall.sh
./install.sh
./verify-install.sh
bash tests/test-install.sh
bash tests/test-uninstall.sh
bash tests/test-verify-install.sh
./install.sh    # leave system in installed state
./verify-install.sh
```

Expected: every command exits 0; `verify-install.sh` prints `OK: 17 symlinks installed (1 rule + 3 workflows + 13 skills)`; all three `test-*.sh` print `PASS:`.

If any fails, the PowerShell scripts somehow regressed the bash side (shouldn't be possible — bash files were not modified). Stop and investigate.

- [ ] **Step 2: Audit the three .ps1 files for forbidden strings**

Run:
```bash
cd superpower-custom
# No placeholders left
! grep -nE '\b(TODO|TBD|FIXME)\b' install.ps1 uninstall.ps1 verify-install.ps1
# No bash-isms (defensive — these would mean a copy-paste error)
! grep -n 'ln -sfn' install.ps1 uninstall.ps1 verify-install.ps1
! grep -n 'readlink' install.ps1 uninstall.ps1 verify-install.ps1
# Each file declares the strict error mode
grep -q "ErrorActionPreference = 'Stop'" install.ps1
grep -q "ErrorActionPreference = 'Stop'" uninstall.ps1
grep -q "ErrorActionPreference = 'Stop'" verify-install.ps1
```

All checks must succeed (the `!` ones must exit 1 from grep's perspective; the `grep -q` ones must exit 0).

- [ ] **Step 3: Push**

```bash
cd superpower-custom
git push origin main
```

- [ ] **Step 4: Document manual Windows smoke test**

Append a Windows section to `docs/superpowers/test-results.md`:

```markdown

## Windows Manual Smoke Test (run on a Windows 10/11 machine)

Run in this order from the workspace root in PowerShell:

| # | Command | Expected | Pass? |
|---|---|---|---|
| W1 | `.\superpower-custom\install.ps1` | Output: "Installed ... (13 linked)" plus the re-run note | __ |
| W2 | `.\superpower-custom\verify-install.ps1` | `OK: 17 items installed (1 rule + 3 workflows + 13 skills, mixed copy+junction)` | __ |
| W3 | Append a line to `superpower-custom\skills\brainstorming\SKILL.md`. Open `..\.cline\skills\brainstorming\SKILL.md`. | The appended line is present (junction is live). Revert. | __ |
| W4 | Append a line to `superpower-custom\rules\00-bootstrap.md`. Run `.\superpower-custom\verify-install.ps1`. | `STALE COPY:` line for `.clinerules\00-bootstrap.md`, exit 1. | __ |
| W5 | `.\superpower-custom\install.ps1` then `.\superpower-custom\verify-install.ps1`. | After re-install, verify shows `OK: 17 items installed`. Revert source edit. | __ |
| W6 | `.\superpower-custom\uninstall.ps1` | `Removed N items. Source kept at <path>.` | __ |
| W7 | `.\superpower-custom\verify-install.ps1` | Exit 1, FAIL list (missing files / junctions). | __ |
| W8 | `.\superpower-custom\install.ps1` | Back to installed state. | __ |
```

Then commit:

```bash
cd superpower-custom
git add docs/superpowers/test-results.md
git commit -m "docs: add Windows smoke-test checklist"
git push origin main
```

---

## Plan summary

| Task | Files added/modified | New lines (rough) |
|---|---|---|
| 1 | install.ps1 | ~45 |
| 2 | uninstall.ps1 | ~45 |
| 3 | verify-install.ps1 | ~75 |
| 4 | INSTALL.md (Windows section appended) | ~40 |
| 5 | README.md (Install section replaced) | ~15 net |
| 6 | docs/superpowers/test-results.md (Windows checklist) | ~15 |

**Total:** 6 tasks, ~235 new lines, 4 commits + 1 final push (with extra
test-results commit). No changes to existing bash scripts, tests, or
skills.
