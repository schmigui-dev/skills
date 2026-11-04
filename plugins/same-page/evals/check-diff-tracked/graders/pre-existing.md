---
type: llm
weight: 1
---

The response does not pass pre-existing drift off as part of this change. It passes if either (a) it reports only the changed line's issue (presupuestoId), or (b) it also reports other issues in src/proposals/api.ts (such as the /quotes route or updateStatus) but clearly says, prominently or per finding, that it could not see which lines changed and those findings may be pre-existing. It fails if it presents /quotes or updateStatus as introduced by this diff without any such caveat.
