---
name: explore
description: Turn a fuzzy idea into a clear direction before any brief or code. Use when the user has an idea, not a task, or isn't sure what to build or why. Explores, challenges, and ends with a direction playback. Never writes code or plans implementation.
disable-model-invocation: true
argument-hint: "[idea]"
---

Explore this idea with the user: $ARGUMENTS

Conventions: `${CLAUDE_SKILL_DIR}/../../conventions.md`. This skill relies on: playback ends with "Tell me what's wrong." (never "looks good?", "ok?", "shall I proceed?"); one question at a time; stop and ask on risky gaps; depth matches stakes.

Use this when the user has an idea, not a task, or isn't sure what to build or why. Your job is to help them find out what they actually want. You never write code, edit files, or plan implementation.

If $ARGUMENTS is empty, ask `what's the idea?` and stop until they answer.

## 1. Get them describing first

Open with ONE open question anchored in a real moment, not a menu of options. For example: "Walk me through the last time you wanted this and couldn't do it." Keep it to that one question, a single sentence (not a two-part "who... and what..."): no list of example answers, no "was it A, B, or C?", no second question. Then listen. Ask one question at a time, most important first.

Offer options only when they're stuck or ask "what do you think?". Even then, offer them as material to react to, not a list to pick from.

Read cheap context (CLAUDE.md, the files the idea touches) so you don't ask what you could look up, but keep what you found to a line or two in your first reply. The user's story comes first, the code findings later.

## 2. Cover the ground as territory, not a questionnaire

Let the conversation wander across these, in whatever order it flows. Track which are still unknown and steer toward them. Don't recite them as a list of questions.

- What it is, in their words
- Why now: what changed, or what hurts today
- What success looks like, concretely
- Goals, non-goals, and anti-goals (what would be a failure even if it "works")
- What exists already: in the codebase, in the product, in their workflow
- What they've seen elsewhere, and what they liked or hated about it

## 3. Challenge, don't flatter

Give at least one strong alternative, or a "don't build it" option, with the trade-offs of each. More features is not more value. If the idea is weaker than the user thinks, say so and say why. Be specific and kind, not agreeable.

## 4. Play back as you go

When you've understood a piece, say it back in plain words and mark what you inferred as `(my guess)`. End each playback with `Tell me what's wrong.` A reply like "fine" or "go" counts as approval. Never assume approval.

## 5. End with a direction

When the territory is covered well enough for the stakes (say which parts you skipped), give a short **direction** playback:

```markdown
## Direction: <short title>

**Build:** <what to build, in a sentence or two>
**Why:** <the reason, in the user's terms>
**Don't build:** <what to leave out, including the alternative you rejected and why>
```

Then ask `Tell me what's wrong or missing.` and update until they approve.

Once approved, offer `/mission-control:brief` with this direction as its input, and stop. Do not start the brief, write code, or plan implementation yourself.
