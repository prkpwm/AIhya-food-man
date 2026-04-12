import { NextRequest, NextResponse } from 'next/server';
import { ensureInit } from '@/lib/init';
import { getOrdersByCustomer } from '@/lib/services/order.service';

ensureInit();

export const dynamic = 'force-dynamic';

export function GET(req: NextRequest) {
  const userId = req.nextUrl.searchParams.get('userId');
  if (!userId) {
    return NextResponse.json({ code: '500', en: 'userId required', th: 'กรุณาระบุ userId' }, { status: 500 });
  }
  const activeStatuses = new Set(['pending', 'confirmed', 'preparing', 'ready']);
  const orders = getOrdersByCustomer(userId)
    .filter((o) => activeStatuses.has(o.status))
    .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
    .map((o) => ({
      id: o.id,
      status: o.status,
      items: o.items,
      totalAmount: o.totalPrice,
      estimatedWaitMinutes: o.estimatedWaitMinutes,
      createdAt: o.createdAt,
    }));
  return NextResponse.json({ success: true, orders });
}
