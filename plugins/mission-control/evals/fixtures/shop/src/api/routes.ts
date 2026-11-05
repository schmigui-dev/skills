import { Cart } from '../cart/cart';
import { checkout } from '../checkout/checkout';

const cart = new Cart();

export function handle(method: string, path: string, body: any): { status: number; body: unknown } {
  if (method === 'POST' && path === '/cart/items') {
    cart.add(body);
    return { status: 201, body: { total: cart.total() } };
  }
  if (method === 'POST' && path === '/checkout') {
    const result = checkout(cart, body.payment);
    return { status: result.ok ? 200 : 402, body: result };
  }
  return { status: 404, body: { error: 'not found' } };
}
