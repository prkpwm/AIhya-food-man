import { NextRequest, NextResponse } from 'next/server';
import { ensureInit } from '@/lib/init';
import * as orderService from '@/lib/services/order.service';

ensureInit();

export function GET(req: NextRequest) {
  const merchantId = req.nextUrl.searchParams.get('merchantId') ?? 'merchant-001';
  return NextResponse.json({ success: true, data: orderService.getGroupedActiveOrders(merchantId) });
}
