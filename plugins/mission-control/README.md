# mission-control

Hand off the work, not the accountability, now with a crew.

As agents get better, their output looks finished and is usually right, and that's exactly what makes it easy to stop thinking. You read the last answer carefully, skim the next, and approve the one after that. Then someone asks about a line and you can't explain it. That's *cognitive surrender*: the agent's output quietly becomes yours without anyone checking it.

It gets worse once there's more than one agent. A crew of agents produces more work, faster, across more files, and every hand-off is one more place to stop paying attention. Two agents edit the same file. One guesses an answer that was yours to give. "Tests pass" turns up in a report with no output behind it.

mission-control runs agent work like a space mission. You're the Flight Director: you brief, make the calls, and give the go/no-go. The Captain plans the flight and runs the crew. Every hand-off is a point where you stay in charge, and the plugin makes that cheap. It replaces `no-surrender`: all five of its commands and its Stop guard are here, plus exploring, orchestrating, layered verification, parking and the launch decision.

v1 is software-first: git, tests, commits and worktrees are the worked examples. The steps are written in neutral words, so other kinds of work can be added later.

## Install

```text
/plugin marketplace add schmigui-dev/skills
/plugin install mission-control@schmigui
```

Commands are namespaced as `/mission-control:<command>`.

## Cast

| Role | Who | Does |
| --- | --- | --- |
| **Flight Director** | you | briefs, makes the calls, gives go/no-go, owns the outcome |
| **Captain** | the main agent session | plans the flight, assigns the crew, merges, runs the final verify, briefs you |
| **Crew** | worker agents | do one assignment each and check their own work. Roles: *researcher*, *engineer*, *reviewer*, *comms* (changelog), or others the Captain names |

## Phases and commands

**Pre-flight** (decide what and why) → **flight** (do it) → **landing** (prove it) → **go/no-go** (decide whether it ships). `park` and `parked` work in any phase.

| Phase | Command | Does |
| --- | --- | --- |
| Pre-flight | `/explore [idea]` | Turns a fuzzy idea into a direction: what to build, why, and what not to build. Gets you describing first, challenges you with at least one strong alternative (including "don't build it"), and never writes code. Ends by offering `brief`. |
| Pre-flight | `/brief "task" \| <ticket>` | Builds a short brief with you: what you care about, your hypothesis, scope, and what "done" and "verified" mean, plus optional **Autonomy** and **Tracker** fields. Takes an `explore` direction or a ticket link as input. While it works, the agent asks instead of guessing on anything risky the brief doesn't cover. |
| Pre-flight | `/blindspots [task]` | Sweeps security, data, deploy, failure modes, cost, users, integrations, and more for gaps specific to your project. Returns them as questions for you, plus the strongest counterargument. |
| Flight | `/execute [task]` *(also natural language)* | The Captain splits the work into crew assignments (who owns which files, what each brings back, how each checks its own work) and shows you the flight plan before touching any code. Runs edits in parallel only when they own different files, and the crew as subagents or as separate sessions in git worktrees. |
| Landing | `/verify [what / how]` *(also natural language)* | Layered verification: each crew member's self-check, then a fresh reviewer who wrote none of the work, then the Captain's final checks against the brief's **Verified means**. Reports evidence with real output. |
| Landing | `/evidence` | Shows the exact checks run and their real output first, then what each check proved and **didn't** prove, a verdict, and only then a one-line summary. |
| Go/no-go | `/decisions` | Lists every choice you never made: invented values, defaults, interpretations, scope cuts, assumptions, plus the questions the crew parked. Anything that needs your call comes first. |
| Go/no-go | `/quiz [scope] [n=5] [hard]` | Writes a short report on the change, then quizzes you one question at a time and grades strictly. Ship only on a perfect score. |
| Go/no-go | `/go-no-go [launch]` | The launch briefing: verdict, what needs your call, what changed, how it's split into commits, the version bump and changelog entry, a recommendation, and what the Captain will do on "launch" at the current autonomy level. |
| Any | `/park "note"` | Parks an idea or question without derailing the work. Replies `parked #N` and carries on. |
| Any | `/parked [oldest] [crew] [mission <id>]` | Lists what's parked, yours and the crew's, and picks one to discuss. |

Command names in the table are short for `/mission-control:<command>`.

`execute` and `verify` also run from plain language. "Send one agent to research the payment flow and another to look at the tests" starts `execute`. "Add the endpoint and make sure the tests pass and it returns 404 for unknown ids" does the work, then runs `verify` with your words as the definition of verified. A sentence that only uses "check" loosely ("check out this file and explain it") doesn't trigger it. Every other command runs only when you type it.

Every command that proposes something (a direction, a brief, a flight plan, a verify plan, a briefing) ends with **"Tell me what's wrong."**, never "looks good?". A critique question makes you judge. An approval question invites a rubber stamp.

**Mission state** lives in a project-local `.mission-control/` folder at the repo root, created only when a command first needs it:

```text
.mission-control/
  config.md         autonomy and crew-command (committed)
  parked.md         the parking lot (local)
  missions/<id>/    brief, state (status, verdict, open calls), crew assignments and reports (local)
```

Only `config.md` is committed. The rest is your working state. Edit `.mission-control/.gitignore` if you want it committed too. Mission state is always saved, so `go-no-go` works across sessions.

## Autonomy

How far the Captain may go after you say "launch". Inside the mission, at any level, the Captain and crew may create the mission branch, crew branches and worktrees and commit on them. That's internal working state. Autonomy controls only what reaches **your branch** and **the remote**.

| Level | Captain does after "launch" | Leaves to you |
| --- | --- | --- |
| `recommend` | nothing on your branch or the remote. Proposes commits. Worktree mode is off | everything |
| `commit` **(default)** | organizes local commits on your branch (merging the mission branch, if there is one) | push, PR, merge, deploy |
| `push` | + pushes the branch (`mc/<mission-id>` if yours is the default branch), opens a PR | merge, deploy |
| `merge` | + merges the PR | deploy |
| `deploy` | + releases with the project's documented deploy command, writes the changelog and version | nothing (you're still briefed after) |

Set it per project in `.mission-control/config.md`, or per mission in the brief's **Autonomy** field. The brief wins, then `config.md`, then the default `commit`.

```markdown
# mission-control config

autonomy: commit
crew-command: claude -p --add-dir /path/to/your/repo --allowedTools "Bash(npm test *),Bash(git add *),Bash(git commit *),Bash(PARKED_FILE=* bash *park.sh add *)" --permission-mode acceptEdits
```

