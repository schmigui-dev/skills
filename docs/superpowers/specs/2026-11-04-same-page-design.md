# same-page: design

Date: 2026-11-04
Status: draft for review

## Intent

Get code and business on the same page.

Agents don't need code that is easy to read. They need code they can **verify** (run it, test it, poke at it) and code that **speaks the same language as the human** asking for changes. When the user says "accept the proposal", the agent should find `acceptProposal()`. Finding `updateStatus('accepted')` and guessing is the failure.

The existing `playbooks:domain-driven-design` skill is a good *reference*, but it gives the agent nothing to *do*. `same-page` is the tool side: five commands that build a domain glossary, keep code aligned with it, and check that business rules are verified by tests named in business language.

Sources this design draws on: `context/readibility.md` (verifiability > readability; shared domain language), `context/domain-driven-design.md`, and the `playbooks:domain-driven-design` skill.

## Goals

- Build and maintain a living domain glossary (`docs/domain/glossary.md`) for any project, starting from the code.
- Catch domain-language drift in code, by default in the current diff.
- Align a request with the domain *before* the agent writes code.
- Show which business rules are actually verified by tests.
- Make renames of domain terms safe and complete across the stack.

## Non-goals

- Not a DDD architecture tool: no aggregates/repositories scaffolding, no folder restructuring.
- Not a replacement for the playbooks reference skill. That stays where it is.
- No hooks in v1. Everything runs only when the user types it.
- Not language/framework specific. It must work on any codebase by reading it, with no parsers or build tooling.

## Anti-goals (failure even if it "works")

- **Inventing business meaning.** The agent writes a definition or rule as confirmed without the user confirming it. Unconfirmed things must stay visibly marked as guesses / open questions.
- **Noise.** `check` reporting every variable name. It must flag only domain-relevant terms and rank them by impact.
- **Ceremony.** A huge glossary or doc tree for a tiny CRUD app. Start small; grow when ambiguity is real.
- **Silent edits.** `rename` or `glossary` changing files before the user approves.

## Constraints and conventions

- Lives at `skills/plugins/same-page/` in the `schmigui` marketplace repo (`/Users/guillermo.schmithalter/Documents/projects/skills`).
- Follow `plugins/no-surrender` conventions:
  - `.claude-plugin/plugin.json` (name, version `0.1.0`, description, author, homepage, repository, license MIT, keywords)
  - `skills/<command>/SKILL.md` per command, with frontmatter `name`, `description`, `disable-model-invocation: true`, `argument-hint`
  - plugin `README.md` in the same voice and structure as no-surrender's (tagline, problem paragraph, Install, Commands table, typical loop, Why)
  - add an entry to `.claude-plugin/marketplace.json` and the root `README.md` plugins table
- Commands are namespaced `/same-page:<command>`.
- Git: personal identity only (repo-local `user.email` is already `gschmithalter14@gmail.com`; remote `github.com-personal`). Never the work account.

## The glossary file (shared contract)

All commands read or write `docs/domain/glossary.md` in the target project. Format extends the playbooks template with two fields `check` needs (**Code names**, **Avoid**):

### Languages and the translation map (user decision)

The business may speak one language (e.g. Spanish) while the code is written in another (English recommended). The glossary records both and maps between them:

- The header records **Business language** and **Code language**. `/glossary` asks for both when they aren't recorded: business language first, then code language (if the project has code, it detects the language in use and confirms it; for a new project it recommends English).
- Each term is headed by its **business-language name**. A **Code term** field gives its canonical code-language name, and **Code names** lists the identifiers. This makes the glossary the translation map: "presupuesto" ↔ `Proposal` ↔ `acceptProposal`.
- If both languages are the same, **Code term** equals the heading and can be omitted.
- `translate` takes requests in the business language and maps them through this table.
- `check` never counts a mapped translation as drift. It **does** flag code identifiers written in the business language when the code language differs (e.g. `presupuestoTotal` in an English codebase) as **mixed-language drift**, suggesting the mapped code term.
- `rename` asks whether it's renaming the business term, the code term, or both.

