---
name: unpark
description: Remove one or more parked items by ID.
disable-model-invocation: true
argument-hint: "<id> [id...]"
---

Remove parked items: $ARGUMENTS

1. Parse IDs from the arguments (accept `3`, `#3`, `3 5`, `3,5`). If none, reply `usage: /unpark <id>` and stop.
2. Read `~/.claude/parked.md`. Delete the line for each matching `#N`. Leave `next-id` untouched.
3. Reply `removed #N` for each removed, and `#N not found` for any missing. No other commentary.
