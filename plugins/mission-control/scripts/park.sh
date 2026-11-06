#!/usr/bin/env bash
# Parked list operations. Every write runs under a lock and lands via an atomic
# rename, so parallel sessions never share an ID or overwrite each other's notes.
#
#   park.sh add [--crew <id> --mission <id>] [--assumed <text>]   note on stdin → parked #N
#   park.sh list [--mission <id>] [--crew-only] [--oldest]        newest first by default
#   park.sh get <id>         print the note text
#   park.sh remove <id>...                                        → removed #N / #N not found
#
# IDs may be written as 3, #3, or 3,5. Default file is <project>/.mission-control/parked.md
# in the main worktree, also when run from a linked (mission or crew) worktree (resolved
# by mc-init.sh next to this script). Set PARKED_FILE to use another file.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -n "${PARKED_FILE:-}" ]; then
  file="$PARKED_FILE"
else
  file="$(bash "$here/mc-init.sh")/parked.md"
fi
lock="$file.lock"
entry_re='^- #([0-9]+) · ([^ ]+) · (.*)$'

die() { echo "$*" >&2; exit 1; }

read_note() {
  tr '\n\t' '  ' | sed -E 's/ +/ /g; s/^ //; s/ $//'
}

# Drops one pair of quotes wrapping the whole note ("note" or 'note' → note),
# as left by `/park "note"`. Only when the quote char appears nowhere inside, so
# `"a" or "b"` is kept as written.
strip_quotes() {
  local s="$1" q inner
  if [ "${#s}" -ge 2 ]; then
    q="${s:0:1}"
    inner="${s:1:${#s}-2}"
    if { [ "$q" = '"' ] || [ "$q" = "'" ]; } && [ "${s: -1}" = "$q" ]; then
      case "$inner" in *"$q"*) ;; *) s="$inner" ;; esac
    fi
  fi
  printf '%s' "$s"
}

parse_ids() {
  echo "$*" | tr ',#' '  ' | tr -s ' ' '\n' | sed '/^$/d' | while read -r id; do
    [[ "$id" =~ ^[0-9]+$ ]] || die "not an id: $id"
    echo "$((10#$id))"
  done
}

mtime() {
  local t
  t="$(stat -f %m "$1" 2>/dev/null)" && [[ "$t" =~ ^[0-9]+$ ]] && { echo "$t"; return; }
  stat -c %Y "$1" 2>/dev/null
}

acquire_lock() {
  mkdir -p "$(dirname "$file")"
  local i m held=0 tomb
  # mkdir is atomic, so it works as a lock without flock (not on macOS by default).
  for ((i = 0; i < ${PARK_LOCK_TRIES:-100}; i++)); do
    if mkdir "$lock" 2>/dev/null; then held=1; break; fi
    # A lock 30s or older is left over from a killed run. Reap it by renaming it
    # to a unique tombstone (atomic, so only one waiter wins), then re-check the
    # tombstone's age: if we grabbed a fresh lock by mistake, put it back.
    m="$(mtime "$lock" || true)"
    if [ -n "$m" ] && [ $(( $(date +%s) - m )) -ge 30 ]; then
      tomb="$lock.stale.$$.$RANDOM"
      if mv "$lock" "$tomb" 2>/dev/null; then
        m="$(mtime "$tomb" || true)"
        if [ -n "$m" ] && [ $(( $(date +%s) - m )) -ge 30 ]; then
          rmdir "$tomb" 2>/dev/null || true
        elif [ ! -e "$lock" ]; then
          mv "$tomb" "$lock" 2>/dev/null || rmdir "$tomb" 2>/dev/null || true
        fi
      fi
      continue
    fi
    sleep 0.1
  done
  [ "$held" = 1 ] || die "park: could not get lock $lock"
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
    crew="" mission="" assumed=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --crew)    [ $# -ge 2 ] || die "--crew needs a value"; crew="$2"; shift 2 ;;
        --mission) [ $# -ge 2 ] || die "--mission needs a value"; mission="$2"; shift 2 ;;
        --assumed) [ $# -ge 2 ] || die "--assumed needs a value"; assumed="$2"; shift 2 ;;
        *) die "usage: park.sh add [--crew <crew-id> --mission <mission-id>] [--assumed <text>]" ;;
      esac
    done
    case "$crew$mission" in *·*) die "--crew/--mission must not contain '·'" ;; esac
    [ -z "$crew" ] || [ -n "$mission" ] || die "--crew requires --mission"
    [ -z "$mission" ] || [ -n "$crew" ] || die "--mission requires --crew"
    note="$(strip_quotes "$(read_note)")"
    [ -n "$note" ] || die 'nothing to park — usage: park.sh add (note on stdin)'
    if [ -n "$crew" ]; then
      note="[crew:$crew · mission:$mission] $note"
      if [ -n "$assumed" ]; then
        assumed="$(echo "$assumed" | read_note)"
        note="$note — assumed: $assumed"
      fi
    fi
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

  list)
    mission="" crew_only=0 oldest=0
    while [ $# -gt 0 ]; do
      case "$1" in
        --mission)   [ $# -ge 2 ] || die "--mission needs a value"; mission="$2"; shift 2 ;;
        --crew-only) crew_only=1; shift ;;
        --oldest)    oldest=1; shift ;;
        *) die "usage: park.sh list [--mission <id>] [--crew-only] [--oldest]" ;;
      esac
    done
    out=""
    if [ -f "$file" ]; then
      out="$(grep -E "$entry_re" "$file" || true)"
      # The crew tag sits right after the date field; anchor so notes can't spoof it.
      tag_re='^- #[0-9]+ · [^ ]+ · \[crew:'
      if [ "$crew_only" = 1 ] || [ -n "$mission" ]; then out="$(echo "$out" | grep -E "$tag_re" || true)"; fi
      if [ -n "$mission" ]; then out="$(echo "$out" | grep -F "mission:$mission]" || true)"; fi
      if [ -n "$out" ] && [ "$oldest" = 0 ]; then
        out="$(echo "$out" | awk '{ l[NR] = $0 } END { for (i = NR; i >= 1; i--) print l[i] }')"
      fi
    fi
    [ -n "$out" ] && echo "$out" || echo "nothing parked"
    ;;

  get)
    ids="$(parse_ids "$@")"
    [ "$(echo "$ids" | wc -l | tr -d ' ')" = 1 ] && [ -n "$ids" ] || die "usage: park.sh get <id>"
    require_file
    line="$(grep -E "^- #$ids · " "$file" | head -1)" || die "#$ids not found"
    echo "$line" | sed -E "s/$entry_re/\3/"
    ;;

  remove)
    ids="$(parse_ids "$@")"
    [ -n "$ids" ] || die "usage: park.sh remove <id>..."
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

  *)
    die "usage: park.sh add|list|get|remove"
    ;;
esac
