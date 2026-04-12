import { v4 as uuidv4 } from 'uuid';
import { Order, OrderItem, OrderStatus } from '../types';
import { connectDB } from '../db/mongoose';
import { OrderModel } from '../db/models';

// ─── helpers ──────────────────────────────────────────────────────────────────

function docToOrder(doc: Record<string, unknown>): Order {
  return {
    id: doc._id as string,
    merchantId: doc.merchantId as string,
    customerId: doc.customerId as string,
    customerName: doc.customerName as string,
    items: doc.items as OrderItem[],
    status: doc.status as OrderStatus,
    totalPrice: doc.totalPrice as number,
    estimatedWaitMinutes: doc.estimatedWaitMinutes as number,
    note: (doc.note as string | null) ?? null,
    createdAt: new Date(doc.createdAt as string),
    updatedAt: new Date(doc.updatedAt as string),
  };
}

// ─── public API ───────────────────────────────────────────────────────────────

export async function createOrder(
  merchantId: string, customerId: string, customerName: string,
  items: OrderItem[], note?: string,
): Promise<Order> {
  const totalPrice = items.reduce((sum, i) => sum + i.unitPrice * i.quantity, 0);
  const estimatedWaitMinutes = items.reduce((sum, i) => sum + i.quantity * 5, 0);
  const id = uuidv4();
  await connectDB();
  const doc = await OrderModel.create({
    _id: id, merchantId, customerId, customerName, items,
    status: 'pending', totalPrice, estimatedWaitMinutes, note: note ?? null,
  });
  return docToOrder(doc.toObject());
}

export async function getOrder(id: string): Promise<Order | null> {
  await connectDB();
  const doc = await OrderModel.findById(id).lean();
  return doc ? docToOrder(doc as Record<string, unknown>) : null;
}

export async function getOrdersByMerchant(merchantId: string): Promise<Order[]> {
  await connectDB();
  const docs = await OrderModel.find({ merchantId }).sort({ createdAt: -1 }).lean();
  return docs.map((d) => docToOrder(d as Record<string, unknown>));
}

export async function getOrdersByCustomer(customerId: string): Promise<Order[]> {
  await connectDB();
  const docs = await OrderModel.find({ customerId }).sort({ createdAt: -1 }).lean();
  return docs.map((d) => docToOrder(d as Record<string, unknown>));
}

export async function updateOrderStatus(id: string, status: OrderStatus): Promise<Order | null> {
  await connectDB();
  const doc = await OrderModel.findByIdAndUpdate(
    id,
    { status, ...(status === 'completed' ? { estimatedWaitMinutes: 0 } : {}) },
    { returnDocument: 'after' },
  ).lean();
  return doc ? docToOrder(doc as Record<string, unknown>) : null;
}

export async function getGroupedActiveOrders(merchantId: string): Promise<Record<string, number>> {
  await connectDB();
  const docs = await OrderModel.find({
    merchantId,
    status: { $in: ['pending', 'confirmed', 'preparing', 'ready'] },
  }).lean();
  const grouped: Record<string, number> = {};
  for (const order of docs) {
    for (const item of (order.items as OrderItem[])) {
      grouped[item.menuName] = (grouped[item.menuName] ?? 0) + item.quantity;
    }
  }
  return grouped;
}

export async function getQueueInfo(orderId: string): Promise<{ queuePosition: number; estimatedWaitMinutes: number } | null> {
  await connectDB();
  const order = await OrderModel.findById(orderId).lean();
  if (!order) return null;
  const active = await OrderModel.find({
    merchantId: (order as Record<string, unknown>).merchantId,
    status: { $in: ['pending', 'confirmed', 'preparing'] },
  }).sort({ createdAt: 1 }).lean();
  const pos = active.findIndex((o) => String(o._id) === orderId) + 1;
  const totalWait = active.slice(0, pos).reduce((sum, o) => sum + ((o as Record<string, unknown>).estimatedWaitMinutes as number), 0);
  return { queuePosition: pos > 0 ? pos : 1, estimatedWaitMinutes: totalWait };
}
