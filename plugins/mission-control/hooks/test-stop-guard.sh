#!/bin/bash
# Tests for stop-guard.sh. Runs on macOS bash 3.2 with jq.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$DIR/stop-guard.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
FAILS=0
unset MISSION_CONTROL_STOP_GUARD NO_SURRENDER_STOP_GUARD

# Transcript entry builders (one JSONL line each).
u_prompt() { jq -nc --arg t "$1" '{type:"user",message:{content:$t}}'; }
u_meta()   { jq -nc '{type:"user",isMeta:true,message:{content:"injected skill body"}}'; }
u_result() { jq -nc '{type:"user",message:{content:[{type:"tool_result",tool_use_id:"t1",content:"ok"}]}}'; }
a_edit()   { jq -nc '{type:"assistant",message:{content:[{type:"tool_use",name:"Edit",input:{}}]}}'; }
a_text()   { jq -nc --arg t "$1" '{type:"assistant",message:{content:[{type:"text",text:$t}]}}'; }

# run_hook <transcript> <message|-> <stop_hook_active>
# "-" means: omit last_assistant_message (forces the transcript fallback).
# Sets OUT (stdout), ERR (stderr), RC (exit status). Env vars come from the caller.
run_hook() {
  OUT=""; ERR=""; RC=99
  [[ -f "$HOOK" ]] || { ERR="hook file missing: $HOOK"; return; }
  if [[ "$2" == "-" ]]; then
    jq -nc --arg p "$1" --argjson a "$3" '{transcript_path:$p,stop_hook_active:$a}' > "$TMP/in.json"
  else
    jq -nc --arg p "$1" --arg m "$2" --argjson a "$3" \
      '{transcript_path:$p,stop_hook_active:$a,last_assistant_message:$m}' > "$TMP/in.json"
  fi
  bash "$HOOK" < "$TMP/in.json" > "$TMP/out" 2> "$TMP/err"
  RC=$?
  OUT=$(cat "$TMP/out"); ERR=$(cat "$TMP/err")
}

report() { # name, 0 = pass, detail
  if [[ "$2" -eq 0 ]]; then echo "ok   $1"; else echo "FAIL $1 ${3:-}"; FAILS=$((FAILS+1)); fi
}

# The hook ran cleanly (file exists, exit 0, no stderr) and did not block.
assert_pass() {
  local ok=0
  [[ "$RC" -eq 0 && -z "$ERR" && -z "$OUT" ]] || ok=1
  report "$1" "$ok" "(rc=$RC stderr='$ERR' stdout='$OUT')"
}

# The hook ran cleanly and blocked; optional 3rd arg: substring the reason must contain.
assert_block() {
  local ok=0
  [[ "$RC" -eq 0 && -z "$ERR" ]] || ok=1
  [[ "$(jq -r .decision <<<"$OUT" 2>/dev/null)" == "block" ]] || ok=1
  [[ "$(jq -r .reason <<<"$OUT" 2>/dev/null)" == mission-control:* ]] || ok=1
  if [[ -n "${2:-}" ]]; then [[ "$(jq -r .reason <<<"$OUT" 2>/dev/null)" == *"$2"* ]] || ok=1; fi
  report "$1" "$ok" "(rc=$RC stderr='$ERR' stdout='$OUT')"
}

T="$TMP/t.jsonl"
BOTH=$'## Evidence\nran tests\n## Decisions\nnone'

test_blocks_missing_sections() {
  { u_prompt "change it"; a_edit; a_text done; } > "$T"
  run_hook "$T" done false
  assert_block test_blocks_missing_sections "Evidence and Decisions"
}
test_passes_with_sections() {
  { u_prompt "change it"; a_edit; a_text done; } > "$T"
  run_hook "$T" "$BOTH" false
  assert_pass test_passes_with_sections
}
test_no_edits_passes() {
  { u_prompt "question"; a_text done; } > "$T"
  run_hook "$T" done false
  assert_pass test_no_edits_passes
}
test_env_off() {
  { u_prompt "change it"; a_edit; a_text done; } > "$T"
  ( export MISSION_CONTROL_STOP_GUARD=off; run_hook "$T" done false
    echo "$RC|$ERR|$OUT" > "$TMP/res" )
  IFS='|' read -r RC ERR OUT < "$TMP/res"
  # sanity: the hook file must exist, else rc is not 0 here
  assert_pass test_env_off
}
test_legacy_env_off() {
  { u_prompt "change it"; a_edit; a_text done; } > "$T"
  ( export NO_SURRENDER_STOP_GUARD=off; run_hook "$T" done false
    echo "$RC|$ERR|$OUT" > "$TMP/res" )
  IFS='|' read -r RC ERR OUT < "$TMP/res"
  assert_pass test_legacy_env_off
}
test_active_passes() {
  { u_prompt "change it"; a_edit; a_text done; } > "$T"
  run_hook "$T" done true
  assert_pass test_active_passes
}
test_fallback_blocks() {
  { u_prompt "change it"; a_edit; a_text "all done"; } > "$T"
  run_hook "$T" - false
  assert_block test_fallback_blocks "Evidence and Decisions"
}
test_fallback_passes() {
  { u_prompt "change it"; a_edit; a_text "$BOTH"; } > "$T"
  run_hook "$T" - false
  assert_pass test_fallback_passes
}
test_prior_turn_edits_ignored() {
  { u_prompt "turn one"; a_edit; a_text "edited"; u_prompt "turn two"; a_text "just chatting"; } > "$T"
  run_hook "$T" "just chatting" false
  assert_pass test_prior_turn_edits_ignored
}
test_tool_result_not_a_prompt() {
  { u_prompt "change it"; a_edit; u_result; a_text done; } > "$T"
  run_hook "$T" done false
  assert_block test_tool_result_not_a_prompt
}
test_meta_not_a_prompt() {
  { u_prompt "change it"; a_edit; u_meta; a_text done; } > "$T"
  run_hook "$T" done false
  assert_block test_meta_not_a_prompt
}
test_evidence_only_blocks() {
  { u_prompt "change it"; a_edit; a_text done; } > "$T"
  run_hook "$T" $'## Evidence\nran tests' false
  assert_block test_evidence_only_blocks "missing: Decisions."
}

test_blocks_missing_sections
test_passes_with_sections
test_no_edits_passes
test_env_off
test_legacy_env_off
test_active_passes
test_fallback_blocks
test_fallback_passes
test_prior_turn_edits_ignored
test_tool_result_not_a_prompt
test_meta_not_a_prompt
test_evidence_only_blocks
[[ $FAILS -eq 0 ]] && echo "all passed" || { echo "$FAILS failed"; exit 1; }
