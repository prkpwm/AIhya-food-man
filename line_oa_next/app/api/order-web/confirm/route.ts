import { NextRequest, NextResponse } from 'next/server';
import { ensureInit } from '@/lib/init';
import * as orderService from '@/lib/services/order.service';
import { env } from '@/lib/config/env';
import { OrderItem } from '@/lib/types';

ensureInit();

export async function POST(req: NextRequest) {
  try {
    const { userId, items, merchantId } = await req.json() as {
      userId: string; items: OrderItem[]; merchantId: string;
    };

    if (!userId || !Array.isArray(items) || items.length === 0) {
      return NextResponse.json({ code: '400', en: 'Missing fields', th: 'ข้อมูลไม่ครบ' }, { status: 400 });
    }

    const order = orderService.createOrder(merchantId ?? 'merchant-001', userId, 'ลูกค้า LINE', items);
    const paymentUrl = `${env.renderExternalUrl}/payment?orderId=${order.id}`;

    return NextResponse.json({
      success: true,
      data: {
        orderId: order.id,
        shortId: order.id.slice(-6),
        totalPrice: order.totalPrice,
        estimatedWaitMinutes: order.estimatedWaitMinutes,
        items: order.items,
        paymentUrl,
      },
    });
  } catch {
    return NextResponse.json({ code: '500', en: 'Internal error', th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
