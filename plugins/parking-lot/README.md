# parking-lot

Park an idea or question in two seconds without derailing what you're doing. Come back to it later.

```text
/park "check if the retry logic also covers webhook timeouts"
parked #12
```

Claude doesn't answer or comment on the note. It saves it and goes back to the task.

## Install

```text
/plugin marketplace add schmigui-dev/skills
/plugin install parking-lot@schmigui
```

Commands are namespaced as `/parking-lot:<command>`.

## Commands

| Command | Does |
| --- | --- |
| `/park "note"` | Park a note. Replies `parked #N`. |
| `/parked [oldest]` | List notes, newest first. Pick a number to discuss it. Offers to remove it when you're done. |
| `/unpark <id> [id...]` | Remove notes. |
| `/repark <id> "text"` | Replace a note, keeping its ID and date. |
| `/repark <id> add "x" at the end` | Edit a note in place. Also `prepend`, `replace "a" with "b"`, `remove "x"`, `insert "x" after "y"`. |
| `/mergepark <id> <id> [id...]` | Merge into the lowest ID. Notes are joined with ` \| `. |
| `/reindexpark` | Renumber notes 1..n, oldest first, to close gaps. |

All commands run only when you type them. Claude never invokes them on its own.

## Storage

Notes live in `~/.claude/parked.md`, one per line. It's plain Markdown, so you can edit it by hand.

```markdown
<!-- next-id: 4 -->
# Parked

- #1 · 2026-10-31 · max upload size for a Worker endpoint?
- #3 · 2026-10-31 · a glossary site for business terms
```

IDs are never reused until you run `/reindexpark`.

Every command that changes the list goes through `scripts/park.sh`, which takes a lock and writes atomically, so parallel sessions never share an ID or overwrite each other's notes. Set `PARKED_FILE` to use a different file.

## MCP backend (optional)

Set `PARKED_BACKEND=corteza` to keep notes in an MCP server instead of the local file, e.g. in
`~/.claude/settings.json`:

```json
{ "env": { "PARKED_BACKEND": "corteza" } }
```

The commands then call the server's `park_idea`, `list_ideas`, `get_idea`, `update_idea` and
`remove_idea` tools. [corteza](https://corteza.dev) exposes them at `https://corteza.dev/mcp`, and your
notes show up as Ideas in its dashboard; any server with the same tools works. Same commands, with two
differences: `/mergepark` is emulated (update the lowest ID, remove the rest) and `/reindexpark` does
nothing, since the server never reuses IDs. Unset it to go back to `~/.claude/parked.md`. Existing local
notes are not moved.

Details: [references/mcp-backend.md](references/mcp-backend.md).

## License

MIT
