---
name: migratepark
description: Move local parked notes (~/.claude/parked.md) to the MCP backend with park_idea.
disable-model-invocation: true
allowed-tools: Bash(printenv PARKED_BACKEND), Bash(echo local)
---

Backend: !`printenv PARKED_BACKEND || echo local`

1. If the backend is `local`, reply `set PARKED_BACKEND=corteza first, then run /migratepark` and stop.
2. Follow `${CLAUDE_SKILL_DIR}/../../references/mcp-backend.md`. If no `park_idea` tool is connected, reply as it says and stop.
3. Read `~/.claude/parked.md` (or `$PARKED_FILE`). Each entry is `- #N · YYYY-MM-DD · note`. If there are none, reply `nothing to migrate` and stop.
4. Show the count and ask `move N notes to the server? they'll be removed from parked.md (y/n)`. On anything but yes, stop.
5. For each entry, oldest ID first, one at a time:
   1. Call `park_idea` with `text` = the note verbatim. Nothing else: no date, no ID, no Tags.
   2. Only if it succeeded, run `bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" remove N` with the local ID. Do not edit the file yourself.
   3. If `park_idea` fails (e.g. rate limited), stop the loop. The notes not yet moved stay in the file, so running `/migratepark` again later continues where it left off.
6. Reply with one line per moved note, `#local → #server`, then `moved X of N`, plus the error if the loop stopped. No other commentary.
