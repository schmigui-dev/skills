import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Cart } from '../src/cart/cart.ts';

test('add puts an item in the cart', () => {
  const cart = new Cart();
  cart.add({ id: 'a', name: 'Mug', priceCents: 1000, qty: 1 });
  assert.equal(cart.items.length, 1);
});

test('total sums price times quantity', () => {
  const cart = new Cart();
  cart.add({ id: 'a', name: 'Mug', priceCents: 1000, qty: 2 });
  cart.add({ id: 'b', name: 'Pen', priceCents: 250, qty: 1 });
  assert.equal(cart.total(), 2250);
});
