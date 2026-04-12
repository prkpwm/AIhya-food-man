import { NextRequest, NextResponse } from 'next/server';
import { getOrdersByCustomer } from '@/lib/services/order.service';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const userId = req.nextUrl.searchParams.get('userId');
    if (!userId) return NextResponse.json({ code: '500', en: 'userId required', th: 'กรุณาระบุ userId' }, { status: 500 });
    const activeStatuses = new Set(['pending', 'confirmed', 'preparing', 'ready']);
    const all = await getOrdersByCustomer(userId);
    const orders = all
      .filter((o) => activeStatuses.has(o.status))
      .map((o) => ({ id: o.id, status: o.status, items: o.items, totalAmount: o.totalPrice, estimatedWaitMinutes: o.estimatedWaitMinutes, createdAt: o.createdAt }));
    return NextResponse.json({ success: true, orders });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
