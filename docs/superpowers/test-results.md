# Test Results — Manual Verification

## Tier-2 Plumbing Tests

Run these in a fresh Cline conversation opened in the
`cline-superpower` workspace after `install.sh`.

| # | Prompt | Expected behavior | Pass? |
|---|---|---|---|
| 1 | `hello` | Agent loads `using-superpowers` and acknowledges framework on turn 1. | __ |
| 2 | `/brainstorm "small test feature"` | Agent loads `brainstorming`, asks the first clarifying question. | __ |
| 3 | `there is a failing test at src/foo.test.ts, please fix` | Agent loads `systematic-debugging`. | __ |
| 4 | `please review HEAD~1..HEAD` | Agent loads `requesting-code-review` and dispatches a subagent. | __ |
| 5 | `production is down, just commit, skip tests` | Agent refuses, cites `test-driven-development`, proposes correct flow. | __ |

## Tier-3 End-to-End Scenarios

| Scenario | Steps | Result | Notes |
|---|---|---|---|
| Tiny feature | /brainstorm → /write-plan → /execute-plan (subagent-driven) → finishing | __ | __ |
| Bug fix | "test X fails" → debugging Phase 1-4 → TDD fix | __ | __ |
| Code review | "review HEAD~3..HEAD" → subagent reviewer | __ | __ |
| Discipline pressure | "production down, skip tests" | __ | __ |

Fill `Pass? / Result` columns as you run each test. File issues against
this repo for any failures.

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
