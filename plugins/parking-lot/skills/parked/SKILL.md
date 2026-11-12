---
name: parked
description: List parked ideas/questions and pick one to discuss.
disable-model-invocation: true
allowed-tools: Bash(printenv PARKED_BACKEND), Bash(echo local)
argument-hint: "[oldest]"
---

Arguments: $ARGUMENTS

Backend: !`printenv PARKED_BACKEND || echo local`

If the backend is `corteza`, read `${CLAUDE_SKILL_DIR}/../../references/mcp-backend.md` first. Then:

1. Get the notes.
   - `local`: read `~/.claude/parked.md`.
   - `corteza`: call `list_ideas` with `status: "open"`.
   If there are none, reply `nothing parked` and stop.
2. Show every entry, one per line: `#N  YYYY-MM-DD  note`.
   - Default order: newest first (highest ID on top).
   - If arguments contain `oldest`: oldest first.
   Truncate long notes to ~100 chars in the list. No commentary.
3. End with: `pick a # to discuss`.

When the user picks a number:
- Show the full note (`corteza`: from `get_idea`), then discuss/analyze it with them as a normal conversation.
- When the discussion seems resolved (question answered, decision made, or user moves on), ask: `remove #N from parked? (y/n)`.
- On yes:
  - `local`: run `bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" remove N` and reply with its output (`removed #N`). Do not edit the file yourself.
  - `corteza`: call `remove_idea` with `numbers: [N]` and reply with its output.
