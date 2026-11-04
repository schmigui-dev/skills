---
name: check
description: Check code against the domain glossary (by default the current uncommitted diff) for synonym drift, unknown terms, overloaded words, mixed business/code language, generic mutations, and naming that differs across layers.
disable-model-invocation: true
argument-hint: "[file | folder | git ref — defaults to the current uncommitted diff]"
---

Check domain language in: $ARGUMENTS

Code should speak the glossary's language. When it doesn't, agents and people translate the wrong way. Your job is to find where the code drifts from the glossary, ranked by how much it matters. You are **read-only**: suggest fixes, never apply them.

## 1. Load the glossary

**Finding the glossary** (the same order in every `/same-page` command):
1. `docs/domain/glossary.md`, if it exists.
2. Otherwise, files named `glossary.md`, `GLOSSARY.md` or `ubiquitous-language.md` (any case) anywhere in the repo, skipping `node_modules`, `vendor` and `.git`. Exactly one → use it where it is. **Several → list them, ask which one to use, and stop until the user answers.**

The glossary's field labels are always the English template labels (`Code term`, `Code names`, `Avoid`, `Not the same as`, `Rules`, `Examples`, `Status`, `Sources`, `Open questions`, `Code location`, `Business language`, `Code language`). Status values are `confirmed` or `draft`.

Use it where it is. Never suggest moving or reformatting it.

**No glossary found:** say so, offer to run `/same-page:glossary` first, and **stop**. Don't guess the domain language from the code.

From the glossary, take: the business and code languages; each context's **Code location**; and each term's Code term, Code names, Avoid, Not the same as, and Status. If the glossary lacks Code names or Avoid, work them out from the definitions and say you're doing so. Treat `draft` terms as hints, not rules.

## 2. Pick the target

- **No argument:** the current uncommitted diff. That's `git diff HEAD` (staged and unstaged) plus untracked files from `git status --porcelain`. Check only the changed lines and new files. **If the diff is empty**, say so and ask what to check (a file, folder, or git ref). Don't fall back to scanning the repo. **If git can't run** (or this isn't a git repo), say so. Use the session's git status, if you have one, only for the list of changed files. Since you can't see changed lines, label findings in those files as "may be pre-existing" unless you can tell they're new.
- **A file or folder:** check all of it.
- **A git ref or range** (`main`, `main..HEAD`, a PR branch): check that diff.

## 3. Find drift

For each file, work out its context from **Code location** (if no context matches, use the closest one by meaning, or the single context). A term's **Avoid** list only applies inside its own context.

Look for:

1. **Synonym drift:** a word on a concept's Avoid list (`Quote`, `Offer` for Proposal), or an unlisted synonym for a known concept. Check identifiers, file names, routes, DB names, test names and UI copy.
2. **Mixed-language drift:** an identifier written in the business language when the code language is different (`presupuestoTotal` in English code). Suggest the mapped code term (`proposalTotal`). A correctly mapped translation (`Proposal` for presupuesto) is **never** drift.
3. **Unknown term:** a new domain-looking name or status value that's not in the glossary (`'booked'`). Ask "add to glossary or rename?". If it's close to a draft term, say which one.
4. **Overloaded term:** one name used for two meanings, or a term used outside its context. Don't flag a word that legitimately belongs to another context: `ShiftProposal` in Staffing is not Proposal drift if the glossary defines it there.
5. **Generic mutation:** `update*`, `set*Status`, `patch*`, or a raw status write where the glossary or code has a domain operation (`updateStatus(id, 'accepted')` instead of `proposal.accept()`). Flag it louder if it bypasses a rule the domain operation enforces.
6. **Cross-layer inconsistency:** the same concept named differently across UI copy, API routes, DB, code and tests (class `Proposal`, route `/quotes`, button "Confirm offer").

Skip plumbing and generic programming words. Only domain terms matter.

## 4. Report

Rank by impact. Highest first: things that change behavior or bypass rules (generic mutations around invariants, money, permissions), then ambiguity that misleads (overloaded terms, unknown statuses), then naming drift. Report at most 10. Lead with the total, and say how many minor ones you dropped.

```markdown
## Domain check: <target> (<N> findings, <M> minor dropped)
Glossary used: <path> (<context(s) applied>)

1. **<kind>: <one line>**
   `path/to/file.ts:12`: `<the offending code>`
   Glossary: <entry it conflicts with, e.g. Presupuesto → Proposal; Avoid: Quote>
   Fix: <suggested rename or change>

...

**Unknown terms to decide:** <term>: add to glossary or rename?
```

Every finding must point at code inside the target. You can cite other files as evidence ("`Proposal.accept()` enforces this"), but don't report their own drift when the target is a diff.

If nothing drifts, say so in one line, along with what you checked.

End by offering to apply the suggested fixes, or to add unknown terms with `/same-page:glossary`. Don't do either unless the user asks.
