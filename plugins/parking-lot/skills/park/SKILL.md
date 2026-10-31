---
name: park
description: Park an idea, question, or thought to revisit later without derailing current work.
disable-model-invocation: true
argument-hint: "\"the idea/question/thought\""
---

Park this note: $ARGUMENTS

This must cost the user nothing. Do NOT answer, discuss, or comment on the note. Do NOT interrupt or change the current task.

If $ARGUMENTS is empty, reply `nothing to park — usage: /park "note"` and stop.

Otherwise run this one command, with the note verbatim between the heredoc markers. Do not read `~/.claude/parked.md` first. The script assigns the ID under a lock and appends the line.

```bash
bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" add <<'PARKED_NOTE'
<note verbatim>
PARKED_NOTE
```

Reply with exactly the script's output (`parked #N`), then resume whatever you were doing before (if mid-task, continue it). If the script fails, reply with its error and resume.
