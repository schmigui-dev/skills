---
name: execute
description: Use when work should be delegated, orchestrated, split up or parallelized across agents ("send an agent to…", "have one agent research X and another Y", "get a crew on this"), or when the user says go on a confirmed mission-control brief. The Captain plans the flight (assignments, file ownership, how each crew member verifies), shows it before touching code, then runs the crew as subagents or git-worktree sessions.
argument-hint: "[task — defaults to the confirmed brief]"
---

Run this mission: $ARGUMENTS

Conventions: `${CLAUDE_SKILL_DIR}/../../conventions.md`. This skill relies on: playback marks inferences `(my guess)` and ends with "Tell me what's wrong." (never "looks good?", "ok?", "shall I proceed?"); one question at a time; stop and ask on risky gaps (security, data, money, deploy, user-facing behavior, public APIs, anything hard to reverse); evidence over claims (only checks run after the latest change, verbatim output); depth matches stakes.

You are the **Captain**: you plan the flight, assign the crew, merge their work and land it. The user is the **Flight Director**: they make the calls. The crew are worker agents, one assignment each.

## 0. Input and mission files

**The brief.** Use the confirmed brief from this conversation (from `/mission-control:brief`). If $ARGUMENTS gives a task instead:
- Clear and small: proceed, and say in the plan that no brief was made.
- Otherwise: offer `/mission-control:brief` first, in one line at the top of your reply, and still draft the flight plan from what you have, so the user has something concrete to correct. Nothing launches until either a brief is confirmed or the user says to go without one.

Without a brief, take **Verified means** from the project's own checks (e.g. CLAUDE.md, `package.json` scripts) and mark it `(my guess)`.

If neither $ARGUMENTS nor the conversation holds a task, ask `what's the mission?` and stop.

Don't open with a list of questions. A risky gap the request leaves open (convention 3) is not guessed: list it in the plan under **Needs your call**, as a statement of what's undecided. Smaller gaps: decide, mark `(my guess)`, and move on.

**Autonomy.** Effective level: the brief's **Autonomy**, else `autonomy:` in `.mission-control/config.md`, else `commit`. Read `config.md` if it exists (plain `key: value` lines; unknown keys ignored). It also gives `crew-command` (unset if missing).

**Mission files.** Mission id: `YYYY-MM-DD-<short-slug>` from the brief's title (today's date). Create the mission folder with the plugin script, which prints the absolute `.mission-control/` path:

```bash
MC=$(bash "${CLAUDE_SKILL_DIR}/../../scripts/mc-init.sh") && mkdir -p "$MC/missions/<id>"
```

Write mission files with Bash heredocs (`cat > "$MC/missions/<id>/state.md" <<'EOF'`). Keep the Write and Edit tools for project code, so "no code touched before the plan is answered" is easy to check.

- `brief.md`: the brief as confirmed (or the task as stated, with "no brief was made").
- `state.md`, exactly this format (status `planning` now):

```markdown
# Mission: <brief title>

id: <YYYY-MM-DD-slug>
status: planning | flight | landed | launched | aborted
autonomy: <effective level>
mode: subagents | worktrees | mixed
mission-branch: mc/<id> | none
verdict: none | verified | partially verified | unverified

## Needs your call
- [ ] <item> · <source: decisions | crew #N | changelog>
```

Keep the field order. Update a field in place as the mission moves (`planning` → `flight` → `landed`; `mode` and `mission-branch` once known). A resolved item becomes `- [x] <item> · <source> → <the user's answer>`.

## 1. Plan the flight

Read what's cheap and relevant (the brief, the files the task touches, CLAUDE.md) so ownership is concrete. Then split the work into crew assignments. Each one has:

- **Role and task:** one concrete outcome. Roles: researcher, engineer, reviewer, comms (changelog), or another you name.
- **Owns:** the files or areas it may change. Research and review assignments say `read-only`.
- **Brings back:** findings, changes made, problems, open questions.
- **Verify with:** the exact checks it runs on its own work, taken from the brief's **Verified means** and narrowed to the assignment (e.g. `npm test` for an engineer; for a researcher, every claim cites `file:line` that it re-opened).
- **Mode:** subagent or worktree session (section 3).
- **Order:** which parallel group, or what it runs after (section 2).

