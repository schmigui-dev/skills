#!/usr/bin/env bash
# Parked list operations. Every write runs under a lock and lands via an atomic
# rename, so parallel sessions never share an ID or overwrite each other's notes.
#
#   park.sh add              note on stdin            → parked #N
#   park.sh get <id>         print the note text
#   park.sh replace <id>     new note on stdin        → updated #N: <note>
#   park.sh remove <id>...                            → removed #N / #N not found
#   park.sh merge <id> <id>...                        → merged #A, #B → #A
#   park.sh reindex                                   → #3→#1, #7→#2 / already contiguous
#
# IDs may be written as 3, #3, or 3,5. Set PARKED_FILE to use another file.
set -euo pipefail

file="${PARKED_FILE:-$HOME/.claude/parked.md}"
lock="$file.lock"
entry_re='^- #([0-9]+) · ([^ ]+) · (.*)$'

die() { echo "$*" >&2; exit 1; }

read_note() {
  tr '\n\t' '  ' | sed -E 's/ +/ /g; s/^ //; s/ $//'
}

parse_ids() {
  echo "$*" | tr ',#' '  ' | tr -s ' ' '\n' | sed '/^$/d' | while read -r id; do
    [[ "$id" =~ ^[0-9]+$ ]] || die "not an id: $id"
    echo "$id"
  done
}

acquire_lock() {
  mkdir -p "$(dirname "$file")"
  # mkdir is atomic, so it works as a lock without flock (not on macOS by default).
  for _ in $(seq 1 100); do
    mkdir "$lock" 2>/dev/null && break
    # A lock older than 30s is left over from a killed run.
    if [ -n "$(find "$lock" -maxdepth 0 -mmin +0.5 2>/dev/null)" ]; then rmdir "$lock" 2>/dev/null || true; fi
    sleep 0.1
  done
  [ -d "$lock" ] || die "park: could not get lock $lock"
  trap 'rmdir "$lock" 2>/dev/null || true' EXIT
}

# Runs awk over the file and atomically replaces it with awk's stdout.
# awk's messages for the user go to the path in the `out` variable.
rewrite() {
  local tmp msg
  tmp="$(mktemp "$file.XXXXXX")"
  msg="$(mktemp "$file.msg.XXXXXX")"
  if awk -v out="$msg" "$@" "$file" > "$tmp"; then
    mv "$tmp" "$file"
    cat "$msg"
    rm -f "$msg"
  else
    local rc=$?
    rm -f "$tmp"
    cat "$msg" >&2
    rm -f "$msg"
    exit "$rc"
  fi
}

require_file() {
  [ -f "$file" ] && grep -qE "$entry_re" "$file" || die "nothing parked"
}

cmd="${1:-add}"
shift || true

