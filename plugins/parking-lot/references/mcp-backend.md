# MCP backend (`PARKED_BACKEND=corteza`)

With `PARKED_BACKEND=corteza`, notes live in an MCP server instead of `~/.claude/parked.md`.
The commands work with any MCP server that exposes these tools; [corteza](https://corteza.dev)
is one (`https://corteza.dev/mcp`, the notes show up as Ideas in its dashboard).

| Tool | Used by |
| --- | --- |
| `park_idea` (`text`) → `parked #N in <Org>` | `/park`, `/migratepark` |
| `list_ideas` (`status`) → one line per note | `/parked` |
| `get_idea` (`number`) → the full note | `/parked`, `/repark`, `/mergepark` |
| `update_idea` (`number`, `text`) | `/repark`, `/mergepark` |
| `remove_idea` (`numbers`) → `removed #N` / `#N not found` | `/unpark`, `/parked`, `/mergepark` |

Rules for every command in this mode:

- Find the tool by its suffix: in Claude Code it is named like `mcp__<server>__park_idea`.
  If it is deferred, load it first. Never touch `~/.claude/parked.md` or `park.sh`.
- If no `park_idea` tool is connected, reply
  `PARKED_BACKEND=corteza but no park_idea tool is connected. Connect your MCP server (corteza: https://corteza.dev/mcp) or unset PARKED_BACKEND.`
  and stop.
- If a tool returns an error, reply with its text and stop.
- IDs are the server's `#N`. They are never reused, so `/reindexpark` does nothing.
