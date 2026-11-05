#!/usr/bin/env bash
# Creates <project root>/.mission-control/ (with its .gitignore) if missing and
# prints its absolute path. Idempotent.
#
#   mc-init.sh [dir]    dir, else the git toplevel, else the current directory
set -euo pipefail

if [ $# -ge 1 ] && [ -n "$1" ]; then
  root="$1"
else
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
root="$(cd "$root" && pwd -P)"

mc="$root/.mission-control"
mkdir -p "$mc"
[ -f "$mc/.gitignore" ] || printf '*\n!.gitignore\n!config.md\n' > "$mc/.gitignore"
echo "$mc"
