# Slim Code Heuristic — what stays in the plan, what does not

The plan is the **executor's contract** and the **agent's discipline guardrail** — not a copy of the eventual codebase. Code in the plan competes with conversation history for context. Every code block must earn its tokens.

## Keep / cut matrix

| Category | Keep in plan? | Why |
|---|---|---|
| Test code (full body) | **KEEP** | Test IS the contract. TDD discipline depends on engineer seeing the assertion verbatim. |
| Type signatures, function signatures, API shapes | **KEEP** | The interface is the agreement between tasks. Drift here breaks later tasks. |
| Exact output formats (JSON shape, file layout, CSV header) | **KEEP** | Format is a contract. Engineer cannot derive a wrong-but-passing format. |
| Non-obvious patterns, gotchas, anti-patterns to avoid | **KEEP** | Things the engineer would otherwise get wrong. |
| Exact shell commands + expected output | **KEEP** | Verification is the loop's closing step. |
| `git add` / `git commit -m "..."` exact lines | **KEEP** | Commit-message discipline. |
| "Minimal impl to make test pass" | **CUT** | Test already specifies behavior. Reference spec § for design. |
| Trivial getter / setter / constructor / default init | **CUT** | The engineer writes these in their sleep. |
| Boilerplate scaffolding (framework `__init__`, empty class shell) | **CUT** | Not project-specific knowledge. |
| Re-statement of spec content | **CUT** | Link to spec §X.Y instead. |
| Prose translation of the test ("loop through array and apply X") | **CUT** | The test reads as the prose. |
| Code already shown in a prior task | **CUT** | Reference the prior task by number. |

## What CUT actually means

Cutting code is **not** vagueness. Replace the removed code block with:

- One-line description (what is being implemented)
- A precise pointer: spec §X.Y, file:line, related test name, or earlier task number

The engineer must always know exactly where to look. A cut step without a pointer is a plan failure — the engineer guesses, the agent shortcuts, the discipline breaks.

## Worked examples

### Example 1 — implement step

Bad (bloated, just re-states the test):

````markdown
- [ ] Step 3: Write the minimal implementation

```python
def add(a, b):
    return a + b
```
````

Good (slim, with pointer):

```markdown
- [ ] Step 3: Implement `add` in `src/math.py`.
      The test already constrains behavior; no edge-case handling beyond
      what the test asserts.
```

### Example 2 — non-obvious algorithm

Bad (cuts too much, engineer cannot derive):

```markdown
- [ ] Step 3: Implement the matching algorithm.
```

Good (kept because the algorithm is non-obvious):

````markdown
- [ ] Step 3: Implement `match_records` in `src/match.py`.

Use a two-pointer scan: sort both lists by `key`, then walk in lockstep
matching on equal keys. Time complexity must be O(n log n), not O(n²).

Skeleton:

```python
def match_records(left: list[Record], right: list[Record]) -> list[Pair]:
    left_sorted  = sorted(left, key=lambda r: r.key)
    right_sorted = sorted(right, key=lambda r: r.key)
    # two-pointer walk...
```

See spec §4.1 for the tie-breaking rule when multiple right-records share a key.
````

The skeleton is kept because the two-pointer pattern is the contract. Tie-breaking is in the spec — referenced, not duplicated.

### Example 3 — boilerplate setup task

Bad (every line spelled out):

````markdown
- [ ] Step 1: Create the package

```python
# src/match/__init__.py
"""Record matching package."""
```

- [ ] Step 2: Create the empty class

```python
# src/match/matcher.py
class Matcher:
    pass
```
````

Good (collapsed):

```markdown
- [ ] Steps 1-2: Scaffold `src/match/` package (empty `__init__.py`,
      empty `Matcher` class stub in `matcher.py`). No tests for this step.
```

### Example 4 — output format that must be exact

Bad (description only — engineer will improvise the format):

```markdown
- [ ] Step 3: Make the function return a summary dict.
```

Good (exact format kept because format is a contract):

````markdown
- [ ] Step 3: Implement `summarize`. Return exactly this shape — no
      extra keys, key order does not matter:

```python
{
    "total": int,              # row count
    "by_status": dict[str, int],  # status -> count
    "first_seen": datetime,    # earliest timestamp in the data
    "last_seen":  datetime,
}
```
````

## The "would a fresh engineer derive this from spec + test alone?" test

For every code block in the plan, ask:

> Could a competent engineer who has only read the spec and the failing test in this task arrive at this code without me showing it?

- **Yes** → cut it. Replace with description + pointer.
- **No** → keep it. The plan is the only place the engineer will see it.

When in doubt, keep the **shape** (signatures, types, output format) and cut the **body**.

## Anti-anti-pattern: do not strip the test code

Test code is the one category that is **always full** in the plan. It looks like "implementation" to the slim-cutter's eye but it is actually the contract.

If you find yourself cutting test code to save tokens, stop — that is the failure mode this heuristic is designed to prevent. The test is what makes the plan executable; without it, the plan becomes spec, and the agent shortcuts.
