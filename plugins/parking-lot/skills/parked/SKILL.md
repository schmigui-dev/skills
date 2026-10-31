---
name: parked
description: List parked ideas/questions and pick one to discuss.
disable-model-invocation: true
argument-hint: "[oldest]"
---

Arguments: $ARGUMENTS

1. Read `~/.claude/parked.md`. If missing or no entries, reply `nothing parked` and stop.
2. Show every entry, one per line: `#N  YYYY-MM-DD  note`.
   - Default order: newest first (highest ID on top).
   - If arguments contain `oldest`: oldest first.
   Truncate long notes to ~100 chars in the list. No commentary.
3. End with: `pick a # to discuss`.

When the user picks a number:
- Show the full note, then discuss/analyze it with them as a normal conversation.
- When the discussion seems resolved (question answered, decision made, or user moves on), ask: `remove #N from parked? (y/n)`.
- On yes: run `bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" remove N` and reply with its output (`removed #N`). Do not edit the file yourself.
