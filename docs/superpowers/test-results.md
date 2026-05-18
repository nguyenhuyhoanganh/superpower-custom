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
