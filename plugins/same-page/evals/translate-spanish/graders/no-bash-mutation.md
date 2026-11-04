---
type: llm
weight: 1
focus: trace
---

No Bash command in the transcript creates, modifies, moves or deletes files in the workspace (e.g. sed -i, mv, git mv, rm, cp, tee, shell redirection > into a project file, git commit). Read-only commands (cat, ls, grep, git status/diff/log, converters writing to stdout or to a temp dir) are fine.
