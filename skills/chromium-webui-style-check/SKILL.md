---
name: chromium-webui-style-check
description: Use after writing or editing Chromium WebUI code (HTML, CSS, TS/JS, Polymer/Lit) and BEFORE committing or pushing - runs a local style gate over the git diff to catch coding-style violations (alphabetical CSS sorting, 80-column limit, naming, RTL, zero-units, banned iron-/paper- deps, var/isNaN, inline style/handlers) the way `git cl presubmit` would, so review is clean before upload
---

# Chromium WebUI Style Check

Local style gate for Chromium-fork WebUI work. Mirrors the cheap, mechanical
parts of `git cl presubmit` so you catch nits **before** committing/pushing
and before Gerrit review — not after.

**Core principle:** evidence before "it's clean". Run the checker, read every
finding, fix or justify each one. Never claim style-clean without fresh output.

## When to use

- Right after finishing a WebUI change, before `git commit`.
- Before `git push` / `git cl upload`.
- When asked to "check style", "lint", "presubmit", "before push".

This is a complement to, not a replacement for, the real `git cl presubmit`
and build-time `:lint_ts`. It is fast and offline; the canonical checks still
run on the Chromium tree.

## The Gate

Tuned for the Gerrit workflow: a CL is a single (amended) commit on a shared
branch, so by default the checker looks at ONLY the most recent commit — the
CL you're about to `git cl upload` — not the whole branch history and not other
people's commits.

```
1. RUN the checker on the diff:
     bash check-style.sh            # the latest commit (HEAD~1..HEAD) [default]
     bash check-style.sh working    # uncommitted changes (before you commit)
     bash check-style.sh origin/main   # everything from a base ref to HEAD
     bash check-style.sh A..B          # an explicit commit range

2. READ every ERROR and WARN, mapped to file:line.

3. FIX:
     - ERROR  -> must fix before push (high-confidence, mechanical).
     - WARN   -> fix or write down why it's a false positive.

4. REVIEW BY HAND the rules the script cannot judge (see checklist below):
     naming conventions, semantics, $i18n usage, dom-if vs hidden, etc.

5. RE-RUN until ERRORs are 0. Only then claim style-clean, WITH the output.
```

Exit code: non-zero if any ERROR is found (suitable for a git `pre-push` hook).

## What the script checks (mechanical, on changed lines)

**All files**
- Lines over 80 columns (ERROR).
- Trailing whitespace; tabs instead of 2-space indent (WARN).

**CSS**
- Properties not in alphabetical order within a block (WARN — `-webkit-`/`--vars` heuristic).
- Zero values carrying a length unit, e.g. `0px` -> `0` (WARN).
- Double quotes instead of single quotes (WARN).
- Sub-second times in `s` instead of `ms`, e.g. `0.2s` -> `200ms` (WARN).
- `!important` (WARN).
- CSS Mixins `@apply` / `--foo: { }` — banned (ERROR).

**HTML**
- Inline `style="..."` attribute (ERROR).
- Inline native event handler `onclick="..."` etc. — note `on-click` Polymer
  binding is allowed and not flagged (ERROR).
- Self-closing void tags `<input ... />` (WARN).
- `<br>` (WARN); `<input type="button">` -> use `<button>` (WARN).

**TS/JS**
- `document.getElementById` -> use `$()` from `util` (WARN).
- `var` declarations -> `const`/`let` (ERROR).
- Global `isNaN(` -> `Number.isNaN()` (WARN).
- Non-strict `==` / `!=` (excluding `== null`/`!= null`) -> `===`/`!==` (WARN).

## Manual checklist (the script can't reliably judge these)

Source of truth: the Chromium Web Style Guide and the Google HTML/CSS, TS, and
JS guides. Condensed reference lives in `STYLE-RULES.md` next to this file.

**HTML**
- IDs in `dash-form` (or `camelCase` only in Polymer/Lit for `this.$.id`).
- All user-facing strings localized via `$i18n{}`, keys in `camelCase`.
- `<!doctype html>`, `dir="$i18n{direction}"`, `<meta charset="utf-8">`.
- Double-quoted attributes; 2-space indent; no spacing-only `<div>`s.
- `<table>` only for tabular data; label checkboxes by nesting `<input>` in `<label>`.

**CSS**
- Class names in `dash-form`; one selector per line; opening brace on last selector.
- RTL-friendly logical properties: `margin-inline-start`, `padding-inline-end`,
  `text-align: start/end`; otherwise `html[dir='rtl']` prefix.
- Colors: `rgb()/rgba()` decimals (gray shades like `#333` ok); no embedded data URIs.
- `::` for pseudo-elements; no class for a single element (use the ID).

**TypeScript**
- New WebUI code is TypeScript, not JS.
- No `any` to silence the compiler — use a precise type or `unknown`.
- No unnecessary non-null `!`; no `?.` used only to mute "possibly null" (use `assert()`).
- No `async` without `await`; no re-exporting imports from other files.
- `assertNotReachedCase()` in the default of an exhaustive enum switch.

**Polymer / Lit**
- Lit for new code; Polymer only for the documented exceptions.
- No new `iron-`/`paper-` dependencies — use `cr-*` from
  `ui/webui/resources/cr_elements` (e.g. `cr-collapse`, `cr-icon`).
- `on-click` not `on-tap`; `dom-if` only for non-trivial subtrees, else `hidden`.

## Wire it as a pre-push gate (optional)

```bash
# .git/hooks/pre-push  (chmod +x)
#!/usr/bin/env bash
# No args = check the latest commit (the CL being uploaded).
bash path/to/skills/chromium-webui-style-check/check-style.sh || {
  echo "Style gate failed — fix ERRORs above before uploading."
  exit 1
}
```

## Red flags — STOP

- "Looks fine, skipping the checker" — run it.
- Claiming clean from a previous run, not this diff.
- Suppressing a finding by reformatting rather than fixing the cause.
- Ignoring WARNs without a written reason.
