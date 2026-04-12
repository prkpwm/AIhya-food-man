import { NextRequest, NextResponse } from 'next/server';
import * as orderService from '@/lib/services/order.service';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const merchantId = req.nextUrl.searchParams.get('merchantId') ?? 'merchant-001';
    const data = await orderService.getGroupedActiveOrders(merchantId);
    return NextResponse.json({ success: true, data });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
