# Superpowers (Custom for Cline VSCode)

A port of the [Superpowers](https://github.com/obra/superpowers) framework
adapted for Cline running as a VSCode extension. Single-agent + read-only
subagents.

## Install

From the workspace root that contains this repo:

```bash
./superpower-custom/install.sh
```

This creates symlinks in `.clinerules/`, `.clinerules/workflows/`, and
`.cline/skills/` pointing into this repo. Edit the source here and Cline
sees the update on the next turn.

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
