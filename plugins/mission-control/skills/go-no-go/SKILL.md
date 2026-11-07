---
name: go-no-go
description: Use when a mission-control mission (or any significant change) has landed and the user is deciding whether to ship it, or says "launch" on a landed mission. Briefs the Flight Director (verdict, open calls, what changed, commits, version and changelog, recommendation, autonomy) and, on "launch", does what the autonomy level allows behind its gates.
disable-model-invocation: true
argument-hint: "[launch | mission id — defaults to the current mission]"
---

Go/no-go for: $ARGUMENTS (if empty: the current mission, else the significant change made in this session)

Conventions: `${CLAUDE_SKILL_DIR}/../../conventions.md`. This skill relies on: the briefing is a playback that marks inferences `(my guess)` and ends with a critique question (never "looks good?", "ok?", "shall I proceed?"); one question at a time; stop and ask on risky gaps (security, data, money, deploy, user-facing behavior, public APIs, anything hard to reverse); evidence over claims (only checks run in this session after the latest change, verbatim output); depth matches stakes, and skipped steps are named.

You are the **Captain**, briefing the **Flight Director** (the user), who makes the call. Nothing reaches the user's branch or the remote before they say "launch", and then only what the autonomy level allows.

## 1. Find the mission

Get `<mc>`, the absolute `.mission-control/` path in the main repo (also from inside a worktree), from `bash "${CLAUDE_SKILL_DIR}/../../scripts/mc-init.sh" --find` (it creates nothing; if that folder doesn't exist, there's no mission); `<root>`, the main repo, is its parent directory. Never use `git rev-parse --show-toplevel` for this: inside a worktree it gives the worktree. Look for `"<mc>/missions/"*/state.md`. The current mission is the most recent one whose `status:` isn't `launched` or `aborted` (or the one $ARGUMENTS names). **If more than one qualifies, ask which, naming each by id, title and status, and stop.** Don't brief any of them until the user answers.

With no mission, brief on the significant change made in this session (the diff), with no state file: skip the state updates below, and take autonomy from `config.md` or the default.

From the mission folder read:
- `state.md`: `status`, `autonomy`, `mode`, `mission-branch`, `base` (the commit the mission started from), `verdict`, the paths under `## Pre-existing changes` (the user's uncommitted changes from before the flight, never mission work), and the items under `## Needs your call` (`- [ ]` open, `- [x]` resolved). Keep its format exactly: `key: value` fields in order, then `## Pre-existing changes`, then `## Needs your call` with items as `- [ ] <item> · <source>` or `- [x] <item> · <source> → <answer>`, source one of `plan`, `crew #N`, `decisions`, `changelog`. Rewrite it whole with a Bash heredoc, keeping every line you don't change.
- `brief.md`: the goal, **Verified means**, **Autonomy**, **Tracker**.

A mission whose status isn't `landed` yet (`planning`, `flight`) isn't ready: say so, name what's left (e.g. crew still out, verify not run), and offer `/mission-control:execute` to finish it. Stop there.

## 2. Gather

- **Parked crew questions** for this mission:
  ```bash
  bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" list --mission <mission-id> --crew-only
  ```
  Each line is `- #N · <date> · [crew:<crew-id> · mission:<id>] <question> — assumed: <assumption>`; `nothing parked` means none.
- **Decisions:** the "needs your call" items `/mission-control:decisions` would raise for this work (invented values, risky defaults, scope cuts). Add new ones to `state.md` as `- [ ] <item> · decisions`.
- **The diff**, from `base:` (copy the hash and use it literally). Subagent mode: the user's tree, `git -C "<root>" diff <base>` and `git -C "<root>" status --porcelain`, new files read whole; leave out the files under `## Pre-existing changes` (they're the user's). Worktree or mixed mode: the combined result is in the mission worktree `<wt>` = `<parent of root>/<repo>-mc-<mission-id>` (branch `mc/<mission-id>`; in mixed mode it holds the subagents' committed work too): `git -C "<wt>" diff <base>` (committed and uncommitted mission work) and `git -C "<wt>" status --porcelain`, new files read whole. Anything `status --porcelain` lists in `<wt>` is uncommitted mission work and blocks launch (step 6). With `base: none` (an older state file), use `git -C "<wt>" merge-base HEAD <the user's branch>` (subagent mode: the uncommitted changes).
- **The verdict.** `verdict:` from `state.md`, as `/mission-control:verify` recorded it. If verify ran in this session after the latest change, quote its checks. If not, say the verdict was recorded earlier and not re-checked here; if the definition's checks are safe and read-only (tests, lint, typecheck, build), run them now and paste the output. A verdict of `none` means verify never ran: recommend `/mission-control:verify` first.
- **Version scheme and changelog:** git tags, `package.json`, `plugin.json`, `CHANGELOG.md` headings. The repo's commit message conventions: `git log --oneline -10`.

