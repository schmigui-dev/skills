---
name: reindexpark
description: Renumber parked items 1..n (oldest first) to close ID gaps.
disable-model-invocation: true
---

1. Read `~/.claude/parked.md`. If missing or no entries, reply `nothing parked` and stop.
2. Sort entries by current ID ascending. Renumber them 1..n in that order, keeping each entry's date and note verbatim.
3. Set the `next-id` comment to n+1. Leave the header and everything else untouched.
4. If no ID changed, reply `already contiguous` and stop without writing.
5. Otherwise write the file and reply with only the changed IDs, comma-separated: `#3→#1, #7→#2, #11→#3`. No other commentary.
