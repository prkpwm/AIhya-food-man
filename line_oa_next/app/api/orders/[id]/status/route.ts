import { NextRequest, NextResponse } from 'next/server';
import { ensureInit } from '@/lib/init';
import * as orderService from '@/lib/services/order.service';
import * as lineService from '@/lib/services/line.service';
import { env } from '@/lib/config/env';
import { OrderStatus } from '@/lib/types';

ensureInit();

const validStatuses: OrderStatus[] = ['pending','confirmed','preparing','ready','completed','cancelled'];

export async function PATCH(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const { status, notifyCustomer, userId } = await req.json() as {
    status: OrderStatus; notifyCustomer?: boolean; userId?: string;
  };

  if (!validStatuses.includes(status)) {
    return NextResponse.json({ code: '400', en: 'Invalid status', th: 'สถานะไม่ถูกต้อง' }, { status: 400 });
  }

  const order = orderService.updateOrderStatus(id, status);
  if (!order) return NextResponse.json({ code: '404', en: 'Not found', th: 'ไม่พบออเดอร์' }, { status: 404 });

  if (notifyCustomer && userId) {
    const lineResult = await lineService.pushOrderStatus(env.line.channelAccessToken, userId, order);
    return NextResponse.json({ success: true, data: order, lineResult });
  }

  return NextResponse.json({ success: true, data: order });
}
