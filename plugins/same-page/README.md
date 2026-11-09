# same-page

Get code and business on the same page.

You say "accept the presupuesto". The agent goes looking and finds `updateStatus('accepted')`, a `/quotes` route, a button that says "Confirm offer", and a `calculateQuoteTotal`. Four names for one thing, and it has to guess which one you meant. It usually guesses right. When it doesn't, the bug looks like perfectly reasonable code.

Agents don't need code that's pleasant to read. They need code that **speaks your business's language** and that they can **verify**. These five commands build that shared language as a glossary, keep the code aligned with it, and check that your business rules are actually covered by tests.

## Install

```text
/plugin marketplace add schmigui-dev/skills
/plugin install same-page@schmigui
```

Commands are namespaced as `/same-page:<command>`.

## Commands

| When | Command | Does |
|---|---|---|
| Anytime | `/glossary [sources...]` | Builds or grows `docs/domain/glossary.md` from **anything**: business docs in any format (md, pdf, docx, pptx, xlsx…), folders, screenshots, pages in connected tools, a quoted description, or the code itself. Run it as often as you like; each run merges into the same glossary. It asks the business language and the code language (English recommended), so the glossary doubles as a translation map: *presupuesto* ↔ `Proposal` ↔ `acceptProposal`. |
| Before | `/translate "request"` | Rewrites your request in glossary terms (in any language you write it in), points to the code it touches, and turns ambiguous or new words into questions before any code is written. |
| After | `/check [target]` | Checks the **current diff** (or a file, folder or ref) for synonym drift, business-language names in the code, unknown terms, overloaded words, generic `updateStatus`-style mutations, and naming that differs across UI, API, DB and code. |
| After | `/rules [module]` | Lists the business rules in a module, maps each to its tests, and reports which are verified, weak, untested, or bypassable. Suggests tests named in business language. |
| Anytime | `/rename <old> <new>` | Renames a domain term across code, schema, API, UI copy, tests, docs, agent tools and the glossary. Shows an impact report first, separates look-alikes (`ShiftProposal` isn't a `Proposal`), and never runs migrations. |

All commands run only when you type them. Claude never invokes them on its own. `glossary` and `rename` change nothing until you approve. `check`, `translate` and `rules` are read-only.

## The glossary

One file, `docs/domain/glossary.md` (an existing glossary elsewhere is used where it is):

```markdown
# Domain Glossary

**Business language:** Spanish
**Code language:** English

## Context: Proposals
**Code location:** src/proposals/, db/

### Presupuesto
- **Code term:** Proposal
- **Definition:** Versioned commercial offer sent to a client for an event.
- **Code names:** `Proposal`, `acceptProposal`, `proposals` (table)
- **Avoid:** `Quote`, `Offer`, cotización
- **Not the same as:** Reserva
- **Rules:** Only draft proposals can be accepted. An accepted proposal cannot be edited.
- **Status:** confirmed
- **Sources:** about.md, src/proposals/, user
```

Nothing becomes `confirmed` without your answer. What a document says is evidence, not a decision.

## A typical loop

```text
/glossary docs/business/ pitch-deck.pptx     # seed it from what you already have
/glossary "a seña is a 30% deposit paid on acceptance"   # add as you learn
/translate "let clients confirm the quote online"   # align before coding
... agent works ...
/check                                       # did the diff drift?
/rules src/proposals                         # are the rules actually tested?
```

## Why

We used to optimize code for human readers, who are slow at reading lots of text. Agents read differently: they run the code, poke at it, and lean on tests. So for them, "readable" really means two things:

- **Same language.** The code uses the words people use to describe the business, so a request maps straight onto code without guesswork. Readability that still pays off is mostly naming and boundaries.
- **Verifiable.** Business rules are pinned by tests named in business language. A rule with no test, or one a raw `updateStatus` can bypass, isn't safe for an agent to touch, however clean the code looks.

Inside a module, optimize freely. At the boundary (names, operations, rules, tests), speak the business's language.

Built on Domain-Driven Design's *ubiquitous language* and *bounded contexts*, applied with as little ceremony as possible.

## Evals

Behavior tests live in [`evals/`](evals), run with `claude plugin eval`.

## License

MIT
