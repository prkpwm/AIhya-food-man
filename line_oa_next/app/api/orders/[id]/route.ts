import { NextRequest, NextResponse } from 'next/server';
import { getOrder } from '@/lib/services/order.service';

export const dynamic = 'force-dynamic';

export async function GET(_req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const order = await getOrder(id);
    if (!order) return NextResponse.json({ code: '500', en: 'Not found', th: 'ไม่พบออเดอร์' }, { status: 500 });
    return NextResponse.json({ success: true, data: order });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
