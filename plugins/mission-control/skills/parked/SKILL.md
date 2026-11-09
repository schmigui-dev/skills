---
name: parked
description: List parked ideas and crew questions, and pick one to discuss.
disable-model-invocation: true
argument-hint: "[oldest] [crew] [mission <id>]"
---

Arguments: $ARGUMENTS

Conventions: `${CLAUDE_SKILL_DIR}/../../conventions.md`. This skill relies on: one question at a time, and the parking lot is only read and changed through `park.sh`.

1. Build the list command from the arguments, never reading the file directly:
   - `oldest` adds `--oldest`
   - `crew` adds `--crew-only` (crew questions only, hides the human's own notes)
   - `mission <id>` adds `--mission <id>`

   ```bash
   bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" list [--oldest] [--crew-only] [--mission <id>]
   ```

   If it prints `nothing parked`, reply `nothing parked` and stop.
2. Show every line the script prints, one per line, keeping its order (newest first by default) and its tags: `#N  YYYY-MM-DD  [crew:<id> · mission:<id>]  note — assumed: <text>`. Crew notes always keep their crew and mission tags and their assumption. Truncate long notes to ~100 chars, but never cut the tags or the assumption. No commentary.
3. End with: `pick a # to discuss`.

When the user picks a number:
- Show the full note (`park.sh get N`), then discuss/analyze it with them as a normal conversation. For a crew note, state the assumption the crew made and ask whether it holds, one question at a time.
- When the discussion seems resolved (question answered, decision made, or user moves on), ask: `remove #N from parked? (y/n)`.
- On yes: run `bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" remove N` and reply with its output (`removed #N`). Do not edit the parked file yourself.
- Removing a crew note closes the loop, as in `/mission-control:decisions`: in the note's mission (`<mc>/missions/<mission-id>/state.md`, with `<mc>` from `bash "${CLAUDE_SKILL_DIR}/../../scripts/mc-init.sh" --find`), mark its item `- [x] <question> · crew #N → <the answer>`, or add it that way if it isn't there, keeping every other line (rewrite the file with a Bash heredoc). If the answer differs from the crew's assumption, say so: the work has to change, so offer to send it back through `/mission-control:execute` (iterate).
