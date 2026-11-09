#!/usr/bin/env bash
# Tests for park.sh locking. Run: bash plugins/parking-lot/scripts/test-park.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
park="$here/park.sh"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

ok()   { echo "ok   $1"; }
fail() { echo "FAIL $1: $2"; fails=$((fails + 1)); }

fresh() { export PARKED_FILE="$tmp/$1/parked.md"; mkdir -p "$tmp/$1"; }

# Sets a path's mtime to N seconds ago (BSD and GNU touch both take -t).
age() {
  local stamp
  stamp="$(date -r $(( $(date +%s) - $2 )) +%Y%m%d%H%M.%S 2>/dev/null || date -d "@$(( $(date +%s) - $2 ))" +%Y%m%d%H%M.%S)"
  touch -t "$stamp" "$1"
}

test_add_basic() {
  fresh basic
  out="$(echo "first note" | bash "$park" add)"
  [ "$out" = "parked #1" ] || { fail test_add_basic "got: $out"; return; }
  [ ! -e "$PARKED_FILE.lock" ] || { fail test_add_basic "lock left behind"; return; }
  ok test_add_basic
}

test_stale_lock_reclaimed() {
  fresh stale
  mkdir "$PARKED_FILE.lock"; age "$PARKED_FILE.lock" 120
  start=$(date +%s)
  out="$(echo "after crash" | PARK_LOCK_TRIES=20 bash "$park" add 2>&1)"
  # Reaping is immediate; waiting out every retry means the stale lock was never reaped.
  [ $(( $(date +%s) - start )) -le 3 ] || { fail test_stale_lock_reclaimed "stale lock not reaped (waited out the retries)"; return; }
  [ "$out" = "parked #1" ] || { fail test_stale_lock_reclaimed "got: $out"; return; }
  [ ! -e "$PARKED_FILE.lock" ] || { fail test_stale_lock_reclaimed "lock left behind"; return; }
  ls "$tmp/stale" | grep -q stale && { fail test_stale_lock_reclaimed "tombstone left behind"; return; }
  ok test_stale_lock_reclaimed
}

test_fresh_lock_times_out_without_writing() {
  fresh busy
  echo "existing" | bash "$park" add >/dev/null
  before="$(cat "$PARKED_FILE")"
  mkdir "$PARKED_FILE.lock"
  out="$(echo "should not land" | PARK_LOCK_TRIES=3 bash "$park" add 2>&1)"; rc=$?
  [ "$rc" -ne 0 ] || { fail test_fresh_lock_times_out_without_writing "exit 0, expected failure"; return; }
  echo "$out" | grep -q "could not get lock" || { fail test_fresh_lock_times_out_without_writing "no lock error: $out"; return; }
  [ "$(cat "$PARKED_FILE")" = "$before" ] || { fail test_fresh_lock_times_out_without_writing "file changed while unlocked"; return; }
  [ -d "$PARKED_FILE.lock" ] || { fail test_fresh_lock_times_out_without_writing "removed another run's lock"; return; }
  rmdir "$PARKED_FILE.lock"
  ok test_fresh_lock_times_out_without_writing
}

test_parallel_adds() {
  fresh parallel
  for i in $(seq 1 20); do echo "note $i" | bash "$park" add >/dev/null & done
  wait
  n="$(grep -c '^- #' "$PARKED_FILE")"
  ids="$(grep '^- #' "$PARKED_FILE" | sed -E 's/^- #([0-9]+) .*/\1/' | sort -n | tr '\n' ' ')"
  [ "$n" = 20 ] || { fail test_parallel_adds "got $n lines"; return; }
  [ "$ids" = "$(seq 1 20 | tr '\n' ' ')" ] || { fail test_parallel_adds "ids: $ids"; return; }
  ok test_parallel_adds
}

test_add_basic
test_stale_lock_reclaimed
test_fresh_lock_times_out_without_writing
test_parallel_adds

[ "$fails" = 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
