---
name: verify
description: Use whenever a plan, brief, assignment or message says how work must be checked ("make sure…", "confirm that…", "check it works in the browser", "test that…", "prove it", "don't ship until…"), or when asked to verify work. Runs layered verification (a fresh reviewer, then the final checks) and reports evidence with real output. Not for crew members working on a mission-control assignment: they only self-check.
argument-hint: "[what to verify / how]"
when_to_use: Invoke it as soon as the request says how the result must be checked, even when that is only part of a larger request ("do X and make sure Y"): do the work, then run this skill before reporting.
---

Verify: $ARGUMENTS (if empty: the combined result of the mission this session ran, else the work done in this session)

Conventions: `${CLAUDE_SKILL_DIR}/../../conventions.md`. This skill relies on: evidence over claims (only checks run in this session after the latest change, with verbatim output); a proposed plan is a playback that marks inferences `(my guess)` and ends with "Tell me what's wrong." (never "looks good?", "ok?", "shall I proceed?"); stop and ask on risky gaps (security, data, money, deploy, user-facing behavior, public APIs, anything hard to reverse); depth matches stakes, and skipped steps are named.

`verify` is the process. Its output uses the `evidence` report format (`${CLAUDE_SKILL_DIR}/../evidence/SKILL.md`).

## 0. Is this a verification request?

Decide this first, in a moment, before doing anything else.

- **Crew member on a mission-control assignment** (your prompt is an assignment with **Standing orders**): don't run this skill. Self-check with the assignment's **Verify with**, paste the output, and report. Don't start reviewers.
- **Not about checking work.** The message only asks to look at, explain, explore or discuss something, even if it uses words like "check" or "test" loosely. Step aside: answer the request as you normally would, with no Evidence section, no test runs and no reviewer. Say nothing about this skill.
- **Work plus how to check it** ("do X and make sure Y", "fix X, then prove it"): do the work first, as you normally would. Then verify it below, with the user's own words about checking as the definition of verified.
- **Only verification** (`/mission-control:verify …`, "confirm that…", "is this actually working?"): verify what exists now.

## 1. Define "verified"

Take the definition from, in order:
1. The user's words in this message or $ARGUMENTS (every check the words name is a check you run and show; "run the tests and show me the output for an empty list" is two checks, not one).
2. The brief's **Verified means** (in a mission: `<mc>/missions/<id>/brief.md`, step 2).
3. The project's own checks (CLAUDE.md, `package.json` scripts, Makefile), marked `(my guess)`.

Quote the definition at the top of the evidence. If the words leave a property implicit (e.g. what "works" or "right" means for this change), say how you read it, marked `(my guess)`.

**When nothing says how,** or the claim to verify isn't covered by any existing check: propose a **verify plan** as a playback before running anything. List each check, what it would prove, and anything it needs (a new test, a running server, a browser). End with `Tell me what's wrong.` and stop. Skip the playback only when the checks are obvious and read-only (the existing tests, lint, typecheck, build): run those and report, and still name the gap they leave in **Not checked**. Never write new tests or change code to verify a claim before the plan is answered.

**Never run unsafe checks** (deploys, writes to shared or external systems, payments, anything costly or hard to reverse). List them as **not run**, with why. A check you can't run here (no runtime, no browser, no network) is also **not run**, with the exact error or reason. That's an honest result, not a failure to hide.

## 2. Find the scope

**A mission, only when it's clearly the one.** Verify a mission's result only if:
- you're running as `/mission-control:execute`'s landing step for that mission;
- $ARGUMENTS or the conversation names the mission (by id or title); or
- this session ran that mission with `/mission-control:execute`.

Otherwise this is verification outside a mission, even when `.mission-control/` holds a mission that isn't launched: verify this session's work, and don't read or write any `state.md`. (If this session changed nothing and there is such a mission, ask whether to verify it, one question, and stop.)

To read a mission, get `<mc>`, the absolute `.mission-control/` path in the main repo (also from inside a worktree), from `bash "${CLAUDE_SKILL_DIR}/../../scripts/mc-init.sh" --find` (it creates nothing; if that folder doesn't exist, there's no mission); `<root>`, the main repo, is its parent directory. Never use `git rev-parse --show-toplevel` for this: inside a worktree it gives the worktree. The mission is `<mc>/missions/<id>/`. Read its `state.md` for `mode:`, `mission-branch:`, `base:` and `## Pre-existing changes`. Copy the hashes and paths once and use them literally.
- **Worktree or mixed mode:** the combined result lives in the mission worktree `<wt>` = `"<parent of root>/<repo>-mc-<mission-id>"`, on `mc/<mission-id>` (in mixed mode, subagent work is committed there too). Run every check there, never in the user's checkout, and never with a bare `cd "<wt>"` (your session would stay there): `git -C "<wt>" …` for git, and a subshell `(cd "<wt>" && <check>)` for anything else. The diff is `git -C "<wt>" diff <base>` (committed and uncommitted mission work), plus the new files `git -C "<wt>" status --porcelain` lists, read whole. With `base: none` (an older state file), use `git -C "<root>" merge-base HEAD "mc/<mission-id>"` as the base.
- **Subagent mode:** the work is in the user's tree. The diff is `git -C "<root>" diff <base>`, plus the new files `git -C "<root>" status --porcelain` lists. Files under `## Pre-existing changes` are the user's, not the mission's: leave them out, and name them in the evidence.

