import { v4 as uuidv4 } from 'uuid';
import { Order, OrderItem, OrderStatus } from '../types';

const orders: Map<string, Order> = new Map();

export function createOrder(merchantId: string, customerId: string, customerName: string, items: OrderItem[], note?: string): Order {
  const totalPrice = items.reduce((sum, i) => sum + i.unitPrice * i.quantity, 0);
  const estimatedWaitMinutes = items.reduce((sum, i) => sum + i.quantity * 5, 0);
  const order: Order = { id: uuidv4(), merchantId, customerId, customerName, items, status: 'pending', totalPrice, estimatedWaitMinutes, note: note ?? null, createdAt: new Date(), updatedAt: new Date() };
  orders.set(order.id, order);
  return order;
}
export function getOrder(id: string): Order | null { return orders.get(id) ?? null; }
export function getOrdersByMerchant(merchantId: string): Order[] {
  return [...orders.values()].filter((o) => o.merchantId === merchantId);
}
export function getOrdersByCustomer(customerId: string): Order[] {
  return [...orders.values()].filter((o) => o.customerId === customerId);
}
export function updateOrderStatus(id: string, status: OrderStatus): Order | null {
  const order = orders.get(id);
  if (!order) return null;
  const updated = { ...order, status, estimatedWaitMinutes: status === 'completed' ? 0 : order.estimatedWaitMinutes, updatedAt: new Date() };
  orders.set(id, updated);
  return updated;
}
export function getGroupedActiveOrders(merchantId: string): Record<string, number> {
  const active = [...orders.values()].filter((o) => o.merchantId === merchantId && ['pending','confirmed','preparing','ready'].includes(o.status));
  const grouped: Record<string, number> = {};
  for (const order of active) for (const item of order.items) grouped[item.menuName] = (grouped[item.menuName] ?? 0) + item.quantity;
  return grouped;
}
