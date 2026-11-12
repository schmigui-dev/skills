---
name: repark
description: Edit a parked item in place (replace, append, insert, tweak), keeping its ID and date.
disable-model-invocation: true
allowed-tools: Bash(printenv PARKED_BACKEND), Bash(echo local)
argument-hint: "<id> \"new text\" | <id> <edit instruction>"
---

Edit parked item: $ARGUMENTS

Backend: !`printenv PARKED_BACKEND || echo local`

If the backend is `corteza`, follow `${CLAUDE_SKILL_DIR}/../../references/mcp-backend.md`.

1. Parse the ID (accept `3` or `#3`) and everything after it. If either is missing, reply `usage: /repark <id> "new text"` or `/repark <id> add "x" at the end` and stop.
2. Work out the new note:
   - Only quoted text, no instruction → the new note is that text. Skip to step 3.
   - Anything else is an edit instruction applied to the existing note. Get it (`local`: `bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" get <id>`, which prints the note or `#N not found`; `corteza`: `get_idea` with `number`, which returns the note or an error). If it's not found, reply with that and stop. Apply the instruction, e.g. `add "slack, etc" at the end`, `prepend "urgent:"`, `replace "AWS" with "GCP"`, `remove "cool"`, `insert "and Slack" after "cowork"`. Keep the rest of the note verbatim. Quoted text goes in verbatim. Appended text is joined with a sensible separator (a space, or `, ` when continuing a list).
   - If the instruction is truly ambiguous, show the proposed note and ask `ok? (y/n)` before writing.
3. Write it.
   - `local`: with the new note verbatim between the heredoc markers. Do not edit `~/.claude/parked.md` yourself.

     ```bash
     bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" replace <id> <<'PARKED_NOTE'
     <new note>
     PARKED_NOTE
     ```

   - `corteza`: call `update_idea` with `number` and `text` = the new note verbatim.

4. Reply `updated #N: <note>` (or the not-found error), truncated to ~100 chars. No other commentary.