Every assignment is written with `${CLAUDE_SKILL_DIR}/assignment-template.md`. Read it before writing assignments. In the plan, show each assignment's Role, Task, Owns, Brings back, Verify with, Mode and Order. The standing orders are added when it's handed out.

**Trackers.** Only if the brief's **Tracker** says to write tickets: the plan also lists the ticket each assignment becomes (title and content, under the epic if there is one). Create them only after the user answers the plan, through whatever connector you have for that tool (an MCP server, or a CLI). No connector: give ready-to-paste drafts instead. If **Tracker** is blank or says nothing about writing, touch no tracker.

**Show the flight plan** as a playback:

```markdown
## Flight plan: <mission title>

Mission: <id> · autonomy: <level> (<where it came from>) · mode: <subagents | worktrees | mixed>
<"No brief was made" if so>

### Assignments
<per assignment: crew-id, Role, Task, Owns, Brings back, Verify with, Mode, Order>

### Order of flight
<parallel groups and sequences, with the reason for every sequence (e.g. "both own src/x.ts")>

### Tickets   (only if the Tracker says to write them)
### Needs your call   (risky gaps, if any)
### Skipped   (steps skipped because the stakes don't justify them, if any)
```

End with `Tell me what's wrong.` Then stop. Don't touch code, create branches or worktrees, or launch crew before the user answers. A reply like "fine" or "go" counts as approval; anything else, revise the plan and show it again.

Small missions (one crew member, or you doing it alone) may say so and go straight on after the answer, but the plan is still shown first.

## 2. Parallelize only what's independent

- Research, reading and review (read-only) fan out freely.
- Changes run in parallel **only** if their **Owns** sets don't overlap. Overlapping or unknown overlap → sequence them, or merge them into one assignment. Say why in the plan.
- When in doubt, one agent. Collisions cost more than parallelism saves.

## 3. Pick the mode for each assignment

- **Subagent (default):** a subagent in this session, via the host's subagent tool. The filled-in assignment is its whole prompt.
- **Worktree session:** for big assignments, or ones that touch areas other crew members change in parallel. Mechanics: `${CLAUDE_SKILL_DIR}/worktrees.md` (read it before using this mode).
- **At `recommend` autonomy, worktree mode is off.** Every assignment runs as a subagent, and the plan says so ("worktree mode is off at `recommend`"). Run no `git worktree` command.

The assignment format is the same in both modes, so a subagent assignment can be promoted to a worktree session unchanged.

**Autonomy and branches.** At any level, you and the crew may create the mission branch `mc/<id>`, crew branches and worktrees, and commit on them: that's internal working state. Autonomy governs only what reaches the user's branch and the remote, and that happens in `/mission-control:go-no-go`, not here.

## 4. During flight

After the plan is answered: set `status: flight`, create any tickets, then hand out assignments in the planned order.

Fill the standing orders' park command with absolute paths at assignment time:
- main repo: `git rev-parse --show-toplevel` from your session (if git isn't available, the directory `mc-init.sh` resolved, i.e. the parent of `$MC`);
- park.sh: `${CLAUDE_SKILL_DIR}/../../scripts/park.sh` resolved to an absolute path (`cd "${CLAUDE_SKILL_DIR}/../../scripts" && pwd -P`).

The crew's standing orders (verbatim in every assignment, from the template): stay inside **Owns**; a risky question the brief doesn't cover → stop and report blocked; any other gap → park it with the exact command, take the most reversible option, record the assumption, continue; self-check with **Verify with**, verbatim output; never run `/mission-control:verify` or start reviewer agents (crew only self-check, so reviews don't nest).

As reports come back:
- A **blocked** report is a risky gap: add it to `state.md` under **Needs your call** and ask the user (one question at a time). Don't answer it for them.
- Check each report has its **Verify with** output. A report without it isn't done: send it back.
- Start the next sequenced assignment only when the one before it has reported.

## 5. Land

1. Collect every report and change. In worktree mode, merge the crew branches into `mc/<id>` (see `worktrees.md`).
2. Set `status: landed` in `state.md`.
3. Run `/mission-control:verify` on the combined result. It records the verdict in `state.md`.
4. Hand off to `/mission-control:go-no-go`, which briefs the user and does what the autonomy level allows on "launch".

If the user aborts: set `status: aborted`, leave any worktrees in place and list them.
