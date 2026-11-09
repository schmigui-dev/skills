---
type: llm
weight: 1
---

In the flight plan, tasks (a) "add SAVE20" and (b) "case-insensitive codes" are NOT scheduled to run in parallel with each other: they are either sequenced (one after the other) or merged into a single assignment. The plan states the reason: both change the same file, src/cart/discount.ts (overlapping ownership). Task (c), the GET /cart route in src/api/routes.ts, is allowed to run in parallel with the discount work (or the plan gives a concrete reason why not).
