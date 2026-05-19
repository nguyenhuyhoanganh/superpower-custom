# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL — Use `subagent-driven-development` (recommended) or `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** [One sentence describing what this builds.]

**Architecture:** [2-3 sentences about the approach.]

**Tech Stack:** [Key technologies / libraries.]

**Files:**
- Create: `path/a`, `path/b`
- Modify: `path/c`, `path/d`
- Test: `tests/path/...`

---

### Task 1: [Component name]

**Goal:** [One sentence.]

**Files:**
- Create: `exact/path/to/file.py`
- Test:   `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

`pytest tests/path/test.py::test_name -v` → expected FAIL.

- [ ] **Step 3: Implement `<symbol>`**

[One-line description.] Reference: spec §X.Y.

- [ ] **Step 4: Run test to verify it passes**

`pytest tests/path/test.py::test_name -v` → expected PASS.

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: <short description> (task 1)"
```

---

### Task 2: [...]

...
