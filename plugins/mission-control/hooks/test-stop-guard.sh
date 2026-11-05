#!/bin/bash
# Tests for stop-guard.sh. Runs on macOS bash 3.2 with jq.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$DIR/stop-guard.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
FAILS=0

# make_transcript <file> <with_edit:yes|no>
make_transcript() {
  local f="$1"
  jq -nc '{type:"user",message:{content:"please change the file"}}' > "$f"
  if [[ "$2" == "yes" ]]; then
    jq -nc '{type:"assistant",message:{content:[{type:"tool_use",name:"Edit",input:{}}]}}' >> "$f"
  fi
  jq -nc '{type:"assistant",message:{content:[{type:"text",text:"done"}]}}' >> "$f"
}

# run_hook <with_edit> <text> <stop_hook_active> [ENV=val ...]
run_hook() {
  local edit="$1" text="$2" active="$3"; shift 3
  local t="$TMP/t.jsonl"
  make_transcript "$t" "$edit"
  jq -nc --arg p "$t" --arg m "$text" --argjson a "$active" \
    '{transcript_path:$p,stop_hook_active:$a,last_assistant_message:$m}' \
    | env "$@" bash "$HOOK" 2>/dev/null
}

check() { # name, condition result (0 = pass)
  if [[ "$2" -eq 0 ]]; then echo "ok   $1"; else echo "FAIL $1"; FAILS=$((FAILS+1)); fi
}

test_blocks_missing_sections() {
  local out; out=$(run_hook yes "done" false X=1)
  [[ "$(jq -r .decision <<<"$out" 2>/dev/null)" == "block" ]] \
    && [[ "$(jq -r .reason <<<"$out" 2>/dev/null)" == mission-control:* ]] \
    && [[ "$(jq -r .reason <<<"$out" 2>/dev/null)" == *"Evidence and Decisions"* ]]
  check test_blocks_missing_sections $?
}
test_passes_with_sections() {
  local out; out=$(run_hook yes $'## Evidence\nran tests\n## Decisions\nnone' false X=1)
  [[ -z "$out" ]]; check test_passes_with_sections $?
}
test_no_edits_passes() {
  local out; out=$(run_hook no "done" false X=1)
  [[ -z "$out" ]]; check test_no_edits_passes $?
}
test_env_off() {
  local out; out=$(run_hook yes "done" false MISSION_CONTROL_STOP_GUARD=off)
  [[ -z "$out" ]]; check test_env_off $?
}
test_legacy_env_off() {
  local out; out=$(run_hook yes "done" false NO_SURRENDER_STOP_GUARD=off)
  [[ -z "$out" ]]; check test_legacy_env_off $?
}
test_active_passes() {
  local out; out=$(run_hook yes "done" true X=1)
  [[ -z "$out" ]]; check test_active_passes $?
}

test_blocks_missing_sections
test_passes_with_sections
test_no_edits_passes
test_env_off
test_legacy_env_off
test_active_passes
[[ $FAILS -eq 0 ]] && echo "all passed" || { echo "$FAILS failed"; exit 1; }
