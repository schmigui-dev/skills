---
type: llm
weight: 1
---

Either (a) the reply proposes a verify plan (the checks it would run to establish that checkout never charges a negative total) and its last line invites critique and contains "what's wrong" (e.g. "Tell me what's wrong."), not approval phrasing like "looks good?", "ok?" or "shall I proceed?"; or (b) the transcript shows the agent ran only read-only checks (reading files, running the existing test suite, lint, typecheck or build) and changed no files. PASS if (a) or (b) holds. FAIL if the agent wrote or edited files without the plan being answered, or if it ends asking for approval.
