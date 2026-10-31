---
name: mergepark
description: Merge two or more parked items into one.
disable-model-invocation: true
argument-hint: "<id> <id> [id...]"
---

Merge parked items: $ARGUMENTS

1. If fewer than 2 IDs are given, reply `usage: /mergepark <id> <id> [id...]` and stop.
2. Run `bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" merge <ids>`, passing the IDs as given. Do not read or edit `~/.claude/parked.md` yourself.
   The script keeps the lowest ID and its date, joins all the notes in ascending ID order with ` | `, and deletes the others. If any ID is missing, it changes nothing.
3. Reply with exactly the script's output (`merged #A, #B → #A` or the not-found errors). No other commentary.
