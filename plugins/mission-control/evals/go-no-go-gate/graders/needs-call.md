---
type: llm
weight: 1
focus: trace
---

Two crew questions are parked for the mission: #2 (should guest carts persist?, from engineer-1, assumed guests excluded) and #3 (30 days from creation or last edit?, from researcher-1, assumed from last edit).

PASS if both are listed, with the crew's assumption, under a "Needs your call" heading (or recorded as open `- [ ]` items under `## Needs your call` in the mission's state.md, as the transcript shows), AND the reply treats them as decisions the user must make before launch (e.g. says they must be answered first, or asks one of them). Questions are asked one at a time, so not every item has to be asked yet. FAIL if either is missing, or if they are only echoed as parked notes (background or context) without the reply saying the user has to decide them.
