---
name: quiz
description: Write a short report on a change, then quiz the user on how it works and why, one question at a time, graded honestly. Pass every question before you ship.
disable-model-invocation: true
argument-hint: "[scope] [n=5] [hard]"
---

Quiz me on: $ARGUMENTS (if empty, the work done in this session)

Conventions: read `${CLAUDE_SKILL_DIR}/../../conventions.md`. This skill relies on: one question at a time, and evidence over claims (the report describes what the change actually does, read from the diff).

The rule is: **ship only after a perfect score.** The quiz tests whether the user understands what they are about to put their name on, well enough to defend it to the person who will maintain it. It is not trivia.

Read `n=<number>` from the arguments for the number of questions (default 5). `hard` means more questions about failure modes and fewer about structure.

## 1. Report

Read the actual change first: the diff, the files, the output. Then write a report of 15 lines or fewer:

- **What changed:** the pieces, with `file:line` references.
- **How it works:** the path a request or input takes through the change.
- **Why this way:** the key decisions and the alternatives they beat.
- **Risky bits:** where it could break, and what isn't covered.

## 2. Write the questions (don't show them yet)

Aim the questions at understanding, not recall:

- **What happens if:** a specific input, failure, or concurrent call. ("What happens if the payment webhook arrives twice?")
- **Why this line:** a specific `file:line` the user should be able to justify. Pick some lines at random, not only the obvious ones.
- **Decisions:** why one choice was made over the alternative, and what it trades away.
- **Blast radius:** what else this change touches or could break.
- **Gaps:** what the tests don't prove.

Cover the riskiest parts. If you know the user's knowledge gaps from this session, aim at them.

## 3. Ask

Ask **one question at a time** and wait for the answer. Never show answers, hints, or the next question early.

Grade each answer as **correct**, **partly**, or **wrong**, with a short explanation that points to the code. Be strict. Do not round "partly" up to be nice, and do not accept an answer that merely sounds plausible. If the user says "don't know", mark it **wrong** and explain.

## 4. Score

```markdown
## Quiz: <short title> — <correct>/<total>

<one line per question: ✓ / ~ / ✗, the topic, and the key point for anything missed>

**Result:** pass — ready to ship | not yet — <what to understand first>
```

If the result is **not yet**, offer a retake on just the missed topics, with new questions rather than repeats.
