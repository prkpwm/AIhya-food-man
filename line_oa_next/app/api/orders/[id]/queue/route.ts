import { NextRequest, NextResponse } from 'next/server';
import { getQueueInfo } from '@/lib/services/order.service';

export const dynamic = 'force-dynamic';

export async function GET(_req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const info = await getQueueInfo(id);
    if (!info) return NextResponse.json({ code: '500', en: 'Order not found', th: 'ไม่พบออเดอร์' }, { status: 500 });
    return NextResponse.json({ success: true, data: info });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
