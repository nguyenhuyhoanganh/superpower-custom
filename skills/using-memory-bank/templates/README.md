# Memory Bank Templates

These are starting-point templates for the 6 core Memory Bank files. The
`using-memory-bank` skill copies them into `<workspace>/memory-bank/` when
you ask it to initialize.

Each template has:
- A short blockquote at the top explaining the file's purpose
- Section headers with `_italic placeholders_` showing what goes there

Fill in the placeholders for your project. Keep entries short and factual
— Memory Bank stores state, not narrative.

## File order (most stable → most volatile)

1. `projectbrief.md` — foundation, scope (rarely changes)
2. `productContext.md` — why, users, UX goals (rarely)
3. `systemPatterns.md` — architecture (changes when arch changes)
4. `techContext.md` — stack, setup (changes when deps change)
5. `activeContext.md` — current focus (every session)
6. `progress.md` — done/pending/blockers (every task completion)
