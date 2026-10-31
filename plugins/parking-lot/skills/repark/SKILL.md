---
name: repark
description: Edit a parked item in place (replace, append, insert, tweak), keeping its ID and date.
disable-model-invocation: true
argument-hint: "<id> \"new text\" | <id> <edit instruction>"
---

Edit parked item: $ARGUMENTS

1. Parse the ID (accept `3` or `#3`) and everything after it. If either is missing, reply `usage: /repark <id> "new text"` or `/repark <id> add "x" at the end` and stop.
2. Read `~/.claude/parked.md`. Find the line for `#N`. If missing, reply `#N not found` and stop.
3. Work out the new note:
   - Only quoted text, no instruction → replace the whole note with it.
   - Anything else is an edit instruction applied to the existing note, e.g. `add "slack, etc" at the end`, `prepend "urgent:"`, `replace "AWS" with "GCP"`, `remove "cool"`, `insert "and Slack" after "cowork"`. Keep the rest of the note verbatim. Quoted text goes in verbatim. Appended text is joined with a sensible separator (a space, or `, ` when continuing a list).
   - If the instruction is truly ambiguous, show the proposed note and ask `ok? (y/n)` before writing.
4. Write `- #N · <original date> · <new note, collapsed to one line>`. Leave `next-id` and all other lines untouched.
5. Reply `updated #N: <new note>` (truncated to ~100 chars). No other commentary.
