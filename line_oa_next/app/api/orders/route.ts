import { NextRequest, NextResponse } from 'next/server';
import * as orderService from '@/lib/services/order.service';
import { OrderItem } from '@/lib/types';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const merchantId = req.nextUrl.searchParams.get('merchantId') ?? 'merchant-001';
    const data = await orderService.getOrdersByMerchant(merchantId);
    return NextResponse.json({ success: true, data });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const { merchantId, customerId, customerName, items, note } = await req.json() as {
      merchantId: string; customerId: string; customerName: string; items: OrderItem[]; note?: string;
    };
    if (!merchantId || !customerId || !customerName || !Array.isArray(items)) {
      return NextResponse.json({ code: '400', en: 'Missing required fields', th: 'ข้อมูลไม่ครบถ้วน' }, { status: 400 });
    }
    const order = await orderService.createOrder(merchantId, customerId, customerName, items, note);
    return NextResponse.json({ success: true, data: order }, { status: 201 });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
