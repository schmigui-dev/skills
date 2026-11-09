#!/usr/bin/env bash
# Tests for mc-init.sh and park.sh. Plain bash 3.2.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT="$HERE/mc-init.sh"
PARK="$HERE/park.sh"
today="$(date +%F)"
fails=0

fail() { echo "FAIL $CURRENT: $*"; return 1; }

test_init_creates_gitignore() {
  git init -q . || return 1
  local out; out="$(bash "$INIT")"
  local want; want="$(pwd -P)/.mission-control"
  [ "$out" = "$want" ] || fail "printed '$out', want '$want'" || return 1
  [ "$(cat .mission-control/.gitignore; echo x)" = "$(printf '*\n!.gitignore\n!config.md\nx')" ] || fail "gitignore content wrong" || return 1
  cp .mission-control/.gitignore before
  bash "$INIT" >/dev/null
  cmp -s before .mission-control/.gitignore || fail "second run changed gitignore" || return 1
}

test_add_human() {
  export PARKED_FILE="$PWD/p.md"
  local out; out="$(echo "idea" | bash "$PARK" add)"
  [ "$out" = "parked #1" ] || fail "got '$out'" || return 1
  grep -qxF -- "- #1 · $today · idea" p.md || fail "line missing: $(cat p.md)" || return 1
}

test_add_crew() {
  export PARKED_FILE="$PWD/p.md"
  echo "guest carts?" | bash "$PARK" add --crew engineer-1 --mission 2026-11-05-saved-carts --assumed "guests excluded" >/dev/null || return 1
  local want="· [crew:engineer-1 · mission:2026-11-05-saved-carts] guest carts? — assumed: guests excluded"
  grep -qxF -- "- #1 · $today $want" p.md || fail "bad line: $(cat p.md)" || return 1
}

test_crew_requires_mission() {
  export PARKED_FILE="$PWD/p.md"
  local rc=0; echo "x" | bash "$PARK" add --crew engineer-1 2>/dev/null || rc=$?
  [ "$rc" = 1 ] || fail "exit $rc, want 1" || return 1
  [ ! -e p.md ] || ! grep -q '^- #' p.md || fail "wrote a note" || return 1
}

test_list_filters() {
  export PARKED_FILE="$PWD/p.md"
  echo "human" | bash "$PARK" add >/dev/null
  echo "a note" | bash "$PARK" add --crew c1 --mission A >/dev/null
  echo "b note" | bash "$PARK" add --crew c2 --mission B >/dev/null
  local out; out="$(bash "$PARK" list --mission A --crew-only)"
  [ "$out" = "- #2 · $today · [crew:c1 · mission:A] a note" ] || fail "got '$out'" || return 1
}

test_list_empty() {
  export PARKED_FILE="$PWD/missing.md"
  local out rc=0; out="$(bash "$PARK" list)" || rc=$?
  [ "$out" = "nothing parked" ] && [ "$rc" = 0 ] || fail "got '$out' rc=$rc" || return 1
}

test_parked_file_wins() {
  git init -q . || return 1
  export PARKED_FILE="$PWD/elsewhere/p.md"
  echo "x" | bash "$PARK" add >/dev/null || return 1
  [ -f elsewhere/p.md ] || fail "not written" || return 1
  [ ! -e .mission-control ] || fail ".mission-control created" || return 1
}