```markdown
# Domain Glossary

**Business language:** Spanish
**Code language:** English

## Context: <Bounded context name>
**Code location:** src/proposals/

### <Business term, e.g. Presupuesto>
- **Code term:** Proposal
- **Definition:** ...
- **Code names:** `Proposal`, `proposals` (table), `acceptProposal`, `/proposals/:id/accept`
- **Avoid:** `Quote`, `Offer` (synonyms that must not appear for this concept)
- **Not the same as:** Booking
- **Rules:** confirmed invariants/transitions only
- **Examples:** concrete scenarios
- **Status:** confirmed | draft
- **Sources:** context.md, src/proposals/, user
- **Open questions:** ...
```

- Each context starts with a `**Code location:** src/proposals/, db/proposals*` line linking it to folders/globs, so `check` knows which context a file belongs to. *(my call)*
- **Avoid** applies only within the term's own context. A word avoided in Sales may be correct in Accounting. *(my call)*
- A single context (`## Context: Main`, or similar) is fine for small projects.
- `Status: draft` marks anything the user has not confirmed. Commands treat draft terms as hints, not truth.
- If a project already has a glossary in another location or format, commands use it and do not move or restructure it unless asked. Adding missing `Code names` / `Avoid` / `Code location` fields is allowed, but only through `/same-page:glossary` with approval. Until then, `check` and `rename` work out code names from the definitions and say they're doing so. *(my call)*

## Commands

### `/same-page:glossary [sources...]`

Build or grow the glossary from whatever the user has. Designed to be **run many times** with different inputs, each run merging into the same glossary.