Outside a mission: the diff is this session's change (`git diff`, plus `git diff --cached`; without git, the changed files whole).

## 3. Scale the layers

| Situation | Layers |
|---|---|
| A mission (crew did the work) | 1, 2, 3 |
| Outside a mission: a single agent, a single change | 2, 3 |
| A trivial change: a few lines, one obvious effect, nothing in a risky area | 3 only, and say "reviewer skipped: trivial change (<why>)" |

A change touching money, data, security, auth, public APIs or user-facing behavior is never trivial. Name every skipped layer and why in the evidence.

## 4. Layer 1: crew self-check (missions only)

Collect each crew member's report: worktree mode, `<mc>/missions/<id>/reports/<crew-id>.md`; subagent mode, what the subagents returned in this session. For each **Verify with** claim, keep it only if the report pastes the output. A claim without pasted output ("tests pass", "verified manually") goes under **Not checked**, naming the crew member. Self-check results ran before the merge, so they never replace layer 3.

## 5. Layer 2: the reviewer

Start one fresh reviewer: a subagent that wrote none of the work, through whatever subagent mechanism the host has. It is read-only and changes nothing.

Give it only:
- **the brief**: the confirmed brief, or outside a mission, the user's request verbatim plus the definition of verified from step 1;
- **the diff** from step 2 (paste it, or name the exact command and directory to get it);
- this task: "Find bugs, missed requirements, and contradictions with the brief (including anything it rules out of scope). For each finding give file:line, what's wrong, and how you know. Re-open every line you cite. Say 'no findings' if there are none. Don't edit anything."

Don't give it the builders' reasoning: no crew reports, no plan rationale, no summary of why the code is right, no conversation history. It judges the change cold.

**Wait for its result before reporting.** If the host runs subagents in the background, wait for the completion notice; don't end your turn or write the report while the reviewer is still running. You may run read-only checks meanwhile, but the report comes once, complete, after the reviewer has answered and any fixes have been re-checked. A report that says "reviewer still running" is not done.

Every finding is either **fixed** or **reported**, never dropped:
- A clear bug inside the work's scope and not in a risky area: fix it, and the final checks below run after the fix. In a worktree or mixed-mode mission, make the fix in the mission worktree (absolute paths under `<wt>`), never in the user's checkout, and commit it on `mc/<mission-id>` (`git -C "<wt>" add <files>`, then `git -C "<wt>" commit`) before layer 3.
- Anything else (risky, ambiguous, out of scope, you disagree): report it under **Decisions**, with the reviewer's words and your view. A risky one goes under **Needs your call**.

If the host has no subagent mechanism, say "reviewer skipped: no subagent available here". Don't present your own re-read as an independent review.

## 6. Layer 3: the final checks

Run the definition of verified from step 1 on the combined result, after the last change (including reviewer fixes): in a worktree or mixed-mode mission, in the mission worktree. Setup or installs the checks need there (e.g. `npm install`) are fine: the mission worktree is internal working state. Every check the definition names gets a line in the evidence: run with verbatim output, or **not run** with the reason. Be suspicious of tests written alongside the change: they can share its wrong assumption. Say so where it applies.

## 7. Report

Use the `evidence` format, then a Decisions section. Both headings are required as written (`## Evidence…` and `## Decisions`).

~~~markdown
## Evidence: <short title>

**"Verified" was defined as:** <the definition and where it came from>
**Layers:** crew self-check <N reports, M claims without output | not a mission> · reviewer <ran: N findings | skipped: reason> · final checks <ran here: path>

### Checks
1. `<exact command or action>`
   ```
   <verbatim relevant output, trimmed with ...>
   ```
   Proves: <the specific property>
   Doesn't prove: <what it leaves untested>

### Reviewer findings
- <finding> → fixed (<how>) | reported under Decisions
<or: no findings | skipped: reason>

### Not checked
- <path, case, environment or crew claim with no evidence, and why>

### Verdict
<verified | partially verified | unverified> against the definition above, in one line.

**Summary:** <one line on what was done>

## Decisions
- <choices made while doing or verifying the work, e.g. how "right" was read, a reviewer finding not fixed and why>
<or: none>

### Needs your call
- <risky open items, one per line>
<or: none>
~~~

The report is one message, written after every layer has finished. If something new arrives after you've reported (a late reviewer result, a fix), send the whole report again, updated, not just the change.

Never upgrade the verdict because the work looks right. If it isn't **verified**, name the single most valuable next check.

**Record the verdict** only when verifying a mission (step 2): set `verdict:` in its `state.md` in place (`verified`, `partially verified` or `unverified`), keeping every other line. Read the items already under `## Needs your call` first, then add each of your **Needs your call** items there as `- [ ] <item> · plan`, unless an item (open or resolved) already says the same thing. Write the file with Bash (e.g. a heredoc of the whole updated file).

End with `Tell me what's wrong or missing in this evidence.`