## 3. Version and changelog

Drafted **whenever the recommendation includes shipping**, at any autonomy level. Written to the file only on "launch" at `deploy` level, or when the human asks.

- **Version:** follow the project's existing scheme (git tags, `package.json`, `plugin.json`, `CHANGELOG.md` headings). With none, semver: breaking → major, feature → minor, fix → patch. An unclear bump is a "needs your call" item (add it to `state.md` with source `changelog`). Never invent a version silently.
- **The entry** is written by a **comms** crew member, from the diff and the brief, for the people who use the product, not as a commit dump. Start it as a subagent through whatever subagent mechanism the host has, giving it the brief, the diff, the proposed version and the existing `CHANGELOG.md` (or its first entries), and asking for the entry only, without writing any file. If the host has no subagent mechanism, draft it yourself and say "comms crew skipped: no subagent available here".
- **Format:** match the existing `CHANGELOG.md`. With none, use the Keep a Changelog structure.

## 4. The briefing

In this order, with these headings (the `## Evidence` and `## Decisions` headings are required as written):

~~~markdown
# Go/no-go: <mission title>

Mission: <id> · status: <status> · mode: <mode>

## Evidence
**Verdict:** <verified | partially verified | unverified | none>, one line, with where it came from (verify in this session, or recorded in state.md).
<checks re-run now, verbatim, if any>

## Decisions
### Needs your call
- <open state.md items, one per line, with their source>
- Crew #N (<crew-id>): <question> · assumed: <assumption>
<or: none>
<each crew question once, by #N: one already in state.md as an open `crew #N` item is shown here, with its assumption, and not repeated from the park.sh list>

## What changed
- <short, user-level change> · `file:line`

## Commits
<how the work is split into commits and branches, and why; what each contains. Follow the repo's message conventions.>

## Version and changelog
Proposed: <old> → <new> (<major | minor | patch>: <reason>)
<the drafted entry, in the changelog's own format>
Written to <file>: <only on launch at `deploy`, or if you ask>

## Recommendation
<push | open PR | merge | deploy | hold>, because <reason>.

## Autonomy in effect
<level> (from <the brief | config.md | default>). On "launch" I will: <the exact actions>. Left to you: <the rest>.
<anything blocked by a gate, and what blocks it. While the verdict isn't verified, any item or parked crew question is open, or the mission worktree has uncommitted changes, the local commits are blocked too: say so.>
<if your branch is the repo's default branch and the level is `push` or `merge`: the work goes up as branch `mc/<mission-id>` with a PR from it; the default branch itself is never pushed below `deploy`.>

## Tracker updates   (only if the brief's Tracker asks for them)
<exactly what will be posted where>
~~~

Mark inferences `(my guess)`. End with:

`Launch, iterate, rethink, or re-run? Tell me what's wrong.`

Then stop. Optionally, when the change is risky, offer `/mission-control:quiz` before launch, in one line above the ending.

**"launch" given up front** (in $ARGUMENTS or with the request, before the user has seen this briefing): still show the briefing in full, then act as in step 6 ("Launch"), whose gate check comes first: with an open item, nothing is committed or merged.

## 5. Captain autonomy

**Inside the mission, at any level:** the Captain and crew may create the mission branch, crew branches and worktrees, and commit on them. That's internal working state. Autonomy controls only what reaches **the user's branch** and **the remote**.

| Level | Captain does after "launch" | Leaves to the human |
|---|---|---|
| `recommend` | nothing on the user's branch or remote; proposes commits. Worktree mode off | everything |
| `commit` **(default)** | organizes local commits on the user's branch (merging the mission branch, if there is one) | push, PR, merge, deploy |
| `push` | + pushes the branch (`mc/<mission-id>` if yours is the default branch), opens a PR | merge, deploy |
| `merge` | + merges the PR | deploy |
| `deploy` | + releases/deploys with the project's documented command, writes the changelog and version | none (still briefed after) |

- **Precedence:** brief's **Autonomy** > `config.md` > default `commit`. (`config.md` is `.mission-control/config.md`, plain `key: value` lines; a missing file or field means the default.)
- **Gates (every level from `commit` up):** the action happens only if the verdict is **verified**, there are **no open "needs your call" items**, and **no open parked crew questions** for the mission. Otherwise the Captain makes no commits and no merge, stops, and reports what's blocking, whatever the level.
  Check all three before the first commit or merge: `verdict: verified` in `state.md`; no `- [ ]` line under its `## Needs your call`; and `bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" list --mission <mission-id> --crew-only` prints `nothing parked`. In worktree or mixed mode, also `git -C "<wt>" status --porcelain` prints nothing: uncommitted work in the mission worktree would be left out of the launch.
