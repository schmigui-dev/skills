---
name: unpark
description: Remove one or more parked items by ID.
disable-model-invocation: true
allowed-tools: Bash(printenv PARKED_BACKEND), Bash(echo local)
argument-hint: "<id> [id...]"
---

Remove parked items: $ARGUMENTS

Backend: !`printenv PARKED_BACKEND || echo local`

1. If no IDs are given, reply `usage: /unpark <id>` and stop.
2. Remove them. Accept `3`, `#3`, `3 5` and `3,5`.
   - `local`: run `bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" remove <ids>`, passing the IDs as given. Do not read or edit `~/.claude/parked.md` yourself.
   - `corteza`: follow `${CLAUDE_SKILL_DIR}/../../references/mcp-backend.md`. Call `remove_idea` with `numbers` = the IDs.
3. Reply with exactly the script's or tool's output. No other commentary.
