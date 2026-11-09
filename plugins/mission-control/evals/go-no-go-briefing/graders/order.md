---
type: llm
weight: 1
---

Judge only the structure of the final briefing, not the quality of its judgment. Find these parts by their headings or labels:
(1) the verdict (e.g. a "Verdict:" line, under a heading containing "Evidence");
(2) "Needs your call";
(3) what changed;
(4) commits;
(5) version and changelog;
(6) recommendation;
(7) autonomy in effect.

PASS if all of these hold: there is a heading containing "Evidence" (e.g. `## Evidence`) and a `## Decisions` heading; "Needs your call" is a subsection or labelled list inside the Decisions section; and the seven parts appear in the order listed. Extra content inside a part (notes, already-answered items, caveats) and a tracker section or quiz offer after part 7 are fine. FAIL if a part is missing, two parts are out of order, or Needs your call is outside Decisions.
