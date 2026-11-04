# same-page evals

Behavior tests for the commands, run with `claude plugin eval` against a small TypeScript fixture project ("catering", Spanish business / English code) with planted drift, an untested rule and ambiguous terms.

## Run

From `plugins/same-page/`:

```bash
claude plugin eval . --scaffold --trust-plugin --no-publish            # all cases, 3 runs each
claude plugin eval . --case 'check-*' --scaffold --trust-plugin --runs 1 --no-publish
```

`--scaffold` is required: each case builds its workspace with a scaffold script.

## Layout

```text
evals/
  fixtures/
    catering/        the fixture project
    setup.sh         copy fixture into the case workspace, git init + baseline commit, apply a variant
    new-case.sh      write a case's scaffold.sh: fixtures/new-case.sh <case-dir> <variant>
  <case>/
    case.yaml        schema_version, name, context.scaffold_script: scaffold.sh
    scaffold.sh      one-line wrapper: exec ../fixtures/setup.sh <variant>
    prompt.md        frontmatter (max_turns, allowed_tools) + the user prompt
    graders/*.md     llm graders (frontmatter type: llm, weight)
```

Variants: `clean` (baseline), `diff` (uncommitted `src/proposals/offer-discount.ts` with drift), `no-glossary`, `root-glossary` (glossary at `GLOSSARY.md`).

## Scaffold mechanics (verified)

- `scaffold_script` goes in `case.yaml` under `context:`. It is not a valid `prompt.md` frontmatter key.
- The path must be inside the case dir (no `..`). Hence the per-case `scaffold.sh` wrapper.
- The script runs with cwd = the agent's workspace (`<sandbox>/home/cwd`), and `$0` is the script's absolute path in this repo. That's how `setup.sh` finds `catering/`.
- `HOME` is sandboxed and `GIT_CONFIG_NOSYSTEM=1`, so `setup.sh` sets a local git identity.
- `claude plugin validate` warns `ICON_MISSING` for this plugin. That's harmless (same as the other plugins here).
