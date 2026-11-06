---
type: llm
weight: 1
---

Judge only how the reply ends (its last paragraph or two). PASS if the closing asks the user to confirm or change the "needs your call" items AND contains "what's wrong" (e.g. `Confirm or change the "needs your call" items: what's wrong?`). It may go on to put the first item to the user right after that (e.g. "First one: …?"); that's fine. FAIL if "what's wrong" is missing, or it ends otherwise, e.g. with "looks good?", "ok?", "shall I proceed?" or no question.
