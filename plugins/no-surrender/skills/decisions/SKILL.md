---
name: decisions
description: List every decision and assumption the agent made that the user never specified (defaults, scope cuts, reinterpretations, invented values), flagging the ones that need the user's call.
disable-model-invocation: true
argument-hint: "[scope — defaults to this session's work]"
---

List the decisions behind: $ARGUMENTS (if empty, all work done in this session)

Over a long session you make many small choices for the user. A summary that says "everything went well" hides them. Your job is to expose every choice the user didn't explicitly make, especially the places where you filled a gap by guessing.

## 1. Collect

Go through the conversation, the diff (`git diff`, plus `git diff --staged` and new files when in a repo), and any files you produced. Collect everything in these categories:

- **Invented:** values, names, config, endpoints, limits, copy, or behavior you made up because nothing specified them. **These matter most.** Be honest about them.
- **Defaults:** timeouts, sizes, sort orders, error handling, permissions, and anything else you picked a value for.
- **Interpretations:** where the request was ambiguous, or two requirements clashed, and you chose a reading.
- **Scope:** what you left out, deferred, simplified, or stubbed.
- **Approach:** design choices where a reasonable alternative existed.
- **Dependencies:** libraries, services, or APIs you added or relied on.
- **Assumptions:** facts about the system, environment, or users that you took as true without checking.

Leave out choices the user stated explicitly, and anything already in the brief.

## 2. Report

Put **needs your call** first, then **FYI**. A decision needs the user's call if it is invented, touches security, data, money, deploy, or user-facing behavior, or is hard to reverse.

```markdown
## Decisions: <short title>

### Needs your call
1. **<the decision in one line>** · <category> · `file:line`
   Why I chose it: <reason, or "guess — nothing specified">
   Alternative: <the most plausible other option>
   Undo cost: <easy | moderate | hard>

### FYI
- **<decision>** · <category> · `file:line` · <why, in a few words>
```

Report every decision you found, without trimming the list to look tidy. If a category is empty, leave it out.

## 3. Close the loop

Ask: `confirm or change the "needs your call" items?` Take the answers one at a time. Apply any changes the user asks for. For confirmed decisions that reflect a lasting preference, offer to record them (in CLAUDE.md, a test, or the brief) so they aren't guessed again.