(See [Crew sessions](#crew-sessions) for what that command allows and why.)

**Gates.** At every level from `commit` up, local commits included, the Captain acts only when:

- the verify verdict is **verified**,
- there are **no open "needs your call" items**, and
- there are **no open parked crew questions** for the mission.

If any gate fails, the Captain makes no commits and no merge, whatever the level. It stops and tells you what's blocking. At `recommend` nothing is executed anyway.

**Your default branch is never pushed below `deploy`.** At `push` and `merge`, if your branch is the repo's default branch, the Captain pushes the work as a feature branch `mc/<mission-id>` and opens the PR from it. Your local default branch keeps the commits until the PR is merged.

**Never inferred**, at any level: force-push, history rewrites, deleting remote branches, and a production deploy without a documented deploy command. Those need an explicit instruction from you in the session.

## Trackers

Tracker use is set **per mission**, in the brief's **Tracker** field, in your own words: "read the epic from <link>", "write a ticket for each assignment", "update statuses and link the PR when done". Leave it blank and the mission touches no tracker.

- `brief` can start from a ticket link and draft **Done means** and **Verified means** from its acceptance criteria.
- `execute` lists the tickets it would create in the flight plan, and creates them only after you answer.
- `go-no-go` shows the exact status updates and links in the briefing, and posts them on "launch".

The plugin ships no integrations. It uses whatever connector the agent already has for the tool you name (an MCP server for Notion, Linear or Jira, or a CLI like `gh`). A write instruction in the brief is the permission for that mission, and every write is shown before it's posted. With no connector, reads fall back to you pasting the ticket, and writes become ready-to-paste drafts.

## Parking

`/mission-control:park "note"` saves an idea or question to `.mission-control/parked.md` in the project, not to a global file. The crew writes to the same parking lot. When a crew member hits a question the brief doesn't cover and it isn't risky, it **parks** the question instead of guessing, takes the most reversible option, records the assumption, and keeps going. A risky question (security, data, money, deploy, anything hard to reverse) stops the crew member instead.

Crew notes are tagged with the crew member and mission:

```text
- #3 · 2026-11-05 · [crew:engineer-1 · mission:2026-11-05-saved-carts] Should guest carts expire? — assumed: 30 days
```

`decisions` and `go-no-go` show the current mission's crew questions under "needs your call", and an open one blocks launch. `/mission-control:parked crew` lists them on their own.

This parking lot is separate from the `parking-lot` plugin's. You can install both.

## Crew sessions

By default the crew runs as subagents in your session. For big assignments, or ones that touch areas other crew members are changing in parallel, the Captain can run a crew member as a separate agent session in its own git worktree:

- **Mission branch** `mc/<mission-id>`, in its own mission worktree at `../<repo>-mc-<mission-id>`.
- **Crew branch** `mc/<mission-id>--<crew-id>`, in a crew worktree at `../<repo>-mc-<mission-id>--<crew-id>`.
- In a mission that mixes the two, subagent crew members also work in the mission worktree, and the Captain commits their work on the mission branch, so there's one combined result.
- Crew branches merge into the mission branch inside the mission worktree. Your checkout is never switched. Your branch only changes on "launch".

Worktree sessions start with `crew-command` from `.mission-control/config.md`, run in the background in the crew's worktree. Any agent CLI works (`claude -p`, `codex exec`, Cursor's agent CLI). A working example for Claude Code, for a project tested with `npm test`:

```text
crew-command: claude -p --add-dir <main repo path> --allowedTools "Bash(npm test *),Bash(git add *),Bash(git commit *),Bash(PARKED_FILE=* bash *park.sh add *)" --permission-mode acceptEdits
```

A crew member needs to:

- **edit files** in its worktree: `--permission-mode acceptEdits` auto-approves edits, but not shell commands;
- **run Bash** for its tests (`npm test`), for git (`git add`, `git commit` on its own branch) and for `park.sh` (parking questions): `--allowedTools` allows exactly those commands. Swap in your project's own test command, and add any setup it needs (e.g. `Bash(npm install *)`);
- **write to the main repo's `.mission-control/`** for its report and parked questions: `--add-dir`.

`--add-dir` and `--allowedTools` take several values, so keep a single-value flag such as `--permission-mode acceptEdits` last: the Captain appends the prompt after the command, and a list flag at the end would swallow it. You can grant the same permissions in the project's Claude Code settings instead of flags. Which way, and how much to allow, is your call. Check the rule syntax against your agent CLI's docs.

**Permissions are your job.** The plugin runs `crew-command` exactly as written and never adds permission flags, least of all bypass flags. If a crew session fails on permissions, the Captain shows you the log and the exact command to run yourself. With no `crew-command` set, it prints the command for you to run in a new terminal and waits.

Worktree mode is off at `recommend` autonomy.

## Stop guard

Commands only help if you remember to run them, and you stop remembering at exactly the moment you've started to drift. So the plugin also installs a `Stop` hook that makes the two most important checks automatic.

When Claude changed files during a turn (with `Edit`, `Write`, `MultiEdit`, or `NotebookEdit`), it can't finish until its final message ends with:

- **`## Evidence`:** the checks it actually ran, with verbatim output, what each proved and didn't prove, and a verdict.
- **`## Decisions`:** every choice you didn't specify, with "needs your call" items first.

If a section is missing, the hook sends Claude back once to add it. Turns that change no files (questions, chat, research) finish normally. `verify` and `go-no-go` use these same headings, so mission output passes without repeating itself.

**Limits:**
- The hook blocks at most once per stop, so it can never trap a session in a loop.
- It fails open: if `jq` or the transcript is unavailable, Claude stops normally.
- File changes made only through `Bash` (`sed`, scripts) aren't detected.
- It's the one Claude Code-specific piece. Everything else is plain instructions and shell scripts.

**Turn it off** for a project by adding this to `.claude/settings.json`:

```json
{ "env": { "MISSION_CONTROL_STOP_GUARD": "off" } }
```

Set it in your shell to turn it off everywhere. The old `NO_SURRENDER_STOP_GUARD=off` still works.

## Coming from no-surrender

mission-control replaces `no-surrender`. Uninstall it and install this:

```text
/plugin uninstall no-surrender@schmigui
/plugin install mission-control@schmigui
```

| no-surrender | mission-control |
| --- | --- |
| `/no-surrender:brief` | `/mission-control:brief` (now also takes a ticket or an `explore` direction, and has **Autonomy** and **Tracker** fields) |
| `/no-surrender:blindspots` | `/mission-control:blindspots` |
| `/no-surrender:evidence` | `/mission-control:evidence` |
| `/no-surrender:decisions` | `/mission-control:decisions` (now also lists parked crew questions) |
| `/no-surrender:quiz` | `/mission-control:quiz` |
| `NO_SURRENDER_STOP_GUARD=off` | `MISSION_CONTROL_STOP_GUARD=off` (the old one still works) |

## A typical mission

```text
/mission-control:explore "saved carts"          # what, why, and what not to build
/mission-control:brief                          # done means, verified means, autonomy, tracker
/mission-control:blindspots                     # what happens to guest carts? to existing sessions?
/mission-control:execute                        # flight plan → "Tell me what's wrong." → go
... crew works, parks what it can't decide ...
/mission-control:verify                         # self-checks, fresh reviewer, final checks
/mission-control:go-no-go                       # the briefing; answer the open calls
launch                                          # the Captain acts up to the autonomy level
```

Not every task needs all of it. A one-line fix needs none of it, and a risky change may want `/mission-control:quiz` before launch. Match the depth to how costly being wrong would be.

## Why

The best way to get good work out of an agent is to tell it what you care about. When you don't, it fills the gaps for you, and confidently. With a crew, it fills them in parallel. These commands are built on the ideas in *Critical thinking when agents do the work*, and on the loop of brief → execute → verify → decide → ship:

- Form a hypothesis before you ask.
- Define "verified" upfront, because afterward you'll rationalize any outcome.
- A green check proves one thing. Ask what it didn't prove.
- Read what the agent decided for you, not just what it produced.
- Parallelize only what's independent. Collisions cost more than parallelism saves.
- A question the agent can't answer belongs to you. Park it, don't guess it.
- If you can't explain it, even with the agent's help, you've surrendered it.

## Evals

Behavior tests live in [`evals/`](evals), run with `claude plugin eval`.

## License

MIT
