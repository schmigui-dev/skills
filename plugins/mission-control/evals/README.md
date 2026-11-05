# mission-control evals

Behavior tests for the skills, run with `claude plugin eval` against a small TypeScript fixture project ("shop") with a changelog, a ticket (`docs/tickets/SHOP-12.md`) and a few tests. Same mechanics as `same-page/evals`.

## Run

From `plugins/mission-control/`:

```bash
FLAGS="--scaffold --trust-plugin --allow-tools Write Edit Bash --judge-model sonnet --no-publish"
claude plugin eval . $FLAGS                                  # all cases, 3 runs each
claude plugin eval . $FLAGS --case smoke --runs 1
```

- `--scaffold`: each case builds its workspace with a scaffold script.
- `--allow-tools Write Edit Bash`: cases list these tools and the operator has to grant them.
- `--judge-model sonnet`: the default Haiku judge misgrades long reports. Sonnet is stable.

## Layout

```text
evals/
  fixtures/
    shop/            the fixture project
    setup.sh         copy fixture into the case workspace, git init + baseline commit, apply a variant
    new-case.sh      write a case's scaffold.sh + case.yaml: fixtures/new-case.sh <case-dir> <variant>
  <case>/
    case.yaml        schema_version, name, context.scaffold_script: scaffold.sh
    scaffold.sh      one-line wrapper: exec ../fixtures/setup.sh <variant>
    prompt.md        frontmatter (max_turns, allowed_tools) + the user prompt
    graders/*.md     llm graders (frontmatter type: llm, weight)
```

Variants: `clean` (baseline), `parked` (parking lot + a landed mission), `recommend` (`config.md` with `autonomy: recommend`), `landed-gated` (landed, verified saved-carts mission with uncommitted work, `autonomy: push`, parked crew questions #2 and #3 open), `landed-clean` (same at `autonomy: commit`, crew questions answered), `two-missions` (`landed-clean` plus a wishlist mission in flight). Later tasks add more.

## Scaffold mechanics (verified in same-page)

- `scaffold_script` goes in `case.yaml` under `context:`, not in `prompt.md` frontmatter.
- The path must be inside the case dir (no `..`), hence the per-case `scaffold.sh` wrapper.
- The script runs with cwd = the agent's workspace, and `$0` is its absolute path in this repo. That's how `setup.sh` finds `shop/`.
- `HOME` is sandboxed and `GIT_CONFIG_NOSYSTEM=1`, so `setup.sh` sets a local git identity.
- git doesn't run inside the eval sandbox on macOS (the `/usr/bin/git` xcrun shim can't write its cache). Git-dependent cases are graded from the transcript.
- `setup.sh` refuses to run outside an empty workspace.
- `claude plugin validate` warns `ICON_MISSING`. Harmless.
