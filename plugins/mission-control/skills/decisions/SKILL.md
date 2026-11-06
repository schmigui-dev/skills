---
name: decisions
description: List every decision and assumption the agent made that the user never specified (defaults, scope cuts, reinterpretations, invented values), plus the parked crew questions of the current mission, flagging the ones that need the user's call.
disable-model-invocation: true
argument-hint: "[scope — defaults to this session's work]"
---

List the decisions behind: $ARGUMENTS (if empty, all work done in this session, and the current mission if there is one)

Conventions: `${CLAUDE_SKILL_DIR}/../../conventions.md`. This skill relies on: one question at a time, most important first; risky choices (security, data, money, deploy, user-facing behavior, public APIs, anything hard to reverse) are never guessed and always need the user's call.

Over a long session you make many small choices for the user. A summary that says "everything went well" hides them. Your job is to expose every choice the user didn't explicitly make, especially the places where you or the crew filled a gap by guessing.

## 0. Find the current mission

Look for `.mission-control/missions/*/state.md` at the git toplevel (else the current directory). The current mission is the most recent one whose `status:` isn't `launched` or `aborted`. If more than one qualifies, ask which (one question, naming each by id and title) and stop. If there's none, skip the mission parts below.

In a mission, read its `state.md` (the open `- [ ]` items under `## Needs your call`) and `brief.md`, and list the crew's parked questions for it:

```bash
bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" list --mission <mission-id> --crew-only
```

It prints one line per question, `- #N · <date> · [crew:<crew-id> · mission:<id>] <question> — assumed: <assumption>`, or `nothing parked`. Each is a gap a crew member hit, decided by taking the most reversible option, and kept going on.

## 1. Collect

Go through the conversation, the diff (`git diff`, plus `git diff --staged` and new files when in a repo; in a worktree-mode mission, the mission branch against its base), and any files you produced. Collect everything in these categories:

- **Invented:** values, names, config, endpoints, limits, copy, or behavior you made up because nothing specified them. **These matter most.** Be honest about them.
- **Defaults:** timeouts, sizes, sort orders, error handling, permissions, and anything else you picked a value for.
- **Interpretations:** where the request was ambiguous, or two requirements clashed, and you chose a reading.
- **Scope:** what you left out, deferred, simplified, or stubbed.
- **Approach:** design choices where a reasonable alternative existed.
- **Dependencies:** libraries, services, or APIs you added or relied on.
- **Assumptions:** facts about the system, environment, or users that you took as true without checking.
- **Crew questions:** every parked crew question of the current mission. These always need the user's call: the crew guessed so the flight could go on.

Leave out choices the user stated explicitly, and anything already in the brief.

## 2. Report

Put **needs your call** first, then **FYI**. A decision needs the user's call if it is invented, is a crew question, touches security, data, money, deploy, or user-facing behavior, or is hard to reverse. Open `- [ ]` items already in `state.md` are listed there too, as they stand.

```markdown
## Decisions: <short title>

### Needs your call
1. **<the decision in one line>** · <category> · `file:line`
   Why I chose it: <reason, or "guess — nothing specified">
   Alternative: <the most plausible other option>
   Undo cost: <easy | moderate | hard>
2. **Crew #N: <the question>** · crew question · <crew-id>
   Assumed: <the crew's assumption, verbatim>
   Alternative: <the most plausible other answer>
   Undo cost: <easy | moderate | hard>

### FYI
- **<decision>** · <category> · `file:line` · <why, in a few words>
```

Report every decision you found, without trimming the list to look tidy. If a category is empty, leave it out.

**Record them in the mission.** If there is a current mission, add each new "needs your call" item to `state.md` under `## Needs your call`, one line each, keeping every other line: `- [ ] <item> · crew #N` for a crew question, `- [ ] <item> · decisions` for the rest. Don't duplicate an item already there. Write the whole updated file with Bash (a heredoc).

## 3. Close the loop

Ask: `Confirm or change the "needs your call" items: what's wrong?` Take the answers one at a time, most important first. Apply any changes the user asks for. As each item is answered:
- in `state.md`, mark it `- [x] <item> · <source> → <the user's answer>`;
- a crew question: also remove it from the parking lot, `bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" remove <N>`. If the answer differs from the crew's assumption, the work needs changing: say which files, and offer to change them (or, in a mission, to send it back through `/mission-control:execute`).

For confirmed decisions that reflect a lasting preference, offer to record them (in CLAUDE.md, a test, or the brief) so they aren't guessed again.
