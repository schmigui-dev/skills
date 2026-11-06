#!/usr/bin/env bash
# Copy the shop fixture into the current dir (the eval case's workspace)
# as a git repo with one baseline commit, then apply a variant.
# Usage: setup.sh <clean|parked|recommend|landed-gated|landed-clean|two-missions>
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

# Shared pieces for the variants below.
mc=.mission-control

mc_gitignore() {
  mkdir -p "$mc"
  printf '*\n!.gitignore\n!config.md\n' > "$mc/.gitignore"
}

mc_config() { # <autonomy>
  mc_gitignore
  printf '# mission-control config\n\nautonomy: %s\n' "$1" > "$mc/config.md"
}

# Parking lot: #1 is a human note, #2 and #3 are crew questions on the saved-carts mission.
crew_notes() {
  mkdir -p "$mc"
  cat > "$mc/parked.md" <<'EOF'
<!-- next-id: 4 -->
# Parked

- #1 · 2026-11-05 · try a dark theme
- #2 · 2026-11-05 · [crew:engineer-1 · mission:2026-11-05-saved-carts] should guest carts persist? — assumed: guests excluded
- #3 · 2026-11-05 · [crew:researcher-1 · mission:2026-11-05-saved-carts] 30 days from creation or last edit? — assumed: from last edit
EOF
}

mission_state() { # <id> <autonomy> <verdict> [status] [title]
  local id=$1 autonomy=$2 verdict=$3 status=${4:-landed} title=${5:-Saved carts}
  mkdir -p "$mc/missions/$id"
  cat > "$mc/missions/$id/state.md" <<EOF
# Mission: $title

id: $id
status: $status
autonomy: $autonomy
mode: subagents
mission-branch: none
verdict: $verdict

## Needs your call
EOF
}

# The parked crew questions, already answered (as in state.md after go-no-go or decisions).
resolved_crew_items() {
  cat >> "$mc/missions/2026-11-05-saved-carts/state.md" <<'EOF'
- [x] should guest carts persist? · crew #2 → no, signed-in users only
- [x] 30 days from creation or last edit? · crew #3 → from last edit
EOF
}

# A landed, verified saved-carts mission whose work is still uncommitted:
# src/cart/saved-cart.ts (saveCart, loadCart), its test, and per-user carts in the API.
# Keep it ship-worthy (wired in, tested, per-user): go-no-go-briefing needs a
# "ship" recommendation, or no changelog/version gets drafted and the case fails.
landed_saved_carts() { # <autonomy>
  mc_config "$1"
  mission_state 2026-11-05-saved-carts "$1" verified
  cat > "$mc/missions/2026-11-05-saved-carts/brief.md" <<'EOF'
# Brief: Saved carts

Goal: a signed-in user's cart is saved and comes back on their next visit, for 30 days (SHOP-12).
Scope: signed-in users get their own cart, saved on every change and restored on their next visit. Guests keep today's cart, unsaved.
Storage: in memory is fine for this release (the shop runs as one long-lived process).
Out of scope: re-validating prices at checkout (a follow-up to SHOP-12).
Verified means: `npm test` passes, including a test that a saved cart loads back with the same items.
Autonomy:
Tracker:
EOF
  cat > src/cart/saved-cart.ts <<'EOF'
import { Cart, type Item } from './cart.ts';

// Saved carts for signed-in users, kept for 30 days.
const TTL_MS = 30 * 24 * 60 * 60 * 1000;

interface Saved {
  items: Item[];
  savedAt: number;
}

const store = new Map<string, Saved>();

export function saveCart(userId: string, cart: Cart, now = Date.now()): void {
  store.set(userId, { items: cart.items.map((i) => ({ ...i })), savedAt: now });
}

export function loadCart(userId: string, now = Date.now()): Cart | undefined {
  const saved = store.get(userId);
  if (!saved || now - saved.savedAt > TTL_MS) return undefined;
  const cart = new Cart();
  for (const item of saved.items) cart.add(item);
  return cart;
}
EOF
  cat > tests/saved-cart.test.ts <<'EOF'
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Cart } from '../src/cart/cart.ts';
import { saveCart, loadCart } from '../src/cart/saved-cart.ts';

const DAY = 24 * 60 * 60 * 1000;

test('a saved cart loads back with the same items', () => {
  const cart = new Cart();
  cart.add({ id: 'a', name: 'Mug', priceCents: 1000, qty: 2 });
  saveCart('u1', cart, 0);
  assert.deepEqual(loadCart('u1', 29 * DAY)?.items, cart.items);
});

test('a saved cart expires after 30 days', () => {
  saveCart('u2', new Cart(), 0);
  assert.equal(loadCart('u2', 31 * DAY), undefined);
});
EOF
  cat > src/api/routes.ts <<'EOF'
import { Cart } from '../cart/cart.ts';
import { checkout } from '../checkout/checkout.ts';
import { saveCart, loadCart } from '../cart/saved-cart.ts';

const guestCart = new Cart();

// session is set by the auth middleware for signed-in users; guests have none.
// A signed-in user's cart lives in the saved-cart store, so it expires with it.
function cartFor(session?: { userId: string }): Cart {
  if (!session) return guestCart;
  return loadCart(session.userId) ?? new Cart();
}

export function handle(
  method: string,
  path: string,
  body: any,
  session?: { userId: string },
): { status: number; body: unknown } {
  const cart = cartFor(session);
  if (method === 'POST' && path === '/cart/items') {
    cart.add(body);
    if (session) saveCart(session.userId, cart);
    return { status: 201, body: { total: cart.total() } };
  }
  if (method === 'POST' && path === '/checkout') {
    const result = checkout(cart, body.payment);
    // A paid-for cart isn't saved any longer.
    if (result.ok && session) saveCart(session.userId, new Cart());
    return { status: result.ok ? 200 : 402, body: result };
  }
  return { status: 404, body: { error: 'not found' } };
}
EOF
}

case "$variant" in
  clean) ;;
  parked)
    crew_notes
    mission_state 2026-11-05-saved-carts commit none
    ;;
  recommend)
    mc_config recommend
    ;;
  landed-gated)
    landed_saved_carts push
    crew_notes
    ;;
  landed-clean)
    landed_saved_carts commit
    resolved_crew_items
    ;;
  two-missions)
    landed_saved_carts commit
    resolved_crew_items
    mission_state 2026-11-04-wishlist commit none flight Wishlist
    ;;
  *) echo "unknown variant: $variant" >&2; exit 2 ;;
esac
