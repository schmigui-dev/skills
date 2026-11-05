---
name: brief
description: Before a non-trivial task, build a short brief with the user that states what they care about, their hypothesis, scope, and what "done" and "verified" mean, so the agent never fills gaps by guessing. Accepts an idea, an explore direction, or a ticket link or path.
disable-model-invocation: true
argument-hint: "\"what you want done\" | <ticket link or path>"
---

Build a brief for: $ARGUMENTS

Conventions: `${CLAUDE_SKILL_DIR}/../../conventions.md`. This skill relies on: playback marks inferences `(my guess)` and ends with "Tell me what's wrong." (never "looks good?", "ok?", "shall I proceed?"); one question at a time; stop and ask on risky gaps (security, data, money, deploy, user-facing behavior, public APIs, anything hard to reverse).

The brief is the contract for this task. Its job is to capture what the user cares about, in their words, so you never have to invent it. A vague request answered with confident output is how intent gets lost.

## 1. Draft from what you already know

If $ARGUMENTS is empty and the conversation holds no `/mission-control:explore` direction, ask `what do you want done?` and stop until they answer.

Work out what kind of input you got:

- **An explore direction** (from the conversation, or pasted): use it as the starting point. Its Build / Why / Don't build map to Goal / why and Out of scope.
- **A ticket link or id**: read it through whatever connector you have for that tool (an MCP server, or a CLI such as `gh`). Draft the brief from it: acceptance criteria go into **Done means** and **Verified means**, the description into **Goal / why**, and unanswered comments or questions into **Open questions**.
- **A local file path**: read the file directly and treat it as the ticket.
- **A ticket you can't reach** (no connector, or it fails): ask the user to paste the ticket text, then continue.
- **Plain words**: the task as the user stated it.

Read whatever other context is cheap and relevant (the conversation, the files the task touches, CLAUDE.md) so you don't ask what you could look up. Then draft every field below that you can fill honestly. Mark anything you inferred as `(my guess)`. Leave the rest blank.

## 2. Ask only for the gaps

Ask for the missing or guessed fields **one question at a time**, most important first. Always ask for these yourself. Never fill them in for the user:

- **Hypothesis:** "Before I look, what do you think the answer or approach is?" A bad guess is fine. Ask this before you show any solution, because once they read a polished answer it's hard to picture any other.
- **What you care about:** what matters most, and what would make them wince if you got it wrong.

**When the input is rich (a ticket, a file, an explore direction):** don't open with questions alone. Show the draft brief first (section 3 format), with the fields you couldn't honestly fill left blank, and with each ticket gap (unanswered comments, unclear criteria, such as who is covered) listed under **Open questions** as short statements of what is unknown (no question marks, nothing the user must answer yet). Then, below the draft, ask ONE question: the hypothesis question if the user hasn't given theirs, otherwise the most important remaining gap. Exactly one question mark in the whole reply: do not ask several questions in that turn, and don't add example answers.

Stop asking once the brief is good enough to act on. Five questions is usually plenty. If the user says "just guess", fill the field, mark it `(my guess)`, and move on. A user's own hypothesis and priorities, if they already gave them, go in verbatim and are not re-asked.

**Autonomy** and **Tracker** are optional. Leave them blank unless the user mentioned them or the task obviously needs them. Don't ask about them by default. Fill them only with what the user said, never guess.

## 3. Show the brief

```markdown
## Brief: <short title>

**Goal / why:** <the outcome and why it matters now>
**What I care about:** <ranked priorities; what would make me wince if you got it wrong>
**My hypothesis:** <the user's guess at the answer or approach>
**Who it's for:** <users, readers, or maintainers affected>
**Constraints:** <stack, conventions, deadlines, things that must not change>
**Autonomy:** <recommend|commit|push|merge|deploy — blank = config/default>
**Tracker:** <what to read/write where, in the user's words — blank = no tracker>
**Out of scope:** <what not to touch or build>
**Done means:** <concrete, observable end state>
**Verified means:** <the exact checks that will prove it: commands, tests, screenshots, logs. Defined now, before the work, so the outcome can't be rationalized afterward. Mandatory for non-trivial work>
**Open questions:** <anything still unknown; suggest `/mission-control:blindspots` if this list is thin or empty on a risky task>
```

- **Autonomy** is a per-mission override of how far the Captain may go with the user's branch and the remote. Precedence: this field, then `config.md`, then the default (`commit`). Blank means use config or default.
- **Tracker** records, in the user's own words, what to read and write where (for example "read the epic from this link", "write tickets for each assignment", "update statuses and link the PR when done"). Blank means the mission touches no tracker. A write instruction here is the permission for that mission. Without one, nothing is written.

Always show **Autonomy** and **Tracker** as lines, even when empty: write `blank (config/default)` and `blank (no tracker)` so it's visible they were considered.

If a risky gap is left (money, data, public API, etc.) and the user said to guess the rest, don't guess it and don't end on a separate question: list it first under **Open questions**, marked as needing their call, and still close with the line below. They answer it in their correction.

Once nothing is left to ask, or when the user has told you to guess the rest, end the reply with `Tell me what's wrong or missing.` Update the brief until they approve. A reply like "fine" or "go" counts as approval. Never assume it.

## 4. Follow the brief while you work

Once approved, keep to it for the rest of the task:

- If you hit a choice the brief doesn't cover **and** it touches something costly to get wrong (security, data, money, deploy, user-facing behavior, public APIs, anything hard to reverse), **stop and ask**. Never invent an answer for these.
- For smaller choices, decide, keep going, and record them for `/mission-control:decisions`.
- If the answer belongs to the human but isn't risky enough to stop for, park it instead of guessing: `/mission-control:park "the question"`.
- If the work starts to contradict the brief (scope creep, a different approach, an assumption turning out false), say so before continuing.
- When finished, check against **Done means** and **Verified means**, and suggest `/mission-control:evidence`.

## 5. Offer to launch

After the brief is approved, offer `/mission-control:execute` to start the flight with this brief. If the task is small enough to do directly, say so and do it, still following section 4.

Don't save the brief to a file unless the user asks.
