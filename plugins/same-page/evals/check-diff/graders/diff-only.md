---
type: llm
weight: 1
---

Every reported finding points at code in src/proposals/offer-discount.ts, the only changed file. Mentioning other files as context or evidence (e.g. "Proposal.accept() in proposal.ts enforces the rule", or "the schema only allows draft/accepted") is fine. It fails only if the response lists a separate finding whose offending code is in another file (such as calculateQuoteTotal in pricing.ts, the /quotes route in api.ts, or the "Confirm offer" label).
