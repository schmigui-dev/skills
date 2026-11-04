---
name: translate
description: Before coding, rewrite a request in the glossary's domain terms (from the business language into code terms), point to the existing operations it touches, and turn ambiguous or new words into questions.
disable-model-invocation: true
argument-hint: "\"request in your own words\""
---

Translate this request into the domain language: $ARGUMENTS

If `$ARGUMENTS` is empty, ask `translate what?` and stop.

People describe work in their own words. Code is written in glossary terms, often in a different language. Your job is to close that gap **before** any code is written, so the agent builds what was meant, not what it guessed. You are **read-only**: don't edit any files.

## 1. Load the glossary

**Finding the glossary** (the same order in every `/same-page` command):
1. `docs/domain/glossary.md`, if it exists.
2. Otherwise, files named `glossary.md`, `GLOSSARY.md` or `ubiquitous-language.md` (any case) anywhere in the repo, skipping `node_modules`, `vendor` and `.git`. Exactly one → use it where it is. **Several → list them, ask which one to use, and stop until the user answers.**

The glossary's field labels are always the English template labels (`Code term`, `Code names`, `Avoid`, `Not the same as`, `Rules`, `Examples`, `Status`, `Sources`, `Open questions`, `Code location`, `Business language`, `Code language`). Status values are `confirmed` or `draft`.

Read the business and code languages, and each term's Code term, Code names, Avoid, Rules, Status, and Open questions.

**No glossary found:** say so and suggest `/same-page:glossary`, then keep going using the code alone (types, routes, function names) to map terms. Mark those mappings as inferred from code.

## 2. Map every domain word

Go through the request phrase by phrase. For each noun, verb and status:

- **Glossary term:** map it, including across languages. "presupuesto" → **Presupuesto** → `Proposal`. "aceptar" → `Proposal.accept()`.
- **Synonym on an Avoid list:** map it to the real term and say so. "quote" → Presupuesto / `Proposal`, since `Quote` is on its Avoid list.
- **Draft term:** map it, but flag that its meaning isn't confirmed, and bring up its Open questions ("booked" → Reserva / `Booking`, draft. Does a booking require a paid seña?).
- **Ambiguous word:** a word that could mean two glossary things ("confirm": accept the presupuesto, or confirm the reserva?) becomes a question.
- **New word:** not in the glossary and not in the code. Ask whether it's a new concept or a synonym of an existing one.

## 3. Find what it touches

List the existing code the request would touch, as `file:line`: operations, types, routes, DB tables, UI copy, and tests. Note any rule the change could run into ("Only draft proposals can be accepted", enforced in `proposal.ts:10`).

## 4. Report and ask

Write to the user in the language they wrote the request in.

```markdown
## Translation: "<original request>"

**In domain terms (draft):** <the request rewritten with glossary terms and code names>

| Said | Means | Code | Note |
|---|---|---|---|
| quote | Presupuesto | `Proposal` | `Quote` is on the Avoid list |
| ... | | | |

**Touches:** `src/proposals/proposal.ts:10` `Proposal.accept()` · ...
**Rules in play:** ...

**Questions before coding:**
1. <most consequential first: money, permissions, state changes>
2. ...
```

Then **stop and wait for answers**. Once answered, give the final aligned request in one paragraph, ready to hand to the agent, and suggest adding any new or confirmed terms with `/same-page:glossary`.

If nothing is ambiguous, say so and give the aligned request right away.
