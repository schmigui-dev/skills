import { Cart } from '../cart/cart.ts';

export interface Payment {
  method: 'card' | 'gift-card';
  token: string;
}

export function checkout(cart: Cart, payment: Payment): { ok: boolean; charged: number } {
  const charged = cart.total();
  if (charged <= 0) return { ok: false, charged: 0 };
  // Payment provider call omitted in this fixture.
  return { ok: payment.token.length > 0, charged };
}
