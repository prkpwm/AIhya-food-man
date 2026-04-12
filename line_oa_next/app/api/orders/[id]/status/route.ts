import { NextRequest, NextResponse } from 'next/server';
import * as orderService from '@/lib/services/order.service';
import * as lineService from '@/lib/services/line.service';
import { env } from '@/lib/config/env';
import { OrderStatus } from '@/lib/types';

const validStatuses: OrderStatus[] = ['pending','confirmed','preparing','ready','completed','cancelled'];

export async function PATCH(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const { status, notifyCustomer, userId } = await req.json() as {
      status: OrderStatus; notifyCustomer?: boolean; userId?: string;
    };
    if (!validStatuses.includes(status)) {
      return NextResponse.json({ code: '400', en: 'Invalid status', th: 'สถานะไม่ถูกต้อง' }, { status: 400 });
    }
    const order = await orderService.updateOrderStatus(id, status);
    if (!order) return NextResponse.json({ code: '500', en: 'Not found', th: 'ไม่พบออเดอร์' }, { status: 500 });
    if (notifyCustomer && userId) {
      await lineService.pushOrderStatus(env.line.channelAccessToken, userId, order).catch(() => {});
    }
    return NextResponse.json({ success: true, data: order });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
