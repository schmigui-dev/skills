---
name: mergepark
description: Merge two or more parked items into one.
disable-model-invocation: true
allowed-tools: Bash(printenv PARKED_BACKEND), Bash(echo local)
argument-hint: "<id> <id> [id...]"
---

Merge parked items: $ARGUMENTS

Backend: !`printenv PARKED_BACKEND || echo local`

1. If fewer than 2 IDs are given, reply `usage: /mergepark <id> <id> [id...]` and stop.
2. Merge them: keep the lowest ID, join all the notes in ascending ID order with ` | `, delete the others. If any ID is missing, change nothing.
   - `local`: run `bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" merge <ids>`, passing the IDs as given. Do not read or edit `~/.claude/parked.md` yourself. The script does all of the above.
   - `corteza`: follow `${CLAUDE_SKILL_DIR}/../../references/mcp-backend.md`. The server has no merge, so emulate it, in this order:
     1. `get_idea` for every ID. If any is not found, reply `#N not found` for each missing one and stop without changing anything.
     2. `update_idea` on the lowest ID with `text` = the notes joined as above.
     3. `remove_idea` with the other IDs.
3. Reply with exactly `merged #A, #B → #A` (or the not-found errors). No other commentary.
