---
name: creating-hooks
description: Creates new Cline hooks (.clinerules/hooks/<EventName>) that fire on lifecycle events (TaskStart, PreToolUse, PostToolUse, etc.) to inject context, block tool calls, or run side effects. Covers the two hook systems (file-based for VSCode extension vs SDK plugin events for custom agents), event types, JSON stdin/stdout schema, executable file naming, cross-platform variants (bash + PowerShell), and safety considerations.
---

# Creating Cline Hooks

A Cline hook is an executable file under `.clinerules/hooks/` that Cline runs on a lifecycle event. The hook reads a JSON event from stdin and writes a JSON response to stdout. The response can:

- Inject text into the conversation (`contextModification`)
- Block the upcoming operation (`cancel: true`)
- Surface an error to the user (`errorMessage`)

Use this skill when the user wants to wire deterministic logic into Cline's lifecycle — auto-load a skill on task start, validate tool calls before they run, or log activity to disk.

## When a hook is the right tool

| Need | Use |
|---|---|
| "On event E, inject context / block / log" | **Hook** |
| "When I say `/X`, run a procedure" | **Workflow** — see `creating-workflows` |
| "Always behave like X" | **Rule** — see `creating-rules` |
| "When I ask about Z, expert procedure" | **Skill** — see `creating-skills` |

Hooks fire automatically and deterministically. If the user can comfortably invoke the logic manually, a workflow is usually simpler and easier to audit.

## Two hook systems — pick the right one

Cline exposes hooks at **two levels**. Use the right one for the user's environment.

### A. File-based hooks (VSCode extension users) — this is the default

Executable scripts at `.clinerules/hooks/<EventName>`. No code build, no npm package — just an executable file the extension runs on the listed lifecycle events. **This is what this skill writes by default.**

Events available to file-based hooks (from the v3.36 release):

| Event | When it fires | Common use |
|---|---|---|
| `TaskStart` | New Cline task begins | Inject project context, point at a skill, detect project type |
| `TaskResume` | Cline resumes a paused task | Restore state, re-warn about pending items |
| `TaskCancel` | A task is cancelled | Cleanup, logging |
| `UserPromptSubmit` | User submits a message | Pre-process the prompt, inject memory, redact secrets |
| `PreToolUse` | Cline is about to call a tool | Validate / block dangerous operations |
| `PostToolUse` | A tool call completed | Audit log, learning, side effects |

Event names are **case-sensitive** and must match exactly.

### B. SDK plugin hooks (Cline SDK / custom agents) — richer event surface

