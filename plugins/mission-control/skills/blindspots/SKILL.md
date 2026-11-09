---
name: blindspots
description: Surface the unknown unknowns of a task or plan (security, deployment, data, failure modes, and more) as concrete questions for the user, plus the strongest counterargument, before the agent has to guess.
disable-model-invocation: true
argument-hint: "[task, plan, or file — defaults to the current task]"
---

Find the blind spots in: $ARGUMENTS

Conventions: read `${CLAUDE_SKILL_DIR}/../../conventions.md`. This skill relies on: one question at a time, stop on risky gaps, and close with a critique question ("Tell me what's wrong."), never "looks good?".

If $ARGUMENTS is empty, use the current task and its brief (`/mission-control:brief`), if there is one. If there is no current task either, ask `blind spots in what?` and stop.

The goal is to turn the user's unknown unknowns into known questions **before** work starts. Every gap you don't raise now is one the agent will later fill by guessing. You are not here to solve anything, only to make the user see what they haven't considered.

## 1. Ground yourself

Read the relevant code, config, and docs first: deploy setup, CI, environment and config files, auth, data models, and the integrations the task touches. A blind spot has to be specific to **this** project, not generic advice.

## 2. Sweep these lenses

Check each lens and keep only those that genuinely apply:

- **Security:** authentication and permissions, secrets, input validation, injection, personal data, the trust boundaries the change crosses.
- **Data:** schema changes, migrations and backfills, data loss, consistency, retention, what happens to existing records.
- **Deploy and ops:** environments, config and environment variables, rollout order, feature flags, rollback, monitoring and alerting, who gets paged.
- **Failure modes:** timeouts, retries, partial failure, concurrency and races, idempotency, what the user sees when it breaks.
- **Scale and cost:** load, rate limits, query cost, third-party quotas, the bill.
- **Users:** changes to existing behavior, edge cases, empty states, accessibility, localization, backward compatibility.
- **Integrations:** upstream and downstream systems, API contracts, versioning, other teams affected.
- **Compliance:** licenses, privacy and regulatory exposure, audit needs.
- **Maintenance:** who owns it after, how it's tested, docs, how hard it is to understand later.
- **Reversibility:** what's hard or impossible to undo.

Also ask yourself what lens this list is missing for this particular task.

## 3. Report

Rank by how costly it would be to get wrong. Report at most 7, plus a count of what you dropped:

```markdown
## Blind spots: <short title>

1. **<lens>: <the risk in one line>**
   Why here: <the concrete reason it applies, with file:line or config references>
   Question for you: <one question only the user can answer>

...

**Strongest counterargument:** <the best case that the plan or approach itself is wrong, argued properly, not as a straw man>

**Dropped as unlikely here:** <lenses checked and judged irrelevant, comma-separated>
```

## 4. Close the loop

End the report with: `Tell me what's wrong or missing in this list, and which of these you want to decide now.` Take the answers one at a time. Add each answer to the brief, under **What I care about**, **Constraints**, or **Out of scope**. If the user waves one off ("don't care"), record that explicitly in the brief so nobody revisits it silently later.

Never answer the questions yourself, and never hand back a list of assumptions instead of questions.
