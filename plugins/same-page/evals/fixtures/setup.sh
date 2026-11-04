#!/usr/bin/env bash
# Copy the catering fixture into the current dir (the eval case's workspace)
# as a git repo with one baseline commit, then apply a variant.
# Usage: setup.sh <clean|diff|no-glossary|root-glossary>
set -euo pipefail
variant=${1:?variant required}
here="$(cd "$(dirname "$0")" && pwd)"

cp -R "$here/catering/." .
git init -q
git config user.email fixture@example.com
git config user.name fixture
git add -A
git commit -q -m baseline

case "$variant" in
  clean) ;;
  diff)
    cat > src/proposals/offer-discount.ts <<'TS'
import { Quote } from './quote';
import { updateProposal } from './store';

export function applyOfferDiscount(quote: Quote, percent: number): number {
  const presupuestoTotal = quote.total * (1 - percent / 100);
  return presupuestoTotal;
}

export async function markBooked(id: string) {
  await updateProposal(id, { status: 'booked' });
}
TS
    ;;
  no-glossary)
    git rm -q docs/domain/glossary.md
    git commit -q -m "remove glossary"
    ;;
  root-glossary)
    git mv docs/domain/glossary.md GLOSSARY.md
    git commit -q -m "move glossary to root"
    ;;
  *) echo "unknown variant: $variant" >&2; exit 2 ;;
esac
