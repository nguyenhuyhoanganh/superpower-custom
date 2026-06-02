# /check-webui-style

Load the `chromium-webui-style-check` skill via `use_skill` and follow it
exactly.

Run the style gate over the most recent commit (the CL about to be uploaded —
`check-style.sh` with no args, suited to the Gerrit one-commit-per-CL flow),
report every ERROR and WARN mapped to file:line, then work the manual checklist
for what the script can't judge. Use `check-style.sh working` if checking
uncommitted changes before a commit.

Hard gate: do NOT report the work as style-clean, and do NOT commit or push,
until the checker has been run on THIS diff and all ERRORs are resolved (or
explicitly justified to the user).
