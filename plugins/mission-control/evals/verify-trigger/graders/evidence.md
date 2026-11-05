---
type: llm
weight: 1
---

The final reply has a section headed "Evidence" (a markdown heading such as "## Evidence" or "## Evidence: <title>"). In it: the actual test command that was run (e.g. `npm test` or `node --test ...`) with its output quoted verbatim (pasted lines from the run, not a paraphrase like "all tests pass"), OR an explicit statement that the tests were not run with a concrete reason (e.g. node is not available, with the error shown). The reply also shows a total for 3 items at 0.1, from a command that was actually run (with its output) or explicitly marked not run with a reason. PASS only if all of this is present. FAIL if test results are claimed without pasted output.
