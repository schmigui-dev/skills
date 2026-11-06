#!/usr/bin/env bash
# Creates <project root>/.mission-control/ (with its .gitignore) if missing and
# prints its absolute path. Idempotent.
#
#   mc-init.sh [dir]    dir, else the main worktree of the current git repo
#                       (also from inside a linked worktree), else the current directory
set -euo pipefail

# The main worktree: the directory holding the repo's common .git dir. From a
# linked worktree (a mission or crew worktree), `--show-toplevel` would give the
# linked worktree, where .mission-control/ doesn't exist.
main_worktree() {
  local common
  common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" ||
    common="$(git rev-parse --git-common-dir 2>/dev/null)" || return 1
  # git older than 2.31 has no --path-format and may print a path relative to cwd.
  case "$common" in /*) ;; *) common="$(pwd)/$common" ;; esac
  [ -d "$common" ] || return 1
  common="$(cd "$common" && pwd -P)"
  # Only a normal `<worktree>/.git` layout; submodules, bare repos and custom
  # GIT_DIRs fall back to the toplevel.
  [ "$(basename "$common")" = .git ] || return 1
  dirname "$common"
}

if [ $# -ge 1 ] && [ -n "$1" ]; then
  root="$1"
else
  root="$(main_worktree || git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
root="$(cd "$root" && pwd -P)"

mc="$root/.mission-control"
mkdir -p "$mc"
[ -f "$mc/.gitignore" ] || printf '*\n!.gitignore\n!config.md\n' > "$mc/.gitignore"
echo "$mc"
