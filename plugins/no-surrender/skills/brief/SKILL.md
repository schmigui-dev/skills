---
name: brief
description: Before a non-trivial task, build a short brief with the user that states what they care about, their hypothesis, scope, and what "done" and "verified" mean, so the agent never fills gaps by guessing.
disable-model-invocation: true
argument-hint: "\"what you want done\""
---

Build a brief for: $ARGUMENTS

The brief is the contract for this task. Its job is to capture what the user cares about, in their words, so you never have to invent it. A vague request answered with confident output is how intent gets lost.

## 1. Draft from what you already know

If $ARGUMENTS is empty, ask `what do you want done?` and stop until they answer.

Read whatever context is cheap and relevant (the conversation, the files the task touches, CLAUDE.md) so you don't ask what you could look up. Then draft every field below that you can fill honestly. Mark anything you inferred as `(my guess)`. Leave the rest blank.

## 2. Ask only for the gaps

Ask for the missing or guessed fields **one question at a time**, most important first. Always ask for these yourself. Never fill them in for the user:

- **Hypothesis:** "Before I look, what do you think the answer or approach is?" A bad guess is fine. Ask this before you show any solution, because once they read a polished answer it's hard to picture any other.
- **What you care about:** what matters most, and what would make them wince if you got it wrong.

Stop asking once the brief is good enough to act on. Five questions is usually plenty. If the user says "just guess", fill the field, mark it `(my guess)`, and move on.

## 3. Show the brief

```markdown
## Brief: <short title>

**Goal / why:** <the outcome and why it matters now>
**What I care about:** <ranked priorities; what would make me wince if you got it wrong>
**My hypothesis:** <the user's guess at the answer or approach>
**Who it's for:** <users, readers, or maintainers affected>
**Constraints:** <stack, conventions, deadlines, things that must not change>
**Out of scope:** <what not to touch or build>
**Done means:** <concrete, observable end state>
**Verified means:** <the exact checks that will prove it: commands, tests, screenshots, logs. Defined now, before the work, so the outcome can't be rationalized afterward>
**Open questions:** <anything still unknown; suggest `/blindspots` if this list is thin or empty on a risky task>
```

Then ask: `anything wrong or missing?` Update the brief until they confirm.

## 4. Follow the brief while you work

Once confirmed, keep to it for the rest of the task:

- If you hit a choice the brief doesn't cover **and** it touches something costly to get wrong (security, data, money, deploy, user-facing behavior, public APIs, anything hard to reverse), **stop and ask**. Never invent an answer for these.
- For smaller choices, decide, keep going, and remember them for `/decisions`.
- If the work starts to contradict the brief (scope creep, a different approach, an assumption turning out false), say so before continuing.
- When finished, check against **Done means** and **Verified means**, and suggest `/evidence`.

Don't save the brief to a file unless the user asks.
