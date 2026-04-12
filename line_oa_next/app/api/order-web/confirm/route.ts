import { NextRequest, NextResponse } from 'next/server';
import { ensureInit } from '@/lib/init';
import * as orderService from '@/lib/services/order.service';
import * as lineService from '@/lib/services/line.service';
import { emitNewOrder } from '@/lib/services/order_events';
import { env } from '@/lib/config/env';
import { Order, OrderItem } from '@/lib/types';

ensureInit();

function buildConfirmFlex(order: Order, paymentUrl: string) {
  const itemRows = order.items.map((i) => {
    const spice = i.spiceLevel > 0 ? ` (เผ็ด ${i.spiceLevel})` : '';
    const note = i.customNote ? ` [${i.customNote}]` : '';
    return {
      type: 'box', layout: 'baseline', contents: [
        { type: 'text', text: `${i.menuName} ×${i.quantity}${spice}${note}`, size: 'sm', color: '#555555', flex: 4 },
        { type: 'text', text: `฿${(i.unitPrice * i.quantity).toFixed(0)}`, align: 'end', size: 'sm', flex: 2 },
      ],
    };
  });

  const waitText = order.estimatedWaitMinutes > 0
    ? [{ type: 'text', text: `⏱ รอประมาณ ${order.estimatedWaitMinutes} นาที`, size: 'sm', color: '#999999' }]
    : [];

  return {
    type: 'flex',
    altText: `✅ ยืนยันออเดอร์ #${order.id.slice(-6)} — ฿${order.totalPrice.toFixed(0)}`,
    contents: {
      type: 'bubble',
      header: {
        type: 'box', layout: 'vertical', backgroundColor: '#FF6B00', paddingAll: '16px',
        contents: [
          { type: 'text', text: '✅ ยืนยันออเดอร์แล้ว', weight: 'bold', size: 'lg', color: '#ffffff' },
          { type: 'text', text: `#${order.id.slice(-6)}`, size: 'sm', color: 'rgba(255,255,255,0.8)' },
        ],
      },
      body: {
        type: 'box', layout: 'vertical', spacing: 'md',
        contents: [
          ...itemRows,
          { type: 'separator', margin: 'sm' },
          { type: 'box', layout: 'baseline', contents: [
            { type: 'text', text: 'ยอดรวม', size: 'sm', color: '#555555', flex: 4 },
            { type: 'text', text: `฿${order.totalPrice.toFixed(0)}`, align: 'end', size: 'lg', weight: 'bold', color: '#FF6B00', flex: 2 },
          ]},
          ...waitText,
        ],
      },
      footer: {
        type: 'box', layout: 'vertical', spacing: 'sm',
        contents: [
          { type: 'button', style: 'primary', color: '#FF6B00', action: { type: 'uri', label: '📦 ติดตามสถานะ', uri: `${env.liffUrl}?page=status` } },
          { type: 'button', style: 'secondary', action: { type: 'uri', label: '🍽️ สั่งเพิ่ม', uri: `${env.liffUrl}?page=order` } },
        ],
      },
    },
  };
}

export async function POST(req: NextRequest) {
  try {
    const { userId, items, merchantId } = await req.json() as {
      userId: string; items: OrderItem[]; merchantId: string;
    };

    if (!userId || !Array.isArray(items) || items.length === 0) {
      return NextResponse.json({ code: '400', en: 'Missing fields', th: 'ข้อมูลไม่ครบ' }, { status: 400 });
    }

    const order = await orderService.createOrder(merchantId ?? 'merchant-001', userId, 'ลูกค้า LINE', items);
    const paymentUrl = `${env.renderExternalUrl}/payment?orderId=${order.id}`;
    const flex = buildConfirmFlex(order, paymentUrl);

    // notify SSE listeners (merchant app)
    emitNewOrder(order.id, order.customerName, order.totalPrice);

    // push flex to user — fire and forget (don't fail the order if LINE push fails)
    if (env.line.channelAccessToken) {
      lineService.pushFlex(env.line.channelAccessToken, userId, flex).catch(() => {});
    }

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
