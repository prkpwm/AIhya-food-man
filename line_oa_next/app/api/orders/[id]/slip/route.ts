import { NextRequest, NextResponse } from 'next/server';
import { getOrder } from '@/lib/services/order.service';
import * as lineService from '@/lib/services/line.service';
import { env } from '@/lib/config/env';

export const dynamic = 'force-dynamic';

// Store slips in memory (base64) — good enough for notification purposes
const slips = new Map<string, string>();

export async function POST(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const order = await getOrder(id);
    if (!order) return NextResponse.json({ code: '500', en: 'Order not found', th: 'ไม่พบออเดอร์' }, { status: 500 });

    const form = await req.formData();
    const file = form.get('slip') as File | null;
    if (!file) return NextResponse.json({ code: '500', en: 'No file', th: 'ไม่มีไฟล์' }, { status: 500 });

    const buf = Buffer.from(await file.arrayBuffer());
    const mime = file.type || 'image/jpeg';
    const base64 = `data:${mime};base64,${buf.toString('base64')}`;
    slips.set(id, base64);

    // notify merchant via LINE push to a merchant channel or broadcast
    // For now push a flex to the customer's LINE notifying store
    if (env.line.channelAccessToken) {
      const shortId = id.slice(-6);
      const notifyFlex = {
        type: 'flex',
        altText: `💳 ลูกค้าแนบสลิปแล้ว #${shortId}`,
        contents: {
          type: 'bubble',
          header: {
            type: 'box', layout: 'vertical', backgroundColor: '#4CAF50', paddingAll: '16px',
            contents: [
              { type: 'text', text: '💳 ได้รับสลิปการชำระเงิน', weight: 'bold', size: 'lg', color: '#ffffff' },
              { type: 'text', text: `#${shortId}`, size: 'sm', color: '#ffffff' },
            ],
          },
          body: {
            type: 'box', layout: 'vertical', spacing: 'md',
            contents: [
              { type: 'text', text: `ลูกค้า: ${order.customerName}`, size: 'sm', color: '#555555' },
              { type: 'text', text: `ยอด: ฿${order.totalPrice.toFixed(0)}`, size: 'sm', color: '#555555' },
              { type: 'text', text: 'กรุณาตรวจสอบสลิปในแอปร้าน', size: 'sm', color: '#999999' },
            ],
          },
        },
      };
      // broadcast to all (merchant will see it)
      lineService.broadcastFlex(env.line.channelAccessToken, notifyFlex).catch(() => {});
    }

    return NextResponse.json({ success: true });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}

export async function GET(_req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const slip = slips.get(id);
  if (!slip) return new NextResponse('Not found', { status: 404 });
  const match = slip.match(/^data:([^;]+);base64,(.+)$/);
  if (!match) return new NextResponse('Invalid', { status: 400 });
  return new NextResponse(Buffer.from(match[2], 'base64'), {
    headers: { 'Content-Type': match[1] },
  });
}
