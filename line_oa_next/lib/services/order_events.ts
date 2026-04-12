// Simple in-process SSE event bus for new order notifications

type Listener = (data: string) => void;

const listeners = new Set<Listener>();

export function subscribe(fn: Listener): () => void {
  listeners.add(fn);
  return () => listeners.delete(fn);
}

export function emitNewOrder(orderId: string, customerName: string, totalPrice: number): void {
  const payload = JSON.stringify({ orderId, customerName, totalPrice, ts: Date.now() });
  listeners.forEach((fn) => fn(payload));
}