If the user is building a custom agent with the [Cline SDK](https://docs.cline.bot/sdk/plugins) (TypeScript `AgentPlugin`), they get a much finer-grained event surface:

**Lifecycle stages** (low-level event names):

| Stage | When it fires |
|---|---|
| `input` | Raw input received before any agent processing |
| `runtime_event` | Generic runtime event channel |
| `session_start` | Agent session opens |
| `run_start` | A `run()` call begins |
| `iteration_start` | One agent iteration (planning + tool call loop) begins |
| `turn_start` | One conversation turn begins |
| `before_agent_start` | Just before the agent's first model call — inject context / modify prompt here |
| `tool_call_before` | Just before a tool executes |
| `tool_call_after` | After a tool finishes |
| `turn_end` | Turn complete |
| `stop_error` | Agent stopped due to an error |
| `iteration_end` | Iteration complete |
| `run_end` | `run()` complete — emit metrics, send notifications, cleanup |
| `session_shutdown` | Session closes |
| `error` | Unhandled error surfaced |

**High-level handlers** (`AgentPlugin.hooks` object): `beforeRun`, `afterRun`, `beforeModel`, `afterModel`, `beforeTool`, `afterTool`, `onEvent` — these wrap the raw stages for ergonomic plugin code.

**Important:** SDK plugin hooks are **TypeScript code** distributed as npm packages or local files. They are **not** file-based scripts and they do **not** live in `.clinerules/hooks/`. Choose this path only when the user is building a custom agent with the SDK, not when they're using the VSCode extension.

This skill writes **file-based hooks (system A)** unless the user explicitly says they're building an SDK plugin. If they ask for an event that only exists in system B (e.g., "fire something on `iteration_end`"), say so and ask whether they want to go the SDK route.

## Anatomy

```
<workspace>/.clinerules/hooks/
├── TaskStart            ← bash / shell (no extension)
├── TaskStart.ps1        ← PowerShell variant for Windows users
├── PreToolUse           ← optional
└── PostToolUse          ← optional
```

- **Workspace hooks:** `.clinerules/hooks/<EventName>` (commit to git; project-specific)
- **Global hooks:** `~/Documents/Cline/Rules/Hooks/<EventName>` (apply to every project)
- File **name must match the event exactly**, no extension on the canonical Unix variant
- The Unix file must be **executable** (`chmod +x .clinerules/hooks/TaskStart`)
- For Windows, ship a sibling `<EventName>.ps1`

### Platform notes

Cline's official v3.36 hooks release stated macOS and Linux only. Community implementations ship a `<EventName>.ps1` PowerShell variant alongside the Unix script so Windows users get parity. If anyone on the team runs Windows, write both variants and keep their behavior identical.

## JSON I/O contract

### Input on stdin

Cline writes a single JSON object to the hook's stdin. Base fields present on every event:

```json
{
  "clineVersion": "3.36.0",
  "hookName": "TaskStart",
  "timestamp": "2026-05-19T10:00:00Z",
  "taskId": "task-abc123",
  "workspaceRoots": ["/Users/alice/project"],
  "userId": "user-xyz"
}
```

Event-specific fields are added on top — `tool` and `toolInput` for `PreToolUse`, `prompt` for `UserPromptSubmit`, and so on. The exact schema can evolve across Cline versions; treat the payload as forward-compatible and read defensively (default to `""` when a field is missing).

### Output on stdout

The hook writes exactly one JSON object to stdout:

```json
{
  "cancel": false,
  "contextModification": "Optional text to inject into the conversation",
  "errorMessage": ""
}
```

| Field | Type | Meaning |
|---|---|---|
| `cancel` | bool | If `true`, Cline aborts the upcoming operation (task / tool call / message) |
| `contextModification` | string | Text appended to the conversation as system context — visible to the agent next turn |
| `errorMessage` | string | Shown to the user if non-empty |

Exit code 0 = success. Non-zero = failure; Cline surfaces stderr to the user. On crash, treat as `cancel: true` for safety.

## Examples

### TaskStart — bash variant

```bash
#!/usr/bin/env bash
# .clinerules/hooks/TaskStart
set -euo pipefail

# Read the event payload (discard if unused — Cline still requires us to consume stdin)
cat >/dev/null

NOTE="Use the 'house-style' skill for any new code.
Run /engineering-rules before opening a PR."

# JSON-escape NOTE using pure bash parameter substitution (portable: macOS BSD + Linux GNU)
escape_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/\\r}"
  printf '"%s"' "$s"
}

printf '{"cancel": false, "contextModification": %s, "errorMessage": ""}\n' \
  "$(escape_json "$NOTE")"
```

### TaskStart — PowerShell variant

```powershell
#!/usr/bin/env pwsh
# .clinerules/hooks/TaskStart.ps1
$ErrorActionPreference = 'Stop'

# Drain stdin even if we don't read it
$input | Out-Null

$note = @"
Use the 'house-style' skill for any new code.
Run /engineering-rules before opening a PR.
"@

[ordered]@{
  cancel              = $false
  contextModification = $note
  errorMessage        = ''
} | ConvertTo-Json -Compress
```

### PreToolUse — block destructive shell commands

```bash
#!/usr/bin/env bash
# .clinerules/hooks/PreToolUse
set -euo pipefail

INPUT="$(cat)"

# Robust field extraction — jq if available, python3 fallback
get() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r "$1 // empty"
  else
    printf '%s' "$INPUT" | python3 -c "import sys,json;d=json.load(sys.stdin)
def dig(o,p):
  for k in p.split('.'):
    if isinstance(o,dict): o=o.get(k,'')
    else: return ''
  return o
print(dig(d,'${1#.}'))"
  fi
}

TOOL="$(get .tool)"
CMD="$(get .toolInput.command)"

if [ "$TOOL" = "execute_command" ] && \
   printf '%s' "$CMD" | grep -qE 'rm -rf /|git reset --hard|chmod -R 777'; then
  printf '{"cancel": true, "contextModification": "", "errorMessage": "Refused by PreToolUse hook: destructive command blocked"}\n'
  exit 0
fi

printf '{"cancel": false, "contextModification": "", "errorMessage": ""}\n'
```

## Safety considerations

Hooks run on **every** matching event with the user's full shell privileges and **no sandboxing**.

- **Never** `rm`, `curl | sh`, package installs, or git destructive operations from a hook unless the user has explicitly opted in.
- Treat stdin JSON as untrusted: validate before using fields as shell args. Quote variables.
- **Keep hooks fast.** They block Cline's UI; aim for <100ms.
- Log to a workspace-relative path, never to `/tmp` outside the workspace, never to the user's home outside `~/Cline/`.
- **Crash-safe:** if the hook errors out partway, Cline blocks the operation. Wrap script bodies in `set -euo pipefail` (bash) or `$ErrorActionPreference = 'Stop'` (PowerShell), and emit a valid JSON response even on failure.
- Avoid network calls. A hook that depends on a remote service blocks the whole agent when the service is down.

## Anti-patterns

| Anti-pattern | What to do instead |
|---|---|
| Hook does work the agent should do | Let the agent do it; use the hook only for deterministic guardrails |
| Always-on context injection that fits a rule | Use a **rule** in `.clinerules/` — easier to maintain and toggle |
| Hook with no PowerShell variant on a Windows team | Ship `<Event>` + `<Event>.ps1` |
| `contextModification` re-explaining agent basics | Cut — agent already knows |
| Hardcoded absolute paths inside the script | Resolve from `$(dirname "$0")` / `$PSScriptRoot` |
| Crash on malformed stdin | Validate JSON; on error, emit a clean failure response |
| Writing to files outside the workspace | Confine to workspace-relative paths |
| Network call on every event | Hooks block the UI; avoid remote dependencies |
| Hook silently does side effects | Surface them via `contextModification` so the user sees what fired |

## Process

### 1. Pick the event

Match the user's need to one of the file-based events: `TaskStart` / `TaskResume` / `TaskCancel` / `UserPromptSubmit` / `PreToolUse` / `PostToolUse`.

If the user names an event that only exists in the SDK plugin surface (e.g. `iteration_end`, `before_agent_start`, `session_shutdown`), stop and ask whether they want to write a TypeScript SDK plugin instead. That is a different workflow from this skill — point them at https://docs.cline.bot/sdk/plugins.

### 2. Pick the destination

- Project-specific → `.clinerules/hooks/<Event>` (commit to git)
- Global → `~/Documents/Cline/Rules/Hooks/<Event>`

### 3. Decide platform variants

If anyone on the team runs Windows, ship `<Event>` (bash) **and** `<Event>.ps1` (PowerShell) with matching behavior. Otherwise the bash variant alone is fine for macOS / Linux.

### 4. Write the script

- Read stdin (drain it even if you don't use the payload)
- Compute the response
- Emit exactly one JSON object on stdout
- Exit 0 on success; non-zero only on genuine failure
- `set -euo pipefail` (bash) or `$ErrorActionPreference = 'Stop'` (PowerShell)

### 5. Make it executable

```bash
chmod +x .clinerules/hooks/TaskStart
```

(PowerShell `.ps1` does not need a Unix executable bit.)

### 6. Test the hook in isolation

```bash
echo '{"clineVersion":"3.36.0","hookName":"TaskStart","timestamp":"2026-01-01T00:00:00Z","taskId":"t1","workspaceRoots":["'"$PWD"'"],"userId":"u1"}' \
  | .clinerules/hooks/TaskStart
```

```powershell
$payload = '{"clineVersion":"3.36.0","hookName":"TaskStart","timestamp":"2026-01-01T00:00:00Z","taskId":"t1","workspaceRoots":[".'"],"userId":"u1"}'
$payload | pwsh -File .clinerules/hooks/TaskStart.ps1
```

Expected: exit 0, exactly one line of valid JSON on stdout.

### 7. Self-review

- Does this need to fire on every event? Or would a workflow / rule be simpler?
- Does the hook write outside the workspace? Don't.
- Does the hook block dangerous operations cleanly with a useful `errorMessage`?
- Does the hook survive malformed stdin without crashing?
- Bash + PowerShell variants behave identically? Diff the test outputs.
- Hook responds in <100ms on a warm cache? If not, trim.

### 8. Tell the user how to verify

Open Cline, start a new task, and confirm the `contextModification` text appears in the conversation (or that the `cancel:true` block trips on a test command). Cline does not need to be restarted after writing the hook — the next event fires it.

## Example walkthrough

**User:** "On every task start, remind Cline to use our `house-style` skill and `/engineering-rules` workflow."

**1. Event:** `TaskStart`.

**2. Destination:** `.clinerules/hooks/TaskStart` (commit to repo so the whole team benefits).

**3. Platforms:** team uses both macOS and Windows → bash + `.ps1`.

**4-5. Scripts:** as in the TaskStart examples above, with `$NOTE` containing the project-specific guidance.

**6. Test:**

```bash
echo '{"hookName":"TaskStart","timestamp":"2026-05-19T00:00:00Z","taskId":"t","workspaceRoots":["'"$PWD"'"]}' \
  | .clinerules/hooks/TaskStart
```

Should emit `{"cancel": false, "contextModification": "Use the 'house-style' skill...", "errorMessage": ""}`.

**7-8. Verify in Cline:** start a fresh task; the `contextModification` text should appear as system context on turn 1.
