import { OrderItem } from '../types';

interface Cart {
  merchantId: string;
  items: OrderItem[];
  updatedAt: Date;
}

// in-memory cart per userId (TTL 30 min)
const carts = new Map<string, Cart>();
const TTL_MS = 30 * 60 * 1000;

function cleanup(): void {
  const now = Date.now();
  for (const [key, cart] of carts) {
    if (now - cart.updatedAt.getTime() > TTL_MS) carts.delete(key);
  }
}

export function getCart(userId: string): Cart | null {
  cleanup();
  return carts.get(userId) ?? null;
}

export function addItem(userId: string, merchantId: string, item: OrderItem): Cart {
  const existing = carts.get(userId);
  const items = existing?.items ?? [];

  // merge same menuId
  const idx = items.findIndex((i) => i.menuId === item.menuId);
  if (idx >= 0) {
    items[idx] = { ...items[idx], quantity: items[idx].quantity + item.quantity };
  } else {
    items.push(item);
  }

  const cart: Cart = { merchantId, items, updatedAt: new Date() };
  carts.set(userId, cart);
  return cart;
}

export function clearCart(userId: string): void {
  carts.delete(userId);
}

export function cartTotal(cart: Cart): number {
  return cart.items.reduce((s, i) => s + i.unitPrice * i.quantity, 0);
}

export function cartSummary(cart: Cart): string {
  return cart.items.map((i) => `${i.menuName} ×${i.quantity}`).join(', ');
}
