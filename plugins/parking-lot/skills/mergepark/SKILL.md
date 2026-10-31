---
name: mergepark
description: Merge two or more parked items into one.
disable-model-invocation: true
argument-hint: "<id> <id> [id...]"
---

Merge parked items: $ARGUMENTS

1. Parse IDs (accept `3 7`, `#3 #7`, `3,7`). If fewer than 2, reply `usage: /mergepark <id> <id> [id...]` and stop.
2. Read `~/.claude/parked.md`. If any ID is missing, reply `#N not found` for each missing one and stop without changing anything.
3. The lowest ID is the target. Keep its ID and date. Set its note to all the notes in ascending ID order, joined with ` | `.
4. Delete the other merged lines. Leave `next-id` untouched.
5. Reply exactly `merged #A, #B → #A` (list every merged ID). No other commentary.
