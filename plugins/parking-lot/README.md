# parking-lot

Park an idea or question in two seconds without derailing what you're doing. Come back to it later.

```text
/park "max upload size for a Worker endpoint? AWS API Gateway caps at ~10MB"
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

`/park` appends through `scripts/park.sh`, which takes a lock, so parallel sessions never hand out the same ID. Set `PARKED_FILE` to use a different file.

## License

MIT
