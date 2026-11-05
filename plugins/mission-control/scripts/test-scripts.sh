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
  if echo "x" | bash "$PARK" add --crew engineer-1 2>/dev/null; then fail "exit 0" || return 1; fi
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
}

for CURRENT in $(declare -F | awk '{print $3}' | grep '^test_'); do
  tmp="$(mktemp -d)"
  if ( cd "$tmp" && unset PARKED_FILE && "$CURRENT" ); then echo "ok $CURRENT"; else
    echo "FAIL $CURRENT (see above)" >/dev/null; fails=$((fails + 1)); fi
  rm -rf "$tmp"
done
[ "$fails" = 0 ]
