# Assignment template

Every crew assignment uses exactly these sections, in this order, in both modes. In subagent mode the filled-in text is the subagent's whole prompt. In worktree mode it is saved as `.mission-control/missions/<id>/assignments/<crew-id>.md` in the main repo. The same text works in either mode, so an assignment can be promoted from subagent to worktree unchanged.

Fill every `<…>` before handing it out. The Standing orders are fixed text: copy them verbatim, filling only the park command's absolute paths, crew id and mission id.

~~~markdown
# Assignment: <crew-id> · mission <mission-id>

## Role
<researcher | engineer | reviewer | comms | other named role>

## Task
<one concrete outcome, in plain words; what the brief says about it>

## Owns
<the files or areas this assignment may change, one per line>
<or: read-only (changes nothing)>

## Brings back
- Findings: <what to report>
- Changes made: <files and what changed, or "none" for read-only>
- Problems: <anything that went wrong or looks wrong>
- Open questions: <questions you parked or were blocked on, with the assumption you took>
<worktree mode: write this report to <abs path to reports/<crew-id>.md>>

## Verify with
<the exact checks to run on your own work, from the brief's Verified means narrowed to this assignment, e.g. `npm test`, or for research: cite file:line for every claim and re-open each cited line>

## Mode
<subagent | worktree session (worktree: <abs worktree path>, branch mc/<mission-id>/<crew-id>)>

## Order
<parallel group N | after <crew-id> | runs alone>

## Standing orders
- Stay inside **Owns**. Do not change anything outside it. If the task needs a change outside it, stop and report that as blocked.
- A question the brief doesn't cover and that is risky (security, data, money, deploy, user-facing behavior, public APIs, anything hard to reverse): stop and report it as blocked. Do not guess.
- Any other question the brief doesn't cover: park it, take the most reversible option, record the assumption in your report, and continue. Park with exactly this command (the question goes on stdin):

  ```bash
  PARKED_FILE=<abs main repo>/.mission-control/parked.md bash <abs path to park.sh> add --crew <crew-id> --mission <mission-id> --assumed "<assumption>" <<'PARKED_NOTE'
  <the question>
  PARKED_NOTE
  ```

- Before reporting, self-check with **Verify with** and paste its output verbatim. Only report checks you actually ran after your last change.
- Only self-check. Never run `/mission-control:verify` and never start reviewer agents yourself.
~~~
