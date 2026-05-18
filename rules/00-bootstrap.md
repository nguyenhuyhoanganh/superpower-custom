# Superpowers — Bootstrap

This workspace uses the Superpowers framework. At the start of every
session, BEFORE replying to any message (including clarifying questions),
load the `using-superpowers` skill via `use_skill`. That skill defines
how you use the other skills.

**Rule:** if there is ≥1% chance the user's request matches a skill's
description, load that skill and follow it exactly. User instructions
always override skills when they conflict.
