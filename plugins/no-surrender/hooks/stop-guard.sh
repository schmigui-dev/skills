#!/bin/bash
# no-surrender Stop hook.
#
# If the agent changed files during this turn, it may not finish until its
# final message contains an "Evidence" section and a "Decisions" section.
# Turns that changed no files (questions, chat, research) stop normally.
#
# Opt out by setting NO_SURRENDER_STOP_GUARD=off (for example in the "env"
# block of a project's .claude/settings.json).
#
# The hook fails open: if anything is missing or unparseable, it lets the
# agent stop rather than trapping the session.

set -uo pipefail

[[ "${NO_SURRENDER_STOP_GUARD:-on}" == "off" ]] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)

# Block at most once per stop. If we already blocked and the agent is
# stopping again, let it go so the session can never loop.
[[ "$(jq -r '.stop_hook_active // false' <<<"$INPUT" 2>/dev/null)" == "true" ]] && exit 0

TRANSCRIPT=$(jq -r '.transcript_path // ""' <<<"$INPUT" 2>/dev/null)
[[ -f "$TRANSCRIPT" ]] || exit 0

# Scope everything to the current turn: entries after the last real user
# prompt. Real prompts are user entries that are not meta (skill bodies,
# injected context) and are not tool results.
TURN=$(tail -n 3000 "$TRANSCRIPT" | jq -cs '
  def is_prompt:
    .type == "user"
    and ((.isMeta // false) | not)
    and ((.message.content | type) == "string"
         or ([.message.content[]?.type] | index("tool_result") | not));
  (to_entries | map(select(.value | is_prompt)) | last | .key // -1) as $start
  | [.[$start + 1:][] | select(.type == "assistant") | .message.content[]?]
  | (map(select(.type == "tool_use") | .name)) as $tools
  | (map(.type) | rindex("tool_use") // -1) as $last_tool
  | {
      edits: ($tools | map(select(IN("Edit", "Write", "MultiEdit", "NotebookEdit"))) | length),
      final: ([.[$last_tool + 1:][] | select(.type == "text") | .text] | join("\n"))
    }
' 2>/dev/null) || exit 0

EDITS=$(jq -r '.edits // 0' <<<"$TURN")
[[ "$EDITS" =~ ^[0-9]+$ && "$EDITS" -gt 0 ]] || exit 0

# Prefer the final message as Claude Code reports it, when available.
FINAL=$(jq -r '.last_assistant_message // ""' <<<"$INPUT" 2>/dev/null)
[[ -n "$FINAL" ]] || FINAL=$(jq -r '.final // ""' <<<"$TURN")

# A section counts as a markdown heading ("## Evidence") or a bold label
# at the start of a line ("**Evidence**" or "**Evidence:**").
has_section() {
  grep -Eiq "^[[:space:]]*(#{1,6}[[:space:]]*|\*\*)$1" <<<"$FINAL"
}

MISSING=()
has_section "evidence" || MISSING+=("Evidence")
has_section "decisions" || MISSING+=("Decisions")
[[ ${#MISSING[@]} -eq 0 ]] && exit 0

LIST="${MISSING[0]}"
[[ ${#MISSING[@]} -gt 1 ]] && LIST="${MISSING[0]} and ${MISSING[1]}"
REASON="no-surrender: you changed ${EDITS} file(s) this turn, but your final message is missing: ${LIST}. Before finishing, add the missing section(s) at the end of your reply:

## Evidence
For each check you actually ran this session after the latest change: the exact command, its verbatim output (trimmed with ...), what it proves, and what it does NOT prove. Run safe read-only checks (tests, lint, typecheck, build) now if you haven't. List what was not checked, and give a verdict: verified, partially verified, or unverified. If nothing could be checked, say so plainly. Never claim a result you didn't see.

## Decisions
Every choice the user did not explicitly specify: values you invented, defaults, interpretations, scope cuts, assumptions. Put \"needs your call\" items first (invented, security, data, money, deploy, user-facing, hard to reverse), each with file:line and the alternative. Then FYI items. If there were none, write \"none: everything followed explicit instructions\".

Keep both sections compact. Do not repeat the rest of your reply."

jq -n --arg reason "$REASON" '{decision: "block", reason: $reason}'
exit 0
