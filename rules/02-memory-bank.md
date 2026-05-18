# Memory Bank — always check

This workspace uses a **Memory Bank** to survive session resets and context
compaction. The Memory Bank lives in `<workspace>/memory-bank/` and contains
6 markdown files that capture the persistent state of work.

**At the start of EVERY session (or right after a context compaction), do this BEFORE anything else:**

1. Check if `<workspace>/memory-bank/` exists.
2. If yes: `read_file` ALL six files in this order:
   - `projectbrief.md` — what this project is and its scope
   - `productContext.md` — why it exists, UX/UI goals
   - `systemPatterns.md` — architecture and patterns
   - `techContext.md` — tech stack and constraints
   - `activeContext.md` — current focus and recent changes
   - `progress.md` — what's done, what's next, blockers
3. If no: ask the user "Do you want me to initialize the Memory Bank?"
   (and follow the `using-memory-bank` skill if they say yes).

**During work**, after any significant change (new decision, completed task,
blocker hit, architecture shift), update the relevant Memory Bank file(s).
At a minimum, update `activeContext.md` and `progress.md` before ending a
session or running a long-running operation.

If the user says **"update memory bank"**, do a full review of all 6 files
and update them to reflect current state. If they say **"follow your custom
instructions"** or **"resume"**, re-read the Memory Bank and continue from
where `activeContext.md` and `progress.md` indicate.

Detailed guidance: load the `using-memory-bank` skill via `use_skill`.
