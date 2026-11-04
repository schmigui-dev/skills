---
name: glossary
description: Build or grow the project's domain glossary from any source (business docs in any format, images, free text, or code), merging into one glossary across runs and mapping business-language terms to code names.
disable-model-invocation: true
argument-hint: "[docs, images, \"text\", or code paths — defaults to the whole repo]"
---

Build or grow the domain glossary from: $ARGUMENTS

The glossary is the shared language between the business and the code. It's also the translation map between the language the business speaks and the language the code is written in. Your job is to **propose** entries, not decide them: business meaning comes from the user. Run this as often as the user likes with different sources. Each run merges into the same glossary.

## 1. Find the glossary

**Finding the glossary** (the same order in every `/same-page` command):
1. `docs/domain/glossary.md`, if it exists.
2. Otherwise, files named `glossary.md`, `GLOSSARY.md` or `ubiquitous-language.md` (any case) anywhere in the repo, skipping `node_modules`, `vendor` and `.git`. Exactly one → use it where it is. **Several → list them, ask which one to use, and stop until the user answers.**

The glossary's field labels are always the English template labels (`Code term`, `Code names`, `Avoid`, `Not the same as`, `Rules`, `Examples`, `Status`, `Sources`, `Open questions`, `Code location`, `Business language`, `Code language`). Status values are `confirmed` or `draft`.

If one exists, load it and use it where it is. Don't move or restructure it unless the user asks. If none exists, you'll propose a new one at `docs/domain/glossary.md`.

## 2. Languages (only if not recorded)

If the glossary header doesn't record **Business language** and **Code language**, you need both, but don't make the user wait for them to see any work:

1. **Business language:** guess from the sources (the docs' language, the user's own text) and ask the user to confirm the language their people, docs and customers use.
2. **Code language:** if the project has code, detect the language its identifiers are written in, and say what you found. If there's no code yet, recommend English.

Do all the remaining steps in the **same reply** using these guesses, then make the language confirmation the **first** question in step 6. If the user corrects a language, redo the translation map.

If both are already recorded, don't ask again.

## 3. Read the sources

Parse `$ARGUMENTS` into sources. An argument that is an existing path is a file or folder. Anything else (usually quoted) is free text from the user. Any mix is allowed:

- **Business docs, any format:** md, txt, pdf, docx, pptx, xlsx/csv, html, or anything else describing the business (vision, goals, product, pitch deck, process docs, price lists).
- **Folders:** read every readable file in them.
- **Images:** screenshots, whiteboard photos, mockups, forms.
- **Pages in connected tools** (Notion, Drive, docs connectors) when the user points at one.
- **Free text:** the user's own description. Source name: `user`.
- **Code:** a folder or file.
- **Nothing given:** mine the whole repo. If there's no code and no docs either, ask the user to describe the business or point to a document, and stop.

The list of formats is open-ended. For each source, use the simplest reader available: the Read tool for text, PDF and images. For office files, use whatever converter exists (`textutil -convert txt -stdout` on macOS, `pandoc`, `markitdown`, unzipping the XML in pptx/xlsx/docx, or an installed docx/pptx/xlsx skill). **If a source can't be read** (empty, corrupt, unsupported), name it, ask for a PDF or text export, never guess its contents, and carry on with the other sources.

## 4. Extract candidates

- **From docs, images and text:** nouns (things the business deals with), verbs (actions people take), statuses and lifecycles, roles, rules ("X only happens after Y"), and goals that shape meaning.
- **From code:** types and classes, DB tables and columns, enum and status values, routes, function verbs (`approve`, `cancel`, `accept`), test names, UI copy, and agent or MCP tool names.

Keep only domain terms: things a business person would recognize. Skip technical plumbing (`utils`, `handler`, `db`). A term from a business source counts even if the code doesn't use it yet (products, services, roles, policies). Propose it with `Code names: none yet`. Docs often run ahead of the code.

## 5. Merge against the glossary

Classify every candidate:

- **new:** not in the glossary
- **matches existing:** the same concept already defined. Note any new code names or synonyms
- **answers an open question:** the source settles something listed under an entry's Open questions
- **conflicts:** contradicts a `confirmed` definition or rule

Then look for trouble:

- **Synonym clusters:** different words for one concept (`quote`/`proposal`/`offer`, or business-language synonyms like cotización/presupuesto). Suggest which term to keep and which go under **Avoid**, but it's the user's call: every synonym cluster is a question in step 7, because they may really be different things. This covers code too: if code names one concept with different words (`Proposal` class, `calculateQuoteTotal`, `/quotes` route, "Confirm offer" label), name the cluster explicitly (`Proposal` / `Quote` / `Offer`). Don't list the off-words as plain Code names. List them as drift until the user picks.
- **One word, two meanings:** the same word used for different concepts, especially across contexts. Propose separate entries or contexts.
- **Translation map:** for each business term, find its code term and code names when the code exists (e.g. presupuesto ↔ `Proposal` ↔ `acceptProposal`).

Hard rules:

- A **conflict** is always a question for the user. Never overwrite a confirmed entry.
- What a document says is evidence, not confirmation. Everything you propose is `Status: draft` until the user confirms it, including answers to open questions.

## 6. Propose

In your first reply, show the full proposal: a compact list of glossary entries, grouped as new, updated (including answered open questions), and conflicts, each with its Sources and `Status: draft`. Also list the synonym clusters with the term you suggest keeping and what goes under Avoid, plus any unreadable sources. Lead with counts (`5 new, 2 updated, 1 conflict, 3 open questions`).

## 7. Ask, one at a time

Then ask about the ambiguous items and conflicts **one question at a time**, starting with the language confirmation if it's needed, then most consequential first (ones that change behavior, money, or permissions come before naming nits). Offer your best guess so the user can just correct it. List the remaining questions briefly as "next up" so the user can see what's coming.

## 8. Write on approval

**Write nothing until the user approves.** Then write the file, using this format for new files and new entries:

```markdown
# Domain Glossary

**Business language:** Spanish
**Code language:** English

## Context: <Bounded context name>
**Code location:** src/proposals/, db/

### <Business term>
- **Code term:** Proposal            (omit if business and code languages match)
- **Definition:** ...
- **Code names:** `Proposal`, `acceptProposal`, `proposals` (table), `/proposals/:id/accept`
- **Avoid:** `Quote`, `Offer`, cotización   (synonyms not to use for this concept, within this context)
- **Not the same as:** Reserva
- **Rules:** confirmed invariants and transitions only
- **Examples:** concrete scenarios
- **Status:** confirmed | draft
- **Sources:** about.md, deck.pptx, src/proposals/, user
- **Open questions:** ...
```

- **Keep the field labels and Status values exactly as in the template, in English,** in your proposal and in the file, whatever language you reply in or write definitions in. Other `/same-page` commands read these labels.
- A single context (`## Context: Main`) is fine for a small project. Add contexts only where words really change meaning.
- **Code location** links a context to folders or globs, so other commands know which context a file belongs to.
- **Avoid** applies only inside its own context.
- For an existing glossary in another format, add the fields other `/same-page` commands rely on (Code names, Avoid, Code location) only with approval.
- Start small. Don't pad the glossary with terms nobody is confused about.

After writing, report: what changed, what is still `draft`, and the open questions left.
