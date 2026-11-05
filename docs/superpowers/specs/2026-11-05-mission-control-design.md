# mission-control: design

Date: 2026-11-05
Status: ready for user review

## Intent

Hand off the work, not the accountability, now with a crew.

`mission-control` is Guillermo's whole process for working with AI agents, packaged as one plugin. It **replaces `no-surrender`**: it keeps all five of its commands (`brief`, `blindspots`, `evidence`, `decisions`, `quiz`) and its Stop guard, and adds what was missing:

- **`explore`:** brainstorm *what* to build and *why* before there's a brief (the Judgement skill).
- **`execute`:** the Captain splits a task across a crew of agents, in one session or in separate worktree sessions (the Orchestration skill).
- **`verify`:** layered verification that triggers from **natural language**, not only by command.
- **`go-no-go`:** the launch decision: one briefing with evidence, decisions, parked questions, commits, a ship recommendation and a changelog, with a configurable level of Captain autonomy.
- **`park` / `parked`:** a project-local parking lot that both the human and the crew write to. The crew parks questions instead of guessing.

Source of the ideas: `context/ai-era-principles.md` (the five core skills Judgement, Orchestration, Ownership, Expertise and Curiosity; the brief → execute → verify → decide → ship loop; the dev's field note on orchestration). Also the sources no-surrender drew on (`context/critical-thinking.md`), plus `context/overprompting-claude.md` and `context/solving-code-review-at-anthropic.md`.

## The metaphor

A space mission. It's flavor in the README and in the output's headings, never cute filler.

| Role | Who | Does |
|---|---|---|
| **Flight Director** | the human | briefs, makes the calls, gives go/no-go, owns the outcome |
| **Captain** | the root orchestrator (the main agent session, one per project) | plans the flight, assigns the crew, merges, runs final verify, briefs the Flight Director |
| **Crew** | worker agents | do one assignment each and self-verify. Roles: *researcher*, *engineer*, *reviewer*, *comms* (changelog). The Captain may name others. |

Phases: **pre-flight** (`explore`, `brief`, `blindspots`) → **flight** (`execute`) → **landing** (`verify`, `evidence`) → **go/no-go** (`decisions`, `quiz`, `go-no-go`), with `park`/`parked` available throughout.

## Goals

- One installable plugin that covers the full loop, from idea to production.
- The human stays in charge at every hand-off point, and the plugin makes that cheap.
- Verification is defined before the work, carried into every crew assignment, and checked in three layers.
- Orchestration that knows when *not* to parallelize.
- Tool-agnostic core: works with Claude Code today, portable to Codex or Cursor later.
- Software-first v1, written in neutral words so non-software work can be added later without a rewrite.

## Non-goals (v1)

- No non-software path (docs, research, decks). The wording must not shut it out, but git/test specifics are the worked examples.
- No dependency on any agent desktop app (Orca, Conductor, etc.) or on `superpowers`.
- No persistent mission dashboard or UI.
- No parking-lot editing commands (`repark`, `mergepark`, `reindexpark`). Those stay in `parking-lot`.

## Anti-goals (failure even if it "works")

- **Rubber-stamp prompts.** Any "looks good?" or yes/no approval question. See the playback convention.
- **Silent guessing.** The crew or Captain inventing an answer to something the brief doesn't cover instead of parking it, or stopping on risky items.
- **Parallel collisions.** Two crew members editing the same files at once.
- **Claimed verification.** Any "tests pass" without real output in the session.
- **Autonomy creep.** The Captain pushing, merging or deploying beyond the configured level, or acting at a high level while verify isn't green or questions are still open.
- **Unasked tracker writes.** Posting to Notion, Jira or similar without a write instruction in the brief, or without showing the content first.
- **Ceremony.** Running the full loop on a one-line fix. Every skill says to match depth to how costly being wrong would be.
- **Theme overload.** Space jargon that makes output harder to read.

## Shared conventions (all skills)

Put these in one file, `plugins/mission-control/conventions.md`. Each SKILL.md points to it (`${CLAUDE_SKILL_DIR}/../../conventions.md`) and also restates in one line the parts it relies on, so a skill still works if the file isn't read.

1. **Playback, then "tell me what's wrong."** Any skill that proposes something (an explore direction, a brief, a flight plan, a verify plan, a go/no-go briefing) shows it in plain words, marks inferences `(my guess)`, and ends with **"Tell me what's wrong."** (or "…or missing"). Never "looks good?", "ok?", "shall I proceed?". A reply like "fine" or "go" counts as approval. Approval is never assumed. *Why:* a critique question makes the human judge, while an approval question invites a rubber stamp. This is Judgement and Ownership from the principles doc.
2. **One question at a time**, most important first.
3. **Stop on risky gaps:** security, data, money, deploy, user-facing behavior, public APIs, anything hard to reverse. Never guess these. Smaller uncovered choices are either decided and recorded for `decisions`, or parked (crew).
4. **Evidence over claims:** only report checks actually run in this session after the latest change, with verbatim output.
5. **Depth matches stakes.** Skip steps that the cost of being wrong doesn't justify, and say which ones were skipped.

## Project-local state: `.mission-control/`

At the target project's root:

```text
.mission-control/
  .gitignore        written on first use: ignores everything except config.md and .gitignore
  config.md         autonomy level and crew launch command (committed)
  parked.md         the parking lot (local)
  missions/<id>/    per-mission working files (local)
    brief.md        the confirmed brief (always, in both modes)
    state.md        status + open "needs your call" items (always)
    assignments/<crew-id>.md   (worktree mode)
    reports/<crew-id>.md       (worktree mode)
```

- **Mission id:** `YYYY-MM-DD-<short-slug>` from the brief's title. The Captain creates it when `execute` starts.
- *My call:* **mission state is always saved**, in both modes, so the go/no-go gate works across sessions. `state.md` holds `status: planning | flight | landed | launched | aborted`, the verify verdict, and the list of open "needs your call" items. `decisions` and `go-no-go` add and resolve items there. **Current mission** = the most recent mission whose status isn't `launched` or `aborted`. If there's more than one, ask which.
- Created lazily by whichever skill first needs it. Never create it for a task that doesn't need it.
- *My call:* only `config.md` is committed. The parking lot and mission files are personal working state. If the user wants them committed, they edit `.mission-control/.gitignore`.

### `config.md`

```markdown
# mission-control config

autonomy: commit
crew-command: claude -p
```

- Missing file or field → defaults: `autonomy: commit`, `crew-command` unset (see execute).
- Plain `key: value` lines. Unknown keys are ignored.

## Skills

`disable-model-invocation: true` on every skill **except `verify` and `execute`**, which carry trigger-rich descriptions so the agent picks them up from natural language. Commands are namespaced `/mission-control:<skill>`.

| Phase | Skill | Invocation | Origin |
|---|---|---|---|
| Pre-flight | `explore` | command | new |
| Pre-flight | `brief` | command | no-surrender, updated |
| Pre-flight | `blindspots` | command | no-surrender, as-is plus conventions |
| Flight | `execute` | command **and** natural language | new |
| Landing | `verify` | command **and** natural language | new |
| Landing | `evidence` | command | no-surrender, as-is plus conventions |
| Go/no-go | `decisions` | command | no-surrender, updated |
| Go/no-go | `quiz` | command | no-surrender, as-is |
| Go/no-go | `go-no-go` | command | new |
| Any | `park` | command (human). The crew uses the script directly | parking-lot copy, adapted |
| Any | `parked` | command | parking-lot copy, adapted |

### `explore` (new)

**When:** the user has an idea, not a task, or isn't sure what to build or why.

- Get the user describing first: open questions anchored in a real moment ("walk me through the last time…"). Offer options only when they're stuck or ask "what do you think?".
- Cover the ground (what it is, why now, what success looks like, goals / non-goals / anti-goals, what exists already, what they've seen elsewhere) as territory, not a questionnaire.
- Challenge, don't flatter: give at least one strong alternative or "don't build it" option, plus the trade-offs. More features ≠ more value.
- Play back as you go (convention 1).
- **Ends** with a short "direction" playback (what to build, why, what not to build), and offers `brief` with that direction as input. `explore` never writes code or plans implementation.

### `brief` (from no-surrender)

Keep the current skill. Changes:

- Accepts an `explore` direction as input.
- New brief fields: **Autonomy:** (optional per-mission override of `config.md`), and **Tracker:** (see Trackers). **Verified means** stays mandatory for non-trivial work.
- Accepts a ticket link or id as input (`/mission-control:brief <link>`). It reads the ticket through the tracker connector and drafts the brief from it: acceptance criteria → **Done means** / **Verified means**. Gaps are asked as usual.
- The confirmation question becomes "Tell me what's wrong or missing." (convention 1).
- Section 4 ("follow the brief"): uncovered small choices are recorded for `decisions`, **or parked** when the answer belongs to the human but isn't risky enough to stop for.
- Ends by offering `execute` (instead of only `/evidence`).

### `blindspots`, `evidence`, `quiz` (from no-surrender)

Move as-is. Change `/blindspots`, `/evidence` and similar references to `/mission-control:<name>`. `blindspots` and `evidence` follow convention 1 in their closing questions.

### `decisions` (from no-surrender)

As-is, plus: it also lists **parked crew questions** from the current mission (see park), each with the assumption the crew made, in the "needs your call" section.

### `execute` (new): the Captain's playbook

**Triggers (description must say so):** `/mission-control:execute [task]`; the user asks to delegate, orchestrate, split up, parallelize, "send agents to…", "have a crew…"; or a confirmed brief is followed by "go".

**Input:** a confirmed brief. With none: if the task is clear and small, proceed and say no brief was made. Otherwise offer `brief` first.

**1. Plan the flight.** Split the work into crew assignments. Each one has:
- **Role and task:** one concrete outcome.
- **Owns:** the files or areas it may change. Read-only assignments (research, review) say so.
- **Brings back:** findings, changes made, problems, open questions.
- **Verify with:** the exact checks it must run on its own work, taken from the brief's **Verified means** and narrowed to the assignment.
- **Mode:** subagent or worktree session.
- **Order:** parallel group or sequence.

If the brief's **Tracker** says to write tickets, the plan also lists the ticket each assignment will become (title and content), and tickets are created only after the human answers.

Show the flight plan as a playback ending "Tell me what's wrong." No code is touched before the human answers. Small missions (one crew member, or the Captain doing it alone) may say so and go straight on, but the plan is still shown.

**2. Parallelize only what's independent.**
- Research, reading and review fan out freely.
- Changes run in parallel **only** if their **Owns** sets don't overlap. Overlap, or unknown overlap → sequence.
- When in doubt, one agent. (From the field note: collisions cost more than parallelism saves.)

**3. Pick the mode for each assignment.**
- **Subagent (default):** a subagent in the current session, via the host's subagent tool. The assignment text is the subagent's whole prompt.
- **Worktree session:** for big assignments, or assignments that touch areas other crew members are working on in parallel. **Off at `recommend` autonomy**: there, every assignment runs as a subagent.
  - **Mission branch:** `mc/<mission-id>`, created from the user's current branch when the first worktree is needed.
  - `git worktree add ../<repo>-mc-<crew-id> -b mc/<mission-id>/<crew-id> mc/<mission-id>`
  - Write `.mission-control/missions/<id>/assignments/<crew-id>.md` in the **main** repo, and give the crew member the absolute path to it and to its report path.
  - Launch with `crew-command` from `config.md` (e.g. `claude -p`, `codex exec`, or Cursor's agent CLI), in the background, cwd = the worktree, prompt = "Read <assignment path> and do it. Write your report to <report path>." If `crew-command` is unset or launching isn't possible, print the exact command for the human to run in a new terminal, and wait.
  - **Permissions are the user's job (user decision).** The plugin never adds permission flags, least of all bypass flags, to `crew-command`. It runs exactly what's configured. The README shows a working example, e.g. `claude -p --permission-mode acceptEdits --add-dir <main repo path>` (the crew needs edit and test permissions in its worktree, plus write access to the main repo's `.mission-control/` for its report and `park.sh`). If a crew session fails on permissions, the Captain reports the failure and prints the command for the user to run themselves.
  - Worktrees are removed after a successful merge. On abort they're left in place and listed.
- *My call:* the assignment format is the same in both modes, so a subagent assignment can be promoted to a worktree session unchanged.

**4. During flight: the crew's standing orders** (included verbatim in every assignment):
- Stay inside **Owns**.
- A question the brief doesn't cover: if it's risky (convention 3), stop and report it as blocked. Otherwise **park it** (exact park command, with absolute script path and mission id filled in), choose the most reversible option, record the assumption in the report, and continue.
- Self-verify with **Verify with** before reporting. Include verbatim output.
- *My call:* crew members **only self-check (layer 1)**. They never run `verify` or start reviewer agents themselves, so reviews don't nest. `verify`'s description excludes crew assignments explicitly.

**5. Land.** Collect reports and changes, merge worktree branches into the mission branch, then run `verify` on the combined result. Hand off to `go-no-go`.

### `verify` (new)

**Triggers (description must say so, prominently):** `/mission-control:verify [what / how]`; **or any time a plan, assignment, brief or message states how something must be checked**: "make sure…", "confirm that…", "check it works in the browser", "the reviewer should verify…", "prove it", "test that…", "don't ship until…". In those cases the agent runs `verify` with that text as the definition of verified. Also runs at the end of `execute`.

**Three layers:**
1. **Crew self-check:** done inside each assignment (execute step 4). `verify` collects those results and treats any claim without output as **not checked**.
2. **Reviewer:** a fresh crew member (subagent) that wrote none of the work checks the combined change against the brief, looking for bugs, missed requirements and contradictions with **Out of scope**. It is given the brief and the diff, **not** the builders' reasoning. Its findings are fixed or reported, never silently dropped.
3. **Captain's final check:** runs the brief's **Verified means** (or the natural-language definition) on the merged result.

**Output:** the `evidence` report format (checks with verbatim output, proves / doesn't prove, not checked, verdict). `verify` is the process. `evidence` stays as the standalone report command.

**Scaling:** outside a mission (a single agent, a single change), `verify` runs layers 2 and 3 only. For trivial changes, layer 3 only, and it says the reviewer was skipped.

**Defining verified when nothing says how:** propose a verify plan as a playback ("Tell me what's wrong.") before running it, unless the checks are obvious and read-only (tests, lint, typecheck, build).

### `go-no-go` (new)

**When:** a mission (or any significant change) has landed. Also offered at the end of `execute`.

**The briefing**, in this order:
1. **Verdict:** from verify/evidence: verified / partially / unverified, one line.
2. **Needs your call:** `decisions` "needs your call" items plus parked crew questions from this mission.
3. **What changed:** short, with `file:line` anchors.
4. **Commits:** how the work is split into commits and branches, and why. What each contains.
5. **Version and changelog:** proposed version bump with its reason, and the drafted changelog entry (see below).
6. **Recommendation:** push / open PR / merge / deploy / hold, with the reason.
7. **Autonomy in effect** and what the Captain will do after "launch".
8. **Tracker updates** (if the brief asks for them): exactly what will be posted where.

Ends: "Launch, iterate, rethink, or re-run? Tell me what's wrong."

- **Launch:** act up to the autonomy level, and recommend the rest.
- **Iterate:** back to `execute` with the human's notes as a new or amended assignment.
- **Rethink:** back to `brief` (or `explore`).
- **Re-run:** run `execute` again with the same brief, e.g. after an environment fix.

Optionally offers `quiz` before launch when the change is risky.

### Captain autonomy

**Inside the mission, at any level (user decision):** the Captain and crew may create the mission branch, crew branches and worktrees, and commit on them. That's internal working state. Autonomy controls only what reaches **the user's branch** and **the remote**.

| Level | Captain does after "launch" | Leaves to the human |
|---|---|---|
| `recommend` | nothing on the user's branch or remote; proposes commits. Worktree mode off | everything |
| `commit` **(default)** | organizes local commits on the user's branch (merging the mission branch, if there is one) | push, PR, merge, deploy |
| `push` | + pushes the branch, opens a PR | merge, deploy |
| `merge` | + merges the PR | deploy |
| `deploy` | + releases/deploys with the project's documented command, writes the changelog and version | none (still briefed after) |

- **Precedence:** brief's **Autonomy** > `config.md` > default `commit`.
- **Gates (all levels above `commit`):** the action happens only if the verdict is **verified**, there are **no open "needs your call" items**, and **no open parked crew questions** for the mission. Otherwise the Captain stops and reports what's blocking, whatever the level.
- **Never inferred:** force-push, history rewrite, deleting remote branches, and a prod deploy without a documented deploy command. These need an explicit instruction in the session, whatever the level.
- Commits follow the repo's existing message conventions and identity. Commit messages carry no attribution beyond what the host requires.

### Changelog and version

- Drafted at go/no-go **whenever the recommendation includes shipping**, at any autonomy level. Written to the file only on "launch" at `deploy` level, or when the human asks.
- Written by a **comms** crew member, from the diff and the brief, for the people who use the product, not as a commit dump.
- **Version:** follow the project's existing scheme (git tags, `package.json`, `plugin.json`, `CHANGELOG.md` headings). With none, semver: breaking → major, feature → minor, fix → patch. An unclear bump is a "needs your call" item. Never invent a version silently.
- **Format:** match the existing `CHANGELOG.md`. With none, use the Keep a Changelog structure.

### Trackers (Notion, Linear, Jira, GitHub Issues, …)

Set **per mission in the brief** (user decision), not in `config.md`. The brief's **Tracker:** field records what the human said, e.g. "read the epic from <Notion link>", "write tickets to Notion", "update statuses and link the PR when done". If it's empty, the mission doesn't touch any tracker.

- **Connector-agnostic:** the plugin ships no integrations and no tracker-specific code. It uses whatever connector the agent has for the named tool (MCP, or a CLI like `gh`).
- **Read** (`brief` input): fetch the ticket or epic and draft the brief from it.
- **Write tickets** (`execute`): one ticket per crew assignment, under the epic if there is one, created after the flight plan is answered.
- **Update** (`go-no-go`): statuses, PR/commit links, the changelog entry. Proposed in the briefing and done on "launch".
- **Gate:** a write instruction in the brief is the permission for that mission. Without one, nothing is written. Every write is shown before it's posted (in the flight plan or the briefing).
- **No connector available:** reads fall back to the user pasting the ticket. Writes become ready-to-paste drafts.

### `park` / `parked` (adapted from parking-lot)

- Copy `parking-lot/scripts/park.sh` into `mission-control/scripts/park.sh` and adapt it:
  - Default file: `<project root>/.mission-control/parked.md` (project root = `git rev-parse --show-toplevel`, else cwd). `PARKED_FILE` still overrides.
  - Keep the lock and atomic writes. Parallel crew members write here.
  - Commands kept: `add`, `remove`, `get`, and a `list` filter for one mission's crew notes if that's simpler than parsing in the skill.
  - `add` accepts optional tags: `--crew <crew-id>` and `--mission <id>`.
- Line format: `- #N · YYYY-MM-DD · [crew:<crew-id> · mission:<id>] <note> — assumed: <assumption>`. Human notes have no tag block.
- `park "note"`: same behavior as parking-lot's (reply `parked #N`, never discuss it, resume the task).
- `parked [oldest] [crew] [mission <id>]`: list and discuss as in parking-lot. Crew notes show their tags. Offers removal once a note is resolved.
- `go-no-go` and `decisions` read the crew notes for the current mission. Resolving one there removes it.
- `parking-lot` itself is unchanged and stays in the marketplace. The two parking lots are independent.

## Stop guard (from no-surrender)

Move `hooks/hooks.json` and `hooks/stop-guard.sh` as-is, with these changes:
- Opt-out env var: `MISSION_CONTROL_STOP_GUARD=off`. *My call:* also honor the old `NO_SURRENDER_STOP_GUARD=off` so existing settings keep working.
- Message prefix `mission-control:` instead of `no-surrender:`.
- *My call:* the hook's check stays the same (literal `Evidence` and `Decisions` headings). `verify` and `go-no-go` name their sections `## Evidence` and `## Decisions` ("Needs your call" becomes a subsection of Decisions), so mission output passes without repeating itself.
- It's the one Claude Code-specific piece. The README says so.

## Portability

- SKILL.md bodies use plain instructions: "use a subagent", "run this command". They don't name Claude Code tools except where unavoidable, and then with a generic fallback.
- Crew launching is entirely through `crew-command`. No agent app is assumed.
- Software-specific steps (git, tests, commits, worktrees, changelog) are written as "for code: …" examples inside neutral steps, so a later non-software path can swap them out.

## Removing no-surrender

- Delete `plugins/no-surrender/` (git history keeps it).
- Remove its entry from `.claude-plugin/marketplace.json` and its row from the root `README.md`.
- Add `mission-control` to both.
- Fold no-surrender's README "Why" section (cognitive surrender, the critical-thinking points) into mission-control's README.

## Plugin layout and conventions

```text
plugins/mission-control/
  .claude-plugin/plugin.json      name, version 0.1.0, description, author, homepage, repository, MIT, keywords
  README.md                       same voice/structure as no-surrender's: tagline, problem, install, cast, phases + command table, autonomy, parking, stop guard, typical mission, why
  conventions.md
  hooks/hooks.json
  hooks/stop-guard.sh
  scripts/park.sh
  skills/<name>/SKILL.md          explore, brief, blindspots, execute, verify, evidence, decisions, quiz, go-no-go, park, parked
  evals/                          see below
```

- Repo: `/Users/guillermo.schmithalter/Documents/projects/skills` (`schmigui` marketplace). Follow the `same-page` and `no-surrender` frontmatter and README conventions.
- Git: personal identity only (repo-local `user.email` is already `gschmithalter14@gmail.com`). Never the work account.

## Evals

Use the `claude plugin eval` harness the way `same-page/evals` does. Required cases, since these are the behaviors most likely to fail silently:

- **verify triggers from natural language:** a prompt like "add X, and make sure it works by running the tests and checking the endpoint" leads to verify-style evidence without the command being typed. Plus a negative case where no verification language appears, so it doesn't fire on every message.
- **execute triggers from natural language:** "send one agent to research A and another to look at B, then propose a plan".
- **No parallel overlap:** a flight plan with two edits to the same file puts them in sequence.
- **Flight plan before code:** no Edit/Write before the human answers the playback.
- **Autonomy gate:** at `push` with an open parked crew question, nothing is pushed.
- **Playback wording:** proposing skills end with a "what's wrong" question, not an approval question.

The rest of the eval set is the builder's call.

*My call:* git may not run in the eval sandbox (see the same-page evals README). Git-dependent cases (autonomy gate, worktrees, merges) are graded **from the transcript**: the agent didn't attempt the forbidden command and reported the block. The builder may add real-git cases if the sandbox supports them.

## Left to the builder

- Exact SKILL.md wording, description text (within the trigger requirements above) and argument hints.
- `park.sh` internals beyond the contract above.
- Eval fixture project and graders.
- README prose.
- Plan order and commit granularity.