**Sources (user decision)**, any mix, in one run:
- **Business docs, any format:** md, txt, PDF, docx, pptx, xlsx/csv, html, and anything else describing the business (vision, goals, product brief, pitch deck, process docs, price lists)
- **Images:** screenshots, whiteboard photos, UI mockups, forms (read with the Read tool's image support)
- **Folders of docs:** a folder path reads every supported file in it

**Flexibility rule:** the source list is open-ended, not a whitelist. For each source, use the simplest way the session has to read it: the Read tool for text, PDF and images. Office files go through whatever converter is available (e.g. `textutil -convert txt` on macOS for docx, `pandoc`, `markitdown`, unzipping pptx/xlsx XML, or an installed docx/pptx/xlsx skill). Connected tools (Notion, Google Drive, docs connectors) work when the user points at a page. If a source can't be read, say which one and ask for an export (PDF/text). Never guess its contents, and keep processing the other sources.
- **Free text:** a quoted description ("we're a catering company that sends proposals…")
- **Code:** a folder or file path
- **Nothing:** defaults to mining the whole repo. If there is no code either, ask the user to describe the business or point to a doc.

Steps:

1. If a glossary exists, load it. Otherwise start a new one. If business/code languages aren't recorded, ask them first (see "Languages and the translation map"). A project with business docs but no code still records both (code language: recommend English).
2. Extract candidate terms from each source. **From docs/images/text:** nouns, verbs/actions, statuses, roles, rules, and stated goals that shape meaning. **From code:** types/classes, DB tables/columns, enum/status values, routes, function verbs (`approve`, `cancel`), test names, UI copy, agent/MCP tool names.
3. Merge against the existing glossary. Classify each candidate as **new**, **matches existing**, **answers an open question**, or **conflicts** with a confirmed definition. A conflict is always a question for the user and is never overwritten. Business docs never auto-confirm a term: what a doc says is still `draft` until the user confirms it.
4. Cluster candidates: likely synonyms (`order`/`purchase`), one word used for different things, status values with unclear transitions.
5. Ask the user about the ambiguous ones and the conflicts, one at a time, most consequential first. Never write a definition as `confirmed` without their answer.
6. Show the proposed additions/changes, then write the file on approval. Each touched entry gets a **Sources** field listing where it came from (`context.md`, `screenshot-checkout.png`, `src/proposals/`, `user`).

Output: the glossary diff plus a count of terms left as `draft` / open questions.

### `/same-page:check [target]`

Check code against the glossary.

- Target: file, folder, or PR/branch ref. **Default: the current uncommitted diff** (staged + unstaged). If the diff is empty, say so and ask what to check.
- No glossary → offer to run `/same-page:glossary` first, and stop.
- Flags, ranked by impact:
  - **Synonym drift:** a term from a concept's **Avoid** list, or an unlisted synonym for a known concept
  - **Unknown term:** a new domain-looking name not in the glossary → "add to glossary or rename?"
  - **Overloaded term:** one name used with two meanings, or a term used outside its context
  - **Generic mutation:** `update*/set*Status/patch` where a glossary operation exists (`updateStatus('accepted')` vs `acceptProposal`)
  - **Inconsistency across layers:** UI copy, API route, DB, and code naming the same concept differently
- Each finding: `file:line`, what's wrong, the glossary entry it conflicts with, suggested fix.
- Read-only. It offers fixes and never applies them.

### `/same-page:translate "request"`

Align a request with the domain before coding.

1. Rewrite the request in glossary terms.
2. List the existing operations/types/routes it touches (`file:line`).
3. Flag ambiguous words (e.g. "complete": which meaning?) and new terms not in the glossary as questions for the user.
4. Stop and wait for answers. Then output the aligned request, ready to hand to the agent.

No glossary → it can still run from the code alone, but says so and suggests `/same-page:glossary`.

### `/same-page:rules [module]`

Is the business logic verifiable?

1. Extract business rules/invariants from the code in scope (guards, validations, state-transition checks, throws) and from the glossary's **Rules**.
2. Map each rule to the tests that exercise it.
3. Report:
   - rules with **no test**
   - rules only tested indirectly or weakly
   - tests named after implementation (`test updateStatus works`) rather than business behavior (`cannot accept an expired proposal`)
   - glossary rules with no code enforcing them, and code rules missing from the glossary
4. Read-only. It can offer to write the missing tests, as a separate step the user approves.

Default scope: the current diff's modules; with no diff, ask.

### `/same-page:rename <old> <new>`

Semantic rename of a domain term across the stack.

1. Find every occurrence across code identifiers, file names, DB schema/migrations, API routes/contracts, UI copy, tests, docs, agent/MCP tool definitions, and the glossary.
2. Report the impact before touching anything: what changes, what is risky (DB migration, public API, persisted enum values, analytics/reports, external consumers), and occurrences that look like a *different* meaning and should **not** be renamed.
3. Ask whether the meaning is changing or only the name. If the meaning changes, update the glossary definition with the user.
4. On approval, apply the code/doc changes. For DB or public API changes, describe the migration/deprecation path in the report. Writing a migration file or alias route takes a separate, explicit approval. Never run migrations. *(my call)*
5. Update the glossary (`Code names`, and add the old term to `Avoid`).

## README "Why" and the merged doc

The user wants `context/readibility.md` and `context/domain-driven-design.md` merged into one doc combining verifiability and domain language. Deliverables:

- **Merged doc** at `context/domain-language.md`: thesis (verifiability > readability; the domain-language surface is not optional), DDD essentials condensed, and the agent angle. Keep the two originals. *(my call: new file, originals untouched)*
- **Plugin README "Why"**: a short version of the same thesis, in the no-surrender voice.

The commands do not depend on the merged doc at runtime. Each SKILL.md is self-contained. *(my call)*

## Left to the builder

- Exact wording/structure of each SKILL.md, heuristics for what counts as "domain-looking", report templates (follow no-surrender's style: ranked, capped, with counts of what was dropped).
- Whether commands share a small reference file inside the plugin for the glossary format, or each repeats it.
- Keywords and description copy.

## Decisions log

- Name `same-page`: user.
- v1 commands `glossary`, `check`, `translate`, `rules`, `rename`: user.
- `check` defaults to current diff: user.
- No hook in v1; `contexts`, `interview`, `tools` deferred to v2: user picked the five, rest by omission.
- Glossary asks business language and code language (English recommended) and acts as a translation map: user.
- `/glossary` takes business docs, images, free text, or code, and is run repeatedly to merge into one glossary: user.
- Conflicts never overwrite, docs never auto-confirm, `Sources` field per entry: my call.
- Glossary at `docs/domain/glossary.md` with added `Code names` / `Avoid` fields: my call.
- `Code term` field, mixed-language drift rule in `check`, `rename` asking which side: my call, following the user's language decision.
- Commands needing a glossary offer `/glossary` instead of guessing: my call, user approved in playback.
- Merged doc location and runtime independence: my call.
