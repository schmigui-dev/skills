#!/usr/bin/env bash
# Write a case's scaffold.sh. scaffold_script must live inside the case dir,
# so each case carries a one-line wrapper around fixtures/setup.sh.
# Usage: fixtures/new-case.sh <case-dir> <variant>
set -euo pipefail
dir=${1:?case dir}; variant=${2:?variant}
mkdir -p "$dir"
printf '#!/usr/bin/env bash\nexec "$(dirname "$0")/../fixtures/setup.sh" %s\n' "$variant" > "$dir/scaffold.sh"
chmod +x "$dir/scaffold.sh"
