---
name: unpark
description: Remove one or more parked items by ID.
disable-model-invocation: true
argument-hint: "<id> [id...]"
---

Remove parked items: $ARGUMENTS

1. If no IDs are given, reply `usage: /unpark <id>` and stop.
2. Run `bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" remove <ids>`, passing the IDs as given (`3`, `#3`, `3 5` and `3,5` all work). Do not read or edit `~/.claude/parked.md` yourself.
3. Reply with exactly the script's output. No other commentary.