test_parallel_adds() {
  export PARKED_FILE="$PWD/p.md"
  local i
  for i in $(seq 1 20); do echo "note $i" | bash "$PARK" add >/dev/null & done
  wait
  for i in $(seq 1 20); do
    [ "$(grep -c -- "^- #$i · " p.md)" = 1 ] || fail "id $i count wrong" || return 1
  done
  grep -qxF '<!-- next-id: 21 -->' p.md || fail "next-id not 21" || return 1
}

test_remove() {
  export PARKED_FILE="$PWD/p.md"
  echo "x" | bash "$PARK" add >/dev/null
  local out; out="$(bash "$PARK" remove 1 9)"
  [ "$out" = "$(printf 'removed #1\n#9 not found')" ] || fail "got '$out'" || return 1
  ! grep -q -- '^- #1 · ' p.md || fail "line still in file" || return 1
}

test_remove_leading_zero() {
  export PARKED_FILE="$PWD/p.md"
  echo "a" | bash "$PARK" add >/dev/null; echo "b" | bash "$PARK" add >/dev/null; echo "c" | bash "$PARK" add >/dev/null
  local out; out="$(bash "$PARK" remove 03)"
  [ "$out" = "removed #3" ] || fail "got '$out'" || return 1
}

test_get() {
  export PARKED_FILE="$PWD/p.md"
  echo "plain" | bash "$PARK" add >/dev/null
  echo "tagged" | bash "$PARK" add --crew c1 --mission m1 >/dev/null
  [ "$(bash "$PARK" get 1)" = "plain" ] || fail "get 1" || return 1
  [ "$(bash "$PARK" get '#2')" = "[crew:c1 · mission:m1] tagged" ] || fail "get 2" || return 1
}

test_list_order() {
  export PARKED_FILE="$PWD/p.md"
  echo "a" | bash "$PARK" add >/dev/null; echo "b" | bash "$PARK" add >/dev/null
  [ "$(bash "$PARK" list | head -1)" = "- #2 · $today · b" ] || fail "newest first" || return 1
  [ "$(bash "$PARK" list --oldest | head -1)" = "- #1 · $today · a" ] || fail "--oldest" || return 1
}

test_unknown_command() {
  export PARKED_FILE="$PWD/p.md"
  local out rc=0; out="$(bash "$PARK" bogus 2>&1)" || rc=$?
  [ "$rc" = 1 ] && [ "$out" = "usage: park.sh add|list|get|remove" ] || fail "rc=$rc out='$out'" || return 1
}

test_mission_alone_rejected() {
  export PARKED_FILE="$PWD/p.md"
  local rc=0; echo "x" | bash "$PARK" add --mission m1 2>/dev/null || rc=$?
  [ "$rc" = 1 ] && [ ! -e p.md ] || fail "rc=$rc" || return 1
}

test_dot_rejected() {
  export PARKED_FILE="$PWD/p.md"
  local rc=0; echo "x" | bash "$PARK" add --crew "a · b" --mission m 2>/dev/null || rc=$?
  [ "$rc" = 1 ] && [ ! -e p.md ] || fail "rc=$rc" || return 1
}

test_crew_only_anchored() {
  export PARKED_FILE="$PWD/p.md"
  echo "human mentions [crew:x] tag" | bash "$PARK" add >/dev/null
  local out; out="$(bash "$PARK" list --crew-only)"
  [ "$out" = "nothing parked" ] || fail "got '$out'" || return 1
}

test_worktree_style() {
  mkdir other repo; ( cd repo && git init -q )
  export PARKED_FILE="$PWD/other/p.md"
  ( cd repo && echo "x" | bash "$PARK" add --crew c --mission m >/dev/null ) || return 1
  [ -f other/p.md ] || fail "not written" || return 1
  [ ! -e repo/.mission-control ] || fail ".mission-control in cwd" || return 1
}

test_linked_worktree_uses_main_repo() {
  git init -q main || return 1
  git -C main -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m base || return 1
  git -C main worktree add -q -b mc/m "$PWD/main-mc-m" || return 1
  ( cd main && echo "from main" | bash "$PARK" add >/dev/null ) || return 1
  local out; out="$(cd main-mc-m && bash "$PARK" list)"
  [ "$out" = "- #1 · $today · from main" ] || fail "list from worktree got '$out'" || return 1
  local mc; mc="$(cd main-mc-m && bash "$INIT")"
  [ "$mc" = "$(cd main && pwd -P)/.mission-control" ] || fail "mc-init printed '$mc'" || return 1
  [ ! -e main-mc-m/.mission-control ] || fail ".mission-control created in the worktree" || return 1
  [ -z "$(git -C main-mc-m status --porcelain)" ] || fail "worktree not clean" || return 1
}

test_init_find_creates_nothing() {
  git init -q . || return 1
  local out; out="$(bash "$INIT" --find)"
  [ "$out" = "$(pwd -P)/.mission-control" ] || fail "printed '$out'" || return 1
  [ ! -e .mission-control ] || fail "--find created .mission-control" || return 1
}

test_add_strips_wrapping_quotes() {
  export PARKED_FILE="$PWD/p.md"
  echo '"quoted note"' | bash "$PARK" add >/dev/null
  echo "'single'" | bash "$PARK" add >/dev/null
  echo '"a" or "b"' | bash "$PARK" add >/dev/null
  [ "$(bash "$PARK" get 1)" = "quoted note" ] || fail "get 1: $(bash "$PARK" get 1)" || return 1
  [ "$(bash "$PARK" get 2)" = "single" ] || fail "get 2: $(bash "$PARK" get 2)" || return 1
  [ "$(bash "$PARK" get 3)" = '"a" or "b"' ] || fail "get 3: $(bash "$PARK" get 3)" || return 1
}

test_stale_lock_reclaimed() {
  export PARKED_FILE="$PWD/p.md"
  mkdir p.md.lock; touch -t 200001010000 p.md.lock
  local start=$SECONDS out; out="$(echo "x" | bash "$PARK" add)"
  [ "$out" = "parked #1" ] && [ $((SECONDS - start)) -le 3 ] || fail "out='$out'" || return 1
}

test_held_lock_dies() {
  export PARKED_FILE="$PWD/p.md"
  mkdir p.md.lock
  local rc=0; echo "x" | PARK_LOCK_TRIES=5 bash "$PARK" add 2>/dev/null || rc=$?
  [ "$rc" = 1 ] || fail "rc=$rc" || return 1
  [ -d p.md.lock ] || fail "holder's lock was removed" || return 1
}

for CURRENT in $(declare -F | awk '{print $3}' | grep '^test_'); do
  tmp="$(mktemp -d)"
  if ( cd "$tmp" && unset PARKED_FILE && "$CURRENT" ); then echo "ok $CURRENT"; else
    echo "FAIL $CURRENT"; fails=$((fails + 1)); fi
  rm -rf "$tmp"
done
[ "$fails" = 0 ]
