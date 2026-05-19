# Task NN: [Component Name]

**Goal:** [One sentence — what this task delivers.]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test:   `tests/exact/path/to/test.py`

**Depends on:** [Task numbers — leave empty if none.]

---

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    # Arrange
    input_value = ...
    # Act
    result = function(input_value)
    # Assert
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

```bash
pytest tests/path/test.py::test_specific_behavior -v
```

Expected: `FAILED` with `NameError: name 'function' is not defined` (or equivalent).

- [ ] **Step 3: Implement `<symbol>`**

[One-line description.]
Reference: spec §X.Y for [algorithm / data model / constraint].

[Only include a code snippet here if the implementation pattern is non-obvious from the test — see `references/slim-code-heuristic.md`. Otherwise just describe + reference.]

- [ ] **Step 4: Run test to verify it passes**

```bash
pytest tests/path/test.py::test_specific_behavior -v
```

Expected: `PASSED`.

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: <short description> (task NN)"
```

---

## Notes / gotchas (optional)

[Anything the engineer would otherwise get wrong: hidden dependencies,
ordering constraints, environment requirements, non-obvious patterns
to mirror or avoid. Leave this section out entirely if not needed.]
