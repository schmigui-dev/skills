#!/usr/bin/env bash
# Append a note to the parked list. Reads the note from stdin, prints "parked #N".
# Read-increment-append runs under a lock so parallel sessions never share an ID.
set -euo pipefail

file="${PARKED_FILE:-$HOME/.claude/parked.md}"
lock="$file.lock"

note="$(tr '\n\t' '  ' | sed -E 's/ +/ /g; s/^ //; s/ $//')"
if [ -z "$note" ]; then
  echo 'nothing to park — usage: /park "note"' >&2
  exit 1
fi

mkdir -p "$(dirname "$file")"

# mkdir is atomic, so it works as a lock without flock (not on macOS by default).
for _ in $(seq 1 100); do
  mkdir "$lock" 2>/dev/null && break
  # A lock older than 30s is left over from a killed run.
  if [ -n "$(find "$lock" -maxdepth 0 -mmin +0.5 2>/dev/null)" ]; then rmdir "$lock" 2>/dev/null || true; fi
  sleep 0.1
done
[ -d "$lock" ] || { echo "park: could not get lock $lock" >&2; exit 1; }
trap 'rmdir "$lock" 2>/dev/null || true' EXIT

[ -f "$file" ] || printf '<!-- next-id: 1 -->\n# Parked\n' > "$file"

n="$(sed -nE 's/^<!-- next-id: ([0-9]+) -->$/\1/p' "$file" | head -1)"
if [ -z "$n" ]; then
  echo "park: no next-id comment in $file" >&2
  exit 1
fi

tmp="$(mktemp "$file.XXXXXX")"
sed -E "s/^<!-- next-id: [0-9]+ -->$/<!-- next-id: $((n + 1)) -->/" "$file" > "$tmp"
[ -z "$(tail -c1 "$tmp")" ] || echo >> "$tmp"
printf -- '- #%s · %s · %s\n' "$n" "$(date +%F)" "$note" >> "$tmp"
mv "$tmp" "$file"

echo "parked #$n"
