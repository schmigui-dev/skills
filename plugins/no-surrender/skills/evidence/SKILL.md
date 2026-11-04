---
name: evidence
description: Show the proof behind the agent's work: the exact checks run and their real output first, then what each check proved and did not prove, and only then a one-line summary.
disable-model-invocation: true
argument-hint: "[what to show evidence for — defaults to the latest work]"
---

Show the evidence for: $ARGUMENTS (if empty, the work just completed in this session)

The user reads the evidence **before** any summary. A green check proves one property, not everything. Your job is to make that visible, not to sound confident.

## Rules

- Only report checks you **actually ran in this session**, with their real output. Never report results from memory, from expectation, or from an earlier run before the latest change.
- If a key check wasn't run and it is safe and read-only (tests, lint, typecheck, build, a dry run), run it now. If it isn't safe (deploys, writes to shared or external systems, anything costly), list it as **not run** and say why.
- Quote output verbatim. Trim it to the lines that matter, and show where you trimmed with `...`. Never paraphrase a failure into something milder.
- Be suspicious of tests you wrote alongside the code. They can share the same wrong assumption and still pass. Say so where it applies.

## Output, in this order

~~~markdown
## Evidence: <short title>

**"Verified" was defined as:** <from the brief's "Verified means", or "not defined upfront — this is my after-the-fact choice">

### Checks
1. `<exact command or action>`
   ```
   <verbatim relevant output>
   ```
   Proves: <the specific property this establishes>
   Doesn't prove: <what it leaves untested: paths, inputs, environments, integrations>

...

### Not checked
- <path, case, or environment with no evidence at all, and why>

### Verdict
<verified | partially verified | unverified> against the definition above, in one line.

**Summary:** <one line on what was done>
~~~

If the verdict isn't **verified**, end with the single most valuable next check to close the gap. Never upgrade the verdict because the work "looks right".
