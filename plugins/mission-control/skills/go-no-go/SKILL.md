---
name: go-no-go
description: Use when a mission-control mission (or any significant change) has landed and the user is deciding whether to ship it, or says "launch" on a landed mission. Briefs the Flight Director (verdict, open calls, what changed, commits, version and changelog, recommendation, autonomy) and, on "launch", does what the autonomy level allows behind its gates.
argument-hint: "[launch | mission id — defaults to the current mission]"
---

Go/no-go for: $ARGUMENTS (if empty: the current mission, else the significant change made in this session)

Conventions: `${CLAUDE_SKILL_DIR}/../../conventions.md`. This skill relies on: the briefing is a playback that marks inferences `(my guess)` and ends with a critique question (never "looks good?", "ok?", "shall I proceed?"); one question at a time; stop and ask on risky gaps (security, data, money, deploy, user-facing behavior, public APIs, anything hard to reverse); evidence over claims (only checks run in this session after the latest change, verbatim output); depth matches stakes, and skipped steps are named.

You are the **Captain**, briefing the **Flight Director** (the user), who makes the call. Nothing reaches the user's branch or the remote before they say "launch", and then only what the autonomy level allows.

## 1. Find the mission

Look for `.mission-control/missions/*/state.md` at the git toplevel (else the current directory). The current mission is the most recent one whose `status:` isn't `launched` or `aborted` (or the one $ARGUMENTS names). **If more than one qualifies, ask which, naming each by id, title and status, and stop.** Don't brief any of them until the user answers.

With no mission, brief on the significant change made in this session (the diff), with no state file: skip the state updates below, and take autonomy from `config.md` or the default.

From the mission folder read:
- `state.md`: `status`, `autonomy`, `mode`, `mission-branch`, `verdict`, and the items under `## Needs your call` (`- [ ]` open, `- [x]` resolved). Keep its format exactly: `key: value` fields in order, items as `- [ ] <item> · <source>` or `- [x] <item> · <source> → <answer>`, source one of `plan`, `crew #N`, `decisions`, `changelog`. Rewrite it whole with a Bash heredoc, keeping every line you don't change.
- `brief.md`: the goal, **Verified means**, **Autonomy**, **Tracker**.

A mission whose status isn't `landed` yet (`planning`, `flight`) isn't ready: say so, name what's left (e.g. crew still out, verify not run), and offer `/mission-control:execute` to finish it. Stop there.

## 2. Gather

- **Parked crew questions** for this mission:
  ```bash
  bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" list --mission <mission-id> --crew-only
  ```
  Each line is `- #N · <date> · [crew:<crew-id> · mission:<id>] <question> — assumed: <assumption>`; `nothing parked` means none.
- **Decisions:** the "needs your call" items `/mission-control:decisions` would raise for this work (invented values, risky defaults, scope cuts). Add new ones to `state.md` as `- [ ] <item> · decisions`.
- **The diff.** Subagent mode: the user's tree (`git status`, `git diff`, new files read whole). Worktree or mixed mode: the mission branch against its base, `git -C "<root>" diff "$(git -C "<root>" merge-base HEAD "mc/<mission-id>")" "mc/<mission-id>"`, in the mission worktree `"<parent of root>/<repo>-mc-<mission-id>"`.
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
<anything blocked by a gate, and what blocks it>

## Tracker updates   (only if the brief's Tracker asks for them)
<exactly what will be posted where>
~~~

Mark inferences `(my guess)`. End with:

`Launch, iterate, rethink, or re-run? Tell me what's wrong.`

Then stop. Optionally, when the change is risky, offer `/mission-control:quiz` before launch, in one line above the ending.

**"launch" given up front** (in $ARGUMENTS or with the request, before the user has seen this briefing): still show the briefing in full, then act as in step 5, which stops at the first failed gate.

## 5. Captain autonomy

**Inside the mission, at any level:** the Captain and crew may create the mission branch, crew branches and worktrees, and commit on them. That's internal working state. Autonomy controls only what reaches **the user's branch** and **the remote**.

