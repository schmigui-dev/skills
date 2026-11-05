import { Cart } from './cart.ts';

// Hardcoded discount codes. Only SAVE10 exists today.
export function applyDiscount(cart: Cart, code: string): number {
  const total = cart.total();
  if (code === 'SAVE10') return Math.round(total * 0.9);
  return total;
}
