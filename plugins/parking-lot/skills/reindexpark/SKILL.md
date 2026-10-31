---
name: reindexpark
description: Renumber parked items 1..n (oldest first) to close ID gaps.
disable-model-invocation: true
---

1. Run `bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" reindex`. Do not read or edit `~/.claude/parked.md` yourself.
   The script renumbers entries 1..n by current ID, keeps dates and notes, and sets `next-id` to n+1.
2. Reply with exactly the script's output (`#3→#1, #7→#2`, `already contiguous`, or `nothing parked`). No other commentary.
