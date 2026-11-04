---
name: rules
description: Extract the business rules and invariants in a module, map each to the tests that verify it, and report untested rules, weak tests, implementation-named tests, and gaps between the glossary's rules and the code.
disable-model-invocation: true
argument-hint: "[module — defaults to modules in the current diff]"
---

Verify the business rules in: $ARGUMENTS

For agents, readable code matters less than **verifiable** code: a business rule is only safe to change if a test proves it. Tests named in business language double as an executable spec. Your job is to show which rules are actually verified. You are **read-only**: you may offer to write tests, but don't write them until the user approves.

## 1. Load the glossary

**Finding the glossary** (the same order in every `/same-page` command):
1. `docs/domain/glossary.md`, if it exists.
2. Otherwise, files named `glossary.md`, `GLOSSARY.md` or `ubiquitous-language.md` (any case) anywhere in the repo, skipping `node_modules`, `vendor` and `.git`. Exactly one → use it where it is. **Several → list them, ask which one to use, and stop until the user answers.**

The glossary's field labels are always the English template labels (`Code term`, `Code names`, `Avoid`, `Not the same as`, `Rules`, `Examples`, `Status`, `Sources`, `Open questions`, `Code location`, `Business language`, `Code language`). Status values are `confirmed` or `draft`.

Take each term's **Rules** and the context **Code location** lines.

**No glossary found:** say so, offer to run `/same-page:glossary` first, and **stop**. Without it you can't tell business rules from incidental code.

## 2. Pick the scope

- **A module, folder, or file:** use it.
- **No argument:** use the modules touched by the current uncommitted diff (`git diff HEAD` plus untracked files). If the diff is empty, say so and ask which module to analyze. Don't scan the whole repo. **If git can't run** (or this isn't a git repo), say so. Use the session's git status, if you have one, only for the list of changed files. Since you can't see changed lines, label findings in those files as "may be pre-existing" unless you can tell they're new.

## 3. Extract rules

Collect business rules from two places:

- **Code:** guards and throws (`if (status !== 'draft') throw`), validations, state-transition checks, permission checks, limits and amounts, DB constraints (`CHECK`, `UNIQUE`, foreign keys). Phrase each one in business language ("Only draft proposals can be accepted"), with its `file:line`.
- **Glossary:** each **Rules** line for terms whose context covers this scope.

Skip technical checks with no business meaning (null guards, parsing).

## 4. Map rules to tests

Find the tests that exercise each rule. Read them. Don't go by file names. Classify each rule:

- **verified:** a test triggers the rule, including its failure path (e.g. accepting a non-draft throws)
- **weak:** a test touches the code but doesn't prove the rule (only the happy path, or the assertion doesn't check the rule)
- **untested:** no test exercises it

Also flag:

- **Implementation-named tests:** names that describe code, not behavior (`accept works`, `test updateStatus`). Suggest a business-language name (`only a draft proposal can be accepted`).
- **Bypasses:** code paths that change the same state without going through the rule (a raw `updateStatus` that skips `accept()`). A rule that can be bypassed isn't verified, even if it's tested.
- **Glossary ↔ code gaps:** glossary rules with no enforcing code, and code rules missing from the glossary.

## 5. Report

```markdown
## Business rules: <scope> (<V> verified, <W> weak, <U> untested)

| Rule | Enforced at | Tests | Status |
|---|---|---|---|
| Only draft proposals can be accepted | `proposal.ts:10` | `accept works` (happy path only) | weak |
| An accepted proposal cannot be edited | `proposal.ts:17` | none | untested |

**Bypasses:** `api.ts:6` `updateStatus` sets status without `accept()` ...
**Rename tests:** `accept works` → `accepting a draft proposal marks it accepted`
**Glossary gaps:** ...

**Suggested tests (business language):**
- cannot edit an accepted proposal
- cannot accept a proposal that is not a draft
```

Untested and bypassed rules around money, permissions or irreversible state go first. End by offering to write the suggested tests. Write them only on approval, following the project's existing test framework and style.
