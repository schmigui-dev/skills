---
name: rename
description: Semantically rename a domain term across code, schema, API, UI copy, tests, docs, agent tools and the glossary. Shows an impact report first and changes nothing without approval.
disable-model-invocation: true
argument-hint: "<old> <new>"
---

Rename the domain term: $ARGUMENTS

Parse `$ARGUMENTS` as `<old> <new>`. Terms can be several words: use quotes when given (`"Propuesta de turno" "Plan de turnos"`). With more than two unquoted words, the split is ambiguous: state your best reading (matching `<old>` against glossary terms) and ask the user to confirm before anything else. If either term is missing, ask for it and stop. Never invent the new name.

Renaming a domain term isn't cosmetic. "Completed" may drive reports, permissions, analytics and agent behavior. Your job is to find every place the concept lives, separate it from look-alikes, show the impact, and change things only once the user approves.

## 1. Load the glossary

**Finding the glossary** (the same order in every `/same-page` command):
1. `docs/domain/glossary.md`, if it exists.
2. Otherwise, files named `glossary.md`, `GLOSSARY.md` or `ubiquitous-language.md` (any case) anywhere in the repo, skipping `node_modules`, `vendor` and `.git`. Exactly one → use it where it is. **Several → list them, ask which one to use, and stop until the user answers.**

The glossary's field labels are always the English template labels (`Code term`, `Code names`, `Avoid`, `Not the same as`, `Rules`, `Examples`, `Status`, `Sources`, `Open questions`, `Code location`, `Business language`, `Code language`). Status values are `confirmed` or `draft`.

Find the entry for `<old>`, matching on the business term, the Code term or the Code names. Note its context, Code names, Avoid list, and Not the same as.

- If `<new>` is on the term's **Avoid** list, or is another term's name, say so prominently: the rename would go against the agreed language.
- No glossary: continue from the code, and say the impact report can't separate meanings as reliably.

## 2. Find every occurrence

Search case- and convention-insensitively (`Proposal`, `proposal`, `proposals`, `PROPOSAL`, `proposal_id`, `/proposals/`, `acceptProposal`) across:

- code identifiers and file names
- DB schema, migrations, and persisted values (table and column names, enum or status strings stored in rows)
- API routes and contracts (OpenAPI, GraphQL, public SDKs)
- UI copy and i18n strings
- tests (names and code)
- docs, README, the glossary
- agent and MCP tool names and descriptions

## 3. Separate meanings

For every hit, decide: is this the **same concept**, or a **different meaning** that happens to share the word? Use the glossary's contexts and Code location lines. `ShiftProposal` in Staffing is a different concept from Proposal. List these under "do not rename". When unsure, ask.

## 4. Impact report (before touching anything)

```markdown
## Rename: <old> → <new> (<N> occurrences in <F> files)

**Glossary:** <entry>; warnings (e.g. "<new> is on the Avoid list")

| Layer | Occurrences | Risk |
|---|---|---|
| Code | `src/proposals/proposal.ts:3` class Proposal, ... | low |
| DB | `db/schema.sql:1` table proposals | needs migration |
| API | `src/proposals/api.ts:10` route | breaks clients: alias needed |
| UI copy | `src/ui/labels.ts:3` | user-visible |
| Tests | ... | low |
| Glossary / docs | ... | low |

**Do not rename (different meaning):** `ShiftProposal`, `proposeShift` (Staffing: Propuesta de turno)
**Risky:** persisted values, public API, analytics/report names, external consumers
**Glossary on apply:** <exact entry changes: heading or Code term/Code names; `<new>` removed from Avoid; `<old>` added to Avoid>

**Questions:**
1. Is the meaning changing, or only the name?
2. Which side: the business term (<business term>), the code term (<code term>), or both?
```

Then stop and wait for answers.

## 5. Apply on approval

- If the meaning changes, update the glossary definition with the user first.
- Rename code, file names, tests, UI copy, docs and tool definitions in one consistent pass.
- **DB and public API:** describe the migration or deprecation path (new table or column plus a data migration, alias routes during the transition). Write a migration file or alias route only with a separate, explicit approval. **Never run migrations.**
- Update the glossary for the side being renamed. **Business term:** change the entry heading. **Code term:** change Code term and Code names, and leave the heading alone. In both cases, **remove `<new>` from Avoid** if it was there, and add `<old>` to Avoid.
- Afterwards, run the project's tests if they exist, and suggest `/same-page:check` on the diff.