| Level | Captain does after "launch" | Leaves to the human |
|---|---|---|
| `recommend` | nothing on the user's branch or remote; proposes commits. Worktree mode off | everything |
| `commit` **(default)** | organizes local commits on the user's branch (merging the mission branch, if there is one) | push, PR, merge, deploy |
| `push` | + pushes the branch, opens a PR | merge, deploy |
| `merge` | + merges the PR | deploy |
| `deploy` | + releases/deploys with the project's documented command, writes the changelog and version | none (still briefed after) |

- **Precedence:** brief's **Autonomy** > `config.md` > default `commit`. (`config.md` is `.mission-control/config.md`, plain `key: value` lines; a missing file or field means the default.)
- **Gates (all levels above `commit`):** the action happens only if the verdict is **verified**, there are **no open "needs your call" items**, and **no open parked crew questions** for the mission. Otherwise the Captain stops and reports what's blocking, whatever the level.
  Check all three right before acting: `verdict: verified` in `state.md`; no `- [ ]` line under its `## Needs your call`; and `park.sh list --mission <mission-id> --crew-only` prints `nothing parked`.
- **Never inferred:** force-push, history rewrite, deleting remote branches, and a prod deploy without a documented deploy command. These need an explicit instruction in the session, whatever the level.
- Commits follow the repo's existing message conventions and identity. Commit messages carry no attribution beyond what the host requires.

## 6. On the user's answer

**Launch:** act up to the autonomy level, and recommend the rest.
1. **`commit` part** (levels `commit` and above): make the commits shown under **Commits**.
   - Subagent mode (`mission-branch: none`): commit directly on the user's branch.
   - Worktree or mixed mode: merge `mc/<mission-id>` into the user's branch, organizing the local commits. A conflict stops the launch: `git merge --abort`, add a `- [ ] … · plan` item naming the files, and ask. Then remove the mission worktree only if it's clean (`git -C "<worktree>" status --porcelain` prints nothing) and its branch is merged: `git -C "<root>" worktree remove "<worktree>"`. Never with `--force`; a worktree that isn't clean or merged stays, and you list it.
2. **Above `commit`:** check the gates. If any fails, stop: do nothing further on the remote, and report exactly what's blocking (the verdict, each open item, each parked crew question by #). Otherwise push and open the PR (`push`), merge it (`merge`), and at `deploy` write the changelog entry and version, then release with the project's documented deploy command. No documented command: stop and ask, never infer one.
3. **Trackers:** only if the brief's **Tracker** asks for updates (statuses, PR/commit links, the changelog entry). Post exactly what the briefing showed, with whatever connector the host has for that tool. No connector: give ready-to-paste drafts. If **Tracker** is empty or says nothing about updating, touch no tracker.
4. **Changelog to file:** only at `deploy`, or when the user asks for it.
5. Set `status: launched` in `state.md` once everything the level allows is done. If a gate or a conflict stopped you, keep `status: landed`.
6. Report what was done, with the commands' real output (commit hashes, PR URL), and what's left to the human.

**Iterate:** back to `/mission-control:execute` with the user's notes as a new or amended assignment. Keep `status: landed` until execute moves it.

**Rethink:** back to `/mission-control:brief` (or `/mission-control:explore`). Keep `status: landed`.

**Re-run:** run `/mission-control:execute` again with the same brief, e.g. after an environment fix.

**Answers to "needs your call" items**, one at a time, most important first:
- mark each in `state.md` as `- [x] <item> · <source> → <the user's answer>`;
- a parked crew question: also `bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" remove <N>`, and add it to `state.md` as resolved (`- [x] <question> · crew #N → <answer>`) if it wasn't there. If the answer differs from the crew's assumption, the work has to change before launch: offer **iterate**.

Once the last open item is answered, show the gates again and ask `Launch, iterate, rethink, or re-run?`.
