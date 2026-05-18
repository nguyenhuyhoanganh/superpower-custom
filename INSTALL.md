# Installation Guide

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
