import { NextRequest, NextResponse } from 'next/server';
import { ensureInit } from '@/lib/init';
import * as orderService from '@/lib/services/order.service';
import { OrderItem } from '@/lib/types';

ensureInit();

export function GET(req: NextRequest) {
  const merchantId = req.nextUrl.searchParams.get('merchantId') ?? 'merchant-001';
  return NextResponse.json({ success: true, data: orderService.getOrdersByMerchant(merchantId) });
}

export async function POST(req: NextRequest) {
  const { merchantId, customerId, customerName, items, note } = await req.json() as {
    merchantId: string; customerId: string; customerName: string; items: OrderItem[]; note?: string;
  };
  if (!merchantId || !customerId || !customerName || !Array.isArray(items)) {
    return NextResponse.json({ code: '400', en: 'Missing required fields', th: 'ข้อมูลไม่ครบถ้วน' }, { status: 400 });
  }
  const order = orderService.createOrder(merchantId, customerId, customerName, items, note);
  return NextResponse.json({ success: true, data: order }, { status: 201 });
}
