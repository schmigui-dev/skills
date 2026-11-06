# mission-control Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the `mission-control` plugin (11 skills, Stop guard, project-local parking and mission state), which replaces `no-surrender` in the `schmigui` marketplace.

**Architecture:** A mostly prompt-only plugin: one `SKILL.md` per skill plus a shared `conventions.md`. Two bash scripts hold the logic that must be deterministic (locked parking writes, `.mission-control/` setup) and get real shell tests. The Stop guard is moved from no-surrender and gets a shell test too. Skill behavior is tested with `claude plugin eval` against a small TypeScript fixture project (`shop`). Each skill task adds its eval cases first (they fail, since the skill doesn't exist yet), then writes the skill until they pass.

**Tech Stack:** Claude Code plugin format (`.claude-plugin/plugin.json`, `skills/*/SKILL.md`, `hooks/hooks.json`), bash, awk, jq (hook only), git, `claude plugin validate`, `claude plugin eval` (llm + `tool_used` graders, `scaffold_script`).

**Spec:** `docs/superpowers/specs/2026-11-05-mission-control-design.md`. Read it fully before starting any task. Each task names the spec sections it implements, and skill bodies must cover every rule in those sections.

## Global Constraints

- Repo: `/Users/guillermo.schmithalter/Documents/projects/skills`. Work on a new branch `mission-control` created from the current `same-page` HEAD (it contains the spec commit `b768307`). `same-page` is unmerged, so `mission-control` merges after it.
- Git identity: repo-local `user.email` must be `gschmithalter14@gmail.com`. Check before the first commit. Push only via `git@github.com-personal:schmigui-dev/skills.git`, and only if the user asks. Every commit message starts `mission-control: ` and ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Plugin path `plugins/mission-control/`. `plugin.json`: name `mission-control`, version `0.1.0`, license `MIT`, author `Guillermo Schmithalter` / `https://github.com/schmigui-dev`, homepage `https://github.com/schmigui-dev/skills/tree/main/plugins/mission-control`, repository `https://github.com/schmigui-dev/skills`, keywords `["orchestration", "agents", "verification", "critical-thinking", "workflow", "shipping"]`.
- Description (plugin.json, marketplace, root README): `Run agent work like a space mission. Brief and explore before, orchestrate a crew of agents, verify in layers, park questions instead of guessing, and make the go/no-go call before you ship.`
- Skills: `explore, brief, blindspots, execute, verify, evidence, decisions, quiz, go-no-go, park, parked`. Frontmatter: `name`, `description`, `argument-hint` (where it takes args). `disable-model-invocation: true` on all **except `execute` and `verify`**.
- Every SKILL.md references `${CLAUDE_SKILL_DIR}/../../conventions.md` and restates in one line the conventions it relies on.
- Proposing skills (explore, brief, blindspots, execute, verify plan, decisions, go-no-go) end their proposal with a question containing "what's wrong". Never "looks good?", "ok?", "shall I proceed?".
- Cross-references use `/mission-control:<skill>`. No `/no-surrender:` or bare `/brief` references remain anywhere in the plugin.
- No tracker-specific code (no Notion/Jira/Linear names in instructions except as examples). No dependency on Orca, superpowers or any agent app.
- The plugin never adds permission flags to `crew-command`.
- State paths: `.mission-control/{.gitignore,config.md,parked.md,missions/<id>/{brief.md,state.md,assignments/,reports/}}`. Mission id `YYYY-MM-DD-<slug>`. Branches `mc/<mission-id>` (mission) and `mc/<mission-id>--<crew-id>` (crew; `--`, not `/`, since git can't hold both `mc/<id>` and `mc/<id>/x` as refs). Crew worktree path `../<repo>-mc-<crew-id>`. Mission worktree `<parent>/<repo>-mc-<mission-id>`, where crew branches merge into `mc/<mission-id>`; the user's checkout is never switched.
- Autonomy levels exactly `recommend | commit | push | merge | deploy`, default `commit`. Precedence: brief **Autonomy** > `config.md` > default.
- Stop guard env vars: `MISSION_CONTROL_STOP_GUARD=off` and legacy `NO_SURRENDER_STOP_GUARD=off` both disable it. Message prefix `mission-control:`.
- Evals: same harness conventions as `plugins/same-page/evals` (`case.yaml` with `context.scaffold_script: scaffold.sh`, `prompt.md` frontmatter `max_turns`/`allowed_tools`, `graders/*.md` llm graders). git doesn't run inside the eval sandbox, so git-dependent behavior is graded from the transcript. Run with `--judge-model sonnet`.

## Review Focus

1. **Crew in a worktree parks to the worktree, not the main repo.** In a worktree, `git rev-parse --show-toplevel` is the worktree. Expected: every assignment's standing orders set `PARKED_FILE=<main repo>/.mission-control/parked.md` explicitly. Pinned in Task 2 (test that `PARKED_FILE` wins) and Task 6 (grader on the assignment text).
2. **Many crew members park at once.** Expected: unique, consecutive IDs and no lost lines. Pinned in Task 2 (`test_parallel_adds`).
3. **"check" in an ordinary sentence** ("check out this file and explain it"). Expected: `verify` does not fire. Pinned in Task 7 (`verify-no-trigger`).
4. **Two unfinished missions.** Expected: `go-no-go`/`decisions` ask which one instead of picking. Pinned in Task 8 (`go-no-go-two-missions`).
5. **Users with the old no-surrender opt-out set.** Expected: the guard stays off. Pinned in Task 4 (`test_legacy_env_off`).

---

### Task 1: Branch, plugin skeleton, conventions, fixture and eval harness

Spec: "The metaphor", "Shared conventions", "Plugin layout and conventions", "Evals".

**Files:**
- Create: `plugins/mission-control/.claude-plugin/plugin.json`
- Create: `plugins/mission-control/conventions.md`
- Create: `plugins/mission-control/evals/README.md`
- Create: `plugins/mission-control/evals/fixtures/shop/` (contents below)
- Create: `plugins/mission-control/evals/fixtures/setup.sh`, `plugins/mission-control/evals/fixtures/new-case.sh`
- Create: `plugins/mission-control/evals/smoke/{case.yaml,scaffold.sh,prompt.md,graders/criteria.md}`

**Interfaces:**
- Produces `conventions.md` with five numbered sections whose headings later skills cite: `1. Playback`, `2. One question at a time`, `3. Stop on risky gaps`, `4. Evidence over claims`, `5. Depth matches stakes`, plus a short "Cast" table (Flight Director / Captain / Crew roles). Content is the spec's "Shared conventions" and "The metaphor".
- Produces `evals/fixtures/setup.sh <variant>`, a copy of same-page's guard-then-copy pattern (refuse a non-empty dir, copy `shop/`, `git init`, identity `fixture@example.com`, baseline commit), then applies the variant. Variants are added by later tasks. Task 1 defines `clean`.
- Produces `evals/fixtures/new-case.sh <case-dir> <variant>`, which writes the one-line `scaffold.sh` wrapper (`exec "$(dirname "$0")/../fixtures/setup.sh" <variant>`) and `case.yaml`.
- Produces the fixture `shop` (TypeScript, no install needed):
  - `package.json`: name `shop`, version `1.4.0`, script `"test": "node --test tests/"`
  - `CHANGELOG.md`: Keep a Changelog format with `## [1.4.0] - 2026-10-01` / `### Added` / `- Gift cards at checkout.`
  - `src/cart/cart.ts`: `class Cart` with `add(item)`, `remove(id)`, `total()`
  - `src/cart/discount.ts`: `applyDiscount(cart, code)` with a hardcoded `SAVE10` code
  - `src/checkout/checkout.ts`: `checkout(cart, payment)` calling `cart.total()`
  - `src/api/routes.ts`: `POST /cart/items`, `POST /checkout`
  - `tests/cart.test.ts`: tests for `add` and `total`
  - `docs/tickets/SHOP-12.md`: an epic "Saved carts" with description, 3 acceptance criteria ("A signed-in user's cart persists across sessions", "Saved carts expire after 30 days", "Checkout of a saved cart re-validates prices"), and one comment asking about guest users.
  - `CLAUDE.md`: one line, "Run `npm test` before claiming tests pass."

- [ ] **Step 1: Create the branch and check identity**

Run: `git switch -c mission-control && git config user.email`
Expected: `Switched to a new branch 'mission-control'` and `gschmithalter14@gmail.com`.

- [ ] **Step 2: Write `plugin.json` and `conventions.md`, then validate**

Run: `claude plugin validate plugins/mission-control`
Expected: pass (an `ICON_MISSING` warning is fine, same as the other plugins).

- [ ] **Step 3: Write the fixture, `setup.sh`, `new-case.sh`, and the smoke case**

Smoke case: variant `clean`, prompt "List the files under src/ and summarize docs/tickets/SHOP-12.md in one line.", grader passes if the response names `src/cart/cart.ts`, `src/checkout/checkout.ts` and "Saved carts".

- [ ] **Step 4: Run the smoke eval**

Run (from `plugins/mission-control/`): `claude plugin eval . --scaffold --trust-plugin --allow-tools Write Edit Bash --judge-model sonnet --no-publish --case smoke --runs 1`
Expected: smoke PASS. Write the run command and the variant list in `evals/README.md`.

- [ ] **Step 5: Commit**

```bash
git add plugins/mission-control
git commit -m "mission-control: plugin skeleton, conventions, shop fixture, eval harness"
```

### Task 2: State scripts (`mc-init.sh`, `park.sh`) with shell tests

Spec: "Project-local state", "park / parked".

**Files:**
- Create: `plugins/mission-control/scripts/mc-init.sh`
- Create: `plugins/mission-control/scripts/park.sh` (start from `plugins/parking-lot/scripts/park.sh`)
- Test: `plugins/mission-control/scripts/test-scripts.sh`

**Interfaces:**
- Produces `mc-init.sh [dir]`: resolves the project root (`dir`, else `git rev-parse --show-toplevel`, else `pwd`), creates `<root>/.mission-control/` if missing, writes `.mission-control/.gitignore` if missing with exactly the three lines `*`, `!.gitignore`, `!config.md`, and prints the absolute `.mission-control` path. Idempotent.
- Produces `park.sh`, with the same lock and atomic-write mechanics as parking-lot's. Default file `$(mc-init.sh)/parked.md`. `PARKED_FILE` overrides it, and then `mc-init.sh` is **not** called.
  - `park.sh add [--crew <crew-id>] [--mission <mission-id>] [--assumed <text>]`, note on stdin → `parked #N`. Line formats:
    - human: `- #N · YYYY-MM-DD · <note>`
    - crew: `- #N · YYYY-MM-DD · [crew:<crew-id> · mission:<mission-id>] <note> — assumed: <text>` (`--crew` requires `--mission`; ` — assumed: …` only when `--assumed` is given)
  - `park.sh list [--mission <id>] [--crew-only] [--oldest]` → matching lines, newest first by default. `nothing parked` (exit 0) when there are none.
  - `park.sh get <id>` → note text (including the tag block). `park.sh remove <id>...` → `removed #N` / `#N not found`.
  - `replace`, `merge` and `reindex` are dropped. Unknown command → `usage: park.sh add|list|get|remove` on stderr, exit 1.

- [ ] **Step 1: Write the failing tests**

`test-scripts.sh` is plain bash: each `test_*` function runs in a fresh `mktemp -d` with `PARKED_FILE` unset unless the test sets it, and prints `ok <name>` / `FAIL <name>: <detail>`, exiting non-zero on any failure. Tests:
- `test_init_creates_gitignore`: in a fresh `git init` dir, `mc-init.sh` prints `<dir>/.mission-control`, and `.gitignore` is exactly `*\n!.gitignore\n!config.md\n`. A second run leaves it byte-identical.
- `test_add_human`: `echo "idea" | park.sh add` → `parked #1`, and the file has `- #1 · <today> · idea`.
- `test_add_crew`: `echo "guest carts?" | park.sh add --crew engineer-1 --mission 2026-11-05-saved-carts --assumed "guests excluded"` → the line ends `· [crew:engineer-1 · mission:2026-11-05-saved-carts] guest carts? — assumed: guests excluded`.
- `test_crew_requires_mission`: `--crew` without `--mission` exits 1 and writes nothing.
- `test_list_filters`: with one human and two crew notes (missions A and B), `list --mission A --crew-only` prints exactly the A line.
- `test_list_empty`: `list` on a missing file prints `nothing parked` and exits 0.
- `test_parked_file_wins`: with `PARKED_FILE=$tmp/elsewhere/p.md` inside a git repo, `add` writes there and creates no `.mission-control/` dir.
- `test_parallel_adds`: 20 background `add` calls, then `wait` → IDs 1–20 each appear exactly once and `next-id` is 21.
- `test_remove`: `remove 1 9` → `removed #1` and `#9 not found`.

- [ ] **Step 2: Run them to see them fail**

Run: `bash plugins/mission-control/scripts/test-scripts.sh`
Expected: FAIL (scripts missing).

- [ ] **Step 3: Implement `mc-init.sh` and `park.sh`**

Keep parking-lot's `acquire_lock`/`rewrite`/`read_note`/`parse_ids` as they are. Parse flags for `add` and `list` with a `while [ $# -gt 0 ]; case` loop. `list` filters with `grep -F "mission:<id>]"` and `grep -F "[crew:"`.

- [ ] **Step 4: Run the tests to see them pass**

Run: `bash plugins/mission-control/scripts/test-scripts.sh`
Expected: every line `ok …`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add plugins/mission-control/scripts
git commit -m "mission-control: project-local state and parking scripts with tests"
```

### Task 3: `park` and `parked` skills

Spec: "park / parked".

**Files:**
- Create: `plugins/mission-control/skills/park/SKILL.md`, `plugins/mission-control/skills/parked/SKILL.md`
- Create evals: `evals/park-human/`, `evals/parked-crew/`
- Modify: `evals/fixtures/setup.sh` (variant `parked`)

**Interfaces:**
- Consumes: `park.sh add|list|get|remove` (Task 2), called as `bash "${CLAUDE_SKILL_DIR}/../../scripts/park.sh" …`.
- Produces: fixture variant `parked`, which writes `.mission-control/parked.md` with next-id 4 and: `#1` human "try a dark theme", `#2` crew `engineer-1` mission `2026-11-05-saved-carts` "should guest carts persist?" assumed "guests excluded", `#3` crew `researcher-1` same mission "30 days from creation or last edit?" assumed "from last edit". It also writes `.mission-control/missions/2026-11-05-saved-carts/state.md` (format in Task 6) with `status: landed`.

- [ ] **Step 1: Write the failing evals**
  - `park-human` (variant `clean`): prompt `/mission-control:park "max cart size?"`. Graders: the response is `parked #1` with no discussion of the note. `.mission-control/parked.md` contains `· max cart size?`. A `tool_used` grader for `Edit` with max 0 (the file is written by the script only).
  - `parked-crew` (variant `parked`): prompt `/mission-control:parked crew`. Graders: lists #2 and #3 with their crew and mission tags and assumptions, does **not** list #1, and ends asking which # to discuss.

- [ ] **Step 2: Run them to see them fail**

Run: `claude plugin eval . --scaffold --trust-plugin --allow-tools Write Edit Bash --judge-model sonnet --no-publish --case 'park*' --runs 1`
Expected: FAIL (no skills).

- [ ] **Step 3: Write both skills**

`park`: frontmatter `name: park`, `disable-model-invocation: true`, `argument-hint: "\"the idea/question\""`. Body as parking-lot's `park`, but using this plugin's script. `parked`: `argument-hint: "[oldest] [crew] [mission <id>]"`. Body as parking-lot's `parked`, but listing through `park.sh list` with the matching flags, showing tags, and removing through `park.sh remove`.

- [ ] **Step 4: Run the evals to see them pass**

Same command. Expected: both PASS.

- [ ] **Step 5: Commit** — `git commit -m "mission-control: park and parked"`

### Task 4: Move no-surrender's report skills and Stop guard

Spec: "blindspots, evidence, quiz", "Stop guard".

**Files:**
- Create: `plugins/mission-control/skills/{blindspots,evidence,quiz}/SKILL.md` (copied from `plugins/no-surrender/skills/…`)
- Create: `plugins/mission-control/hooks/hooks.json`, `plugins/mission-control/hooks/stop-guard.sh` (copied)
- Test: `plugins/mission-control/hooks/test-stop-guard.sh`

**Interfaces:**
- Produces: `stop-guard.sh`, unchanged except: the guard is off when `MISSION_CONTROL_STOP_GUARD=off` **or** `NO_SURRENDER_STOP_GUARD=off`; `REASON` begins `mission-control:`; the header comment names mission-control. `hooks.json` description begins `mission-control:`.

- [ ] **Step 1: Write the failing hook test**

`test-stop-guard.sh` builds a synthetic JSONL transcript in a temp dir: one user entry with string content, then an assistant entry with a `tool_use` `Edit`, then an assistant `text` entry. It pipes `{"transcript_path": …, "stop_hook_active": false, "last_assistant_message": <text>}` into `bash stop-guard.sh`. Tests:
- `test_blocks_missing_sections`: text `done` → stdout JSON with `.decision == "block"` and `.reason` starting `mission-control:` and naming `Evidence and Decisions`.
- `test_passes_with_sections`: text `## Evidence\n…\n## Decisions\nnone` → empty stdout.
- `test_no_edits_passes`: transcript without the `Edit` tool_use → empty stdout.
- `test_env_off`: `MISSION_CONTROL_STOP_GUARD=off` → empty stdout.
- `test_legacy_env_off`: `NO_SURRENDER_STOP_GUARD=off` → empty stdout.
- `test_active_passes`: `stop_hook_active: true` → empty stdout.

- [ ] **Step 2: Run it to see it fail**

Run: `bash plugins/mission-control/hooks/test-stop-guard.sh`
Expected: FAIL (hook missing, or the prefix and legacy-env tests fail on a plain copy).

- [ ] **Step 3: Copy the hook and skills, apply the changes**

In the three skills: replace every `/blindspots`, `/evidence`, `/decisions`, `/quiz`, `/brief` reference with `/mission-control:<name>`, add the conventions reference line, and make the closing questions in `blindspots` and `evidence` follow convention 1.

- [ ] **Step 4: Run the test and validate**

Run: `bash plugins/mission-control/hooks/test-stop-guard.sh && claude plugin validate plugins/mission-control && ! grep -rn "no-surrender\|/brief\b\|/evidence\b" plugins/mission-control/skills`
Expected: all `ok`, validate passes, grep prints nothing.

- [ ] **Step 5: Commit** — `git commit -m "mission-control: blindspots, evidence, quiz and Stop guard from no-surrender"`

### Task 5: `explore` and `brief`

Spec: "explore", "brief", "Trackers" (read part).

**Files:**
- Create: `plugins/mission-control/skills/explore/SKILL.md`
- Create: `plugins/mission-control/skills/brief/SKILL.md` (from `plugins/no-surrender/skills/brief/SKILL.md`)
- Create evals: `evals/explore-no-code/`, `evals/brief-from-ticket/`, `evals/brief-playback/`

**Interfaces:**
- Produces the brief template used by Tasks 6–8. It's no-surrender's template plus two fields after **Constraints**: `**Autonomy:** <recommend|commit|push|merge|deploy — blank = config/default>` and `**Tracker:** <what to read/write where, in the user's words — blank = no tracker>`.

- [ ] **Step 1: Write the failing evals**
  - `explore-no-code` (clean): prompt `/mission-control:explore I'm thinking about adding wishlists to the shop`. Graders: asks an open question about a real situation (not a list of options), makes no Edit/Write (`tool_used` max 0 for both), no implementation plan.
  - `brief-from-ticket` (clean): prompt `/mission-control:brief docs/tickets/SHOP-12.md`. Graders: the draft brief maps the three acceptance criteria into **Done means**/**Verified means**, has **Autonomy** and **Tracker** fields, marks inferences `(my guess)`, asks the hypothesis question and raises guest users as open, and asks one question at a time.
  - `brief-playback` (clean): prompt `/mission-control:brief "add a SAVE20 discount code" — hypothesis: same as SAVE10; I care that totals never go negative; just guess the rest.` Graders: shows the full brief and ends with a question containing "what's wrong", with no "looks good"/"ok?" phrasing.

- [ ] **Step 2: Run them to see them fail**

Run: `claude plugin eval . … --case 'explore-*' --case 'brief-*' --runs 1` (flags as in Task 3)
Expected: FAIL.

- [ ] **Step 3: Write both skills**

`explore`: `disable-model-invocation: true`, `argument-hint: "[idea]"`. Body covers every bullet in spec "explore" and ends with the direction playback plus the offer of `/mission-control:brief`. `brief`: apply every change listed in spec "brief", including ticket input (read through any available connector, else ask the user to paste it; a local file path is read directly) and the offer of `/mission-control:execute` at the end.

- [ ] **Step 4: Run the evals to see them pass** — same command, all PASS.

- [ ] **Step 5: Commit** — `git commit -m "mission-control: explore and brief"`

### Task 6: `execute`

Spec: "execute", "Captain autonomy" (worktree mode off at `recommend`), "Trackers" (write tickets), "Project-local state" (mission files and state).

**Files:**
- Create: `plugins/mission-control/skills/execute/SKILL.md`
- Create: `plugins/mission-control/skills/execute/assignment-template.md`
- Create evals: `evals/execute-trigger/`, `evals/execute-plan-first/`, `evals/execute-no-overlap/`, `evals/execute-recommend-no-worktree/`
- Modify: `evals/fixtures/setup.sh` (variant `recommend`: writes `.mission-control/config.md` with `autonomy: recommend`)

**Interfaces:**
- Consumes: `mc-init.sh`, `park.sh add --crew --mission --assumed` (Task 2); the brief template (Task 5).
- Produces the `state.md` format that Tasks 7–8 read and write:

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

A resolved item becomes `- [x] … → <the user's answer>`.
- Produces `assignment-template.md`, the exact sections every assignment has: `Role`, `Task`, `Owns` (paths, or `read-only`), `Brings back`, `Verify with`, `Mode`, `Order`, and `Standing orders`. The standing orders text is fixed: stay inside Owns; risky gaps → stop and report blocked; other gaps → `PARKED_FILE=<abs main repo>/.mission-control/parked.md bash <abs park.sh> add --crew <crew-id> --mission <id> --assumed "<assumption>"`, then take the most reversible option; self-check with Verify with, with verbatim output; never run verify or start reviewer agents.
- Frontmatter, `description` exactly: `Use when work should be delegated, orchestrated, split up or parallelized across agents ("send an agent to…", "have one agent research X and another Y", "get a crew on this"), or when the user says go on a confirmed mission-control brief. The Captain plans the flight (assignments, file ownership, how each crew member verifies), shows it before touching code, then runs the crew as subagents or git-worktree sessions.` Also `argument-hint: "[task — defaults to the confirmed brief]"`, and **no** `disable-model-invocation`.

- [ ] **Step 1: Write the failing evals**
  - `execute-trigger` (clean): prompt (no slash command) `I want saved carts (see docs/tickets/SHOP-12.md). Send one agent to look at how the cart is stored now, another to check how checkout computes prices, then put it together and propose a plan before touching code.` Graders: a flight plan with at least two read-only research assignments, each with **Verify with** and **Brings back**. No Edit/Write before the plan (`tool_used` max 0, since the run ends at the playback). Ends with "what's wrong".
  - `execute-plan-first` (clean): prompt `/mission-control:execute add a SAVE20 code and show the discount on the checkout response`. Graders: shows the plan before any change, `tool_used` Edit max 0 and Write max 0, ends with "what's wrong".
  - `execute-no-overlap` (clean): prompt `/mission-control:execute in parallel: (a) add SAVE20 to discount.ts, (b) make discount codes case-insensitive in discount.ts, (c) add a GET /cart route in routes.ts`. Graders: (a) and (b) are sequenced or merged because both own `src/cart/discount.ts`, and (c) may run in parallel. The plan states the overlap reason.
  - `execute-recommend-no-worktree` (variant `recommend`): prompt `/mission-control:execute big refactor: split cart.ts into cart-items.ts and cart-totals.ts and update every importer`. Graders: every assignment is mode `subagent`, and the plan says worktree mode is off at `recommend`. No `git worktree` command is attempted (transcript).

- [ ] **Step 2: Run them to see them fail** — `--case 'execute-*' --runs 1`, all FAIL.

- [ ] **Step 3: Write `execute/SKILL.md` and `assignment-template.md`**

The body follows spec "execute" steps 1–5, in that order and with those headings. It writes `brief.md` and `state.md` (status `planning`, then `flight`, then `landed`) via `mc-init.sh`. Tickets get created only if the brief's Tracker says so, and they're listed in the plan first. Worktree launch uses `crew-command` verbatim, or prints the command for the user. Land by invoking `/mission-control:verify`.

- [ ] **Step 4: Run the evals to see them pass** — all PASS. The trigger case must pass 2 of 3 runs at `--runs 3`.

- [ ] **Step 5: Commit** — `git commit -m "mission-control: execute"`

### Task 7: `verify`

Spec: "verify".

**Files:**
- Create: `plugins/mission-control/skills/verify/SKILL.md`
- Create evals: `evals/verify-trigger/`, `evals/verify-no-trigger/`, `evals/verify-command/`

**Interfaces:**
- Consumes: the `evidence` report format (Task 4), `state.md` (Task 6): sets `verdict:`.
- Produces: output with `## Evidence` (checks, proves / doesn't prove, not checked, verdict) and `## Decisions` headings, so the Stop guard passes.
- Frontmatter `description` exactly: `Use whenever a plan, brief, assignment or message says how work must be checked ("make sure…", "confirm that…", "check it works in the browser", "test that…", "prove it", "don't ship until…"), or when asked to verify work. Runs layered verification (a fresh reviewer, then the final checks) and reports evidence with real output. Not for crew members working on a mission-control assignment: they only self-check.` Also `argument-hint: "[what to verify / how]"`, and **no** `disable-model-invocation`.

- [ ] **Step 1: Write the failing evals**
  - `verify-trigger` (clean): prompt (no slash command) `Make total() round to 2 decimals, and make sure it's right by running the tests and showing me a total for 3 items at 0.1.` Graders: the response has `## Evidence` with the actual test command and verbatim output (or an explicit "not run" with a reason if node is unavailable), a proves / doesn't-prove line, and a verdict. A reviewer pass is mentioned as run or skipped-with-reason.
  - `verify-no-trigger` (clean): prompt `check out src/cart/discount.ts and explain how codes work`. Graders: an explanation only, with no `## Evidence` section and no verification run.
  - `verify-command` (clean): prompt `/mission-control:verify checkout never charges a negative total`. Graders: proposes a verify plan ending "what's wrong" **or** runs only obvious read-only checks. Reports `Doesn't prove` honestly (no test covers negative totals today).

- [ ] **Step 2: Run them to see them fail** — `--case 'verify-*' --runs 1`, the trigger and command cases FAIL.

- [ ] **Step 3: Write `verify/SKILL.md`**

Cover the three layers, the scaling rules, defining "verified" when nothing says how, and the reviewer's inputs (brief + diff, not the builders' reasoning), all per spec "verify".

- [ ] **Step 4: Run the evals to see them pass** — all PASS. `verify-trigger` and `verify-no-trigger` must each pass 2 of 3 runs at `--runs 3`.

- [ ] **Step 5: Commit** — `git commit -m "mission-control: verify"`

### Task 8: `decisions`, `go-no-go` (autonomy, changelog, tracker updates)

Spec: "decisions", "go-no-go", "Captain autonomy", "Changelog and version", "Trackers" (update part).

**Files:**
- Create: `plugins/mission-control/skills/decisions/SKILL.md` (from no-surrender)
- Create: `plugins/mission-control/skills/go-no-go/SKILL.md`
- Create evals: `evals/go-no-go-gate/`, `evals/go-no-go-briefing/`, `evals/go-no-go-two-missions/`, `evals/decisions-crew/`
- Modify: `evals/fixtures/setup.sh` (variants `landed-gated`, `landed-clean`, `two-missions`)

**Interfaces:**
- Consumes: `state.md` format (Task 6), `park.sh list --mission --crew-only` and `remove` (Task 2).
- Fixture variants (each on top of `clean`, with mission `2026-11-05-saved-carts` and an uncommitted change that adds `src/cart/saved-cart.ts` exporting `saveCart` and `loadCart`):
  - `landed-gated`: `config.md` `autonomy: push`. `state.md` `status: landed`, `verdict: verified`, no open items. The `parked` variant's crew notes #2 and #3.
  - `landed-clean`: as above, but `autonomy: commit` and no parked notes.
  - `two-missions`: `landed-clean` plus a second mission `2026-11-04-wishlist` with `status: flight`.

- [ ] **Step 1: Write the failing evals**
  - `go-no-go-gate` (landed-gated): prompt `/mission-control:go-no-go — launch.` Graders: lists parked crew questions #2 and #3 under Needs your call, refuses to push or open a PR because they're open (transcript shows no `git push` / `gh pr create`), and says what's blocking.
  - `go-no-go-briefing` (landed-clean): prompt `/mission-control:go-no-go`. Graders: the sections come in spec order (Verdict, Needs your call inside `## Decisions`, What changed, Commits, Version and changelog, Recommendation, Autonomy in effect). Proposes `1.5.0` as a minor bump with the reason "new feature". The changelog draft uses the existing `### Added` format and is not written to the file. Ends with "Launch, iterate, rethink, or re-run?" and "what's wrong". Has a `## Evidence` heading.
  - `go-no-go-two-missions` (two-missions): prompt `/mission-control:go-no-go`. Graders: asks which mission (naming both), and doesn't brief until answered.
  - `decisions-crew` (landed-gated): prompt `/mission-control:decisions`. Graders: crew questions #2 and #3 appear under Needs your call with their assumptions, and the closing question asks to confirm or change them.

- [ ] **Step 2: Run them to see them fail** — `--case 'go-no-go-*' --case 'decisions-*' --runs 1`, all FAIL.

- [ ] **Step 3: Write both skills**

`decisions`: no-surrender's skill plus crew questions from the current mission (via `park.sh list`) and writing open items to `state.md`. `go-no-go`: the briefing order; launch / iterate / rethink / re-run; the autonomy table, gates and never-inferred actions, verbatim from the spec; changelog drafting by a comms subagent; tracker updates only if the brief's Tracker says so. Sets `status: launched` or keeps `landed`. Resolves parked crew notes with `park.sh remove` and state items with `[x]`.

- [ ] **Step 4: Run the evals to see them pass** — all PASS.

- [ ] **Step 5: Commit** — `git commit -m "mission-control: decisions and go-no-go"`

### Task 9: README, marketplace swap, remove no-surrender, full run

Spec: "Removing no-surrender", "Portability", "Plugin layout and conventions".

**Files:**
- Create: `plugins/mission-control/README.md`
- Modify: `.claude-plugin/marketplace.json` (remove the `no-surrender` entry, add `mission-control` with source `./plugins/mission-control` and the Global Constraints description)
- Modify: `README.md` (root plugins table: remove the no-surrender row, add mission-control)
- Delete: `plugins/no-surrender/`

**Interfaces:**
- README sections, in order: tagline ("Hand off the work, not the accountability, now with a crew."), the problem (cognitive surrender, folded in from no-surrender), Install (`/plugin install mission-control@schmigui`), Cast, Phases + command table (all 11 skills, marking `execute`/`verify` as also natural-language), Autonomy (table plus gates), Trackers, Parking, Crew sessions (`crew-command` with the example `claude -p --permission-mode acceptEdits --add-dir <main repo path>` and the statement that permissions are the user's job), Stop guard (both env vars, limits, Claude Code-only), Coming from no-surrender (old command → new command table), A typical mission, Why.

- [ ] **Step 1: Write the README, swap the marketplace and root README, delete no-surrender**

- [ ] **Step 2: Validate everything**

Run: `claude plugin validate plugins/mission-control && claude plugin validate . && bash plugins/mission-control/scripts/test-scripts.sh && bash plugins/mission-control/hooks/test-stop-guard.sh && ! grep -rn "no-surrender" .claude-plugin README.md && ! grep -rln "Notion\|Orca\|superpowers" plugins/mission-control/skills`
Expected: everything passes, and the greps print nothing. (Notion is allowed only in the README, as an example.)

- [ ] **Step 3: Full eval run**

Run (from `plugins/mission-control/`): `claude plugin eval . --scaffold --trust-plugin --allow-tools Write Edit Bash --judge-model sonnet --no-publish -j 8`
Expected: every case passes at least 2 of 3 runs. Record flaky cases and their fixes in `evals/README.md`.

- [ ] **Step 4: Commit** — `git commit -m "mission-control: README, marketplace listing, retire no-surrender"`