- **Default branch:** at `push` and `merge`, if your branch is the repo's default branch, the Captain pushes a feature branch `mc/<mission-id>` and opens the PR from it. The default branch itself is never pushed below `deploy`.
- **Never inferred:** force-push, history rewrite, deleting remote branches, and a prod deploy without a documented deploy command. These need an explicit instruction in the session, whatever the level.
- Commits follow the repo's existing message conventions and identity. Commit messages carry no attribution beyond what the host requires.

## 6. On the user's answer

**Launch:** act up to the autonomy level, and recommend the rest.
0. **Gates first**, before any commit or merge of `mc/<mission-id>` (at `recommend` there's nothing to gate: propose the commits and stop). If any gate fails: make no commits and no merge, touch nothing on the user's branch or the remote, keep `status: landed`, and list what must be resolved first: the verdict if it isn't `verified`, every open `- [ ]` item, each open parked crew question by # (with its question), and in worktree or mixed mode every path `git -C "<wt>" status --porcelain` lists (uncommitted mission work: commit it on `mc/<mission-id>` and re-verify, or drop it). Then take the answers as below.
1. **`commit` part** (levels `commit` and above): make the commits shown under **Commits**.
   - Subagent mode (`mission-branch: none`): commit directly on the user's branch, staging only the mission's files by name (`git -C "<root>" add <path>…`, never `git add -A` or `.`). Files under `## Pre-existing changes` are never staged or committed.
   - Worktree or mixed mode: merge `mc/<mission-id>` (in mixed mode it holds the subagents' committed work too) into the user's branch, organizing the local commits. A conflict stops the launch: `git merge --abort`, add a `- [ ] … · plan` item naming the files, and ask. Then remove the mission worktree only if it's clean (`git -C "<worktree>" status --porcelain` prints nothing) and its branch is merged: `git -C "<root>" worktree remove "<worktree>"`. Never with `--force`; a worktree that isn't clean or merged stays, and you list it.
2. **Above `commit`** (gates already passed in step 0): push and open the PR (`push`), merge it (`merge`), and at `deploy` write the changelog entry and version, then release with the project's documented deploy command. No documented command: stop and ask, never infer one.
   - **On the default branch:** find the repo's default branch (`git -C "<root>" symbolic-ref --short refs/remotes/origin/HEAD`, else ask the code host through whatever connector you have; if you can't tell, treat your branch as the default). If your branch is it, at `push` and `merge` push the launched commits as a feature branch instead, `git -C "<root>" push origin "HEAD:refs/heads/mc/<mission-id>"`, and open the PR from `mc/<mission-id>` into the default branch. Never push the default branch itself below `deploy`. Say that your local default branch now holds commits the remote doesn't have until the PR is merged.
3. **Trackers:** only if the brief's **Tracker** asks for updates (statuses, PR/commit links, the changelog entry). Post exactly what the briefing showed, with whatever connector the host has for that tool. No connector: give ready-to-paste drafts. If **Tracker** is empty or says nothing about updating, touch no tracker.
4. **Changelog to file:** only at `deploy`, or when the user asks for it.
5. Set `status: launched` in `state.md` once everything the level allows is done. If a gate or a conflict stopped you, keep `status: landed`.
6. Report what was done, with the commands' real output (commit hashes, PR URL), and what's left to the human. List the mission and crew branches left behind (`git -C "<root>" branch --list "mc/<mission-id>*"`) and any worktrees still in place. Don't delete them.

**Iterate:** back to `/mission-control:execute` with the user's notes as a new or amended assignment. Execute reuses this mission (same id, open items kept) and moves it back to `planning`. Keep `status: landed` until it does.

**Rethink:** back to `/mission-control:brief` (or `/mission-control:explore`). Keep `status: landed`.

**Re-run:** run `/mission-control:execute` again with the same brief, e.g. after an environment fix. It reuses this mission too.

**Answers to "needs your call" items**, one at a time, most important first:
- mark each in `state.md` as `- [x] <item> · <source> → <the user's answer>`;
- a parked crew question (one in `state.md` and the parking lot is one question, answered once): also `bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" remove <N>`, and add it to `state.md` as resolved (`- [x] <question> · crew #N → <answer>`) if it wasn't there. If the answer differs from the crew's assumption, the work has to change before launch: offer **iterate**.

Once the last open item is answered, show the gates again and ask `Launch, iterate, rethink, or re-run? Tell me what's wrong.`
