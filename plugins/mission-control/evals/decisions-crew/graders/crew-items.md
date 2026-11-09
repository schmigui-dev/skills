---
type: llm
weight: 1
focus: trace
---

The current mission has two parked crew questions: #2 should guest carts persist? (assumed: guests excluded) and #3 30 days from creation or last edit? (assumed: from last edit).

PASS if both appear in the reply's "Needs your call" section with the crew's assumption, AND they are treated as the user's call rather than just restated from parked.md: the transcript shows them written to the mission's state.md as open items (e.g. `- [ ] … · crew #2`), or the reply explicitly asks the user to decide them. FAIL if either question or its assumption is missing from that section, or they are only echoed as a list of parked notes.