case "$cmd" in
  add)
    note="$(read_note)"
    [ -n "$note" ] || die 'nothing to park — usage: /park "note"'
    acquire_lock
    [ -f "$file" ] || printf '<!-- next-id: 1 -->\n# Parked\n' > "$file"
    n="$(sed -nE 's/^<!-- next-id: ([0-9]+) -->$/\1/p' "$file" | head -1)"
    [ -n "$n" ] || die "park: no next-id comment in $file"
    tmp="$(mktemp "$file.XXXXXX")"
    sed -E "s/^<!-- next-id: [0-9]+ -->$/<!-- next-id: $((n + 1)) -->/" "$file" > "$tmp"
    [ -z "$(tail -c1 "$tmp")" ] || echo >> "$tmp"
    printf -- '- #%s · %s · %s\n' "$n" "$(date +%F)" "$note" >> "$tmp"
    mv "$tmp" "$file"
    echo "parked #$n"
    ;;

  get)
    ids="$(parse_ids "$@")"
    [ "$(echo "$ids" | wc -l | tr -d ' ')" = 1 ] && [ -n "$ids" ] || die "usage: park.sh get <id>"
    require_file
    line="$(grep -E "^- #$ids · " "$file" | head -1)" || die "#$ids not found"
    echo "$line" | sed -E "s/$entry_re/\3/"
    ;;

  replace)
    ids="$(parse_ids "$@")"
    [ "$(echo "$ids" | wc -l | tr -d ' ')" = 1 ] && [ -n "$ids" ] || die 'usage: /repark <id> "new text"'
    note="$(read_note)"
    [ -n "$note" ] || die 'usage: /repark <id> "new text"'
    acquire_lock
    require_file
    NOTE="$note" rewrite -v id="$ids" '
      match($0, /^- #[0-9]+ · [^ ]+ · /) {
        split($0, f, " · ")
        if (substr(f[1], 4) == id) {
          $0 = f[1] " · " f[2] " · " ENVIRON["NOTE"]; found = 1
        }
      }
      { print }
      END {
        if (!found) { print "#" id " not found" > out; exit 1 }
        print "updated #" id ": " ENVIRON["NOTE"] > out
      }'
    ;;

  remove)
    ids="$(parse_ids "$@")"
    [ -n "$ids" ] || die "usage: /unpark <id>"
    acquire_lock
    require_file
    rewrite -v ids="$(echo "$ids" | tr '\n' ' ')" '
      BEGIN { n = split(ids, want, " "); for (i = 1; i <= n; i++) drop[want[i]] = 1 }
      match($0, /^- #[0-9]+ · /) {
        split($0, f, " · "); id = substr(f[1], 4)
        if (id in drop) { gone[id] = 1; next }
      }
      { print }
      END {
        for (i = 1; i <= n; i++)
          print (want[i] in gone ? "removed #" : "#") want[i] (want[i] in gone ? "" : " not found") > out
      }'
    ;;

  merge)
    ids="$(parse_ids "$@" | sort -n | uniq)"
    [ "$(echo "$ids" | sed '/^$/d' | wc -l | tr -d ' ')" -ge 2 ] || die "usage: /mergepark <id> <id> [id...]"
    acquire_lock
    require_file
    # Two passes over the same file: collect the notes, then rewrite.
    rewrite -v ids="$(echo "$ids" | tr '\n' ' ')" '
      BEGIN { n = split(ids, want, " "); target = want[1]; for (i = 1; i <= n; i++) pick[want[i]] = 1 }
      FNR == NR {
        if (match($0, /^- #[0-9]+ · [^ ]+ · /)) {
          id = substr($0, 4, index($0, " · ") - 4)
          if (id in pick) note[id] = substr($0, RLENGTH + 1)
        }
        next
      }
      FNR == 1 {
        missing = 0
        for (i = 1; i <= n; i++) if (!(want[i] in note)) { print "#" want[i] " not found" > out; missing = 1 }
        if (missing) exit 1
        joined = note[want[1]]
        for (i = 2; i <= n; i++) joined = joined " | " note[want[i]]
      }
      match($0, /^- #[0-9]+ · [^ ]+ · /) {
        id = substr($0, 4, index($0, " · ") - 4)
        if (id == target) { print substr($0, 1, RLENGTH) joined; next }
        if (id in pick) next
      }
      { print }
      END {
        if (missing) exit 1
        msg = "merged #" want[1]
        for (i = 2; i <= n; i++) msg = msg ", #" want[i]
        print msg " → #" target > out
      }' "$file"
    ;;

  reindex)
    acquire_lock
    require_file
    rewrite '
      FNR == NR {
        if (match($0, /^- #[0-9]+ · /)) ids[++n] = substr($0, 4, index($0, " · ") - 4) + 0
        next
      }
      FNR == 1 {
        # Insertion sort; parked lists are short.
        for (i = 2; i <= n; i++) { v = ids[i]; for (j = i - 1; j >= 1 && ids[j] > v; j--) ids[j + 1] = ids[j]; ids[j + 1] = v }
        for (i = 1; i <= n; i++) { newid[ids[i]] = i; if (ids[i] != i) changed = changed (changed ? ", " : "") "#" ids[i] "→#" i }
      }
      /^<!-- next-id: [0-9]+ -->$/ { print "<!-- next-id: " n + 1 " -->"; next }
      match($0, /^- #[0-9]+ · /) {
        id = substr($0, 4, index($0, " · ") - 4) + 0
        print "- #" newid[id] substr($0, index($0, " · ")); next
      }
      { print }
      END { print (changed ? changed : "already contiguous") > out }' "$file"
    ;;

  *)
    die "usage: park.sh add|get|replace|remove|merge|reindex"
    ;;
esac
