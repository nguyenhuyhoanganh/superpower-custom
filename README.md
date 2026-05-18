# Superpowers (Custom for Cline VSCode)

A port of the [Superpowers](https://github.com/obra/superpowers) framework
adapted for Cline running as a VSCode extension. Single-agent + read-only
subagents.

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

## Layout

- `rules/` — bootstrap rule appended to every system prompt
- `workflows/` — slash commands (`/brainstorm`, `/write-plan`, `/execute-plan`)
- `skills/` — 13 skills loaded on demand via `use_skill`
- `docs/superpowers/specs/` — design specs
- `docs/superpowers/plans/` — implementation plans

## Uninstall

```bash
./superpower-custom/uninstall.sh
```

Removes symlinks; source files untouched.

## Verify

```bash
./superpower-custom/verify-install.sh
```

Reports symlink health (expected: 17 symlinks resolving to existing files).
