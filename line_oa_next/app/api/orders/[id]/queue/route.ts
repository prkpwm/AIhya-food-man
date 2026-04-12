import { NextRequest, NextResponse } from 'next/server';
import { ensureInit } from '@/lib/init';
import { getQueueInfo } from '@/lib/services/order.service';

ensureInit();

export const dynamic = 'force-dynamic';

export function GET(_req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  return params.then(({ id }) => {
    const info = getQueueInfo(id);
    if (!info) {
      return NextResponse.json({ code: '500', en: 'Order not found', th: 'ไม่พบออเดอร์' }, { status: 500 });
    }
    return NextResponse.json({ success: true, data: info });
  });
}
