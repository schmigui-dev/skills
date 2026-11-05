#!/usr/bin/env bash
# Copy the shop fixture into the current dir (the eval case's workspace)
# as a git repo with one baseline commit, then apply a variant.
# Usage: setup.sh <clean>   (later tasks add variants)
set -euo pipefail
variant=${1:?variant required}
here="$(cd "$(dirname "$0")" && pwd)"

# Only ever run inside an empty eval workspace: never copy the fixture or set
# a fixture git identity inside a real repo.
if [ -e .git ] || [ -n "$(ls -A . 2>/dev/null)" ]; then
  echo "setup.sh: refusing to run in a non-empty directory ($(pwd))" >&2
  exit 1
fi

cp -R "$here/shop/." .
git init -q
git config user.email fixture@example.com
git config user.name fixture
git add -A
git commit -q -m baseline

case "$variant" in
  clean) ;;
  *) echo "unknown variant: $variant" >&2; exit 2 ;;
esac
